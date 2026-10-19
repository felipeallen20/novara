# AGENTS.md — NOVARA

## 1. Propósito del proyecto

**NOVARA** es un videojuego sandbox de exploración espacial en 3D, desarrollado con **Godot 4.7.2**. Utiliza un mundo de estilo voxel compuesto por bloques y entidades, con generación procedural, biomas, exploración, construcción, recolección y gestión de recursos, y mecánicas de supervivencia.

El objetivo es ofrecer un universo que invite al jugador a explorar y experimentar, modificar el entorno, construir soluciones y definir sus propias metas.

NOVARA es un proyecto independiente. No debe mezclarse con el proyecto Valero ni heredar sus decisiones de diseño o arquitectura.

## 2. Regla de alcance: solo scripts (PRIORIDAD MÁXIMA)

Esta sección tiene prioridad sobre cualquier otra instrucción de este archivo y sobre cualquier hábito de trabajo por defecto.

### Qué puedes hacer

- Crear, leer y modificar **scripts GDScript** (`.gd`).
- Leer escenas (`.tscn`), recursos (`.tres`) y la configuración del proyecto **solo para entender** cómo está montado el proyecto. Lectura, nunca escritura.
- Definir clases personalizadas en script (por ejemplo, clases que extiendan `Resource`) cuando el diseño lo requiera. Crear la clase es trabajo de script; crear instancias de esa clase como archivo `.tres` NO lo es (ver más abajo).

### Qué NO puedes hacer (ni siquiera "un cambio pequeño")

- **No crear, editar, renombrar, mover ni borrar escenas** (`.tscn`).
- **No añadir, quitar, renombrar, reordenar ni reconfigurar nodos** en ninguna escena, ni editando el `.tscn` a mano ni por ningún otro medio.
- **No crear ni editar archivos de recursos** (`.tres`, `.res`) ni materiales, mallas, texturas, temas, shaders-recurso u otros assets.
- **No editar `project.godot`** ni la configuración del proyecto: Autoloads, Input Map, capas de física y de renderizado, grupos globales, ajustes de renderizado, etc.
- **No cambiar** propiedades de nodos desde el Inspector (a mano o editando archivos), conexiones de señales hechas en el editor, ni asignaciones de scripts a nodos.
- No tocar archivos importados ni la carpeta `.godot/`.

### Qué sí puede hacer un script con los nodos

Un script puede crear y manipular nodos **en tiempo de ejecución** (por ejemplo, instanciar una `MeshInstance3D` por chunk, conectar señales con `connect()` o añadir un nodo hijo con `add_child()`). Esto está permitido porque el cambio vive en el script, no en la escena. Úsalo cuando sea natural y encaje con la arquitectura existente (por ejemplo, los chunks de un mundo voxel se crean por código de todos modos). No lo uses como excusa para reemplazar toda una escena por código ni para esquivar una estructura de nodos que el proyecto ya tiene.

### Si una tarea requiere tocar escenas, nodos o el editor

Cuando una tarea necesite algo que está fuera de los scripts, **no lo hagas tú**. En su lugar:

1. Termina la parte que sí es de script.
2. Entrega al usuario una **guía paso a paso detallada** (ver sección 3) para la parte que debe hacer él en el editor.
3. Indica claramente en el resumen final qué quedó pendiente del lado del editor.

Si la tarea es imposible o inútil sin esos pasos manuales, di cuáles son antes de empezar y trabaja en el script de forma que funcione en cuanto el usuario los complete.

### Los scripts deben declarar sus requisitos del editor

Como el usuario será quien monte las escenas, cada script que dependa de algo configurado en el editor debe dejarlo explícito y fallar de forma visible:

- Usa `@export` (con tipo) para referencias y valores que el usuario deba asignar en el Inspector, en lugar de rutas frágiles con `get_node("...")` o `$Ruta/Larga`.
- Si el script necesita un nodo hijo concreto, un grupo, una acción de Input Map, una capa de colisión o un Autoload, hazlo constar en la guía de la sección 3 y verifica su existencia al iniciar (`assert` o `push_error` con un mensaje claro que diga qué falta y dónde configurarlo).
- No ocultes una configuración faltante con valores por defecto silenciosos.

## 3. Guía paso a paso para el editor de Godot (obligatoria)

