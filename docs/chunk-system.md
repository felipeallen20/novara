# Sistema de generación de chunks — NOVARA

Documento de diseño del sistema de mundo voxel. Describe las decisiones fijadas, la
organización de la escena y del código, y el orden de implementación.

## 1. Decisiones fijadas

| Tema | Decisión |
| --- | --- |
| Topología | Grid cartesiano plano por planeta. |
| Chunk | Cubo de `32 x 32 x 32` vóxeles. |
| Alcance | Efectivamente infinito en horizontal, con streaming alrededor del jugador. |
| Vertical | Banda configurable `chunk_min_y .. chunk_max_y` (no esfera 3D completa). |
| Ejecución | Multihilo desde el inicio (generación y meshing en worker threads). |

La banda vertical existe porque un radio de streaming esférico en 3D hace crecer el
número de chunks al cubo del radio. Un cilindro (radio horizontal + banda vertical)
mantiene el coste controlado.

## 2. Capas del sistema

Cada capa tiene una responsabilidad y no conoce a las demás más de lo necesario:

1. **Datos del mundo** — identificadores de bloque, `ChunkData`, matemática de
   coordenadas de chunk. Sin nodos ni render.
2. **Generación** — llena un `ChunkData` de forma determinista a partir de semilla y
   coordenada. Sin nodos.
3. **Meshing** — convierte un `ChunkData` en arrays de geometría (vértices, índices,
   colores). Puro cálculo, sin escena.
4. **Presentación** — `ChunkView` aplica esos arrays a un `MeshInstance3D`.
5. **Streaming** — decide qué chunks existen, encola trabajo y descarga los lejanos.
6. **Interacción** — raycast DDA sobre los datos, edición de bloque y marcado de chunks
   sucios.

Regla: generación y meshing **no** conocen nodos ni cámara. Eso permite moverlos a
hilos y reutilizarlos en pruebas sin tocar el árbol de escena.

## 3. Estructura de carpetas

```text
res://
  docs/          chunk-system.md
  scenes/        world.tscn, chunk_view.tscn, player.tscn
    minerals/    sandite.tscn, ferrite.tscn (modelos de depósitos de cristales)
    plants/      oxyfern.tscn (modelo de una planta)
    workspace/   fabricator.tscn (estación de fabricación)
    tools/       mining_pistol.tscn
    ui/          hud.tscn, interaction_prompt.tscn (aviso de interacción),
                 crafting/crafting_ui.tscn (interfaz de fabricación)
  shaders/       alien_sky.gdshader
  scripts/
    blocks/      block.gd, soft_ground.gd, lavender_stone.gd, dark_stone.gd, block_registry.gd
    generation/  biome.gd, mining_lands_biome.gd, terrain_generator.gd, mineral_spawner.gd,
                 plant_spawner.gd
    minerals/    mineral.gd, sandite.gd, ferrite.gd, mineral_registry.gd, mineral_spawn.gd,
                 mineral_deposit.gd, crystal_mesh.gd
    plants/      plant.gd, oxyfern.gd, plant_spawn.gd
    items/       item.gd, sandite_item.gd, ferrite_item.gd, inventory_data.gd, loot_table.gd
    interaction/ interactable.gd
    workspace/   fabricator.gd
    player/      player_controller.gd
    voxel/       chunk_coord.gd, chunk_data.gd, chunk_mesh_data.gd, chunk_mesher.gd
    world/       chunk_view.gd, chunk_streamer.gd, world.gd, safe_zone.gd
  data/          (bloques .tres, world_config.tres) — pendiente
```

`world.tscn` se mantiene en `scenes/` para no mover el archivo ya existente. Cuando
haya más escenas de mundo se agruparán en `scenes/world/`.

## 4. Escena

```text
World (Node3D)                 ← world.tscn, script world.gd (raíz y punto de entrada)
├── WorldEnvironment           ← Environment con cielo procedural (sección 15)
├── DirectionalLight3D         ← sol cálido; sombras suaves
├── ChunkStreamer (Node3D)     ← contenedor y streaming; sus hijos son ChunkView
└── Player                     ← player.tscn, cámara en primera persona
```

