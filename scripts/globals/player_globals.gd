extends Node

## Global player stats and upgrades - accessible from anywhere via PlayerGlobals singleton

# ============================================================================
# SIGNALS
# ============================================================================

signal stats_changed()
signal movement_speed_changed(new_speed: float)
signal inventory_capacity_changed(main_slots: int, quick_slots: int)
signal gathering_speed_changed(multiplier: float)
signal health_changed(current: float, max_value: float)
signal energy_changed(current: float, max_value: float)

# ============================================================================
# MOVEMENT STATS
# ============================================================================

@export_group("Movement")
## Base walking speed (pixels per second)
@export var base_movement_speed: float = 170.0
## Multiplier when running (Shift key)
@export var base_run_multiplier: float = 2.5

# Current stats (can be modified by buffs/debuffs)
var current_movement_speed: float = 170.0
var current_run_multiplier: float = 2.5

# ============================================================================
# INVENTORY STATS
# ============================================================================

@export_group("Inventory")
## Maximum main inventory slots
@export var base_max_main_slots: int = 10
## Maximum quickslot slots
@export var base_max_quick_slots: int = 3
## Weight thresholds for speed penalties (kg)
@export var base_weight_threshold_1: float = 7.0   # No penalty
@export var base_weight_threshold_2: float = 10.0  # 90% speed
@export var base_weight_threshold_3: float = 15.0  # 75% speed
@export var base_weight_threshold_4: float = 20.0  # 50% speed
## Weight reduction for quickslot items (70% = items weigh less in quickslots)
@export var quickslot_weight_multiplier: float = 0.7

# Current stats (upgradeable)
var current_max_main_slots: int = 10
var current_max_quick_slots: int = 3
var current_weight_threshold_1: float = 7.0
var current_weight_threshold_2: float = 10.0
var current_weight_threshold_3: float = 15.0
var current_weight_threshold_4: float = 20.0

# ============================================================================
# GATHERING STATS
# ============================================================================

@export_group("Gathering")
## Detection radius for nearby items (pixels)
@export var base_gather_range: float = 100.0
## Speed multiplier for gathering (1.0 = normal, 1.5 = 50% faster)
@export var base_gather_speed_multiplier: float = 1.0
## Default gather time if item has none specified (seconds)
@export var base_default_gather_time: float = 2.0
## Cooldown between pickups (seconds)
@export var base_gather_cooldown: float = 0.2

# Current stats (upgradeable)
var current_gather_range: float = 100.0
var current_gather_speed_multiplier: float = 1.0
var current_default_gather_time: float = 2.0
var current_gather_cooldown: float = 0.2

# ============================================================================
# HEALTH & ENERGY (Future Implementation)
# ============================================================================

@export_group("Health & Energy")
## Maximum health points
@export var base_max_health: float = 100.0
## Maximum energy points
@export var base_max_energy: float = 100.0
## Energy regeneration per second when idle
@export var base_energy_regen: float = 10.0

# Current stats
var current_max_health: float = 100.0
var current_max_energy: float = 100.0
var current_energy_regen: float = 10.0

# Current values (actual HP/Energy)
var current_health: float = 100.0
var current_energy: float = 100.0

# ============================================================================
# CLIMBING STATS (Future Implementation)
# ============================================================================

@export_group("Climbing")
## Climbing speed (pixels per second)
@export var base_climb_speed: float = 100.0
## Energy cost per second while climbing
@export var base_climb_energy_cost: float = 5.0

# Current stats
var current_climb_speed: float = 100.0
var current_climb_energy_cost: float = 5.0

# ============================================================================
# COMBAT STATS (Future Implementation)
# ============================================================================

@export_group("Combat")
## Base attack damage
@export var base_attack_damage: float = 10.0
## Attack cooldown (seconds)
@export var base_attack_cooldown: float = 0.5

# Current stats
var current_attack_damage: float = 10.0
var current_attack_cooldown: float = 0.5

# ============================================================================
# UPGRADE TRACKING
# ============================================================================

## Dictionary tracking purchased/unlocked upgrades
var unlocked_upgrades: Dictionary = {
	# Example: "inventory_upgrade_1": true
}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("PlayerGlobals initialized")
	reset_to_base_stats()

