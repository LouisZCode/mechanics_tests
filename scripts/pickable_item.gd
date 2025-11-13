class_name PickableItem
extends Area2D

## A pickable item that can be gathered by the player

signal picked_up(item_data: ItemData, quantity: int)

@export var item_data: ItemData  # Reference to ItemData resource
@export var quantity: int = 1
@export var highlight_when_near: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $ItemLabel

var is_highlighted = false

func _ready():
	# Add to pickable group so GatheringMechanic can detect it
	add_to_group("pickable")

	# Set collision layers
	collision_layer = 4  # Layer 4 for items
	collision_mask = 0   # Don't detect anything

	# Update sprite if item_data has an icon
	if item_data and item_data.icon and sprite:
		sprite.texture = item_data.icon

	# Update label with item name
	if item_data and label:
		label.text = item_data.item_name
	elif label:
		label.text = "Unknown"

func get_item_data() -> ItemData:
	"""Return the ItemData resource"""
	return item_data

func get_item_type() -> String:
	"""Return the type of this item (for backward compatibility)"""
	if item_data:
		return item_data.item_id
	return "unknown"

func get_quantity() -> int:
	"""Return the quantity of this item"""
	return quantity

func get_gather_time() -> float:
	"""Return the time needed to gather this item"""
	if item_data:
		return item_data.gather_time
	return 2.0  # Default fallback

func pickup():
	"""Called when this item is picked up"""
	picked_up.emit(item_data, quantity)
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