- `World` lee la configuración, crea el registro de bloques, el generador y el mesher, y
  los inyecta en el streamer.
- `ChunkStreamer` agrupa los `ChunkView` y decide qué chunks existen.
- Cada `ChunkView` es una escena pequeña: `Node3D` + `MeshInstance3D` + `StaticBody3D`
  con `CollisionShape3D`.
- El `WorldEnvironment` y la `DirectionalLight3D` solo describen el cielo y la luz; no
  participan en la generación ni en el streaming.
- Nada de esto es Autoload. El `BlockRegistry` es un `Resource` creado y compartido por
  `World`, no un estado global.

## 5. Coordenadas y datos

- `ChunkCoord`: `Vector3i` en unidades de chunk. Funciones estáticas de conversión
  mundo ↔ chunk ↔ local. Es la única fuente de verdad de esa matemática.
- `ChunkData`: `PackedByteArray` de `size³`, índice `x + z*size + y*size*size`. Un byte
  por vóxel = 256 tipos de bloque. `0` es aire (`ChunkData.AIR`); los bloques reales
  usan identificadores `>= 1`. Además lleva `mineral_spawns`, los depósitos de
  minerales que la generación decide sobre la superficie del chunk (sección 17).
- `ChunkMeshData`: contenedor de `vertices`, `normals`, `colors`, `indices`. Es el
  objeto que se transfiere del hilo de cálculo al hilo principal.

## 6. Bloques

- `Block` (Resource): plantilla con las características comunes (`id`, `display_name`,
  `color`, `opaque`, `solid`). Todos los bloques heredan de ella.
- `SoftGround` (hereda de `Block`): bloque base de superficie, color beige/amarillo.
- `LavenderStone` (hereda de `Block`): piedra de superficie de tono lavanda, algo más
  clara. Comparte terreno con `SoftGround`.
- `DarkStone` (hereda de `Block`): piedra de tono morado oscuro. Completa la paleta
  mineral junto a `SoftGround` y `LavenderStone`.
- `BlockRegistry` (Resource): asocia `id → Block`. Se construye una vez y se comparte
  sin modificarse, lo que lo hace seguro para los hilos.
- Los bloques de superficie se dibujan con su color plano. El atlas de texturas solo
  se construye si algún bloque tiene `textures` asignado; mientras ninguno lo tenga,
  el terreno usa un material sin atlas.
- A futuro, los bloques podrán definirse también como `.tres` sobre `Block` para
  ajustarlos desde el editor sin tocar código.

## 7. Generación

- `TerrainGenerator`: función pura de `(semilla, coordenada)`. Usa `FastNoiseLite` para
  una altura irregular. Dos ejecuciones con la misma semilla dan el mismo `ChunkData`,
  sea en el hilo que sea.
- El coste por chunk está dominado por el recorrido de vóxeles, así que la generación
  evalúa el ruido **una vez por columna** (no una por vóxel, que multiplicaba el coste
  por la altura del chunk) y vuelca cada columna con `ChunkData.fill_column`, sin una
  llamada por vóxel.
- **Material de superficie**: un segundo ruido, con semilla y frecuencia propias, elige el
  bloque de cada columna. Dos umbrales (`-0.33` y `0.33`) dividen el ruido en tres
  bandas de extensión comparable, una por bloque de superficie (`SoftGround`,
  `LavenderStone` y `DarkStone`); mover los umbrales cambia la proporción de cada
  material. Sigue siendo una muestra de ruido por columna, y una columna entera comparte
  material.
- **Safe zone**: `SafeZone` define un área de `8 x 8` columnas centrada en el punto de
  aparición del jugador. `World` la construye a partir de la posición del `Player` en la
  escena y la inyecta al generador, que aplana esas columnas a `BASE_HEIGHT`, y al
  jugador, que imprime `Safe Zone` / `Fuera de Safe Zone` al entrar o salir caminando.
  Es inmutable tras construirse, por lo que los hilos de generación pueden leerla.
