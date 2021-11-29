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
		_pentagons.append(Pentagon.new(I1 * v, A1).materialize())

	var np: Pentagon = _pentagons[0]
	var sp: Pentagon = _pentagons[11]
	var nr: Array = _pentagons.slice(1, 5)
	var sr: Array = _pentagons.slice(6, 10)

	_hexagons.append_array([
		# Row 1:
		Hexagon.new(np.a, np.e),
		Hexagon.new(np.e, np.d),
		Hexagon.new(np.d, np.c),
		Hexagon.new(np.c, np.b),
		Hexagon.new(np.b, np.a),
		# Row 2:
		Hexagon.new(nr[0].b, nr[1].e),
		Hexagon.new(nr[1].b, nr[2].e),
		Hexagon.new(nr[2].b, nr[3].e),
		Hexagon.new(nr[3].b, nr[4].e),
		Hexagon.new(nr[4].b, nr[0].e),
		# Row 3:
		Hexagon.new(nr[0].d, nr[0].c),
		Hexagon.new(nr[1].d, nr[1].c),
		Hexagon.new(nr[2].d, nr[2].c),
		Hexagon.new(nr[3].d, nr[3].c),
		Hexagon.new(nr[4].d, nr[4].c),
		# Row 4:
		Hexagon.new(sr[4].e, sr[0].b),
		Hexagon.new(sr[0].e, sr[1].b),
		Hexagon.new(sr[1].e, sr[2].b),
		Hexagon.new(sr[2].e, sr[3].b),
		Hexagon.new(sr[3].e, sr[4].b),
	])

	# TODO: Figure out why subdivision is not working!
	return
	print(_pentagons[0].a.distance_to(_pentagons[0].b))
	# First mandatory subdivision.
	var tmp: Array = []
	for h in _hexagons:
		h.subdivide()
		tmp.append(Hexagon.new(h.c, h.b))
	_hexagons.append_array(tmp)
	for p in _pentagons:
		p.subdivide()  # _hexagons.append_array(p.subdivide().grow())


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