func reset_to_base_stats():
	"""Reset all current stats to base values"""
	# Movement
	current_movement_speed = base_movement_speed
	current_run_multiplier = base_run_multiplier

	# Inventory
	current_max_main_slots = base_max_main_slots
	current_max_quick_slots = base_max_quick_slots
	current_weight_threshold_1 = base_weight_threshold_1
	current_weight_threshold_2 = base_weight_threshold_2
	current_weight_threshold_3 = base_weight_threshold_3
	current_weight_threshold_4 = base_weight_threshold_4

	# Gathering
	current_gather_range = base_gather_range
	current_gather_speed_multiplier = base_gather_speed_multiplier
	current_default_gather_time = base_default_gather_time
	current_gather_cooldown = base_gather_cooldown

	# Health & Energy
	current_max_health = base_max_health
	current_max_energy = base_max_energy
	current_energy_regen = base_energy_regen
	current_health = current_max_health
	current_energy = current_max_energy

	# Climbing
	current_climb_speed = base_climb_speed
	current_climb_energy_cost = base_climb_energy_cost

	# Combat
	current_attack_damage = base_attack_damage
	current_attack_cooldown = base_attack_cooldown

	stats_changed.emit()

# ============================================================================
# MOVEMENT METHODS
# ============================================================================

func get_movement_speed() -> float:
	"""Get current movement speed"""
	return current_movement_speed

func get_run_multiplier() -> float:
	"""Get current run multiplier"""
	return current_run_multiplier

func apply_movement_speed_upgrade(amount: float):
	"""Permanently increase base movement speed"""
	base_movement_speed += amount
	current_movement_speed = base_movement_speed
	movement_speed_changed.emit(current_movement_speed)
	stats_changed.emit()

func apply_temporary_speed_buff(multiplier: float, duration: float):
	"""Apply temporary speed boost (e.g., from potion)"""
	var original_speed = current_movement_speed
	current_movement_speed *= multiplier
	movement_speed_changed.emit(current_movement_speed)

	# Reset after duration
	await get_tree().create_timer(duration).timeout
	current_movement_speed = original_speed
	movement_speed_changed.emit(current_movement_speed)

# ============================================================================
# INVENTORY METHODS
# ============================================================================

func get_max_main_slots() -> int:
	"""Get current max main inventory slots"""
	return current_max_main_slots

func get_max_quick_slots() -> int:
	"""Get current max quickslot slots"""
	return current_max_quick_slots

func get_weight_thresholds() -> Dictionary:
	"""Get all weight thresholds"""
	return {
		"threshold_1": current_weight_threshold_1,
		"threshold_2": current_weight_threshold_2,
		"threshold_3": current_weight_threshold_3,
		"threshold_4": current_weight_threshold_4
	}

func apply_inventory_upgrade(main_slots: int = 0, quick_slots: int = 0):
	"""Increase inventory capacity"""
	if main_slots > 0:
		base_max_main_slots += main_slots
		current_max_main_slots = base_max_main_slots

	if quick_slots > 0:
		base_max_quick_slots += quick_slots
		current_max_quick_slots = base_max_quick_slots

	inventory_capacity_changed.emit(current_max_main_slots, current_max_quick_slots)
	stats_changed.emit()

func apply_weight_capacity_upgrade(threshold_increase: float):
	"""Increase weight thresholds (carry more without penalty)"""
	base_weight_threshold_1 += threshold_increase
	base_weight_threshold_2 += threshold_increase
	base_weight_threshold_3 += threshold_increase
	base_weight_threshold_4 += threshold_increase

	current_weight_threshold_1 = base_weight_threshold_1
	current_weight_threshold_2 = base_weight_threshold_2
	current_weight_threshold_3 = base_weight_threshold_3
	current_weight_threshold_4 = base_weight_threshold_4

	stats_changed.emit()

# ============================================================================
# GATHERING METHODS
# ============================================================================

func get_gather_range() -> float:
	"""Get current gathering detection range"""
	return current_gather_range

func get_gather_speed_multiplier() -> float:
	"""Get gathering speed multiplier (higher = faster gathering)"""
	return current_gather_speed_multiplier

func get_default_gather_time() -> float:
	"""Get default gather time for items without specified time"""
	return current_default_gather_time

func get_gather_cooldown() -> float:
	"""Get cooldown between pickups"""
	return current_gather_cooldown

func apply_gathering_speed_upgrade(multiplier_increase: float):
	"""Improve gathering speed (e.g., +0.2 = 20% faster)"""
	base_gather_speed_multiplier += multiplier_increase
	current_gather_speed_multiplier = base_gather_speed_multiplier
	gathering_speed_changed.emit(current_gather_speed_multiplier)
	stats_changed.emit()

