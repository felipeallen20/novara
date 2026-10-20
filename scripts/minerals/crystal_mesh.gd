class_name CrystalMesh
extends RefCounted

## Construye el mesh de un depósito de cristales: un grupo de astas facetadas con
## normales por cara (sombreado plano). El tinte va en los vértices, así que un
## único material con vertex_color_use_as_albedo sirve para todos los minerales y
## cada depósito sale distinto según su semilla de variación.

## Caras del prisma de cada asta.
const SHARD_SIDES := 6
## Estrechamiento del prisma en la corona superior, antes de la punta.
const SHOULDER_RADIUS_RATIO := 0.8
## Rango del radio del prisma, en unidades de bloque.
const RADIUS_RANGE := Vector2(0.13, 0.19)
## Rango de altura del prisma, sin contar la punta.
const BODY_HEIGHT_RANGE := Vector2(0.35, 0.55)
## Rango de la altura de la punta como fracción de la del prisma.
const TIP_HEIGHT_RATIO_RANGE := Vector2(0.4, 0.7)
## Escala de los astas satélite respecto a la del asta central.
const SATELLITE_SCALE_RANGE := Vector2(0.45, 0.75)
## Distancia de los astas satélite al centro del depósito.
const SATELLITE_OFFSET_RANGE := Vector2(0.12, 0.3)
## Desviación del radio de cada corona y de su ángulo, para que el asta no sea un
## prisma perfecto.
const RADIUS_JITTER := 0.15
const ANGLE_JITTER := 0.12
## Desviación lateral de la punta, como fracción del radio.
const APEX_JITTER_RATIO := 0.25
## Giro máximo de cada asta alrededor de X y Z, en radianes.
const MAX_SHARD_TILT := 0.2
## Hundimiento de cada asta bajo la superficie. El giro de la asta levanta un borde
## de su base; hundirla un poco mantiene todo el borde apoyado en el bloque.
const BASE_SINK := 0.05
## Variación de brillo del tinte de un asta a otro.
const SHARD_SHADE_RANGE := Vector2(0.85, 1.12)


## Mesh de un grupo de `shard_count` astas. El asta 0 es la grande del centro y el
## resto son satélites más pequeños alrededor.
static func create_cluster(shard_count: int, tint: Color, rng: RandomNumberGenerator) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for shard_index in shard_count:
		var shard_scale := 1.0 if shard_index == 0 else rng.randf_range(
			SATELLITE_SCALE_RANGE.x, SATELLITE_SCALE_RANGE.y
		)
		var transform := Transform3D(
			Basis.from_euler(Vector3(
				rng.randf_range(-MAX_SHARD_TILT, MAX_SHARD_TILT),
				rng.randf_range(0.0, TAU),
				rng.randf_range(-MAX_SHARD_TILT, MAX_SHARD_TILT)
			)),
			_satellite_offset(shard_index, rng) + Vector3(0.0, -BASE_SINK, 0.0)
		)
		var shade := rng.randf_range(SHARD_SHADE_RANGE.x, SHARD_SHADE_RANGE.y)
		_append_shard(
			vertices, normals, colors, indices, transform,
			rng.randf_range(RADIUS_RANGE.x, RADIUS_RANGE.y) * shard_scale,
			rng.randf_range(BODY_HEIGHT_RANGE.x, BODY_HEIGHT_RANGE.y) * shard_scale,
			rng.randf_range(TIP_HEIGHT_RATIO_RANGE.x, TIP_HEIGHT_RATIO_RANGE.y),
			Color(tint.r * shade, tint.g * shade, tint.b * shade, 1.0),
			rng
		)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _satellite_offset(shard_index: int, rng: RandomNumberGenerator) -> Vector3:
	if shard_index == 0:
		return Vector3.ZERO
	var direction := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	var distance := rng.randf_range(SATELLITE_OFFSET_RANGE.x, SATELLITE_OFFSET_RANGE.y)
	return Vector3(direction.x, 0.0, direction.y) * distance


