class_name Icosahedron
extends ArrayMesh

const PHI: float = PI * 2.0 / 5.0
const THETA: float = PI / 2.0 - atan(1.0 / 2.0)

const NP: Vector3 = Vector3.UP
const SP: Vector3 = Vector3.DOWN

# TODO: Come up with constant expressions for all edges!


static func new(r: float = 1.0) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# North & South poles:
	var np: Vector3 = NP * r
	var sp: Vector3 = SP * r

	# North & South rings:
	var nr: Array = []
	var sr: Array = []
	for i in 5:
		nr.append(np.rotated(Vector3.RIGHT, THETA).rotated(Vector3.UP, PHI * i))
		sr.append(sp.rotated(Vector3.RIGHT, THETA).rotated(Vector3.UP, PHI * i))

	for i in 5:
		# North 5-pyramid:
		add_triangle(st, np, nr[(i + 1) % 5], nr[i])

		# South 5-pyramid:
		add_triangle(st, sp, sr[i], sr[(i + 1) % 5])

		# North prism teeth:
		add_triangle(st, nr[i], nr[(i + 1) % 5], sr[(i + 3) % 5])

		# South prism teeth:
		add_triangle(st, nr[(i + 1) % 5], sr[(i + 4) % 5], sr[(i + 3) % 5])

	return st.commit()


static func add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_normal(Plane(a, b, c).normal)
	for v in [a, b, c]:
		st.add_vertex(v)