- La configuración (semilla, frecuencia, amplitud, materiales, biomas) vivirá en un
  `WorldConfig` para no repartir números mágicos.

## 8. Meshing

- **Culling de caras**: se emite una cara solo si el vóxel vecino no es opaco.
- **Oclusión ambiental por vértice**: se muestrean los tres vóxeles que rodean cada
  esquina de la cara y el resultado se aplica como brillo del color de vértice. La
  diagonal del quad se elige entre las esquinas con más luz para evitar bandas.
- **Vecinos**: `build()` recibe los `ChunkData` de los seis vecinos en el orden de
  `ChunkMesher.NEIGHBOR_OFFSETS`. Un vecino ausente se trata como aire.
- Los arrays se construyen sin tocar nodos; el `ArrayMesh` se crea en el hilo principal.
- **Winding**: las esquinas de cada cara (`_FACE_CORNERS`) están en el orden que hace que
  el frente del triángulo, `(p0 - p2) x (p0 - p1)`, apunte en la dirección de la normal.
  Godot considera frontal el winding horario visto desde fuera, y `create_trimesh_shape()`
  deriva la normal de colisión del mismo winding. Como el trimesh es de una sola cara
  (`backface_collision = false`), con el winding invertido el terreno se ve por dentro y
  el jugador lo atraviesa.
- **Colisión**: `ChunkView` genera la forma a partir del mismo mesh
  (`ArrayMesh.create_trimesh_shape()`), así que no hay que recalcular nada aparte.
- Pendiente: superficies transparentes separadas y greedy meshing (solo si se mide que
  hace falta).

## 9. Streaming

Implementado en `ChunkStreamer`, que es además el nodo contenedor de chunks. En cada
frame:

1. Se calcula la coordenada de chunk del visor.
2. Si el visor cambió de chunk, se recalcula el conjunto deseado: cilindro (radio
   horizontal `load_distance` y banda vertical absoluta), ordenado por distancia al
   visor. Mientras no cambie, el conjunto y su orden se reutilizan.
3. Diff contra el estado cargado: se encolan los que faltan; el resto sigue su curso.
4. Descarga con histéresis: un chunk se libera solo cuando supera `unload_distance`, que
   es mayor que `load_distance`, para no recargar lo que se acaba de soltar.
5. Presupuesto: `MAX_TASKS_IN_FLIGHT` tareas de generación/meshing en vuelo como máximo
   (no se encolan más hasta que terminen) y `MAX_RESULTS_PER_FRAME` aplicaciones por frame
   (crear nodo, mesh y colisión).

## 10. Hilos

- Generación: una tarea de `WorkerThreadPool` por chunk.
- Meshing: otra tarea, que recibe el `ChunkData` del chunk y su vecindario ya
  resueltos en el hilo principal. Solo se lanza cuando los vecinos que van a existir
  están generados.
- **Ningún hilo toca el árbol de escena ni `RenderingServer`.** Los resultados se
  publican en una lista protegida por `Mutex` y el hilo principal la drena por frame.
- El hilo principal es el único que lee y escribe `_states`, `_chunk_data` y `_views`.
- Invariante: un chunk en estado `GENERATED` siempre tiene su `ChunkData` guardado. El
  estado se marca **donde se guarda el resultado**, no al terminar la tarea; entre esos
  dos momentos el chunk todavía no tiene con qué mallarse.
- Descarte: si un chunk desaparece antes de que termine su tarea, su resultado se ignora
  al llegar. Un chunk con una tarea en vuelo no se descarga hasta que la tarea termina.
- Al salir del árbol se esperan las tareas en vuelo para que no referencien un nodo
  liberado.
