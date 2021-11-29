class_name Goldberg
extends Node


# Edge length with no subdivision (radius = 1):
# https://mathworld.wolfram.com/TruncatedIcosahedron.html
const A1: float = 4.0 / sqrt(58.0 + 18.0 * sqrt(5.0))

# Inradius at the pentagon face with no subdivision (radius = 1).
const I1: float = sqrt(1 - pow(A1 / Pentagon.A1, 2))

var _icos: Icosahedron = Icosahedron.new()

var _pentagons: Array = []
var _hexagons: Array = []

func _init():
	for v in _icos.verts:
		var p: Pentagon = Pentagon.new(I1 * v, A1).materialize()
		_pentagons.append(p)
		if not p.is_pole():
			_hexagons.append_array(p.grow_2())

	# TODO: Figure out why subdivision is not working!
	return
	print(_pentagons[0].a.distance_to(_pentagons[0].b))
	# First mandatory subdivision.
	var tmp: Array = []
	for h in _hexagons:
		h.subdivide()
		tmp.append(Hexagon.new(h.c, h.b))
	#_hexagons.append_array(tmp)
	for p in _pentagons:
		_hexagons.append_array(p.subdivide().grow_5())


func to_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for p in _pentagons:
		p.add_to(st)
	for h in _hexagons:
		h.add_to(st)

	# Adding one more triangle seems to fix the flipped normal on the last one.
	Icosahedron.add_triangle(st, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)

	st.generate_normals()
	return st.commit()
