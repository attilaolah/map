class_name Goldberg
extends Node


# # Edge length with no subdivision (radius = 1):
# https://mathworld.wolfram.com/TruncatedIcosahedron.html
const A1: float = 4.0 / sqrt(58.0 + 18.0 * sqrt(5.0))

# Inradius after one subdivision (with circumradius = 1).
const I1: float = sqrt(1 - pow(A1 / Pentagon.A1, 2))

var _icos: Icosahedron = Icosahedron.new()

var _pentagons: Array = []

func _init():
	for v in _icos.verts:
		_pentagons.append(Pentagon.new(I1 * v, A1))


func to_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	print("I: R  = ", _icos.verts[0].length())
	print("I: A  = ", _icos.verts[0].distance_to(_icos.verts[1]))
	print("I: A0 = ", Icosahedron.A1)

	for p in _pentagons:
		p.add_to(st)
		print("P: R  = ", p.a.length(), ", A = ", p.a.distance_to(p.b))

	print("H: R  = 1, A = ", _pentagons[0].a.distance_to(_pentagons[1].a))
	Icosahedron.add_triangle(st, _pentagons[0].a, _pentagons[2].a, _pentagons[1].a)

	#return st.commit()
	return _icos.to_mesh(st)
