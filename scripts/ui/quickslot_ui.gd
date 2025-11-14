extends CanvasLayer

## QuickslotUI - Displays the 3 quickslot items with equipped highlight
## Updates when inventory or equipment changes

@onready var slot_nodes: Array[Panel] = [
	$Container/HBoxContainer/Slot0,
	$Container/HBoxContainer/Slot1,
	$Container/HBoxContainer/Slot2
]

var inventory_mechanic: Node
var equipment_manager: Node
var pulse_time: float = 0.0  # For pulsing animation

func _ready():
	# Wait a frame for player and mechanics to be ready
	await get_tree().process_frame

	# Find player and mechanics
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("QuickslotUI: Player not found in group 'player'")
		return

	inventory_mechanic = player.get_node_or_null("InventoryMechanic")
	equipment_manager = player.get_node_or_null("EquipmentManager")

	if not inventory_mechanic:
		push_warning("QuickslotUI: InventoryMechanic not found")
		return

	if not equipment_manager:
		push_warning("QuickslotUI: EquipmentManager not found")
		return

	# Connect to signals
	if inventory_mechanic.has_signal("inventory_changed"):
		inventory_mechanic.inventory_changed.connect(_on_inventory_changed)

	if equipment_manager.has_signal("equipment_changed"):
		equipment_manager.equipment_changed.connect(_on_equipment_changed)

	# Initial update
	update_all_slots()

func _process(delta):
	"""Animate the pulse effect for equipped slot"""
	pulse_time += delta * 2.0  # Speed of pulsing

	# Update the equipped slot's animation
	if equipment_manager:
		var equipped_index = equipment_manager.get_equipped_slot_index()
		if equipped_index >= 0 and equipped_index < slot_nodes.size():
			var slot_panel = slot_nodes[equipped_index]
			var highlight = slot_panel.get_node_or_null("Highlight")
			if highlight and highlight.visible:
				# Pulse the highlight between 0.6 and 1.0 alpha
				var pulse_alpha = 0.6 + sin(pulse_time) * 0.2 + 0.2
				var current_color = highlight.color
				current_color.a = pulse_alpha
				highlight.color = current_color

func update_all_slots():
	"""Update all 3 quickslot displays"""
	if not inventory_mechanic:
		return

	var equipped_index = -1
	if equipment_manager:
		equipped_index = equipment_manager.get_equipped_slot_index()

	for i in range(min(3, inventory_mechanic.quickslots.size())):
		update_slot(i, equipped_index == i)

func update_slot(slot_index: int, is_equipped: bool):
	"""Update a single quickslot display"""
	if slot_index < 0 or slot_index >= slot_nodes.size():
		return

	if slot_index >= inventory_mechanic.quickslots.size():
		return

	var slot_panel = slot_nodes[slot_index]
	var slot = inventory_mechanic.quickslots[slot_index]

	# Get UI elements
	var icon_rect = slot_panel.get_node("Icon")
	var quantity_label = slot_panel.get_node("Quantity")
	var highlight = slot_panel.get_node("Highlight")
	var background = slot_panel.get_node("Background")
	var slot_number_label = slot_panel.get_node_or_null("SlotNumber")

	# Update highlight and background based on equipped status
	if is_equipped:
		# Bright highlight for equipped slot
		highlight.visible = true
		highlight.color = Color(1, 0.9, 0, 0.8)  # Bright gold, more opaque
		background.color = Color(0.3, 0.3, 0.2, 0.9)  # Slightly brighter background

		# Add border effect by making the panel itself have a modulate
		slot_panel.modulate = Color(1.2, 1.2, 1.0, 1.0)  # Slight brightness boost

		# Make slot number more visible when selected
		if slot_number_label:
			slot_number_label.modulate = Color(1.5, 1.5, 0.8, 1.0)  # Bright yellow
			slot_number_label.add_theme_font_size_override("font_size", 16)
	else:
		# Normal state for unequipped slots
		highlight.visible = false
		background.color = Color(0.2, 0.2, 0.2, 0.8)  # Darker background
		slot_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal brightness

		# Normal slot number appearance
		if slot_number_label:
			slot_number_label.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Subtle gray
			slot_number_label.add_theme_font_size_override("font_size", 12)

	# Update content
	if slot and not slot.is_empty():
		# Slot has an item
		var item_data = slot.item_data

		# Set icon (if available)
		if item_data.icon:
			icon_rect.texture = item_data.icon
			icon_rect.visible = true
		else:
			# No icon - show placeholder or item name initial
			icon_rect.visible = false

		# Set quantity
		if item_data.max_stack > 1:
			quantity_label.text = str(slot.quantity)
		else:
			quantity_label.text = ""  # Don't show quantity for non-stackable items
	else:
		# Empty slot
		icon_rect.texture = null
		icon_rect.visible = false
		quantity_label.text = ""

func _on_inventory_changed():
	"""Handle inventory changes"""
	update_all_slots()

func _on_equipment_changed(_item_data: ItemData):
	"""Handle equipment changes (just update highlights)"""
	update_all_slots()
