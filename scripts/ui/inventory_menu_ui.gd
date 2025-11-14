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

# Selection state (for WASD navigation and number keys)
var selected_slot_index: int = 0  # Currently selected slot
var selected_is_quickslot: bool = false  # Is selected slot in quickslot area?

# Pickup/place state (for E key)
var held_item_slot_index: int = -1  # -1 = not holding anything
var held_item_is_quickslot: bool = false

# Mouse hover state
var hovered_slot_index: int = -1  # -1 = not hovering any slot
var hovered_is_quickslot: bool = false

# Drag state (for mouse drag)
var dragging: bool = false
var drag_source_slot: int = -1
var drag_source_is_quickslot: bool = false

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
	# Only handle input when inventory is open
	if not is_open:
		# Toggle with I or Tab (works when closed)
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_I or event.keycode == KEY_TAB:
				toggle_inventory()
				get_viewport().set_input_as_handled()
		return

	# Mouse motion - for hover detection
	if event is InputEventMouseMotion:
		update_mouse_hover(event.position)

	# Mouse button press - start drag
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_mouse_click(event.position)

	# Mouse button release - end drag
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_mouse_release(event.position)

	# Input handling when inventory IS open (keyboard)
	if event is InputEventKey and event.pressed and not event.echo:
		# Toggle close
		if event.keycode == KEY_I or event.keycode == KEY_TAB:
			toggle_inventory()
			get_viewport().set_input_as_handled()
			return

		# Number keys (1/2/3) - Move selected main inventory item to quickslot
		if event.keycode == KEY_1 or event.keycode == KEY_2 or event.keycode == KEY_3:
			# Only works if a main inventory slot is selected
			if not selected_is_quickslot:
				var quick_slot_idx = 0 if event.keycode == KEY_1 else (1 if event.keycode == KEY_2 else 2)
				# Move to quickslot (will swap if occupied)
				if inventory_mechanic.move_to_quickslot(selected_slot_index, quick_slot_idx):
					print("Moved item to quickslot %d" % (quick_slot_idx + 1))
				get_viewport().set_input_as_handled()
			return

		# WASD Navigation
		if event.keycode == KEY_W:
			navigate_up()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_S:
			navigate_down()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_A:
			navigate_left()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_D:
			navigate_right()
			get_viewport().set_input_as_handled()
			return

		# E key - Pickup or Place item
		if event.keycode == KEY_E:
			if held_item_slot_index == -1:
				# Not holding anything → pick up selected item
				pickup_item()
			else:
				# Holding an item → place it at selected slot
				place_item()
			get_viewport().set_input_as_handled()
			return

func toggle_inventory():
	"""Open or close the inventory menu"""
	is_open = !is_open
	background.visible = is_open
	panel.visible = is_open

	if is_open:
		# Pause game
		get_tree().paused = true
		# Reset selection to first main inventory slot
		selected_slot_index = 0
		selected_is_quickslot = false
		# Update display
		update_display()
		update_selection_highlight()
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

func update_selection_highlight():
	"""Update which slot shows the selection highlight"""
	# Clear all highlights in main inventory
	for i in range(main_slots.size()):
		var highlight = main_slots[i].get_node_or_null("Highlight")
		if highlight:
			highlight.visible = (i == selected_slot_index and not selected_is_quickslot)

	# Clear all highlights in quickslots
	for i in range(quick_slots.size()):
		var highlight = quick_slots[i].get_node_or_null("Highlight")
		if highlight:
			highlight.visible = (i == selected_slot_index and selected_is_quickslot)

# ============================================================================
# WASD NAVIGATION
# ============================================================================

func navigate_up():
	"""Move selection up"""
	if selected_is_quickslot:
		# From quickslot → main inventory bottom row (keep column position)
		selected_is_quickslot = false
		selected_slot_index = 3 + selected_slot_index  # Maps QSlot0→Slot3, QSlot1→Slot4, QSlot2→Slot5
	else:
		# In main inventory
		if selected_slot_index >= 3:
			# In bottom row (3-5) → move to top row (0-2)
			selected_slot_index -= 3
		# Already in top row (0-2) → stay there

	update_selection_highlight()

func navigate_down():
	"""Move selection down"""
	if selected_is_quickslot:
		# Already in quickslots → stay there
		return
	else:
		# In main inventory
		if selected_slot_index < 3:
			# In top row (0-2) → move to bottom row (3-5)
			selected_slot_index += 3
		else:
			# In bottom row (3-5) → move to quickslots
			selected_is_quickslot = true
			selected_slot_index = selected_slot_index - 3  # Maps Slot3→QSlot0, Slot4→QSlot1, Slot5→QSlot2

	update_selection_highlight()

func navigate_left():
	"""Move selection left (wraps around in current row)"""
	if selected_is_quickslot:
		# Quickslots: 0 ← 1 ← 2 ← (wraps to 0)
		selected_slot_index = (selected_slot_index - 1 + 3) % 3
	else:
		# Main inventory: Move left within current row
		var row = int(selected_slot_index / 3)
		var col = selected_slot_index % 3
		col = (col - 1 + 3) % 3  # Wrap around
		selected_slot_index = row * 3 + col

	update_selection_highlight()

