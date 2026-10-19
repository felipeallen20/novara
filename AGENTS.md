# AGENTS.md — NOVARA

## 1. Propósito del proyecto

**NOVARA** es un videojuego sandbox de exploración espacial en 3D, desarrollado con **Godot 4.7.2**. Utiliza un mundo de estilo voxel compuesto por bloques y entidades, con generación procedural, biomas, exploración, construcción, recolección y gestión de recursos, y mecánicas de supervivencia.

El objetivo es ofrecer un universo que invite al jugador a explorar y experimentar, modificar el entorno, construir soluciones y definir sus propias metas.

NOVARA es un proyecto independiente. No debe mezclarse con el proyecto Valero ni heredar sus decisiones de diseño o arquitectura.

## 2. Pilares del juego

Considera estos pilares al proponer o implementar cualquier sistema:

1. **Exploración espacial:** descubrir planetas, regiones, biomas, lugares y fenómenos.
2. **Mundo voxel 3D:** bloques y entidades forman parte de un entorno que el jugador puede explorar e interactuar.
3. **Generación procedural:** generar mundos y contenido de forma coherente, configurable y mantenible.
4. **Construcción libre:** permitir que el jugador transforme el entorno y construya estructuras.
5. **Recolección y gestión de recursos:** los recursos deben tener usos claros y fomentar decisiones interesantes.
6. **Supervivencia:** implementar sistemas propios de supervivencia que encajen con la ambientación espacial. No asumir que deben replicar los de otros juegos.
7. **Libertad sandbox:** ofrecer posibilidades y sistemas que permitan al jugador definir sus objetivos, sin convertir toda la experiencia en una secuencia obligatoria de tareas.

La supervivencia es una parte del juego, pero no debe desplazar automáticamente a la exploración, la construcción o la libertad del jugador como prioridades de diseño.

## 3. Principios de diseño

- Favorecer sistemas que interactúen entre sí y generen posibilidades emergentes.
- Diseñar la progresión para ampliar las opciones del jugador, no solo para aumentar estadísticas.
- Las misiones, si se implementan, deben orientar, proponer oportunidades o contar historias sin imponer una ruta única para todas las actividades.
- No añadir mecánicas por cantidad. Cada sistema debe tener una función clara dentro de los pilares del juego.
- La generación procedural debe producir resultados jugables y coherentes, no solo contenido aleatorio.
- Mantener los sistemas configurables cuando sea útil para equilibrar el juego o experimentar con distintas reglas.
- No decidir detalles de lore, economía, progresión o supervivencia que todavía no estén definidos. Si una decisión afecta al diseño general, señalar la duda antes de asumirla.

## 4. Motor y compatibilidad

- Motor objetivo: **Godot 4.7.2**.
- Usa GDScript y las APIs compatibles con esa versión, salvo que el proyecto ya haya establecido otra tecnología.
- Antes de usar una clase, propiedad, método o característica, comprueba que sea compatible con Godot 4.7.2.
- Sigue las convenciones de nodos, escenas, recursos y señales propias de Godot.
- Evita introducir plugins o dependencias externas sin una necesidad clara y una justificación breve.
- No cambies la versión del motor ni la configuración global del proyecto como parte de una tarea no relacionada.

## 5. Directrices de código limpio

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

- Valida los datos y las referencias externas cuando exista un riesgo real de error.
- Evita validaciones redundantes que no aporten seguridad.
- No ocultes errores con valores por defecto silenciosos si eso dificulta detectar un fallo.
- Evita operaciones costosas por fotograma cuando puedan ejecutarse al iniciar, al cambiar el estado o de forma diferida.
- En sistemas de generación procedural, considera el coste de memoria, la carga de CPU, las asignaciones y la actualización de geometría.
- No optimices prematuramente: identifica primero el problema y el impacto esperado.
- No sacrifiques legibilidad ni corrección por optimizaciones especulativas.

## 6. Directrices para el mundo voxel y la generación procedural

Estas reglas orientan futuras implementaciones; no implican que todos los sistemas deban crearse de inmediato.

