class_name Pentagon
extends Node

# Angle between nearby vertices:
const ALPHA: float = PI * 2.0 / 5.0

# Edge length (radius = 1):
# https://mathworld.wolfram.com/RegularPentagon.html
const A1: float = 10.0 / sqrt(50.0 + 10.0 * sqrt(5.0))

# Orientation and hight:
var o: Vector3

# Radius of the circumscribed circle:
var r: float


func _init(o: Vector3, a: float) -> void:
	self.o = o
	r = a / A1


# Add the pentagon to an existing mesh.
func add_to(st: SurfaceTool) -> void:
	var a: Vector3
	var n: Vector3 = o.normalized()
	if is_equal_approx(o.x, 0.0) and is_equal_approx(o.z, 0.0):
		# North Pole "top" should point towards Vector3.BACK.
		# South Pole "top" should point towards Vector3.FORWARD.
		a = Vector3(o.x, o.y, sign(n.y) * r)
	else:
		# Icosahedron north or south ring vertex.
		# The "top" of the pentagon should point away from the XZ plane.
		a = o.move_toward(
			# Intersection of the pentagon's plane with the XY and YZ planes:
			Plane(n, o.length()).intersect_3(Plane.PLANE_XY, Plane.PLANE_YZ),
			r  # Move by "radius" in the plane
		)

	# Rotate by a negative amount (clockwise) to match Godot's winding order.
	var b: Vector3 = a.rotated(n, -ALPHA * 1.0)
	var c: Vector3 = a.rotated(n, -ALPHA * 2.0)
	var d: Vector3 = a.rotated(n, -ALPHA * 3.0)
	var e: Vector3 = a.rotated(n, -ALPHA * 4.0)
	print("P: R = ", a.length(), ", A = ", a.distance_to(b), ", r = ", a.distance_to(o))

	Icosahedron.add_triangle(st, a, b, c)
	Icosahedron.add_triangle(st, a, c, d)
	Icosahedron.add_triangle(st, a, d, e)
