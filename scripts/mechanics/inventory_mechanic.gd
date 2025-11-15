class_name InventoryMechanic
extends Node

## Manages player inventory with main slots and quickslots, weight system
## Uses PlayerGlobals for capacity and weight thresholds (upgradeable)

signal inventory_changed()
signal item_added(item_data: ItemData, quantity: int, is_quickslot: bool)
signal item_removed(item_data: ItemData, quantity: int, is_quickslot: bool)
signal inventory_full()
signal weight_changed(current_weight: float, speed_multiplier: float)

# Internal storage
var main_inventory: Array[InventorySlot] = []
var quickslots: Array[InventorySlot] = []
var current_weight: float = 0.0
var player: CharacterBody2D

func _ready():
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("InventoryMechanic must be child of CharacterBody2D")

	# Initialize inventory arrays
	_initialize_slots()

func _initialize_slots():
	"""Create empty inventory slots based on PlayerGlobals capacity"""
	main_inventory.clear()
	quickslots.clear()

	# Get current max slots from PlayerGlobals (upgradeable)
	var max_main = PlayerGlobals.get_max_main_slots()
	var max_quick = PlayerGlobals.get_max_quick_slots()

	for i in range(max_main):
		main_inventory.append(InventorySlot.new())

	for i in range(max_quick):
		quickslots.append(InventorySlot.new())

func can_add_item(item_data: ItemData, quantity: int, to_quickslot: bool = false) -> bool:
	"""Check if item can be added to inventory"""
	if item_data == null or quantity <= 0:
		return false

	var target_inventory = quickslots if to_quickslot else main_inventory
	var remaining = quantity

	# Get effective max stack for this inventory type
	var effective_max_stack = item_data.get_max_stack_for_quickslot() if to_quickslot else item_data.max_stack

	# Check if can stack with existing items
	for slot in target_inventory:
		if slot.can_stack_with(item_data) and slot.has_space_for(remaining, effective_max_stack):
			return true
		elif slot.can_stack_with(item_data) and not slot.is_empty():
			var space_in_slot = effective_max_stack - slot.quantity
			remaining -= space_in_slot
			if remaining <= 0:
				return true

	# Check for empty slots
	var empty_slots_needed = ceili(float(remaining) / float(effective_max_stack))
	var empty_slots_available = 0

	for slot in target_inventory:
		if slot.is_empty():
			empty_slots_available += 1

	return empty_slots_available >= empty_slots_needed

func add_item(item_data: ItemData, quantity: int, to_quickslot: bool = false) -> bool:
	"""Add item to inventory. Returns true if successful."""
	if not can_add_item(item_data, quantity, to_quickslot):
		inventory_full.emit()
		return false

	var target_inventory = quickslots if to_quickslot else main_inventory
	var remaining = quantity

	# Get effective max stack for this inventory type
	var effective_max_stack = item_data.get_max_stack_for_quickslot() if to_quickslot else item_data.max_stack

	# Try to stack with existing items first
	for slot in target_inventory:
		if remaining <= 0:
			break

		if slot.can_stack_with(item_data) and not slot.is_empty():
			# Set item_data if slot was empty but can stack
			if slot.item_data == null:
				slot.set_item(item_data, 0)

			var added = slot.add_quantity(remaining, effective_max_stack)
			remaining -= added

	# Fill empty slots with remaining items
	for slot in target_inventory:
		if remaining <= 0:
			break

		if slot.is_empty():
			var amount_for_slot = mini(remaining, effective_max_stack)
			slot.set_item(item_data, amount_for_slot)
			remaining -= amount_for_slot

	# Update weight and emit signals
	_recalculate_weight()
	item_added.emit(item_data, quantity, to_quickslot)
	inventory_changed.emit()

	print("Added to inventory: %s x%d" % [item_data.item_name, quantity])
	return true

func remove_item(item_data: ItemData, quantity: int, from_quickslot: bool = false) -> bool:
	"""Remove item from inventory. Returns true if successful."""
	if item_data == null or quantity <= 0:
		return false

	var target_inventory = quickslots if from_quickslot else main_inventory
	var remaining = quantity

	# Remove from matching slots
	for slot in target_inventory:
		if remaining <= 0:
			break

		if slot.item_data != null and slot.item_data.item_id == item_data.item_id:
			var removed = slot.remove_quantity(remaining)
			remaining -= removed

	if remaining > 0:
		# Couldn't remove full amount
		return false

	# Update weight and emit signals
	_recalculate_weight()
	item_removed.emit(item_data, quantity, from_quickslot)
	inventory_changed.emit()

	return true

