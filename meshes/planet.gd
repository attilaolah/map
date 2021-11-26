class_name Planet
extends MeshInstance


func _ready():
	var globe: Goldberg = Goldberg.new()
	set_mesh(globe.to_mesh())
