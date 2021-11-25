class_name Planet
extends MeshInstance


func _ready():
	var icos: Icosahedron = Icosahedron.new()
	icos.subdivide(2)
	set_mesh(icos.to_mesh())
