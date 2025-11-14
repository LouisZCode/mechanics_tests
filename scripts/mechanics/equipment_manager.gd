class_name EquipmentManager
extends Node

## Manages which quickslot item is currently equipped
## Tracks equipped item and provides access to its data

signal equipment_changed(item_data: ItemData)

var player: CharacterBody2D
var inventory_mechanic: Node

# Currently equipped quickslot index (0-2, or -1 for none)
var equipped_slot_index: int = -1

func _ready():
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("EquipmentManager must be child of CharacterBody2D (player)")
		return

	# Get inventory mechanic reference
	inventory_mechanic = player.get_node_or_null("InventoryMechanic")
	if not inventory_mechanic:
		push_warning("InventoryMechanic not found. Equipment system requires inventory.")
		return

	# Connect to inventory signals to update when items change
	if inventory_mechanic.has_signal("inventory_changed"):
		inventory_mechanic.inventory_changed.connect(_on_inventory_changed)

	# Auto-equip first quickslot if it has an item
	call_deferred("_auto_equip_first_slot")

func _auto_equip_first_slot():
	"""Auto-equip the first quickslot if it contains an item"""
	if inventory_mechanic and inventory_mechanic.quickslots.size() > 0:
		var first_slot = inventory_mechanic.quickslots[0]
		if first_slot and not first_slot.is_empty():
			equip_slot(0)

func equip_slot(slot_index: int) -> bool:
	"""
	Equip an item from the specified quickslot index
	Returns true if successful, false if slot is invalid or empty
	"""
	if not inventory_mechanic:
		push_warning("Cannot equip: InventoryMechanic not found")
		return false

	# Validate slot index
	if slot_index < 0 or slot_index >= inventory_mechanic.quickslots.size():
		push_warning("Invalid quickslot index: %d" % slot_index)
		return false

	# Get the slot
	var slot = inventory_mechanic.quickslots[slot_index]
	if not slot or slot.is_empty():
		# Empty slot - unequip current item
		unequip()
		return false

	# Equip the item
	equipped_slot_index = slot_index
	equipment_changed.emit(slot.item_data)
	return true

func unequip():
	"""Unequip the currently equipped item"""
	equipped_slot_index = -1
	equipment_changed.emit(null)

func get_equipped_item() -> ItemData:
	"""
	Get the currently equipped item's data
	Returns null if nothing is equipped
	"""
	if equipped_slot_index < 0 or not inventory_mechanic:
		return null

	if equipped_slot_index >= inventory_mechanic.quickslots.size():
		return null

	var slot = inventory_mechanic.quickslots[equipped_slot_index]
	if not slot or slot.is_empty():
		return null

	return slot.item_data

func get_equipped_slot_index() -> int:
	"""
	Get the index of the currently equipped slot
	Returns -1 if nothing is equipped
	"""
	return equipped_slot_index

func has_item_equipped() -> bool:
	"""Check if any item is currently equipped"""
	return get_equipped_item() != null

func _on_inventory_changed():
	"""Handle inventory changes - re-validate equipped item"""
	if equipped_slot_index < 0:
		return

	# Check if equipped item still exists
	var current_item = get_equipped_item()
	if current_item == null:
		# Item was removed, unequip
		unequip()
