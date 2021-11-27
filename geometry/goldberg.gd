class_name Goldberg
extends Node


# Edge length with no subdivision (radius = 1):
# https://mathworld.wolfram.com/TruncatedIcosahedron.html
const A1: float = 4.0 / sqrt(58.0 + 18.0 * sqrt(5.0))

# Inradius after one subdivision (with circumradius = 1).
const I1: float = sqrt(1 - pow(A1 / Pentagon.A1, 2))

var _icos: Icosahedron = Icosahedron.new()

var _pentagons: Array = []
var _hexagons: Array

func _init():
	for v in _icos.verts:
		_pentagons.append(Pentagon.new(I1 * v, A1, true))

	var np: Pentagon = _pentagons[0]
	var sp: Pentagon = _pentagons[11]
	var nr: Array = _pentagons.slice(1, 5)
	var sr: Array = _pentagons.slice(6, 10)

	_hexagons.append_array([
		# Row 1:
		Hexagon.new(np.a, np.e, nr[1].a, nr[1].e, nr[0].b, nr[0].a),
		Hexagon.new(np.e, np.d, nr[2].a, nr[2].e, nr[1].b, nr[1].a),
		Hexagon.new(np.d, np.c, nr[3].a, nr[3].e, nr[2].b, nr[2].a),
		Hexagon.new(np.c, np.b, nr[4].a, nr[4].e, nr[3].b, nr[3].a),
		Hexagon.new(np.b, np.a, nr[0].a, nr[0].e, nr[4].b, nr[4].a),
		# Row 2:
		Hexagon.new(nr[0].b, nr[1].e, nr[1].d, sr[0].d, sr[0].c, nr[0].c),
		Hexagon.new(nr[1].b, nr[2].e, nr[2].d, sr[1].d, sr[1].c, nr[1].c),
		Hexagon.new(nr[2].b, nr[3].e, nr[3].d, sr[2].d, sr[2].c, nr[2].c),
		Hexagon.new(nr[3].b, nr[4].e, nr[4].d, sr[3].d, sr[3].c, nr[3].c),
		Hexagon.new(nr[4].b, nr[0].e, nr[0].d, sr[4].d, sr[4].c, nr[4].c),
		# Row 3:
		Hexagon.new(nr[0].d, nr[0].c, sr[0].c, sr[0].b, sr[4].e, sr[4].d),
		Hexagon.new(nr[1].d, nr[1].c, sr[1].c, sr[1].b, sr[0].e, sr[0].d),
		Hexagon.new(nr[2].d, nr[2].c, sr[2].c, sr[2].b, sr[1].e, sr[1].d),
		Hexagon.new(nr[3].d, nr[3].c, sr[3].c, sr[3].b, sr[2].e, sr[2].d),
		Hexagon.new(nr[4].d, nr[4].c, sr[4].c, sr[4].b, sr[3].e, sr[3].d),
		# Row 4:
		Hexagon.new(sr[4].e, sr[0].b, sr[0].a, sp.d, sp.c, sr[4].a),
		Hexagon.new(sr[0].e, sr[1].b, sr[1].a, sp.e, sp.d, sr[0].a),
		Hexagon.new(sr[1].e, sr[2].b, sr[2].a, sp.a, sp.e, sr[1].a),
		Hexagon.new(sr[2].e, sr[3].b, sr[3].a, sp.b, sp.a, sr[2].a),
		Hexagon.new(sr[3].e, sr[4].b, sr[4].a, sp.c, sp.b, sr[3].a),
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

	#print("X: R  = 1, A = ", _pentagons[0].a.distance_to(nr[0].a))
	#Icosahedron.add_triangle(st, _pentagons[0].a, nr[1].a, nr[0].a)

	# Adding one more triangle seems to fix the flipped normal on the last one.
	Icosahedron.add_triangle(st, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)


	st.generate_normals()
	return st.commit()
	return _icos.to_mesh(st)
