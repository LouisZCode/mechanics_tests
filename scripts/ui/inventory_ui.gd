class_name InventoryUI
extends CanvasLayer

## Simple text-based UI for inventory display

@onready var inventory_label: Label = $InventoryLabel
@onready var quickslot_label: Label = $QuickslotLabel
@onready var weight_label: Label = $WeightLabel

var inventory: InventoryMechanic

func _ready():
	# Find the player's InventoryMechanic
	call_deferred("_setup_inventory_reference")

func _setup_inventory_reference():
	# Get reference to player's inventory
	var player = get_tree().get_first_node_in_group("player")
	if player:
		inventory = player.get_node_or_null("InventoryMechanic")
		if inventory:
			# Connect to inventory signals
			inventory.inventory_changed.connect(_update_display)
			inventory.weight_changed.connect(_update_weight_display)

			# Initial display update
			_update_display()
		else:
			push_warning("InventoryMechanic not found on player")
	else:
		push_warning("Player not found in 'player' group")

func _update_display():
	"""Update all inventory display labels"""
	if not inventory:
		return

	# Main inventory display (get max from PlayerGlobals)
	var main_used = inventory.get_main_used_slots()
	var main_max = PlayerGlobals.get_max_main_slots()
	inventory_label.text = "Inventory: %d/%d" % [main_used, main_max]

	# Quickslots display (get max from PlayerGlobals)
	var quick_used = inventory.get_quick_used_slots()
	var quick_max = PlayerGlobals.get_max_quick_slots()
	quickslot_label.text = "Quick: %d/%d" % [quick_used, quick_max]

	# Weight display (will be updated by separate signal)
	_update_weight_display(inventory.get_total_weight(), inventory.get_speed_multiplier())

func _update_weight_display(current_weight: float, speed_multiplier: float):
	"""Update weight and speed display"""
	var speed_percent = int(speed_multiplier * 100)
	weight_label.text = "Weight: %.1fkg (%d%%)" % [current_weight, speed_percent]

	# Color code based on speed penalty
	if speed_multiplier >= 1.0:
		weight_label.modulate = Color.WHITE
	elif speed_multiplier >= 0.9:
		weight_label.modulate = Color(1.0, 1.0, 0.7)  # Light yellow
	elif speed_multiplier >= 0.75:
		weight_label.modulate = Color(1.0, 0.8, 0.4)  # Orange
	else:
		weight_label.modulate = Color(1.0, 0.4, 0.4)  # Red