Siempre que el usuario deba hacer algo en el editor de Godot 4.7.2, entrega una guía **muy detallada**, pensada para alguien que no recuerda dónde está cada cosa. Nunca respondas con instrucciones vagas como "añade un nodo X y conecta la señal" o "configura la colisión".

### Formato obligatorio de cada guía

1. **Objetivo:** una frase que diga qué quedará funcionando al terminar.
2. **Antes de empezar:** qué escena o script abrir, qué debe existir ya y qué script nuevo o modificado se usa en la guía.
3. **Pasos numerados:** un solo clic o acción por paso (ver reglas más abajo).
4. **Cómo comprobar que quedó bien:** qué debe verse en el editor o qué debe ocurrir al ejecutar (con la tecla `F5` o `F6`, indicando cuál).
5. **Errores comunes:** los fallos más probables y cómo se ven (por ejemplo, el mensaje de error que mostrará el script si falta la asignación).

### Reglas para redactar los pasos

- **Un paso = una acción.** Divide en pasos separados abrir un menú, elegir la opción y confirmar.
- **Indica dónde está cada cosa:** panel (Scene / árbol de escena, FileSystem / Sistema de archivos, Inspector, Node / Nodo, Output, Debugger, etc.), menú o pestaña, con el nombre tal como aparece en el editor. Menciona el nombre en inglés y, entre paréntesis, el equivalente en español cuando el editor pueda estar en español.
- **Nombres exactos y sensibles a mayúsculas:** da el nombre exacto que debe tener cada nodo, grupo, acción de Input Map, capa o archivo, porque los scripts dependen de ellos. Escríbelos en `código`.
- **Tipo de nodo exacto** (por ejemplo, `Node3D`, `StaticBody3D`, `CollisionShape3D`, `MeshInstance3D`) y **dónde se cuelga** en el árbol: indica el nodo padre.
- **Ruta de los archivos** completa desde `res://`, tanto para scripts como para escenas o recursos que deban abrirse o crearse.
- **Cómo asignar un script a un nodo:** selecciona el nodo, ve al Inspector, busca la propiedad `Script` o usa el botón de adjuntar script del panel Scene, y elige la ruta exacta del script (indica si es adjuntar uno existente o crear uno).
- **Propiedades del Inspector:** indica el nombre exacto de la propiedad, la sección donde está (por ejemplo, `Collision`, `Transform`, `Mesh`, `Material`) y el valor a introducir. Si el valor es una referencia (un nodo o un recurso), explica cómo asignarla: arrastrar desde el panel, o hacer clic en el campo y elegir **Assign...** / **Quick Load** / **Load**.
- **Variables `@export`:** di en qué nodo aparecen (el que lleva el script), con qué nombre se muestran en el Inspector (Godot lo muestra con la primera letra en mayúscula y espacios en lugar de guiones bajos) y qué se debe asignar.
- **Señales:** si debe conectarse una señal en el editor, indica nodo emisor, pestaña **Node** → **Signals**, nombre de la señal, doble clic, nodo receptor y método destino. Si es posible, prefiere conectar la señal por código en el script y evita este paso manual.
- **Grupos, Input Map, Autoloads, capas de física:** indica la ruta de menú completa (por ejemplo, **Project → Project Settings → ...**) y la pestaña exacta, junto con qué escribir en cada campo y qué botón pulsar para confirmar (por ejemplo, **Add**).
- **Guardado:** termina cada bloque de cambios con el paso de guardar (`Ctrl+S`) cuando corresponda, e indica si hay que guardar la escena o el proyecto.
- **No des por hecho nada:** si un paso depende de que algo ya exista (un nodo, un grupo, una escena), dilo en "Antes de empezar" o crea ese requisito como paso previo.
- **Ejemplo breve de redacción correcta:**
  - Mal: "Añade un `CollisionShape3D` y configúralo."
  - Bien: "1. En el panel **Scene**, haz clic derecho sobre el nodo `Chunk` y elige **Add Child Node...**. 2. En la ventana que se abre, escribe `CollisionShape3D`, selecciónalo y pulsa **Create**. 3. Con el nodo nuevo seleccionado, en el **Inspector** haz clic en el campo `Shape` y elige **New BoxShape3D**."
