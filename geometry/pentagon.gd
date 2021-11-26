class_name Pentagon
extends Node

# Angle between nearby vertices:
const ALPHA: float = PI * 2.0 / 5.0

# Edge length (radius = 1):
# https://mathworld.wolfram.com/RegularPentagon.html
const A1: float = 10.0 / sqrt(50.0 + 10.0 * sqrt(5.0))

# Orientation and hight:
var _o: Vector3

# Radius of the circumscribed circle:
var _r: float

# Vertices. These are computed lazily.
# Vertex "a" is the "top", others are in clockwise order.
var a: Vector3
var b: Vector3
var c: Vector3
var d: Vector3
var e: Vector3

# Whether or not the vertices have been computed.
var _materialized: bool = false


func _init(distance: Vector3, edge_len: float) -> void:
	_o = distance
	_r = edge_len / A1


func add_to(st: SurfaceTool) -> void:
	if not _materialized:
		materialize()
	Icosahedron.add_triangle(st, a, b, c)
	Icosahedron.add_triangle(st, a, c, d)
	Icosahedron.add_triangle(st, a, d, e)


func materialize() -> void:
	var n: Vector3 = _o.normalized()
	if is_equal_approx(_o.x, 0.0) and is_equal_approx(_o.z, 0.0):
		# North Pole "top" should point towards Vector3.BACK.
		# South Pole "top" should point towards Vector3.FORWARD.
		a = Vector3(0.0, _o.y, sign(n.y) * _r)
	else:
		# Icosahedron north or south ring vertex.
		# The "top" of the pentagon should point away from the XZ plane.
		a = _o.move_toward(
			# Intersection of the pentagon's plane with the XY and YZ planes:
			Plane(n, _o.length()).intersect_3(Plane.PLANE_XY, Plane.PLANE_YZ),
			_r  # Move by "radius" in the plane
		)

	# Rotate by a negative amount (clockwise) to match Godot's winding order.
	b = a.rotated(n, -ALPHA * 1.0)
	c = a.rotated(n, -ALPHA * 2.0)
	d = a.rotated(n, -ALPHA * 3.0)
	e = a.rotated(n, -ALPHA * 4.0)
	print("P: R = ", a.length(), ", A = ", a.distance_to(b), ", r = ", a.distance_to(_o))
	_materialized = true
