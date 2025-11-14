extends CanvasLayer

## Full Inventory Menu - Opens with I or Tab, shows all inventory slots and quickslots

@onready var background = $Background
@onready var panel = $Panel
@onready var inventory_label = $Panel/VBoxContainer/InventoryLabel
@onready var quickslot_label = $Panel/VBoxContainer/QuickslotLabel

# Slot references
var main_slots: Array[Panel] = []
var quick_slots: Array[Panel] = []

var inventory_mechanic: Node
var is_open: bool = false

func _ready():
	# Get slot references
	for i in range(6):
		var slot = $Panel/VBoxContainer/InventoryGrid.get_node("Slot" + str(i))
		main_slots.append(slot)

	for i in range(3):
		var slot = $Panel/VBoxContainer/QuickslotGrid.get_node("QSlot" + str(i))
		quick_slots.append(slot)

	# Wait for player to be ready
	await get_tree().process_frame

	# Find player and inventory mechanic
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("InventoryMenuUI: Player not found")
		return

	inventory_mechanic = player.get_node_or_null("InventoryMechanic")
	if not inventory_mechanic:
		push_warning("InventoryMenuUI: InventoryMechanic not found")
		return

	# Connect to inventory changes
	if inventory_mechanic.has_signal("inventory_changed"):
		inventory_mechanic.inventory_changed.connect(_on_inventory_changed)

	# Initially hidden
	background.visible = false
	panel.visible = false

func _input(event):
	# Toggle with I or Tab
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I or event.keycode == KEY_TAB:
			toggle_inventory()
			get_viewport().set_input_as_handled()

func toggle_inventory():
	"""Open or close the inventory menu"""
	is_open = !is_open
	background.visible = is_open
	panel.visible = is_open

	if is_open:
		# Pause game
		get_tree().paused = true
		# Update display
		update_display()
	else:
		# Unpause game
		get_tree().paused = false

func update_display():
	"""Update all slots and labels"""
	if not inventory_mechanic:
		return

	# Update main inventory label
	var used_main = inventory_mechanic.get_main_used_slots()
	var max_main = PlayerGlobals.get_max_main_slots()
	inventory_label.text = "Main Inventory: %d/%d" % [used_main, max_main]

	# Update quickslot label
	var used_quick = inventory_mechanic.get_quick_used_slots()
	var max_quick = PlayerGlobals.get_max_quick_slots()
	quickslot_label.text = "Quickslots: %d/%d" % [used_quick, max_quick]

	# Update main inventory slots
	for i in range(main_slots.size()):
		update_slot(main_slots[i], inventory_mechanic.main_inventory, i)

	# Update quickslots
	for i in range(quick_slots.size()):
		update_slot(quick_slots[i], inventory_mechanic.quickslots, i)

func update_slot(slot_panel: Panel, inventory_array: Array, slot_index: int):
	"""Update a single slot display"""
	var icon_rect = slot_panel.get_node("Icon")
	var quantity_label = slot_panel.get_node("Quantity")

	# Check if slot exists and has item
	if slot_index < inventory_array.size():
		var slot = inventory_array[slot_index]

		if slot and not slot.is_empty():
			var item_data = slot.item_data

			# Set icon if available
			if item_data.icon:
				icon_rect.texture = item_data.icon
				icon_rect.visible = true
			else:
				icon_rect.visible = false

			# Set quantity
			if item_data.max_stack > 1:
				quantity_label.text = str(slot.quantity)
			else:
				quantity_label.text = ""
		else:
			# Empty slot
			icon_rect.texture = null
			icon_rect.visible = false
			quantity_label.text = ""
	else:
		# Slot doesn't exist (shouldn't happen)
		icon_rect.texture = null
		icon_rect.visible = false
		quantity_label.text = ""

func _on_inventory_changed():
	"""Update display when inventory changes"""
	if is_open:
		update_display()