- Mantén separadas, cuando corresponda, la generación de datos del mundo, la representación visual, las colisiones y la interacción.
- Evita que la lógica del mundo dependa directamente de la interfaz o de detalles visuales.
- Define claramente cómo se representan los bloques, las entidades, los biomas y los recursos antes de extender esos sistemas.
- Usa datos o recursos configurables para propiedades que deban variar entre bloques, entidades o biomas.
- Procura que la generación sea reproducible mediante semillas cuando el sistema lo requiera.
- Evita generar de nuevo regiones completas si solo cambió una parte pequeña del mundo.
- Ten en cuenta los límites entre regiones o chunks al diseñar generación, iluminación, colisiones y actualización de geometría, si el proyecto utiliza chunks.
- No asumas dimensiones de chunk, distancias de renderizado, cantidad de planetas, formatos de datos ni algoritmos concretos sin revisar la implementación existente o confirmar el requisito.
- Mantén la generación procedural modular para que los biomas puedan variar sin duplicar toda la lógica.
- Trata las entidades como sistemas con comportamiento y ciclo de vida propios; no las mezcles automáticamente con la representación de bloques.
- Considera guardado y carga como parte de la persistencia del mundo cuando se implemente, evitando que los cambios del jugador se pierdan al regenerar una zona.

## 7. Escenas, nodos y recursos de Godot

- Mantén las escenas pequeñas y enfocadas en una responsabilidad reconocible.
- Usa composición de nodos cuando permita reutilizar o reemplazar comportamientos con facilidad.
- Evita acceder repetidamente a nodos mediante rutas frágiles o búsquedas costosas si se puede establecer una referencia clara.
- Usa señales para comunicar eventos entre sistemas sin acoplarlos innecesariamente.
- No conviertas automáticamente todo en un Autoload. Reserva los Autoloads para servicios o estados que realmente deban ser globales.
- No guardes estado global mutable en recursos compartidos sin considerar que varias escenas pueden estar usando la misma instancia.
- Respeta las convenciones de nombres y la organización de carpetas que ya existan. Si no hay una convención, propón una sencilla antes de crear una estructura extensa.

## 8. Flujo de trabajo obligatorio para el agente

Antes de editar:

1. Inspecciona los archivos, escenas y scripts relevantes para entender cómo funciona actualmente el sistema.
2. Identifica el punto de entrada y las dependencias afectadas.
3. Comprueba si la funcionalidad ya existe para evitar duplicarla.
4. Determina el cambio mínimo que resuelva la solicitud.

Durante la implementación:

1. Haz cambios acotados y relacionados directamente con la tarea.
2. Respeta los nombres, patrones y convenciones existentes cuando sean razonables.
3. No sobrescribas trabajo existente ni elimines archivos sin una necesidad clara.
4. No cambies sistemas no relacionados, configuraciones globales o recursos de arte por conveniencia.
5. Si descubres un problema adicional, informa de él y evita ampliar el alcance sin autorización, salvo que sea imprescindible para que la solución funcione.

Después de editar:

1. Revisa los cambios y busca errores de sintaxis, referencias rotas, rutas incorrectas y dependencias faltantes.
2. Ejecuta las comprobaciones o pruebas disponibles que sean pertinentes.
3. Si puedes ejecutar el proyecto con Godot, verifica el resultado relevante. No afirmes que una prueba se ejecutó si no fue así.
4. Resume qué archivos cambiaste, qué comportamiento se añadió o corrigió y qué validaciones realizaste.
5. Indica cualquier limitación o comprobación pendiente con claridad.

## 9. Pruebas y criterios de aceptación

- Implementa pruebas automatizadas cuando el sistema y la infraestructura existente lo permitan y aporten valor.
- Para sistemas de generación procedural, verifica casos límite, semillas repetibles y consistencia de los datos cuando corresponda.
- Para mecánicas de juego, comprueba tanto el caso normal como los estados de fallo relevantes.
- Para cambios visuales o de escenas, verifica que las referencias, señales, colisiones y recursos sigan funcionando.
- No consideres una tarea terminada solo porque el código compila: comprueba el comportamiento solicitado en la medida de lo posible.

## 10. Qué evitar

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

## 11. Cómo responder al usuario

Al terminar una tarea, informa de forma breve y concreta:

- **Implementado:** qué cambió.
- **Archivos:** cuáles se modificaron o crearon.
- **Verificación:** qué pruebas o comprobaciones se ejecutaron y sus resultados.
- **Pendiente:** limitaciones reales o decisiones que requieren confirmación.

Si falta información esencial, haz una pregunta concreta. Si puedes avanzar con una opción segura y reversible, explica brevemente la suposición y continúa sin bloquear el trabajo por detalles menores.

---

## Regla principal

**Construye NOVARA como un conjunto de sistemas claros, conectados y ampliables que favorezcan la exploración, la construcción y la libertad del jugador. Mantén el código simple, los cambios acotados y las decisiones de diseño alineadas con los pilares del proyecto.**
