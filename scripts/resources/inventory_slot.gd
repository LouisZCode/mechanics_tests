class_name InventorySlot
extends Resource

## Represents a single slot in the inventory containing an item and quantity

@export var item_data: ItemData = null
@export var quantity: int = 0

func _init(p_item_data: ItemData = null, p_quantity: int = 0):
	item_data = p_item_data
	quantity = p_quantity

func is_empty() -> bool:
	"""Check if this slot is empty"""
	return item_data == null or quantity <= 0

func can_stack_with(other_item_data: ItemData) -> bool:
	"""Check if this slot can stack with another item"""
	if is_empty():
		return true  # Empty slot can accept any item

	if item_data == null or other_item_data == null:
		return false

	# Must be same item and stackable
	return item_data.item_id == other_item_data.item_id and item_data.max_stack > 1

func has_space_for(amount: int) -> bool:
	"""Check if this slot has space for more of the item"""
	if is_empty():
		return true

	if item_data == null:
		return false

	return (quantity + amount) <= item_data.max_stack

func add_quantity(amount: int) -> int:
	"""
	Add quantity to this slot
	Returns: Amount actually added (may be less if stack limit reached)
	"""
	if item_data == null:
		return 0

	var space_available = item_data.max_stack - quantity
	var amount_to_add = min(amount, space_available)
	quantity += amount_to_add
	return amount_to_add

func remove_quantity(amount: int) -> int:
	"""
	Remove quantity from this slot
	Returns: Amount actually removed
	"""
	var amount_to_remove = min(amount, quantity)
	quantity -= amount_to_remove

	# Clear slot if empty
	if quantity <= 0:
		item_data = null
		quantity = 0

	return amount_to_remove

func set_item(p_item_data: ItemData, p_quantity: int = 1):
	"""Set this slot to a specific item and quantity"""
	item_data = p_item_data
	quantity = p_quantity

func clear():
	"""Empty this slot"""
	item_data = null
	quantity = 0

func get_total_weight() -> float:
	"""Calculate total weight of items in this slot"""
	if is_empty() or item_data == null:
		return 0.0
	return item_data.weight * quantity

func get_display_text() -> String:
	"""Get display text for UI"""
	if is_empty():
		return "[Empty]"

	if item_data.max_stack > 1:
		return "%s x%d" % [item_data.item_name, quantity]
	else:
		return item_data.item_name