- `TerrainGenerator` es sin estado mutable (crea su ruido por llamada) y
  `BlockRegistry` es de solo lectura, por lo que ambos son seguros de compartir.

## 11. Edición de bloques

- Raycast DDA sobre los datos (no sobre la física): más barato y fiable, y funciona
  aunque el chunk todavía no tenga colisión.
- `set_block` marca sucio el chunk dueño y, si el vóxel toca una cara de borde, también
  el vecino, para re-meshear ambos.

## 12. Persistencia

- La generación es determinista con la semilla, así que solo se guardan las **ediciones
  del jugador** (coord → id). Al cargar se regenera y se reaplican.
- Formato versionado por chunk.

## 13. Fases de implementación

1. **Hecho** — `ChunkCoord`, `ChunkData`, `Block`, `SoftGround`, `BlockRegistry`,
   `TerrainGenerator`, `ChunkMesher`, `ChunkView` y un chunk irregular visible.
2. **Hecho** — AO por vértice y colisión por chunk.
3. **Hecho** — `ChunkStreamer` con cilindro de carga, histéresis y presupuesto por frame.
4. **Hecho** — generación y meshing en `WorkerThreadPool`.
5. **En curso** — jugador en primera persona (hecho) y edición de bloques con re-mesh de
   vecinos (pendiente).
6. Biomas y `WorldConfig` como recurso.
7. Persistencia de ediciones.
8. **Hecho** — minerales de superficie: `Mineral`, `Sandite`, `MineralSpawner` y
   depósitos instanciados en la vista del chunk (sección 17). Pendiente: minado y
   recolección de los depósitos.

## 14. Verificación

- **Determinismo**: misma semilla + coordenada → mismo hash de `ChunkData`.
- **Meshing**: chunk conocido → número de triángulos esperado.
- **Streaming**: conteo de cargados/descargados tras moverse de chunk.
- **Hilos**: mismo resultado final con y sin hilos; sin fugas de `Thread` al cerrar.

## 15. Cielo e iluminación

Todo vive en `scenes/world.tscn` (`WorldEnvironment` + `DirectionalLight3D`); no hay
nodos, scripts ni recursos adicionales más allá del shader del cielo.

- **Cielo**: `Environment` con `background_mode = BG_SKY` y un `Sky` cuyo material es un
  `ShaderMaterial` sobre `shaders/alien_sky.gdshader`. El shader es de tipo `sky` y dibuja
  el degradado vertical a partir de `EYEDIR`, así que no depende de texturas externas y
  también sirve para el cubemap de radiancia (reflejos).
- **Paleta**: los colores por defecto de los uniforms del shader (`zenith_color`,
  `upper_color`, `middle_color`, `lower_color`, `horizon_color`, `ground_color`) van de
  violeta en el cénit a naranja cálido en el horizonte, pasando por lavanda, rosa y
  melocotón. `horizon_gradient` reparte la banda cálida y `horizon_glow` añade el
  resplandor de la estrella. El `ShaderMaterial` no sobreescribe ningún uniform: la
  paleta tiene una única fuente de verdad y se ajusta desde el inspector.
- **Luz ambiental**: `ambient_light_source = AMBIENT_SOURCE_COLOR` con un lavanda medio y
  `ambient_light_energy` moderada, para rellenar las sombras con el color de la paleta sin
  lavar el color propio de los bloques. `ambient_light_sky_contribution` se deja en `0.0`
  a propósito: el color y la energía de la luz ambiental solo se aplican cuando la
  contribución del cielo es menor que `1.0`; con `1.0` la única fuente sería el cielo y
  ambos parámetros quedarían sin efecto.
- **Tonemapping**: `TONE_MAPPER_FILMIC` con `tonemap_exposure` algo por encima de `1.0`.
  La curva filmica evita que el resplandor cálido del horizonte se recorte, y la exposición
  compensa que esa curva oscurece ligeramente los medios tonos.
