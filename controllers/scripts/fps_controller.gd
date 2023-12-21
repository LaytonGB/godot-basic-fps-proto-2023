extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var MOUSE_SENSITIVITY: float = 0.25
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER: Camera3D

var clipped := false

var _mouse_input: bool = false
var _mouse_rotation: Vector3
var _rotation_input: float
var _tilt_input: float
var _player_rotation: Vector3
var _camera_rotation: Vector3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("clip"):
		attach_to_closest_fastening()


func _unhandled_input(event):
	_mouse_input = (
		(event is InputEventMouseMotion) and (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED)
	)
	if _mouse_input:
		_rotation_input = -event.relative.x
		_tilt_input = -event.relative.y


func _update_camera(delta):
	var adjusted_delta: float = delta * MOUSE_SENSITIVITY

	# euler rotation
	_mouse_rotation.x += _tilt_input * adjusted_delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * adjusted_delta

	_player_rotation = Vector3(0.0, _mouse_rotation.y, 0.0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0.0, 0.0)

	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0

	global_transform.basis = Basis.from_euler(_player_rotation)

	_rotation_input = 0.0
	_tilt_input = 0.0


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	_update_camera(delta)

	# Handle jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func attach_to_closest_fastening():
	var clippables: Array[Node3D] = []
	for body in $ReachArea.get_overlapping_bodies():
		if body.is_in_group("fastening"):
			clippables.append(body)
	if clippables.is_empty():
		return
	var closest := clippables[0]
	var closest_dist := global_position.distance_to(closest.global_position)
	for i in range(1, clippables.size()):
		var body := clippables[i]
		var dist := global_position.distance_to(body.global_position)
		if dist < closest_dist:
			closest = body
			closest_dist = dist
	attach_clip(closest)


func attach_clip(target: Node3D):
	var clip := preload("res://components/Clip.tscn").instantiate()
	add_child(clip)
	clip.init(self, target)
	clipped = true