- Si hay varias formas de hacer lo mismo, da **una sola** (la más simple y estable) y no ofrezcas alternativas salvo que haga falta.
- Si no estás seguro de dónde está una opción en Godot 4.7.2 o de si existe, dilo con claridad en lugar de inventarlo, y sugiere al usuario cómo localizarla (por ejemplo, con la búsqueda de ayuda del editor).

## 4. Pilares del juego

Considera estos pilares al proponer o implementar cualquier sistema:

1. **Exploración espacial:** descubrir planetas, regiones, biomas, lugares y fenómenos.
2. **Mundo voxel 3D:** bloques y entidades forman parte de un entorno que el jugador puede explorar e interactuar.
3. **Generación procedural:** generar mundos y contenido de forma coherente, configurable y mantenible.
4. **Construcción libre:** permitir que el jugador transforme el entorno y construya estructuras.
5. **Recolección y gestión de recursos:** los recursos deben tener usos claros y fomentar decisiones interesantes.
6. **Supervivencia:** implementar sistemas propios de supervivencia que encajen con la ambientación espacial. No asumir que deben replicar los de otros juegos.
7. **Libertad sandbox:** ofrecer posibilidades y sistemas que permitan al jugador definir sus objetivos, sin convertir toda la experiencia en una secuencia obligatoria de tareas.

La supervivencia es una parte del juego, pero no debe desplazar automáticamente a la exploración, la construcción o la libertad del jugador como prioridades de diseño.

## 5. Principios de diseño

- Favorecer sistemas que interactúen entre sí y generen posibilidades emergentes.
- Diseñar la progresión para ampliar las opciones del jugador, no solo para aumentar estadísticas.
- Las misiones, si se implementan, deben orientar, proponer oportunidades o contar historias sin imponer una ruta única para todas las actividades.
- No añadir mecánicas por cantidad. Cada sistema debe tener una función clara dentro de los pilares del juego.
- La generación procedural debe producir resultados jugables y coherentes, no solo contenido aleatorio.
- Mantener los sistemas configurables cuando sea útil para equilibrar el juego o experimentar con distintas reglas.
- No decidir detalles de lore, economía, progresión o supervivencia que todavía no estén definidos. Si una decisión afecta al diseño general, señalar la duda antes de asumirla.

## 6. Motor y compatibilidad

- Motor objetivo: **Godot 4.7.2**.
- Usa GDScript y las APIs compatibles con esa versión, salvo que el proyecto ya haya establecido otra tecnología.
- Antes de usar una clase, propiedad, método o característica, comprueba que sea compatible con Godot 4.7.2.
- Sigue las convenciones de nodos, escenas, recursos y señales propias de Godot.
- Evita introducir plugins o dependencias externas sin una necesidad clara y una justificación breve.
- No cambies la versión del motor ni la configuración global del proyecto como parte de una tarea no relacionada (y recuerda que, por la sección 2, la configuración del proyecto no se edita; se guía al usuario para hacerlo).

## 7. Directrices de código limpio

### Claridad y responsabilidad

- Escribe código sencillo, legible y directo. Prioriza la solución más simple que cumpla los requisitos.
- Cada función debe tener una responsabilidad clara y un alcance acotado.
- Evita funciones extensas que mezclen lógica de juego, acceso a nodos, generación de contenido e interfaz.
- Usa nombres descriptivos y consistentes para variables, funciones, clases, escenas y recursos.
- Evita abreviaturas ambiguas, nombres genéricos como `data` cuando existe un término más preciso, y números mágicos.
- Extrae constantes o recursos de configuración cuando un valor tenga significado de diseño o deba ajustarse con frecuencia.
- No añadas abstracciones, patrones de diseño o capas adicionales sin una necesidad real.

### Organización y reutilización

- Mantén cada sistema en archivos y componentes con responsabilidades claras.
- Reutiliza código cuando exista una lógica realmente compartida; evita duplicación significativa.
- No crees sistemas genéricos prematuramente para necesidades hipotéticas.
- Evita dependencias circulares y acoplamiento innecesario entre escenas o sistemas.
- Prefiere señales, recursos de configuración o interfaces claras cuando ayuden a separar responsabilidades.
- Respeta la arquitectura existente. No reestructures todo el proyecto para resolver una tarea localizada.

### Comentarios y documentación