- **Sol**: `DirectionalLight3D` con color cálido, energía moderada y
  `light_angular_distance`, que da penumbra suave (el disco solar deja de ser puntual).
  El nodo tenía rotación identidad, así que la luz viajaba en horizontal (`-Z` del nodo) y
  las caras superiores del terreno no recibían luz directa; ahora el sol está alto (≈53°)
  y a la derecha-detrás del jugador.
- **Sombras**: `shadow_enabled` con `directional_shadow_max_distance` ajustado al radio de
  carga del streamer (`LOAD_DISTANCE_CHUNKS * 32` vóxeles), de modo que las sombras se
  desvanecen antes del borde de carga y no aparecen y desaparecen al avanzar.

## 16. Pendientes y limitaciones conocidas

- El material del chunk usa el culling por defecto, con el winding de `_FACE_CORNERS`
  alineado con la convención horaria de Godot. Conviene volver a comprobarlo si se
  cambia el orden de las esquinas o de los índices.
- La colisión de un chunk es un `ConcavePolygonShape3D` de una sola cara: solo frena
  desde el exterior. Si el jugador atravesara el terreno, revisar el winding antes que la
  capa de colisión.
- Sin `WorldConfig`: los parámetros de mundo viven como constantes en `world.gd` y
  `terrain_generator.gd` hasta la fase 6.
- El visor del streamer es el nodo `Player` de `world.tscn` (cámara en primera persona).
- La construcción de colisión (`create_trimesh_shape()`) ocurre en el hilo principal y es
  la parte más cara de aplicar un chunk; por eso `MAX_RESULTS_PER_FRAME` es bajo. Si
  molesta, limitar la colisión a los chunks cercanos.
- Sin edición de bloques todavía: el chunk se puede pisar pero no modificar.

## 17. Minerales de superficie

Los minerales no son bloques: son depósitos con forma propia que la generación coloca
sobre la superficie, separados en capas para no acoplar datos, generación y render:

- `Mineral` (Resource): plantilla con las propiedades comunes (`id`, `display_name`,
  `rarity`, `durability`, `yield_amount`, `color`, `host_block_id`, `model`,
  `patch_threshold` y `scatter_threshold`). Todos los minerales heredan de ella, igual
  que los bloques. Los dos umbrales deciden la abundancia del mineral: los yacimientos
  cubren mucha más superficie cuanto menor es el umbral de parche, y dentro del
  yacimiento hay más cristales cuanto menor es el de dispersión.
- `Sandite` (hereda de `Mineral`): Arenita, mineral común gris/café. Crece sobre las
  columnas de `SoftGround` y su `model` es `scenes/minerals/sandite.tscn`.
- `Ferrite` (hereda de `Mineral`): Ferrita, mineral muy común de tono gris metálico.
  Crece sobre las columnas de `DarkStone`, con umbrales bajos para que los yacimientos
  sean frecuentes, y su `model` es `scenes/minerals/ferrite.tscn`.
- `MineralRegistry` (Resource): asocia `id → Mineral`; se construye una vez en `World`
  y se comparte sin modificarse.
- `MineralSpawner`: decide qué columnas tienen depósito. Cada mineral usa dos ruidos
  derivados de la semilla del mundo y de su id: uno de parche (`patch_frequency` y el
  `patch_threshold` del mineral) marca los yacimientos y otro de dispersión
  (`scatter_frequency` y el `scatter_threshold` del mineral) reparte los cristales
  dentro de cada parche, para que no salgan bloques macizos de cristal. Dos minerales
  no comparten emplazamientos y la generación sigue siendo determinista sin guardar
  nada. Inmutable tras `setup`, con el mismo contrato que `Biome`.
- `MineralSpawn`: dato puro (`mineral_id`, `local_position`, `rotation`, `scale`,
  `variation_seed`) que la generación añade a `ChunkData.mineral_spawns`, en
  coordenadas locales del chunk. `TerrainGenerator` no pide depósitos dentro de la
  safe zone, que queda limpia para la aparición.
