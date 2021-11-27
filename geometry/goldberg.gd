class_name Goldberg
extends Node


# # Edge length with no subdivision (radius = 1):
# https://mathworld.wolfram.com/TruncatedIcosahedron.html
const A1: float = 4.0 / sqrt(58.0 + 18.0 * sqrt(5.0))

# Inradius after one subdivision (with circumradius = 1).
const I1: float = sqrt(1 - pow(A1 / Pentagon.A1, 2))

var _icos: Icosahedron = Icosahedron.new()

var _pentagons: Array = []
var _hexagons: Array

func _init():
	for v in _icos.verts:
		var p: Pentagon = Pentagon.new(I1 * v, A1)
		p.materialize()
		_pentagons.append(p)
	_hexagons.append_array([
		# Row 1:
		Hexagon.new(_pentagons[0].a, _pentagons[0].e, _pentagons[2].a, _pentagons[2].e, _pentagons[1].b, _pentagons[1].a),
		Hexagon.new(_pentagons[0].e, _pentagons[0].d, _pentagons[3].a, _pentagons[3].e, _pentagons[2].b, _pentagons[2].a),
		Hexagon.new(_pentagons[0].d, _pentagons[0].c, _pentagons[4].a, _pentagons[4].e, _pentagons[3].b, _pentagons[3].a),
		Hexagon.new(_pentagons[0].c, _pentagons[0].b, _pentagons[5].a, _pentagons[5].e, _pentagons[4].b, _pentagons[4].a),
		Hexagon.new(_pentagons[0].b, _pentagons[0].a, _pentagons[1].a, _pentagons[1].e, _pentagons[5].b, _pentagons[5].a),
		# Row 2:
		# TODO: Shift by one to keep hex.a == top-left!
		Hexagon.new(_pentagons[1].c, _pentagons[1].b, _pentagons[2].e, _pentagons[2].d, _pentagons[6].d, _pentagons[6].c),
		Hexagon.new(_pentagons[2].c, _pentagons[2].b, _pentagons[3].e, _pentagons[3].d, _pentagons[7].d, _pentagons[7].c),
		Hexagon.new(_pentagons[3].c, _pentagons[3].b, _pentagons[4].e, _pentagons[4].d, _pentagons[8].d, _pentagons[8].c),
		Hexagon.new(_pentagons[4].c, _pentagons[4].b, _pentagons[5].e, _pentagons[5].d, _pentagons[9].d, _pentagons[9].c),
		Hexagon.new(_pentagons[5].c, _pentagons[5].b, _pentagons[1].e, _pentagons[1].d, _pentagons[10].d, _pentagons[10].c),
		# Row 3:
		Hexagon.new(_pentagons[1].d, _pentagons[1].c, _pentagons[6].c, _pentagons[6].b, _pentagons[10].e, _pentagons[10].d),
		Hexagon.new(_pentagons[2].d, _pentagons[2].c, _pentagons[7].c, _pentagons[7].b, _pentagons[6].e, _pentagons[6].d),
		Hexagon.new(_pentagons[3].d, _pentagons[3].c, _pentagons[8].c, _pentagons[8].b, _pentagons[7].e, _pentagons[7].d),
		Hexagon.new(_pentagons[4].d, _pentagons[4].c, _pentagons[9].c, _pentagons[9].b, _pentagons[8].e, _pentagons[8].d),
		Hexagon.new(_pentagons[5].d, _pentagons[5].c, _pentagons[10].c, _pentagons[10].b, _pentagons[9].e, _pentagons[9].d),
		# Row 4:
		# TODO: Shift by one to keep hex.a == top-left!
		Hexagon.new(_pentagons[10].a, _pentagons[10].e, _pentagons[6].b, _pentagons[6].a, _pentagons[11].d, _pentagons[11].c),
		Hexagon.new(_pentagons[6].a, _pentagons[6].e, _pentagons[7].b, _pentagons[7].a, _pentagons[11].e, _pentagons[11].d),
		Hexagon.new(_pentagons[7].a, _pentagons[7].e, _pentagons[8].b, _pentagons[8].a, _pentagons[11].a, _pentagons[11].e),
		Hexagon.new(_pentagons[8].a, _pentagons[8].e, _pentagons[9].b, _pentagons[9].a, _pentagons[11].b, _pentagons[11].a),
		Hexagon.new(_pentagons[9].a, _pentagons[9].e, _pentagons[10].b, _pentagons[10].a, _pentagons[11].c, _pentagons[11].b),
	])


func to_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	print("I: R  = ", _icos.verts[0].length())
	print("I: A  = ", _icos.verts[0].distance_to(_icos.verts[1]))
	print("I: A0 = ", Icosahedron.A1)

	for p in _pentagons:
		p.add_to(st)
		print("P: R  = ", p.a.length(), ", A = ", p.a.distance_to(p.b))
	for h in _hexagons:
		h.add_to(st)
		print("H: R  = ", h.a.length(), ", A = ", h.a.distance_to(h.b))

	print("X: R  = 1, A = ", _pentagons[0].a.distance_to(_pentagons[1].a))
	#Icosahedron.add_triangle(st, _pentagons[0].a, _pentagons[2].a, _pentagons[1].a)

	# Adding one more triangle seems to fix the flipped normal on the last one.
	Icosahedron.add_triangle(st, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)


	st.generate_normals()
	return st.commit()
	return _icos.to_mesh(st)
