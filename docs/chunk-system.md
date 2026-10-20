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
  shaders/       alien_sky.gdshader
  scripts/
    blocks/      block.gd, soft_ground.gd, lavender_stone.gd, block_registry.gd
    generation/  terrain_generator.gd
    player/      player_controller.gd
    voxel/       chunk_coord.gd, chunk_data.gd, chunk_mesh_data.gd, chunk_mesher.gd
    world/       chunk_view.gd, world.gd
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
  usan identificadores `>= 1`.
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
