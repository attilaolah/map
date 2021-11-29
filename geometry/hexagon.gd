class_name Hexagon
extends Node

# Angle between nearby vertices:
const ALPHA: float = PI / 3.0

# Vertices. These are needed at construction time.
# Vertex "a" is the "top-left", others are in clockwise order.
var a: Vector3
var b: Vector3
var c: Vector3
var d: Vector3
var e: Vector3
var f: Vector3


func _init(a: Vector3, b: Vector3) -> void:
	self.a = a
	self.b = b

	# Midpoint of (a, b):
	var m: Vector3 = (a + b) / 2.0
	# Midpoint of the hexagon itself, normalised:
	var on: Vector3 = m.rotated((b - a).normalized(), o_beta()).normalized()
	c = b.rotated(on, -ALPHA)
	d = c.rotated(on, -ALPHA)
	e = d.rotated(on, -ALPHA)
	f = e.rotated(on, -ALPHA)
	validate()


func validate() -> void:
	assert((a + d).is_equal_approx(b + e), str(a + d) + " ! = " + str(b + e))
	assert((b + e).is_equal_approx(c + f), str(b + e) + " ! = " + str(c + f))
	assert(is_equal_approx(a.length(), b.length()))
	assert(is_equal_approx(b.length(), c.length()))
	assert(is_equal_approx(c.length(), d.length()))
	assert(is_equal_approx(d.length(), e.length()))
	assert(is_equal_approx(e.length(), f.length()))


# Angle from world origin between adjacent vertices.
func o_alpha() -> float:
	return a.angle_to(b)

# Angle from world origin between midpoints of opposite edges.
func o_beta() -> float:
	return asin(r_inscr() / ((a + b) / 2.0).length())

# Radius of the inscribed circle.
func r_inscr() -> float:
	return a.distance_to(b) * sqrt(3.0) / 2.0


func subdivide() -> Hexagon:
	var l: float = a.length()
	var o: Vector3 = (a + b + c + d + e + f) / 6.0
	a = a.move_toward(o, o.distance_to(a) / 2.0).normalized() * l
	b = b.move_toward(o, o.distance_to(b) / 2.0).normalized() * l
	c = c.move_toward(o, o.distance_to(c) / 2.0).normalized() * l
	d = d.move_toward(o, o.distance_to(d) / 2.0).normalized() * l
	e = e.move_toward(o, o.distance_to(e) / 2.0).normalized() * l
	f = f.move_toward(o, o.distance_to(f) / 2.0).normalized() * l
	validate()
	return self


func add_to(st: SurfaceTool) -> void:
	Icosahedron.add_triangle(st, a, c, e)
	Icosahedron.add_triangle(st, a, b, c)
	Icosahedron.add_triangle(st, c, d, e)
	Icosahedron.add_triangle(st, e, f, a)