- `CrystalMesh`: construye la malla del depósito por código: un grupo de astas
  facetadas con normales por cara (sombreado plano) y el tinte del mineral en los
  vértices, de modo que un único material sirve para todos los minerales. Cada asta
  se hunde ligeramente (`BASE_SINK`) para que su giro no levante la base del suelo.
- `MineralDeposit` (script de `sandite.tscn`): instancia el modelo y construye su
  malla con `apply(mineral, variation_seed)`. La semilla sale de la posición de la
  columna, así el mismo sitio siempre luce el mismo depósito.
- Streaming: `ChunkStreamer` instancia los depósitos del chunk como hijos de su
  `ChunkView` al crearla, así se descargan con la vista sin llevar una cuenta aparte.
  No tienen colisión todavía: el minado y la recolección están pendientes.

## 18. Zona de trabajo

Objetos fijos del mundo que no son terreno ni mineral, colocados a mano en la zona
segura:

- `Fabricator` (script de `scenes/workspace/fabricator.tscn`): la estación de
  fabricación. La escena instancia el modelo importado
  (`assets/models/workspace/estacion-fabricacion.glb`), lo gira para que su parte
  alta quede contra el borde y lo apoya en el suelo.
- El modelo importado no trae normales, así que el script las genera al entrar en el
  árbol: sin ellas no hay luz difusa y el objeto saldría negro. La orientación de
  cada cara se decide mirando hacia fuera desde el centro de la malla, para no
  depender del sentido de los triángulos del archivo.
- El color va en los vértices (degradado vertical suave sobre el color base) y el
  material es el sombreado estilizado de `resources/materials/workspace_style.tres`,
  con `use_atlas = false` porque el modelo no tiene textura.
- La colocación en el mundo está en `world.tscn`: la instancia va en el borde
  izquierdo de la zona segura (el jugador aparece en `(16, 16)` mirando hacia `-Z`,
  así que su izquierda es `-X`), apoyada en el suelo de la zona segura
  (`y = base_height + 1`). Fuera de la zona segura el terreno es más alto, así que
  la estación queda contra ese desnivel. El giro y la escala van en el transform de
  esa instancia: al instanciar una escena, el transform del nodo en el padre sustituye
  al de la raíz, así que el tamaño final se ajusta en `world.tscn` y no en
  `fabricator.tscn`.
- Al apuntarla y pulsar la tecla `interaction` (E) se abre su interfaz de
  fabricación (`scenes/ui/crafting/crafting_ui.tscn`), que ahora mismo está vacía:
  no hay recetas todavía.

## 19. Plantas

Vegetación que crece sobre el terreno, generada con las mismas reglas que los
minerales (datos puros en el hilo de cálculo, representación en el hilo principal):

- `Plant` (Resource): plantilla de planta (`id`, `display_name`, `model`,
  `host_block_id`, `cliff_block_ids`, `min_cliff_height`, `density`, `spacing` y
  `scale_range`). `can_grow` decide si la superficie le sirve: tiene que ser su
  bloque de host.
- `Oxyfern` (hereda de `Plant`): helecho que crece sobre `SoftGround`, al pie de
  los bordes de roca que la superan por 4 o más bloques (`cliff_block_ids` con
  `DarkStone` y `LavenderStone`). Su modelo es `scenes/plants/oxyfern.tscn`.
- `PlantSpawner`: decide qué plantas nacen en cada columna, con tres filtros:
  1. **Superficie**: la columna tiene que ser del bloque de host de la planta.
  2. **Separación**: el mundo se divide en celdas de `spacing` bloques y solo el
     anclaje de cada celda (una columna elegida con semilla) puede tener planta,
     así que no se amontonan.
  3. **Desnivel**: a `CLIFF_RADIUS` bloques en las ocho direcciones tiene que haber
     roca que la supere por `min_cliff_height` bloques. Es lo que las mantiene al
     pie de las montañas y en ningún otro sitio.
  Encima de eso, `density` decide el porcentaje de columnas que pasan.
