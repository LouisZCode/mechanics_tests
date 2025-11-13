class_name MechanicTemplate
extends Node

## Template for creating new player mechanics
## Copy this file and rename to create new mechanics (e.g., DiggingMechanic, ClimbingMechanic)

# Signals for communicating with other systems
signal mechanic_started
signal mechanic_ended

# Export variables for Inspector configuration
@export var enabled = true

# Reference to parent player
var player: CharacterBody2D

func _ready():
	# Get reference to player
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("Mechanic must be child of CharacterBody2D")

func can_activate() -> bool:
	"""Check if this mechanic can be activated (e.g., near wall, on ground, etc.)"""
	return enabled

func execute(delta: float):
	"""
	Main logic for this mechanic
	Called by player.gd when this mechanic is active
	"""
	pass

func is_active() -> bool:
	"""Check if this mechanic is currently active"""
	return false

func activate():
	"""Start this mechanic"""
	if can_activate():
		mechanic_started.emit()

func deactivate():
	"""Stop this mechanic"""
	mechanic_ended.emit()
