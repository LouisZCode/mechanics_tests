class_name InventorySlot
extends Resource

## Represents a single slot in the inventory containing an item and quantity

@export var item_data: ItemData = null
@export var quantity: int = 0
@export var current_durability: int = 0  # Current durability (0 = unused/infinite)

func _init(p_item_data: ItemData = null, p_quantity: int = 0):
	item_data = p_item_data
	quantity = p_quantity
	# Initialize durability to max when item is set
	if p_item_data and p_item_data.stat_durability > 0:
		current_durability = p_item_data.stat_durability

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

func has_space_for(amount: int, custom_max_stack: int = -1) -> bool:
	"""Check if this slot has space for more of the item
	custom_max_stack: Override max stack (used for quickslot limits)"""
	if is_empty():
		return true

	if item_data == null:
		return false

	var effective_max = custom_max_stack if custom_max_stack > 0 else item_data.max_stack
	return (quantity + amount) <= effective_max

func add_quantity(amount: int, custom_max_stack: int = -1) -> int:
	"""
	Add quantity to this slot
	Returns: Amount actually added (may be less if stack limit reached)
	custom_max_stack: Override max stack (used for quickslot limits)
	"""
	if item_data == null:
		return 0

	var effective_max = custom_max_stack if custom_max_stack > 0 else item_data.max_stack
	var space_available = effective_max - quantity
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
	# Initialize durability for tools/weapons
	if p_item_data and p_item_data.stat_durability > 0:
		current_durability = p_item_data.stat_durability
	else:
		current_durability = 0

func clear():
	"""Empty this slot"""
	item_data = null
	quantity = 0
	current_durability = 0

func reduce_durability(amount: int) -> bool:
	"""
	Reduce durability by specified amount
	Returns: true if item broke (durability reached 0)
	"""
	# No durability for this item (resources, etc)
	if not item_data or item_data.stat_durability <= 0:
		return false

	current_durability -= amount

	# Item broke!
	if current_durability <= 0:
		# For stacked items, only one breaks
		if quantity > 1:
			quantity -= 1
			current_durability = item_data.stat_durability  # Reset for next item
			return false  # Slot still has items
		else:
			# Last item broke, clear slot
			clear()
			return true

	return false

func get_durability_percentage() -> float:
	"""Get durability as a percentage (0.0 to 1.0)"""
	if not item_data or item_data.stat_durability <= 0:
		return 1.0  # Items without durability are always "full"
	return float(current_durability) / float(item_data.stat_durability)

func has_durability() -> bool:
	"""Check if this item uses durability"""
	return item_data != null and item_data.stat_durability > 0

func get_total_weight() -> float:
	"""Calculate total weight of items in this slot"""
	if is_empty() or item_data == null:
		return 0.0
	return item_data.weight * quantity

func get_display_text() -> String:
	"""Get display text for UI"""
	if is_empty():
		return "[Empty]"

	var text = ""
	if item_data.max_stack > 1:
		text = "%s x%d" % [item_data.item_name, quantity]
	else:
		text = item_data.item_name

	# Add durability display if item has durability
	if has_durability():
		var percent = get_durability_percentage()
		if percent < 1.0:
			text += " (%d/%d)" % [current_durability, item_data.stat_durability]

			# Add color indicator
			if percent <= 0.25:
				text = "[color=red]" + text + "[/color]"  # Critical
			elif percent <= 0.5:
				text = "[color=orange]" + text + "[/color]"  # Low
			elif percent <= 0.75:
				text = "[color=yellow]" + text + "[/color]"  # Medium

	return text