- `PlantSpawn`: dato puro (`plant_id`, `local_position`, `rotation`, `scale`) que la
  generación añade a `ChunkData.plant_spawns`. Como los minerales, las plantas no
  nacen dentro de la safe zone.
- Streaming: `ChunkStreamer` instancia las plantas del chunk como hijas de su
  `ChunkView`, con la posición, el giro y la escala que decidió la generación.
- La lista de plantas vive en `world.gd`; con una o dos plantas no hace falta un
  registro propio, el streamer las busca por id.
- El modelo de la Oxyfern viene en centímetros, así que la escena lo escala a 0.006
  (unos 0,4 bloques de alto) y le pone el material del juego con el color en el
  uniforme `base_color` del shader.

### Recoger plantas

- `PlantPickup` (script de `scenes/plants/oxyfern.tscn`): planta que se puede recoger.
  La escena lleva un `Area3D` (un cilindro bajo y fino) para que el rayo de puntería
  la alcance. La planta no lleva ningún aviso: el HUD lo dibuja como elemento de
  interfaz.
- `PlayerController` apunta con su `RayCast3D`: si el collider es el `Area3D` de una
  planta y está a menos de `pick_up_distance` bloques, la planta queda enfocada y la
  tecla `interaction` (E) la recoge. El item va al inventario (`InventoryData.add`) y
  la planta desaparece del mundo.
- `PlayerController` avisa del cambio de foco con la señal `interaction_focus_changed`
  (la planta enfocada, o null si ya no hay ninguna). El HUD se conecta a ella en vez de
  consultar la puntería cada frame.
- `InteractionPrompt` (`scenes/ui/interaction_prompt.tscn`): aviso del HUD con la tecla
  que hay que pulsar (`E`) y la acción (`Recoger Oxyfern`). Es un `Control` de 2D: se
  proyecta la posición de la planta con `Camera3D.unproject_position` y se coloca un
  poco por encima, dentro de la pantalla, para que se lea siempre con nitidez y no se
  confunda con la geometría de la escena.
- `OxyfernItem` (id 3) es el objeto que deja, con el icono de
  `assets/items/icons/plants/oxyfern.png`.
- Aviso: como la planta desaparece al recogerla, la del chunk vuelve a aparecer si
  el chunk se vuelve a cargar. La persistencia del mundo sigue pendiente.

## 20. Interacción

Todo lo con lo que el jugador puede interactuar (una planta, una estación)
comparte la misma base, para que el jugador no repita la lógica de puntería por
cada tipo de objeto:

- `Interactable` (`scripts/interaction/interactable.gd`): base de los objetos
  interactuables. Cada uno decide el texto del aviso
  (`get_interaction_text`), hasta dónde se puede interactuar
  (`get_interaction_distance`) y qué ocurre al interactuar (`interact`). También
  declara `interaction_ui`: la interfaz que se abre al interactuar, si tiene alguna.
- `PlayerController` apunta con su `RayCast3D` y busca el `Interactable` al que
  pertenece el nodo colisionado, subiendo por sus padres (el `Area3D` de una planta,
  el `StaticBody3D` de la estación). Si está dentro del alcance que permite el
  objeto, entra en el foco:
  - `interaction_focus_changed(target)`: el HUD muestra u oculta el aviso.
  - `interaction_performed(target)`: el HUD abre la interfaz del objeto, si tiene.
- `PlantPickup` y `Fabricator` heredan de `Interactable`. La planta se recoge y su
  item va al inventario; la estación abre su interfaz de fabricación.
- `CraftingUi` (`scenes/ui/crafting/crafting_ui.tscn`): interfaz de fabricación. Se
  muestra al entrar en el árbol y se libera al cerrarse, así que el HUD solo la
  instancia. Libera el ratón al abrirse y lo devuelve al cerrarse, y la misma tecla
  `interaction` (E) que la abre la cierra. Ahora mismo el panel está vacío: no hay
  recetas todavía.