- El código debe explicarse principalmente por sus nombres y su estructura.
- Añade comentarios solo cuando aclaren una decisión no evidente, una restricción técnica o un comportamiento difícil de inferir.
- Mantén los comentarios breves, específicos y útiles.
- No escribas documentación extensa, comentarios línea por línea ni resúmenes redundantes del código.
- Actualiza la documentación existente cuando un cambio modifique un comportamiento o una decisión importante.

### Manejo de errores y rendimiento

- Valida los datos y las referencias externas cuando exista un riesgo real de error. Esto incluye las referencias que dependen del editor (sección 2).
- Evita validaciones redundantes que no aporten seguridad.
- No ocultes errores con valores por defecto silenciosos si eso dificulta detectar un fallo.
- Evita operaciones costosas por fotograma cuando puedan ejecutarse al iniciar, al cambiar el estado o de forma diferida.
- En sistemas de generación procedural, considera el coste de memoria, la carga de CPU, las asignaciones y la actualización de geometría.
- No optimices prematuramente: identifica primero el problema y el impacto esperado.
- No sacrifiques legibilidad ni corrección por optimizaciones especulativas.

## 8. Directrices para el mundo voxel y la generación procedural

Estas reglas orientan futuras implementaciones; no implican que todos los sistemas deban crearse de inmediato.

- Mantén separadas, cuando corresponda, la generación de datos del mundo, la representación visual, las colisiones y la interacción.
- Evita que la lógica del mundo dependa directamente de la interfaz o de detalles visuales.
- Define claramente cómo se representan los bloques, las entidades, los biomas y los recursos antes de extender esos sistemas.
- Usa datos o recursos configurables para propiedades que deban variar entre bloques, entidades o biomas. Define la clase en script; si hace falta crear instancias `.tres`, entrega la guía de la sección 3 al usuario.
- Procura que la generación sea reproducible mediante semillas cuando el sistema lo requiera.
- Evita generar de nuevo regiones completas si solo cambió una parte pequeña del mundo.
- Ten en cuenta los límites entre regiones o chunks al diseñar generación, iluminación, colisiones y actualización de geometría, si el proyecto utiliza chunks.
- No asumas dimensiones de chunk, distancias de renderizado, cantidad de planetas, formatos de datos ni algoritmos concretos sin revisar la implementación existente o confirmar el requisito.
- Mantén la generación procedural modular para que los biomas puedan variar sin duplicar toda la lógica.
- Trata las entidades como sistemas con comportamiento y ciclo de vida propios; no las mezcles automáticamente con la representación de bloques.
- Considera guardado y carga como parte de la persistencia del mundo cuando se implemente, evitando que los cambios del jugador se pierdan al regenerar una zona.

## 9. Escenas, nodos y recursos de Godot

Esta sección describe cómo debe **escribirse el código** para convivir con escenas y nodos que el agente no edita (ver sección 2).

- Escribe scripts que encajen con la estructura de escenas y nodos ya existente. Inspecciónala en modo lectura antes de asumir nada.
- Prefiere `@export` tipado para recibir referencias de nodos y recursos, en lugar de rutas frágiles o búsquedas costosas.
- Usa señales para comunicar eventos entre sistemas sin acoplarlos innecesariamente. Prefiere conectarlas por código con `connect()` para evitar pasos manuales en el editor.
- No conviertas automáticamente todo en un Autoload. Reserva los Autoloads para servicios o estados que realmente deban ser globales. Registrar un Autoload es un paso del editor: guía al usuario según la sección 3.
- No guardes estado global mutable en recursos compartidos sin considerar que varias escenas pueden estar usando la misma instancia.
- Respeta las convenciones de nombres y la organización de carpetas que ya existan. Si no hay una convención, propón una sencilla antes de crear una estructura extensa.
- Si un script nuevo necesita una escena, un nodo o un recurso que todavía no existe, descríbelo en la guía del editor en lugar de crearlo.

## 10. Flujo de trabajo obligatorio para el agente

Antes de editar:

1. Inspecciona los archivos, escenas y scripts relevantes para entender cómo funciona actualmente el sistema (las escenas, solo en lectura).
2. Identifica el punto de entrada y las dependencias afectadas.
3. Comprueba si la funcionalidad ya existe para evitar duplicarla.
4. Determina el cambio mínimo que resuelva la solicitud **usando solo scripts**.
5. Decide qué parte de la solución, si alguna, requiere intervención del usuario en el editor.