func drop_item(slot_index: int, quantity: int, is_quickslot: bool = false):
	"""Drop item from inventory into the world"""
	var target_inventory = quickslots if is_quickslot else main_inventory

	if slot_index < 0 or slot_index >= target_inventory.size():
		return

	var slot = target_inventory[slot_index]
	if slot.is_empty():
		return

	# Determine how much to drop
	var amount_to_drop = mini(quantity, slot.quantity)

	# Create PickableItem in world
	var pickable_scene = load("res://scenes/pickable_item.tscn")
	if pickable_scene:
		var pickable = pickable_scene.instantiate()
		pickable.item_data = slot.item_data
		pickable.quantity = amount_to_drop
		pickable.global_position = player.global_position + Vector2(0, 50)  # Drop slightly below player

		# Add to scene
		player.get_parent().add_child(pickable)

		print("Dropped: %s x%d" % [slot.item_data.item_name, amount_to_drop])

	# Remove from inventory
	slot.remove_quantity(amount_to_drop)

	# Update weight and emit signals
	_recalculate_weight()
	item_removed.emit(slot.item_data, amount_to_drop, is_quickslot)
	inventory_changed.emit()

func get_total_weight() -> float:
	"""Calculate total weight including main inventory and quickslots"""
	return current_weight

func _recalculate_weight():
	"""Recalculate current total weight"""
	var total = 0.0

	# Main inventory (100% weight)
	for slot in main_inventory:
		total += slot.get_total_weight()

	# Quickslots (get multiplier from PlayerGlobals)
	var quickslot_mult = PlayerGlobals.quickslot_weight_multiplier
	for slot in quickslots:
		total += slot.get_total_weight() * quickslot_mult

	current_weight = total
	var speed_mult = get_speed_multiplier()
	weight_changed.emit(current_weight, speed_mult)

func get_speed_multiplier() -> float:
	"""Get movement speed multiplier based on weight (stepped thresholds from PlayerGlobals)"""
	var thresholds = PlayerGlobals.get_weight_thresholds()

	if current_weight < thresholds.threshold_1:
		return 1.0  # 100% speed
	elif current_weight < thresholds.threshold_2:
		return 0.9  # 90% speed
	elif current_weight < thresholds.threshold_3:
		return 0.75  # 75% speed
	else:
		return 0.5  # 50% speed

func get_main_used_slots() -> int:
	"""Get number of used main inventory slots"""
	var count = 0
	for slot in main_inventory:
		if not slot.is_empty():
			count += 1
	return count

func get_quick_used_slots() -> int:
	"""Get number of used quickslots"""
	var count = 0
	for slot in quickslots:
		if not slot.is_empty():
			count += 1
	return count

func is_main_inventory_full() -> bool:
	"""Check if main inventory has no empty slots"""
	return get_main_used_slots() >= PlayerGlobals.get_max_main_slots()

func is_quickslots_full() -> bool:
	"""Check if quickslots have no empty slots"""
	return get_quick_used_slots() >= PlayerGlobals.get_max_quick_slots()