static func _append_shard(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	colors: PackedColorArray,
	indices: PackedInt32Array,
	transform: Transform3D,
	radius: float,
	body_height: float,
	tip_height_ratio: float,
	color: Color,
	rng: RandomNumberGenerator
) -> void:
	var base_ring := _ring(radius, 0.0, rng)
	var shoulder_ring := _ring(radius * SHOULDER_RADIUS_RATIO, body_height, rng)
	var apex_local := Vector3(
		rng.randf_range(-1.0, 1.0) * radius * APEX_JITTER_RATIO,
		body_height + body_height * tip_height_ratio,
		rng.randf_range(-1.0, 1.0) * radius * APEX_JITTER_RATIO
	)
	var apex := transform * apex_local
	var base_center := transform * Vector3.ZERO
	for i in SHARD_SIDES:
		var next := (i + 1) % SHARD_SIDES
		var base_a := transform * base_ring[i]
		var base_b := transform * base_ring[next]
		var shoulder_a := transform * shoulder_ring[i]
		var shoulder_b := transform * shoulder_ring[next]
		# Cara lateral de la base a la corona: dos triángulos con la misma normal.
		var side_outward := transform.basis * _horizontal_outward(base_ring[i], base_ring[next])
		_append_face(vertices, normals, colors, indices, base_a, base_b, shoulder_b, side_outward, color)
		_append_face(vertices, normals, colors, indices, base_a, shoulder_b, shoulder_a, side_outward, color)
		# Punta: un triángulo de corona a vértice.
		var tip_outward := transform.basis * _tip_outward(shoulder_ring[i], shoulder_ring[next], apex_local)
		_append_face(vertices, normals, colors, indices, shoulder_a, shoulder_b, apex, tip_outward, color)
		# Base: un abanico hacia abajo, para que el asta quede cerrada.
		_append_face(vertices, normals, colors, indices, base_center, base_a, base_b, transform.basis * Vector3.DOWN, color)


## Corona de `SHARD_SIDES` puntos en el plano y = height, con radio y ángulo
## desviados para que cada asta tenga su irregularidad.
static func _ring(radius: float, height: float, rng: RandomNumberGenerator) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for i in SHARD_SIDES:
		var angle := TAU * float(i) / float(SHARD_SIDES) + rng.randf_range(-ANGLE_JITTER, ANGLE_JITTER)
		var point_radius := radius * rng.randf_range(1.0 - RADIUS_JITTER, 1.0 + RADIUS_JITTER)
		ring.append(Vector3(cos(angle) * point_radius, height, sin(angle) * point_radius))
	return ring


## Dirección hacia fuera de una cara lateral, perpendicular al eje del asta.
static func _horizontal_outward(a: Vector3, b: Vector3) -> Vector3:
	var mid := (a + b) * 0.5
	return Vector3(mid.x, 0.0, mid.z).normalized()


## Dirección hacia fuera de una cara de punta, desde el eje del asta hasta su centro.
static func _tip_outward(a: Vector3, b: Vector3, apex: Vector3) -> Vector3:
	var centroid := (a + b + apex) / 3.0
	return (centroid - Vector3(0.0, centroid.y, 0.0)).normalized()


## Añade un triángulo con el winding que hace que su normal apunte hacia `outward`.
## Godot trata como frontal el triángulo cuyo recorrido, visto desde fuera, es
## horario: su normal es (p0 - p2) x (p0 - p1), la misma convención que usa
## ChunkMesher para las caras de los bloques.
static func _append_face(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	colors: PackedColorArray,
	indices: PackedInt32Array,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	outward: Vector3,
	color: Color
) -> void:
	var flipped := (a - c).cross(a - b).dot(outward) < 0.0
	var p1 := c if flipped else b
	var p2 := b if flipped else c
	vertices.append(a)
	vertices.append(p1)
	vertices.append(p2)
	var face_normal := (a - p2).cross(a - p1).normalized()
	normals.append(face_normal)
	normals.append(face_normal)
	normals.append(face_normal)
	colors.append(color)
	colors.append(color)
	colors.append(color)
	var base := vertices.size() - 3
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)