Durante la implementación:

1. Haz cambios acotados y relacionados directamente con la tarea.
2. Respeta los nombres, patrones y convenciones existentes cuando sean razonables.
3. No sobrescribas trabajo existente ni elimines archivos sin una necesidad clara.
4. No cambies sistemas no relacionados, configuraciones globales o recursos de arte por conveniencia.
5. Si descubres un problema adicional, informa de él y evita ampliar el alcance sin autorización, salvo que sea imprescindible para que la solución funcione.
6. Si algo solo se puede resolver tocando una escena, un nodo o el editor, detente en ese punto, no lo hagas y prepara la guía paso a paso.

Después de editar:

1. Revisa los cambios y busca errores de sintaxis, referencias rotas, rutas incorrectas y dependencias faltantes.
2. Comprueba que ningún archivo que no sea un script (`.gd`) haya sido modificado.
3. Ejecuta las comprobaciones o pruebas disponibles que sean pertinentes.
4. Si puedes ejecutar el proyecto con Godot, verifica el resultado relevante. No afirmes que una prueba se ejecutó si no fue así.
5. Resume qué archivos cambiaste, qué comportamiento se añadió o corrigió y qué validaciones realizaste.
6. Entrega la guía del editor (sección 3) si queda algo por configurar, e indica cualquier limitación o comprobación pendiente con claridad.

## 11. Pruebas y criterios de aceptación

- Implementa pruebas automatizadas cuando el sistema y la infraestructura existente lo permitan y aporten valor. Los scripts de prueba también son scripts: no necesitan escenas nuevas si pueden ejecutarse sin ellas; si las necesitaran, guía al usuario.
- Para sistemas de generación procedural, verifica casos límite, semillas repetibles y consistencia de los datos cuando corresponda.
- Para mecánicas de juego, comprueba tanto el caso normal como los estados de fallo relevantes.
- Para cambios que dependan de escenas, verifica en modo lectura que las referencias, señales, colisiones y recursos esperados existan, y deja en la guía del editor lo que el usuario deba comprobar al ejecutar.
- No consideres una tarea terminada solo porque el código compila: comprueba el comportamiento solicitado en la medida de lo posible.

## 12. Qué evitar

- **No editar escenas, nodos, recursos ni configuración del proyecto** (sección 2).
- **No dar instrucciones de editor vagas o incompletas** (sección 3).
- No introducir sistemas completos que el usuario no haya solicitado.
- No añadir dependencias, plugins o frameworks solo por preferencia personal.
- No duplicar funciones o datos que ya existan.
- No realizar refactorizaciones masivas para resolver problemas pequeños.
- No llenar los scripts de comentarios o documentación redundante.
- No asumir que NOVARA debe copiar la progresión, las recetas o la supervivencia de otro juego.
- No convertir el sandbox en una secuencia obligatoria de misiones.
- No inventar decisiones de diseño que todavía estén abiertas.
- No afirmar que algo está probado, optimizado o terminado sin evidencia.
- No mezclar decisiones, archivos ni sistemas de Valero con NOVARA.

## 13. Cómo responder al usuario

Al terminar una tarea, informa de forma breve y concreta:

- **Implementado:** qué cambió en los scripts.
- **Archivos:** cuáles se modificaron o crearon (solo `.gd`).
- **Verificación:** qué pruebas o comprobaciones se ejecutaron y sus resultados.
- **Pasos en el editor:** la guía detallada de la sección 3 para todo lo que el usuario deba hacer en escenas, nodos o configuración del proyecto. Si no hay nada que hacer en el editor, indícalo expresamente.
- **Pendiente:** limitaciones reales o decisiones que requieren confirmación.

Si falta información esencial, haz una pregunta concreta. Si puedes avanzar con una opción segura y reversible, explica brevemente la suposición y continúa sin bloquear el trabajo por detalles menores.

---

## Regla principal

**Construye NOVARA como un conjunto de sistemas claros, conectados y ampliables que favorezcan la exploración, la construcción y la libertad del jugador. Mantén el código simple, los cambios acotados y las decisiones de diseño alineadas con los pilares del proyecto. Modifica únicamente scripts: todo lo que implique escenas, nodos o el editor de Godot lo hace el usuario, siempre con una guía paso a paso muy detallada.**
