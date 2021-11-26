class_name Goldberg
extends Node


# Edge length after one subdivision.
# The very first subdivision has to be 1 : 3, so divide by 3 first.
const A3: float = Icosahedron.A1 / 3.0

# Inradius after one subdivision (with circumradius = 1).
const I1: float = sqrt(1 - pow(A3 / Pentagon.A1, 2))


func to_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var icos: Icosahedron = Icosahedron.new()
	
	print("R = ", icos.verts[0].length())
	print("A? = ", icos.verts[0].distance_to(icos.verts[1]))
	print("A0 = ", Icosahedron.A1)
	
	for v in icos.verts:
		var p: Pentagon = Pentagon.new(I1 * v, A3)
		p.add_to(st)

	#return st.commit()
	return icos.to_mesh(st)
