class_name HexagonPool
extends Node

# Number of faces / vertices:
const N: int = 6

# Angle between nearby vertices:
const ALPHA: float = TAU / N

# Pool size:
var _count: int = 0

# Pool of indices into _verts, in groups of N.
var _idx: PoolIntArray = PoolIntArray()

# Links between tiles, in groups of 2 ((N*from)+edge, (N*to)+edge).
var _links: PoolIntArray = PoolIntArray()

# Actual vertices. Should be unique.
var _verts: Array  # <Vector3>


# Add a regular hexagon.
func add_regular(a: Vector3, b: Vector3) -> int:
	# Midpoint of (a, b):
	var m: Vector3 = (a + b) / 2.0
	# Midpoint of the hexagon itself, normalised:
	var on: Vector3 = m.rotated((b - a).normalized(), _o_beta(a, b)).normalized()
	var c: Vector3 = b.rotated(on, -ALPHA)
	var d: Vector3 = c.rotated(on, -ALPHA)
	var e: Vector3 = d.rotated(on, -ALPHA)
	var f: Vector3 = e.rotated(on, -ALPHA)
	_validate_regular(a, b, c, d, e, f)

	return _add_existing(a, b, c, d, e, f)


# Add a regular hxagon next to an existing one.
func add_next_to(i: int, edge: int) -> void:
	var a: Vector3 = _verts[_idx[N * i + (edge + 1) % N]]
	var b: Vector3 = _verts[_idx[N * i + (edge + 0) % N]]
	var h: int = add_regular(a, b)
	_mark_linked(i, h, edge, 0)


func _add_existing(a: Vector3, b: Vector3, c: Vector3, d: Vector3, e: Vector3, f: Vector3) -> int:
	_verts.append_array([a, b, c, d, e, f])
	_idx.append_array(range(_count * N, (_count + 1) * N))
	_count += 1

	# Return a pointer to the newly added hexagon:
	return _count - 1


func set_up_linkage():
	for i in 5:
		# Rings 1 & 4:
		_mark_linked(i * 2, ((i + 1) % 5) * 2, 3, 1)
		_mark_linked((i + 5) * 2, ((i + 1) % 5 + 5) * 2, 1, 3)
		# Rings 2 & 3:
		_mark_linked((i * 2) + 1, 10 + ((i + 1) % 5) * 2 + 1, 2, 2)
		_mark_linked((i * 2) + 1, 10 + (i + 1) * 2 - 1, 4, 4)


func subdivide_all() -> void:
	var old: Array = []  # <Vector3>
	var links: PoolIntArray = _links
	_links = PoolIntArray()  # clear old links

	for i in _count:
		# Subdivide existing tiles:
		old.append_array(_subdivide(i))

	# Go through existing links & inject a new tile for each:
	for l in range(0, len(links), 2):
		var a: Vector3
		var b: Vector3 = _verts[links[l]]
		var c: Vector3 = old[links[l]]
		var d: Vector3
		var e: Vector3 = _verts[links[l + 1]]
		var f: Vector3
		if links[l] % N + 1 == N:
			a = _verts[links[l] - N + 1]
			f = old[links[l] - N + 1]
		else:
			a = _verts[links[l] + 1]
			f = old[links[l] + 1]
		if links[l + 1] % N + 1 == N:
			d = _verts[links[l + 1] - N + 1]
		else:
			d = _verts[links[l + 1] + 1]
		var new: int = _add_existing(a, b, c, d, e, f)
		_mark_linked(links[l] / N, new, links[l] % N, 0)
		_mark_linked(new, links[l + 1] / N, 3, links[l + 1] % N)


func add_all_to(st: SurfaceTool) -> void:
	for i in _count:
		_add_to(st, i)


func _add_to(st: SurfaceTool, i: int) -> void:
	_add_triangle(st, i, 0, 2, 4)
	_add_triangle(st, i, 0, 1, 2)
	_add_triangle(st, i, 2, 3, 4)
	_add_triangle(st, i, 4, 5, 0)


func _add_triangle(st: SurfaceTool, i: int, a: int, b: int, c: int) -> void:
	Icosahedron.add_triangle(
		st, _verts[_idx[N * i + a]], _verts[_idx[N * i + b]], _verts[_idx[N * i + c]]
	)


func _subdivide(i: int) -> Array:
	var a: Vector3 = _verts[_idx[N * i + 0]]
	var b: Vector3 = _verts[_idx[N * i + 1]]
	var c: Vector3 = _verts[_idx[N * i + 2]]
	var d: Vector3 = _verts[_idx[N * i + 3]]
	var e: Vector3 = _verts[_idx[N * i + 4]]
	var f: Vector3 = _verts[_idx[N * i + 5]]
	var l: float = a.length()
	var o: Vector3 = (a + b + c + d + e + f) / 6.0

	_verts[_idx[N * i + 0]] = a.move_toward(o, o.distance_to(a) / 2.0).normalized() * l
	_verts[_idx[N * i + 1]] = b.move_toward(o, o.distance_to(b) / 2.0).normalized() * l
	_verts[_idx[N * i + 2]] = c.move_toward(o, o.distance_to(c) / 2.0).normalized() * l
	_verts[_idx[N * i + 3]] = d.move_toward(o, o.distance_to(d) / 2.0).normalized() * l
	_verts[_idx[N * i + 4]] = e.move_toward(o, o.distance_to(e) / 2.0).normalized() * l
	_verts[_idx[N * i + 5]] = f.move_toward(o, o.distance_to(f) / 2.0).normalized() * l

	return [a, b, c, d, e, f]  # old vertices


func _mark_linked(i: int, j: int, ie: int, je: int) -> void:
	_links.append_array([N * i + ie, N * j + je])


static func _validate_regular(a: Vector3, b: Vector3, c: Vector3, d: Vector3, e: Vector3, f: Vector3) -> void:
	assert((a + d).is_equal_approx(b + e), str(a + d) + " ! = " + str(b + e))
	assert((b + e).is_equal_approx(c + f), str(b + e) + " ! = " + str(c + f))
	assert(is_equal_approx(a.length(), b.length()))
	assert(is_equal_approx(b.length(), c.length()))
	assert(is_equal_approx(c.length(), d.length()))
	assert(is_equal_approx(d.length(), e.length()))
	assert(is_equal_approx(e.length(), f.length()))


# Angle from world origin between adjacent vertices.
static func _o_alpha(a: Vector3, b: Vector3) -> float:
	return a.angle_to(b)


# Angle from world origin between midpoints of opposite edges.
static func _o_beta(a: Vector3, b: Vector3) -> float:
	return asin(_r_inscr(a, b) / ((a + b) / 2.0).length())


# Radius of the inscribed circle.
static func _r_inscr(a: Vector3, b: Vector3) -> float:
	return a.distance_to(b) * sqrt(3.0) / 2.0
