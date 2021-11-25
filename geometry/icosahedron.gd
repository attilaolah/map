class_name Icosahedron
extends ArrayMesh

# Base geodesic latitudes:
const GLAT: Array = [
	0,  # North Pole
	PI / 2.0 - atan(1.0 / 2.0),
	PI / 2.0 + atan(1.0 / 2.0),
	PI,  # South Pole
]

# Base geodesic longitudes:
const GLON: Array = [
	PI * 0.0, PI * 0.2, PI * 0.4, PI * 0.6, PI * 0.8,
	PI * 1.0, PI * 1.2, PI * 1.4, PI * 1.6, PI * 1.8,
]

# Base vertices.
# These are indexes to the GLON (odd) and GLAT (even) arrays.
const VERTS: PoolIntArray = PoolIntArray([
	0, 0,  # North Pole
	0, 1, 2, 1, 4, 1, 6, 1, 8, 1,  # North ring vertices
	1, 2, 3, 2, 5, 2, 7, 2, 9, 2,  # South ring vertices
	0, 3,  # South Pole
])

# Base faces:
const FACES: PoolIntArray = PoolIntArray([
	# North pyramid:
	0, 2, 1, 0, 3, 2, 0, 4, 3, 0, 5, 4, 0, 1, 5,
	# Middle antiprism top triangles:
	1, 2, 6, 2, 3, 7, 3, 4, 8, 4, 5, 9, 5, 1, 10,
	# Middle antiprism bottom triangles:
	2, 7, 6, 3, 8, 7, 4, 9, 8, 5, 10, 9, 1, 6, 10,
	# South pyramid:
	6, 7, 11, 7, 8, 11, 8, 9, 11, 9, 10, 11, 10, 6, 11,
])


# Instance variables:
var glat: Array = GLAT
var glon: Array = GLON
var verts: Array
var faces: PoolIntArray = FACES


func _init():
	for v in range(0, len(VERTS), 2):
		verts.append(_cart(GLON[VERTS[v]], GLAT[VERTS[v+1]]))


func subdivide(times: int = 1, normalize: bool = true) -> void:
	for i in times:
		_subdivide_once()
	if normalize:
		self.normalize()
		
		
func normalize() -> void:
	for i in len(verts):
		verts[i] = verts[i].normalized()


func to_mesh(smooth: bool = false) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(0, len(faces), 3):
		_add_triangle(st, verts[faces[i]], verts[faces[i + 1]], verts[faces[i + 2]], smooth)

	return st.commit()


func _subdivide_once() -> void:
	var num_verts: int = len(verts)
	var num_faces: int = len(faces) / 3
	var new_faces: PoolIntArray = PoolIntArray()
	for i in num_faces:
		var a: int = faces[i*3+0]
		var b: int = faces[i*3+1]
		var c: int = faces[i*3+2]
		var v: int = i * 3 + num_verts
		verts.append_array([
			verts[a].linear_interpolate(verts[b], 0.5),
			verts[b].linear_interpolate(verts[c], 0.5),
			verts[c].linear_interpolate(verts[a], 0.5),
		])
		new_faces.append_array([
			v, v + 1, v + 2,
			a, v + 0, v + 2,
			b, v + 1, v + 0,
			c, v + 2, v + 1,
		])
	# TODO: Figure out why the very last normal seems to be flipped!
	faces = new_faces


# Adds triangles based on the three vertices.
# TODO: Add a flag for setting UV coordinates as well.
static func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, smooth: bool) -> void:
	if not smooth:
		st.add_normal(Plane(a, b, c).normal)
	for v in [a, b, c]:
		st.add_vertex(v)


# Polar to Cartesian coordinates conversion.
static func _cart(phi: float, theta: float) -> Vector3:
	return Vector3(sin(phi) * sin(theta), cos(theta), cos(phi) * sin(theta))
