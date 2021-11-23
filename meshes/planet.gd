class_name Planet
extends MeshInstance

onready var icos: Icosahedron = Icosahedron.new()


func _ready():
	set_mesh(icos.build_icosahedron())
