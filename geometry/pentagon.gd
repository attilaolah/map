class_name Pentagon
extends Node

# Number of faces / vertices:
const N = 5

# Angle between nearby vertices:
const ALPHA: float = TAU / N

# Edge length (radius = 1):
# https://mathworld.wolfram.com/RegularPentagon.html
const A1: float = 10.0 / sqrt(50.0 + 10.0 * sqrt(5.0))

# Vertices per zoom level; 'a' is 'top', others are in clockwise order.
var _a: Array  # <Vector3>
var _b: Array  # <Vector3>
var _c: Array  # <Vector3>
var _d: Array  # <Vector3>
var _e: Array  # <Vector3>

# All vertex arrays (a to e).
var _verts: Array = [_a, _b, _c, _d, _e]  # <Array<Vector3>>
# Radius of the circumscribed circle, per zoom level:
var _r: Array  # <float>

# Centre points, per zoom level:
var _origin: Array  # <Vector3>

# Orientation of the centre point, normalised:
var _orientation: Vector3

# Current zoom level (0-based):
var _zoom: int = 0

var _is_pole: bool


func _init(distance: Vector3, edge_len: float) -> void:
	_is_pole = is_equal_approx(distance.x, 0.0) and is_equal_approx(distance.z, 0.0)
	_orientation = distance.normalized()
	_origin.append(distance)
	_r.append(edge_len / A1)
	_compute_vertices(_zoom)


func subdivide() -> Pentagon:
	if len(_r) == _zoom + 1:
		_precompute_next()
	_zoom += 1
	return self


func grow_2(pool: HexagonPool) -> void:
	if _is_pole:
		# The poles should not be growing any neighbour hex tiles.
		return
	var h1: int = pool.add_regular(_b[_zoom], _a[_zoom])
	pool.add_next_to(h1, 5)


func edge_at(edge: int, zoom: int) -> Array:
	while len(_r) <= zoom + 1:
		_precompute_next()
	var verts: Array = [_a, _b, _c, _d, _e]
	return [
		verts[edge % N][zoom],
		verts[(edge + 1) % N][zoom],
	]


func add_to(st: SurfaceTool) -> void:
	Icosahedron.add_triangle(st, _a[_zoom], _b[_zoom], _c[_zoom])
	Icosahedron.add_triangle(st, _a[_zoom], _c[_zoom], _d[_zoom])
	Icosahedron.add_triangle(st, _a[_zoom], _d[_zoom], _e[_zoom])


func _precompute_next() -> void:
	var imax: int = len(_r) - 1
	var lmax: float = _origin[imax].length()
	var rmin: float = _r[imax]
	var rmin2: float = rmin * rmin
	var r2: float = rmin2 + lmax * lmax

	_origin.append(_orientation * sqrt(r2 - rmin2 / 4.0))
	_r.append(rmin / 2.0)

	# With the poles & radius updated, need to re-calculate the vertices.
	_compute_vertices(_zoom + 1)


# Compute vertices at the specified zoom level.
func _compute_vertices(zoom: int) -> void:
	assert(len(_origin) == zoom + 1)
	assert(len(_r) == zoom + 1)

	var a: Vector3
	if _is_pole:
		# North Pole "top" should point towards Vector3.BACK.
		# South Pole "top" should point towards Vector3.FORWARD.
		a = Vector3(0.0, _origin[zoom].y, sign(_orientation.y) * _r[zoom])
	else:
		# Icosahedron north or south ring vertex.
		# The "top" of the pentagon should point away from the XZ plane.
		var p: Plane = Plane(_orientation, _origin[zoom].length())
		a = _origin[zoom].move_toward(
			# Intersection of the pentagon's plane with the XY and YZ planes:
			p.intersect_3(Plane.PLANE_XY, Plane.PLANE_YZ),
			_r[zoom]  # Move by "radius" in the plane
		)
	_a.append(a)

	# Rotate by a negative amount (clockwise) to match Godot's winding order.
	_b.append(a.rotated(_orientation, -ALPHA * 1.0))
	_c.append(a.rotated(_orientation, -ALPHA * 2.0))
	_d.append(a.rotated(_orientation, -ALPHA * 3.0))
	_e.append(a.rotated(_orientation, -ALPHA * 4.0))
	_validate(zoom)


func _validate(zoom: int) -> void:
	var o: Vector3 = (_a[zoom] + _b[zoom] + _c[zoom] + _d[zoom] + _e[zoom]) / N
	assert(_origin[zoom].is_equal_approx(o))
