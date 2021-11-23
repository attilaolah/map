class_name Planet
extends MeshInstance

onready var icos: Icosahedron = Icosahedron.new()
onready var eqr_shader: Shader = load("res://shaders/eqr.tres")
onready var earth_txt: StreamTexture = load("res://textures/nasa_land_ocean_ice_8192.tres")



# Called when the node enters the scene tree for the first time.
func _ready():
	var mat = ShaderMaterial.new()
	mat.set_shader(eqr_shader)
	mat.set_shader_param("texture_map", earth_txt)
	
	#var texture: StreamTexture = mat.get_shader_param("texture_map")
	#print(texture)
	set_mesh(icos.build_icosahedron(mat))
	#mat.add_surface_from_arrays(mesh)
	#get_mesh().surface_set_material(0, mat)
	#print(get_mesh().get_material())
	#mesh.surface_set_material(1, mat)
