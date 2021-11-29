class_name Goldberg
extends Node

# Edge length with no subdivision (radius = 1):
# https://mathworld.wolfram.com/TruncatedIcosahedron.html
const A1: float = 4.0 / sqrt(58.0 + 18.0 * sqrt(5.0))

# Inradius at the pentagon face with no subdivision (radius = 1).
const I1: float = sqrt(1 - pow(A1 / Pentagon.A1, 2))

var _icos: Icosahedron = Icosahedron.new()

var _pentagons: Array = []
var _hexagon_pool: HexagonPool = HexagonPool.new()
#var _hexagons: Array = []


func _init():
	for v in _icos.verts:
		var p: Pentagon = Pentagon.new(I1 * v, A1)
		p.grow_2(_hexagon_pool)
		_pentagons.append(p)
	_hexagon_pool.set_up_linkage()

	#return
	# First mandatory subdivision.
	#var tmp: Array = []
	#for h in _hexagons:
	#	h.subdivide()
	#	tmp.append(Hexagon.new(h.c, h.b))
	#_hexagons.append_array(tmp)
	for i in 1:
		for p in _pentagons:
			p.subdivide()
		_hexagon_pool.subdivide_all()


func to_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for p in _pentagons:
		p.add_to(st)
	#for h in _hexagons:
	#	h.add_to(st)
	_hexagon_pool.add_all_to(st)

	# Adding one more triangle seems to fix the flipped normal on the last one.
	Icosahedron.add_triangle(st, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)

	st.generate_normals()
	return st.commit()
