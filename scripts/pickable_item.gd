class_name PickableItem
extends Area2D

## A pickable item that can be gathered by the player

signal picked_up(item_type: String, quantity: int)

@export var item_type: String = "resource"
@export var quantity: int = 1
@export var highlight_when_near: bool = true

@onready var sprite: Sprite2D = $Sprite2D

var is_highlighted = false

func _ready():
	# Add to pickable group so GatheringMechanic can detect it
	add_to_group("pickable")

	# Set collision layers
	collision_layer = 4  # Layer 4 for items
	collision_mask = 0   # Don't detect anything

func get_item_type() -> String:
	"""Return the type of this item"""
	return item_type

func get_quantity() -> int:
	"""Return the quantity of this item"""
	return quantity

func pickup():
	"""Called when this item is picked up"""
	picked_up.emit(item_type, quantity)
	queue_free()

func set_highlighted(highlighted: bool):
	"""Visual feedback when player is near"""
	if not highlight_when_near or not sprite:
		return

	is_highlighted = highlighted
	if highlighted:
		sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Brighten
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal
