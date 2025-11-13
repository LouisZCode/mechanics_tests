class_name MovementMechanic
extends Node

## Handles basic player movement, running, and physics

signal direction_changed(facing_right: bool)

@export var speed = 170.0
@export var run_multiplier = 2.5

var player: CharacterBody2D
var inventory: InventoryMechanic
var current_direction = 0
var is_running = false
var facing_right = true

func _ready():
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("MovementMechanic must be child of CharacterBody2D")

	# Get reference to inventory (optional, for weight-based speed)
	call_deferred("_setup_inventory")

func _setup_inventory():
	inventory = player.get_node_or_null("InventoryMechanic")
	# Inventory is optional - if not found, speed won't be affected by weight

func get_input_direction() -> float:
	return Input.get_axis("ui_left", "ui_right")

func is_moving_backwards() -> bool:
	return (current_direction < 0 and facing_right) or (current_direction > 0 and not facing_right)

func update_facing_direction(mouse_pos: Vector2):
	var new_facing = mouse_pos.x > player.global_position.x
	if new_facing != facing_right:
		facing_right = new_facing
		direction_changed.emit(facing_right)

func execute(delta: float, can_move: bool = true) -> Dictionary:
	"""
	Execute movement logic and return state info for animations
	Returns: {direction: float, is_running: bool, is_backwards: bool}
	"""
	# Get input
	current_direction = get_input_direction() if can_move else 0

	# Check if moving backwards
	var is_backwards = is_moving_backwards()

	# Only run when moving forward
	is_running = Input.is_action_pressed("ui_shift") and not is_backwards and current_direction != 0
	var current_speed = speed * run_multiplier if is_running else speed

	# Apply weight-based speed reduction if inventory exists
	if inventory:
		var weight_multiplier = inventory.get_speed_multiplier()
		current_speed *= weight_multiplier

	# Apply horizontal movement
	player.velocity.x = current_direction * current_speed

	# Return state for animations
	return {
		"direction": current_direction,
		"is_running": is_running,
		"is_backwards": is_backwards,
		"facing_right": facing_right
	}

func is_active() -> bool:
	"""Check if this mechanic should be active"""
	return true  # Movement is always potentially active