func apply_gathering_range_upgrade(range_increase: float):
	"""Increase gathering detection range"""
	base_gather_range += range_increase
	current_gather_range = base_gather_range
	stats_changed.emit()

# ============================================================================
# HEALTH & ENERGY METHODS
# ============================================================================

func get_max_health() -> float:
	return current_max_health

func get_current_health() -> float:
	return current_health

func get_max_energy() -> float:
	return current_max_energy

func get_current_energy() -> float:
	return current_energy

func damage(amount: float):
	"""Take damage"""
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, current_max_health)

func heal(amount: float):
	"""Restore health"""
	current_health = min(current_max_health, current_health + amount)
	health_changed.emit(current_health, current_max_health)

func consume_energy(amount: float) -> bool:
	"""Consume energy. Returns false if not enough energy."""
	if current_energy >= amount:
		current_energy -= amount
		energy_changed.emit(current_energy, current_max_energy)
		return true
	return false

func restore_energy(amount: float):
	"""Restore energy"""
	current_energy = min(current_max_energy, current_energy + amount)
	energy_changed.emit(current_energy, current_max_energy)

func _process(delta):
	"""Regenerate energy over time"""
	if current_energy < current_max_energy:
		restore_energy(current_energy_regen * delta)

# ============================================================================
# CLIMBING METHODS
# ============================================================================

func get_climb_speed() -> float:
	return current_climb_speed

func get_climb_energy_cost() -> float:
	return current_climb_energy_cost

# ============================================================================
# UPGRADE SYSTEM
# ============================================================================

func unlock_upgrade(upgrade_id: String):
	"""Mark an upgrade as unlocked"""
	unlocked_upgrades[upgrade_id] = true
	print("Unlocked upgrade: %s" % upgrade_id)

func has_upgrade(upgrade_id: String) -> bool:
	"""Check if an upgrade is unlocked"""
	return unlocked_upgrades.get(upgrade_id, false)

func apply_upgrade(upgrade_id: String):
	"""Apply a specific upgrade by ID"""
	if has_upgrade(upgrade_id):
		print("Upgrade %s already unlocked" % upgrade_id)
		return

	# Apply upgrade based on ID
	match upgrade_id:
		"inventory_upgrade_1":
			apply_inventory_upgrade(5, 0)  # +5 main slots
		"inventory_upgrade_2":
			apply_inventory_upgrade(0, 2)  # +2 quickslots
		"gathering_speed_1":
			apply_gathering_speed_upgrade(0.2)  # 20% faster
		"gathering_range_1":
			apply_gathering_range_upgrade(50.0)  # +50 pixels
		"movement_speed_1":
			apply_movement_speed_upgrade(30.0)  # +30 speed
		"weight_capacity_1":
			apply_weight_capacity_upgrade(5.0)  # +5kg per threshold
		_:
			push_warning("Unknown upgrade ID: %s" % upgrade_id)
			return

	unlock_upgrade(upgrade_id)

# ============================================================================
# SAVE/LOAD (Future Implementation)
# ============================================================================

func get_save_data() -> Dictionary:
	"""Get all data for saving"""
	return {
		"base_stats": {
			"movement_speed": base_movement_speed,
			"run_multiplier": base_run_multiplier,
			"max_main_slots": base_max_main_slots,
			"max_quick_slots": base_max_quick_slots,
			"gather_speed_multiplier": base_gather_speed_multiplier,
			"gather_range": base_gather_range,
		},
		"current_values": {
			"health": current_health,
			"energy": current_energy,
		},
		"unlocked_upgrades": unlocked_upgrades
	}

func load_save_data(data: Dictionary):
	"""Load saved data"""
	if data.has("base_stats"):
		var stats = data["base_stats"]
		base_movement_speed = stats.get("movement_speed", base_movement_speed)
		base_run_multiplier = stats.get("run_multiplier", base_run_multiplier)
		base_max_main_slots = stats.get("max_main_slots", base_max_main_slots)
		base_max_quick_slots = stats.get("max_quick_slots", base_max_quick_slots)
		base_gather_speed_multiplier = stats.get("gather_speed_multiplier", base_gather_speed_multiplier)
		base_gather_range = stats.get("gather_range", base_gather_range)

	if data.has("current_values"):
		var values = data["current_values"]
		current_health = values.get("health", current_max_health)
		current_energy = values.get("energy", current_max_energy)

	if data.has("unlocked_upgrades"):
		unlocked_upgrades = data["unlocked_upgrades"]

	reset_to_base_stats()
	print("PlayerGlobals data loaded")