func get_item_count(item_id: String) -> int:
	"""Get total count of a specific item across all inventories"""
	var total = 0

	for slot in main_inventory:
		if slot.item_data != null and slot.item_data.item_id == item_id:
			total += slot.quantity

	for slot in quickslots:
		if slot.item_data != null and slot.item_data.item_id == item_id:
			total += slot.quantity

	return total

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Check if inventory has at least the specified quantity of an item"""
	return get_item_count(item_id) >= quantity

# ============================================================================
# INVENTORY MANAGEMENT (UI INTERACTIONS)
# ============================================================================

func swap_slots(from_idx: int, from_is_quick: bool, to_idx: int, to_is_quick: bool) -> bool:
	"""Swap items between two slots (any combination of main/quickslots)
	Returns true if swap was successful"""

	# Get source and target arrays
	var from_array = quickslots if from_is_quick else main_inventory
	var to_array = quickslots if to_is_quick else main_inventory

	# Validate indices
	if from_idx < 0 or from_idx >= from_array.size():
		push_warning("Invalid from_idx: %d" % from_idx)
		return false
	if to_idx < 0 or to_idx >= to_array.size():
		push_warning("Invalid to_idx: %d" % to_idx)
		return false

	# Get the slots
	var from_slot = from_array[from_idx]
	var to_slot = to_array[to_idx]

	# If both slots are empty, nothing to do
	if from_slot.is_empty() and to_slot.is_empty():
		return false

	# Try to combine stacks first (if same item and stackable)
	if _try_combine_stacks(from_slot, to_slot, to_is_quick):
		# Stacking succeeded - emit signals and return
		inventory_changed.emit()
		_recalculate_weight()
		return true

	# EDGE CASE: Dragging item from main to quickslot, but quantity exceeds quickslot limit
	if not from_is_quick and to_is_quick and not from_slot.is_empty():
		var quickslot_max = from_slot.item_data.get_max_stack_for_quickslot()
		if from_slot.quantity > quickslot_max:
			# Split stack: Move only what fits in quickslot
			if to_slot.is_empty():
				# Target is empty - move quickslot_max amount
				to_slot.set_item(from_slot.item_data, quickslot_max)
				from_slot.remove_quantity(quickslot_max)

				inventory_changed.emit()
				_recalculate_weight()
				print("Split stack: Moved %d to quickslot, %d remains in main inventory" % [quickslot_max, from_slot.quantity])
				return true
			else:
				# Target has different item - can't fit, abort
				print("Cannot move: Stack too large for quickslot (%d > %d max)" % [from_slot.quantity, quickslot_max])
				return false

	# Stacking failed or not applicable - do swap instead
	# Store from_slot data
	var temp_item = from_slot.item_data
	var temp_quantity = from_slot.quantity

	# Move to_slot to from_slot
	if to_slot.is_empty():
		from_slot.clear()
	else:
		from_slot.set_item(to_slot.item_data, to_slot.quantity)

	# Move temp (original from_slot) to to_slot
	if temp_item == null:
		to_slot.clear()
	else:
		to_slot.set_item(temp_item, temp_quantity)

	# Emit signal
	inventory_changed.emit()
	_recalculate_weight()

	return true

func move_to_quickslot(main_idx: int, quick_idx: int) -> bool:
	"""Move item from main inventory to quickslot (swaps if quickslot occupied)
	Convenience wrapper for swap_slots()"""
	return swap_slots(main_idx, false, quick_idx, true)

func _try_combine_stacks(from_slot: InventorySlot, to_slot: InventorySlot, to_is_quickslot: bool = false) -> bool:
	"""Try to combine two slots if they contain stackable items of the same type.
	Returns true if stacking occurred, false if items can't be stacked
	to_is_quickslot: Whether the target slot is in quickslots (affects max stack)"""

	# Can't stack if either slot is empty
	if from_slot.is_empty() or to_slot.is_empty():
		return false

	# Can't stack if items are different
	if from_slot.item_data.item_id != to_slot.item_data.item_id:
		return false

	# Can't stack if item isn't stackable (max_stack = 1 for unique items)
	if from_slot.item_data.max_stack <= 1:
		return false

	# Get effective max stack for target slot
	var effective_max_stack = from_slot.item_data.get_max_stack_for_quickslot() if to_is_quickslot else from_slot.item_data.max_stack

	# Can't stack if target is already at max capacity
	if to_slot.quantity >= effective_max_stack:
		return false

	# Calculate how much we can add to target
	var space_in_target = effective_max_stack - to_slot.quantity
	var amount_to_move = min(from_slot.quantity, space_in_target)

	# Move items from source to target
	to_slot.add_quantity(amount_to_move, effective_max_stack)
	from_slot.remove_quantity(amount_to_move)

	# If source is now empty, clear it
	if from_slot.quantity <= 0:
		from_slot.clear()

	print("Stacked %d items - Target now has %d/%d" % [amount_to_move, to_slot.quantity, effective_max_stack])

	return true

func is_active() -> bool:
	"""Check if this mechanic is currently active"""
	return true  # Inventory is always active

func execute(delta: float):
	"""Main update loop (called from player coordinator)"""
	# Inventory doesn't need per-frame updates
	pass