func navigate_right():
	"""Move selection right (wraps around in current row)"""
	if selected_is_quickslot:
		# Quickslots: 0 → 1 → 2 → (wraps to 0)
		selected_slot_index = (selected_slot_index + 1) % 3
	else:
		# Main inventory: Move right within current row
		var row = int(selected_slot_index / 3)
		var col = selected_slot_index % 3
		col = (col + 1) % 3  # Wrap around
		selected_slot_index = row * 3 + col

	update_selection_highlight()

# ============================================================================
# E KEY PICKUP/PLACE
# ============================================================================

func pickup_item():
	"""Pick up the selected item (first step of two-step move)"""
	# Store which slot we picked up from
	held_item_slot_index = selected_slot_index
	held_item_is_quickslot = selected_is_quickslot
	print("Picked up item from slot %d (%s)" % [held_item_slot_index, "quickslot" if held_item_is_quickslot else "main"])

func place_item():
	"""Place the held item at the selected slot (second step of two-step move)"""
	# Swap held item with selected slot
	if inventory_mechanic.swap_slots(held_item_slot_index, held_item_is_quickslot, selected_slot_index, selected_is_quickslot):
		print("Placed item at slot %d (%s)" % [selected_slot_index, "quickslot" if selected_is_quickslot else "main"])

	# Clear held item
	held_item_slot_index = -1
	held_item_is_quickslot = false

# ============================================================================
# MOUSE INTERACTIONS
# ============================================================================

func update_mouse_hover(mouse_pos: Vector2):
	"""Detect which slot the mouse is hovering over"""
	var old_hovered = hovered_slot_index
	var old_hovered_is_quick = hovered_is_quickslot

	# Reset hover state
	hovered_slot_index = -1
	hovered_is_quickslot = false

	# Check main inventory slots
	for i in range(main_slots.size()):
		if is_mouse_over_slot(main_slots[i], mouse_pos):
			hovered_slot_index = i
			hovered_is_quickslot = false
			break

	# Check quickslots if not hovering main inventory
	if hovered_slot_index == -1:
		for i in range(quick_slots.size()):
			if is_mouse_over_slot(quick_slots[i], mouse_pos):
				hovered_slot_index = i
				hovered_is_quickslot = true
				break

	# Update highlight if hover changed
	if old_hovered != hovered_slot_index or old_hovered_is_quick != hovered_is_quickslot:
		update_hover_highlight()

func is_mouse_over_slot(slot_panel: Panel, mouse_pos: Vector2) -> bool:
	"""Check if mouse position is within a slot's bounds"""
	var rect = slot_panel.get_global_rect()
	return rect.has_point(mouse_pos)

func update_hover_highlight():
	"""Update hover highlight on all slots"""
	# For now, hover just updates selection
	# Later we can add a separate visual effect
	# This makes mouse hover set the selection, which works with number keys
	if hovered_slot_index != -1:
		selected_slot_index = hovered_slot_index
		selected_is_quickslot = hovered_is_quickslot
		update_selection_highlight()

func handle_mouse_click(mouse_pos: Vector2):
	"""Handle mouse click - start drag"""
	# Find which slot was clicked
	var clicked_slot = -1
	var clicked_is_quickslot = false

	for i in range(main_slots.size()):
		if is_mouse_over_slot(main_slots[i], mouse_pos):
			clicked_slot = i
			clicked_is_quickslot = false
			break

	if clicked_slot == -1:
		for i in range(quick_slots.size()):
			if is_mouse_over_slot(quick_slots[i], mouse_pos):
				clicked_slot = i
				clicked_is_quickslot = true
				break

	# If clicked a slot, start dragging from it
	if clicked_slot != -1:
		# Set as selected (for visual feedback)
		selected_slot_index = clicked_slot
		selected_is_quickslot = clicked_is_quickslot
		update_selection_highlight()

		# Start drag
		dragging = true
		drag_source_slot = clicked_slot
		drag_source_is_quickslot = clicked_is_quickslot
		print("Started dragging from slot %d (%s)" % [clicked_slot, "quickslot" if clicked_is_quickslot else "main"])

func handle_mouse_release(mouse_pos: Vector2):
	"""Handle mouse release - complete drag and swap items"""
	if not dragging:
		return

	# Find which slot mouse was released over
	var target_slot = -1
	var target_is_quickslot = false

	for i in range(main_slots.size()):
		if is_mouse_over_slot(main_slots[i], mouse_pos):
			target_slot = i
			target_is_quickslot = false
			break

	if target_slot == -1:
		for i in range(quick_slots.size()):
			if is_mouse_over_slot(quick_slots[i], mouse_pos):
				target_slot = i
				target_is_quickslot = true
				break

	# If released over a slot, swap items
	if target_slot != -1:
		if inventory_mechanic.swap_slots(drag_source_slot, drag_source_is_quickslot, target_slot, target_is_quickslot):
			print("Dragged item to slot %d (%s)" % [target_slot, "quickslot" if target_is_quickslot else "main"])
		else:
			print("Drag failed - couldn't swap")
	else:
		print("Drag cancelled - released outside slots")

	# End drag
	dragging = false
	drag_source_slot = -1
	drag_source_is_quickslot = false
