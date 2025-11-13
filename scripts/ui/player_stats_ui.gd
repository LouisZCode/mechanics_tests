extends CanvasLayer

## Debug UI to display PlayerGlobals stats for testing

@onready var movement_label: Label = $MovementLabel
@onready var gathering_label: Label = $GatheringLabel
@onready var inventory_label: Label = $InventoryStatsLabel

func _ready():
	# Connect to PlayerGlobals signals
	PlayerGlobals.stats_changed.connect(_update_display)
	PlayerGlobals.movement_speed_changed.connect(_on_stats_changed)
	PlayerGlobals.gathering_speed_changed.connect(_on_stats_changed)
	PlayerGlobals.inventory_capacity_changed.connect(_on_stats_changed)

	# Initial update
	_update_display()

func _on_stats_changed(_arg1 = null, _arg2 = null):
	"""Signal handler that ignores arguments and updates display"""
	_update_display()

func _update_display():
	"""Update all stat labels"""
	# Movement stats
	var move_speed = PlayerGlobals.get_movement_speed()
	var run_mult = PlayerGlobals.get_run_multiplier()
	movement_label.text = "Movement: %.0f (Run: x%.1f)" % [move_speed, run_mult]

	# Gathering stats
	var gather_range = PlayerGlobals.get_gather_range()
	var gather_speed = PlayerGlobals.get_gather_speed_multiplier()
	gathering_label.text = "Gather: Range %.0fpx | Speed x%.2f" % [gather_range, gather_speed]

	# Inventory stats
	var main_slots = PlayerGlobals.get_max_main_slots()
	var quick_slots = PlayerGlobals.get_max_quick_slots()
	var thresholds = PlayerGlobals.get_weight_thresholds()
	inventory_label.text = "Capacity: %d/%d | Weight: %.0f/%.0f/%.0f/%.0f kg" % [
		main_slots, quick_slots,
		thresholds.threshold_1, thresholds.threshold_2,
		thresholds.threshold_3, thresholds.threshold_4
	]
