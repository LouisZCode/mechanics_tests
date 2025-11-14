class_name AttackMechanic
extends Node

## Handles attack system with action mode, windup, and cooldowns
## Right-click to enter action mode, left-click to start windup, release to execute attack

signal action_mode_changed(is_active: bool)
signal attack_started(item_data: ItemData)
signal attack_executed(item_data: ItemData, damage: int)
signal windup_progress(progress: float, total: float)

var player: CharacterBody2D
var equipment_manager: Node
var gathering_mechanic: Node
var inventory_mechanic: Node

# State tracking
var is_action_mode: bool = false
var is_winding_up: bool = false
var windup_timer: float = 0.0
var cooldown_timer: float = 0.0

func _ready():
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("AttackMechanic must be child of CharacterBody2D")
		return

	call_deferred("_setup_equipment_manager")
	call_deferred("_setup_gathering_mechanic")
	call_deferred("_setup_inventory_mechanic")

func _setup_equipment_manager():
	equipment_manager = player.get_node_or_null("EquipmentManager")
	if not equipment_manager:
		push_warning("AttackMechanic: EquipmentManager not found. Cannot attack without equipped items.")

func _setup_gathering_mechanic():
	gathering_mechanic = player.get_node_or_null("GatheringMechanic")
	if not gathering_mechanic:
		push_warning("AttackMechanic: GatheringMechanic not found. Attack/gather conflict detection disabled.")

func _setup_inventory_mechanic():
	inventory_mechanic = player.get_node_or_null("InventoryMechanic")
	if not inventory_mechanic:
		push_warning("AttackMechanic: InventoryMechanic not found. Durability system disabled.")

func can_activate() -> bool:
	"""Check if we can enter action mode or start attack"""
	# Can't attack while gathering
	if gathering_mechanic and gathering_mechanic.is_active():
		return false

	# Need equipped item that can attack
	if not equipment_manager or not equipment_manager.has_method("get_equipped_item"):
		return false

	var equipped_item = equipment_manager.get_equipped_item()
	if not equipped_item:
		return false

	return equipped_item.can_attack()

func execute(delta: float) -> Dictionary:
	"""
	Execute attack logic
	Returns: {is_action_mode: bool, is_winding_up: bool, windup_progress: float}
	"""
	# Update cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# Handle action mode toggle (right-click)
	if Input.is_action_just_pressed("ui_select"):  # Right mouse button
		toggle_action_mode()

	# Handle attack input (left-click while in action mode)
	if is_action_mode and can_activate():
		# Start windup on left-click press
		if Input.is_action_just_pressed("interact") and not is_winding_up and cooldown_timer <= 0:
			start_windup()

		# Update windup if active
		if is_winding_up:
			update_windup(delta)

			# Check for release
			if Input.is_action_just_released("interact"):
				execute_attack()

	# Auto-exit action mode if can't attack
	if is_action_mode and not can_activate():
		exit_action_mode()

	return {
		"is_action_mode": is_action_mode,
		"is_winding_up": is_winding_up,
		"windup_progress": windup_timer
	}

func toggle_action_mode():
	"""Toggle action mode on/off"""
	if is_action_mode:
		exit_action_mode()
	else:
		enter_action_mode()

func enter_action_mode():
	"""Enter action mode (ready weapon)"""
	if not can_activate():
		return

	is_action_mode = true
	action_mode_changed.emit(true)

func exit_action_mode():
	"""Exit action mode"""
	is_action_mode = false
	is_winding_up = false
	windup_timer = 0.0
	action_mode_changed.emit(false)

func start_windup():
	"""Start winding up for an attack"""
	if not can_activate():
		return

	var equipped_item = equipment_manager.get_equipped_item()
	if not equipped_item:
		return

	is_winding_up = true
	windup_timer = 0.0
	attack_started.emit(equipped_item)

func update_windup(delta: float):
	"""Update windup progress"""
	if not is_winding_up:
		return

	var equipped_item = equipment_manager.get_equipped_item()
	if not equipped_item:
		cancel_windup()
		return

	windup_timer += delta
	var required_time = equipped_item.attack_windup_time

	# Emit progress for UI/animation
	windup_progress.emit(windup_timer, required_time)

func execute_attack():
	"""Execute attack when windup is complete"""
	if not is_winding_up:
		return

	var equipped_item = equipment_manager.get_equipped_item()
	if not equipped_item:
		cancel_windup()
		return

	var required_time = equipped_item.attack_windup_time

	# Check if windup completed
	if windup_timer >= required_time:
		# Attack executed successfully
		var damage = equipped_item.stat_attack_damage
		attack_executed.emit(equipped_item, damage)

		# Reduce durability if inventory mechanic is available
		if inventory_mechanic and equipment_manager:
			var equipped_slot_index = equipment_manager.get_equipped_slot_index()
			if equipped_slot_index >= 0 and equipped_slot_index < inventory_mechanic.quickslots.size():
				var slot = inventory_mechanic.quickslots[equipped_slot_index]
				if slot and not slot.is_empty():
					# Get durability cost for attacking (default 5 if not specified)
					var durability_cost = 5
					if equipped_item.has("durability_cost_attack"):
						durability_cost = equipped_item.durability_cost_attack

					# Reduce durability
					var item_broke = slot.reduce_durability(durability_cost)

					if item_broke:
						print("Your %s broke!" % equipped_item.item_name)
						# Exit action mode since weapon broke
						exit_action_mode()
					else:
						var durability_percent = slot.get_durability_percentage()
						if durability_percent <= 0.25:
							print("Warning: %s durability critical! (%d/%d)" % [
								equipped_item.item_name,
								slot.current_durability,
								equipped_item.stat_durability
							])

		# Start cooldown
		cooldown_timer = equipped_item.attack_cooldown

		# Reset windup
		is_winding_up = false
		windup_timer = 0.0
	else:
		# Released too early - cancel attack
		cancel_windup()

func cancel_windup():
	"""Cancel windup (released too early or item removed)"""
	is_winding_up = false
	windup_timer = 0.0

func is_active() -> bool:
	"""Check if this mechanic is currently active"""
	return is_action_mode or is_winding_up

func get_windup_progress() -> float:
	"""Get windup progress as percentage (0.0 to 1.0)"""
	if not is_winding_up:
		return 0.0

	var equipped_item = equipment_manager.get_equipped_item()
	if not equipped_item:
		return 0.0

	return min(windup_timer / equipped_item.attack_windup_time, 1.0)
