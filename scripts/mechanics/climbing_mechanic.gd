class_name ClimbingMechanic
extends Node

## Handles wall climbing - press W to climb up climbable walls
## Uses PlayerGlobals for climb speed (upgradeable)

signal climbing_started()
signal climbing_stopped()

@export var horizontal_movement_multiplier: float = 0.3  # Slight horizontal adjustment while climbing
@export var climb_run_multiplier: float = 2.0  # Speed multiplier when holding Shift while climbing

var player: CharacterBody2D
var detection_area: Area2D
var gravity_mechanic: GravityMechanic
var nearby_climbable_walls: Array[Node2D] = []
var is_climbing: bool = false
var can_climb: bool = false

func _ready():
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("ClimbingMechanic must be child of CharacterBody2D")
		return

	# Get references to other mechanics/nodes
	call_deferred("_setup_detection_area")
	call_deferred("_setup_gravity")

func _setup_detection_area():
	detection_area = player.get_node_or_null("ClimbDetectionArea")
	if detection_area:
		detection_area.area_entered.connect(_on_climbable_entered)
		detection_area.body_entered.connect(_on_climbable_body_entered)
		detection_area.area_exited.connect(_on_climbable_exited)
		detection_area.body_exited.connect(_on_climbable_body_exited)
	else:
		push_warning("ClimbDetectionArea not found on player. Add it to player.tscn")

func _setup_gravity():
	gravity_mechanic = player.get_node_or_null("GravityMechanic")
	# Gravity is optional - if not found, climbing will work without gravity toggling

func _on_climbable_entered(area: Area2D):
	"""Detect Area2D climbable surfaces"""
	if area.collision_layer & 2:  # Layer 2 = climbable
		if area not in nearby_climbable_walls:
			nearby_climbable_walls.append(area)
		_update_can_climb()

func _on_climbable_body_entered(body: Node2D):
	"""Detect StaticBody2D climbable surfaces"""
	if body.collision_layer & 2:  # Layer 2 = climbable
		if body not in nearby_climbable_walls:
			nearby_climbable_walls.append(body)
		_update_can_climb()

func _on_climbable_exited(area: Area2D):
	"""Remove Area2D when leaving range"""
	if area in nearby_climbable_walls:
		nearby_climbable_walls.erase(area)
	_update_can_climb()

func _on_climbable_body_exited(body: Node2D):
	"""Remove StaticBody2D when leaving range"""
	if body in nearby_climbable_walls:
		nearby_climbable_walls.erase(body)
	_update_can_climb()

func _update_can_climb():
	"""Check if player is near any climbable surface"""
	# Clean up invalid references
	for wall in nearby_climbable_walls:
		if not is_instance_valid(wall):
			nearby_climbable_walls.erase(wall)

	can_climb = nearby_climbable_walls.size() > 0

	# Stop climbing if no longer near climbable surface
	if not can_climb and is_climbing:
		stop_climbing()

func can_activate() -> bool:
	"""Check if climbing can start"""
	return can_climb and not is_climbing

func execute(delta: float) -> Dictionary:
	"""
	Execute climbing logic
	Returns: {is_climbing: bool, vertical_input: float, horizontal_input: float}
	"""
	# Update climbable detection
	_update_can_climb()

	# Check for climb input
	# Use WASD keys directly (W/S for up/down, A/D for left/right)
	var vertical_input = 0.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		vertical_input = 1.0
	elif Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		vertical_input = -1.0

	var horizontal_input = Input.get_axis("ui_left", "ui_right")  # A = -1, D = +1

	# Start climbing if pressing W near climbable wall
	if can_activate() and vertical_input > 0:
		start_climbing()

	# Check if running (holding Shift)
	var is_running = Input.is_action_pressed("ui_shift")

	# Stop climbing if no vertical input or not near wall
	if is_climbing:
		if vertical_input == 0 and horizontal_input == 0:
			# No input - stop climbing
			stop_climbing()
		elif not can_climb:
			# Left climbable area
			stop_climbing()

	# Apply climbing movement
	if is_climbing:
		# Get climb speed from PlayerGlobals (upgradeable)
		var climb_speed = PlayerGlobals.get_climb_speed() if PlayerGlobals.has_method("get_climb_speed") else PlayerGlobals.current_climb_speed

		# Apply run multiplier if holding Shift
		if is_running:
			climb_speed *= climb_run_multiplier

		# Vertical movement (W = up, S = down)
		player.velocity.y = -vertical_input * climb_speed

		# Horizontal movement (slight adjustment)
		player.velocity.x = horizontal_input * climb_speed * horizontal_movement_multiplier

		# Disable gravity while climbing
		if gravity_mechanic:
			gravity_mechanic.enabled = false

	# Return state for animations
	return {
		"is_climbing": is_climbing,
		"vertical_input": vertical_input,
		"horizontal_input": horizontal_input,
		"is_running": is_running if is_climbing else false
	}

func start_climbing():
	"""Start climbing mode"""
	if is_climbing:
		return

	is_climbing = true
	climbing_started.emit()

func stop_climbing():
	"""Stop climbing mode"""
	if not is_climbing:
		return

	is_climbing = false
	climbing_stopped.emit()

	# Re-enable gravity
	if gravity_mechanic:
		gravity_mechanic.enabled = true

func is_active() -> bool:
	"""Check if this mechanic is currently active"""
	return is_climbing

func get_can_climb() -> bool:
	"""Check if player is near a climbable surface"""
	return can_climb
