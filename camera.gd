extends Camera

# Radius of the globe.
const R = 1

# Minimum / maximum zoom levels.
const ZOOM_MIN: int = 0
const ZOOM_MAX: int = 20

# Difference between zoom levels.
# Zoom level Z + 1 = ZOOM_STEP * Z.
const ZOOM_STEP: float = sqrt(2.0)

# Maximum distance, corresponding to zoom level 0.
const DISTANCE_MAX: float = 4.0

var zoom_level: int = 1

onready var tween: Tween = get_node("Tween")


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("zoom_in"):
		zoom_to(+1)
	elif Input.is_action_just_pressed("zoom_out"):
		zoom_to(-1)


func zoom_to(delta: int, duration: float = 0.1, trans_type: int = Tween.TRANS_LINEAR) -> void:
	get_tree().set_input_as_handled()
	zoom_level = int(max(ZOOM_MIN, min(ZOOM_MAX, zoom_level + delta)))
	var distance = transform.origin.length()
	var target_distance: float = zoom_distance(zoom_level)
	tween.interpolate_method(
		self, "set_distance", distance, target_distance, duration, trans_type, Tween.EASE_OUT
	)
	tween.start()


func zoom_distance(level: int) -> float:
	return R + near + (DISTANCE_MAX - R - near) / pow(ZOOM_STEP, level)


# Updates the camera to look towards the globe from a new distance.
func set_distance(new_distance: float) -> void:
	transform.origin = transform.origin.normalized() * new_distance


# Updates the camera to look towards the globe from a new position.
# Keeps the distance btween the camera origin and the world origin constant.
func set_orientation(new_orientation: Vector3) -> void:
	look_at_from_position(
		normalize_keep_y(new_orientation) * transform.origin.length(), Vector3.ZERO, Vector3.UP
	)


# Normalise a vector by keeping its "y" coordinate unchanged.
func normalize_keep_y(v: Vector3) -> Vector3:
	var y2: float = v.y * v.y

	if v.x == 0:
		# Special-case to avoid a division by zero error below.
		var z1: float = sign(v.z) * sqrt(1 - y2)
		return Vector3(0.0, v.y, z1)

	var x2: float = v.x * v.x
	var z2: float = v.z * v.z

	var x1: float = sign(v.x) * sqrt((1 - y2) / (1 + z2 / x2))
	var z1: float = v.z / v.x * x1
	return Vector3(x1, v.y, z1)


func fly_to(position: Vector3) -> void:
	var orientation: Vector3 = transform.origin.normalized()
	var target_orientation: Vector3 = position.normalized()
	var duration: float = 0.25
	var trans_type: int = Tween.TRANS_CUBIC
	tween.interpolate_method(
		self,
		"set_orientation",
		orientation,
		target_orientation,
		duration,
		trans_type,
		Tween.EASE_OUT
	)
	zoom_to(+2, duration, trans_type)


func _on_ClickArea_input_event(
	_camera: Camera, event: InputEvent, position: Vector3, _normal: Vector3, _shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		event = event as InputEventMouseButton
		if event.button_index == BUTTON_LEFT and event.pressed and event.doubleclick:
			fly_to(position)
