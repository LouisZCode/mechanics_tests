class_name GravityMechanic
extends Node

## Handles gravity physics for the player

@export var gravity = 980.0
@export var enabled = true

var player: CharacterBody2D

func _ready():
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("GravityMechanic must be child of CharacterBody2D")

func execute(delta: float):
	"""Apply gravity to player velocity"""
	if not enabled:
		return

	if not player.is_on_floor():
		player.velocity.y += gravity * delta
	else:
		player.velocity.y = 0

func set_enabled(value: bool):
	"""Enable or disable gravity (useful for climbing, flying, etc.)"""
	enabled = value

func set_gravity_multiplier(multiplier: float):
	"""Temporarily modify gravity strength (e.g., 0.3 for climbing)"""
	# This can be extended if needed for temporary gravity changes
	pass
