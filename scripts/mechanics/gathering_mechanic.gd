class_name GatheringMechanic
extends Node

## Handles gathering/picking up items in the world

signal item_gathered(item_data: ItemData, quantity: int)
signal nearest_item_changed(item: Area2D)
signal gathering_progress(progress: float, total: float)  # For UI feedback

@export var gather_range = 100.0
@export var default_gather_time = 2.0  # Fallback if item has no gather time
@export var gather_cooldown = 0.2

var player: CharacterBody2D
var detection_area: Area2D
var nearby_items: Array[Area2D] = []
var nearest_item: Area2D = null
var cooldown_timer = 0.0
var gathering_progress_timer = 0.0
var is_gathering = false
var target_item: Area2D = null  # Item being gathered

func _ready():
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("GatheringMechanic must be child of CharacterBody2D")
		return

	# Get the ItemDetectionArea (will be added as sibling)
	call_deferred("_setup_detection_area")

func _setup_detection_area():
	detection_area = player.get_node_or_null("ItemDetectionArea")
	if detection_area:
		detection_area.area_entered.connect(_on_item_entered)
		detection_area.area_exited.connect(_on_item_exited)
	else:
		push_warning("ItemDetectionArea not found on player. Add it to player.tscn")

func _on_item_entered(area: Area2D):
	"""Track items that enter detection range"""
	if area.is_in_group("pickable"):
		nearby_items.append(area)
		_update_nearest_item()

func _on_item_exited(area: Area2D):
	"""Remove items that leave detection range"""
	if area in nearby_items:
		nearby_items.erase(area)
		_update_nearest_item()

func _update_nearest_item():
	"""Find the closest item to the player"""
	var previous_nearest = nearest_item
	nearest_item = null
	var closest_distance = gather_range

	for item in nearby_items:
		if not is_instance_valid(item):
			nearby_items.erase(item)
			continue

		var distance = player.global_position.distance_to(item.global_position)
		if distance < closest_distance:
			closest_distance = distance
			nearest_item = item

	# Update highlighting when nearest item changes
	if nearest_item != previous_nearest:
		# Remove highlight from previous item
		if previous_nearest and is_instance_valid(previous_nearest) and previous_nearest.has_method("set_highlighted"):
			previous_nearest.set_highlighted(false)

		# Highlight new nearest item
		if nearest_item and nearest_item.has_method("set_highlighted"):
			nearest_item.set_highlighted(true)

		# Emit signal
		nearest_item_changed.emit(nearest_item)

func can_activate() -> bool:
	"""Check if we can start gathering an item"""
	return (cooldown_timer <= 0.0
		and nearest_item != null
		and is_instance_valid(nearest_item)
		and (not is_gathering or target_item == nearest_item))

func execute(delta: float):
	"""Main gathering logic - called every frame"""
	# Update cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# Update nearest item each frame
	_update_nearest_item()

	# Handle gathering input (hold to gather)
	if Input.is_action_pressed("interact") and can_activate():
		# Start or continue gathering
		if not is_gathering:
			# Start gathering
			is_gathering = true
			target_item = nearest_item
			gathering_progress_timer = 0.0

			# Get item name for feedback
			var item_name = "item"
			if target_item.has_method("get_item_data"):
				var data = target_item.get_item_data()
				if data:
					item_name = data.item_name
			print("Started gathering %s..." % item_name)

		# Get current item's gather time
		var current_gather_time = get_item_gather_time(target_item)

		# Progress gathering timer
		gathering_progress_timer += delta

		# Emit progress signal for UI feedback
		gathering_progress.emit(gathering_progress_timer, current_gather_time)

		# Check if gathering is complete
		if gathering_progress_timer >= current_gather_time:
			# Complete gathering
			if is_instance_valid(target_item):
				gather_item(target_item)
			# Reset gathering state
			is_gathering = false
			gathering_progress_timer = 0.0
			target_item = null
	else:
		# Key released or can't gather - reset progress
		if is_gathering:
			print("Gathering cancelled")
			is_gathering = false
			gathering_progress_timer = 0.0
			target_item = null

func gather_item(item: Area2D):
	"""Pick up an item"""
	if not is_instance_valid(item):
		return

	# Get ItemData and quantity
	var item_data: ItemData = null
	var quantity = 1

	if item.has_method("get_item_data"):
		item_data = item.get_item_data()
	if item.has_method("get_quantity"):
		quantity = item.get_quantity()

	# Notify item it's been picked up
	if item.has_method("pickup"):
		item.pickup()

	# Emit signal with ItemData
	item_gathered.emit(item_data, quantity)

	# Remove from tracking
	if item in nearby_items:
		nearby_items.erase(item)

	# Start cooldown
	cooldown_timer = gather_cooldown

	# Update nearest item
	_update_nearest_item()

	# Print feedback
	if item_data:
		print("Gathered: %s x%d" % [item_data.item_name, quantity])
	else:
		print("Gathered: unknown item x%d" % quantity)

func get_item_gather_time(item: Area2D) -> float:
	"""Get the gather time for a specific item"""
	if not is_instance_valid(item):
		return default_gather_time

	if item.has_method("get_gather_time"):
		return item.get_gather_time()

	# Fallback to default
	return default_gather_time

func is_active() -> bool:
	"""Check if this mechanic is currently active (gathering in progress)"""
	return is_gathering

func get_gathering_progress() -> float:
	"""Get current gathering progress as percentage (0.0 to 1.0)"""
	if is_gathering and target_item:
		var current_gather_time = get_item_gather_time(target_item)
		return gathering_progress_timer / current_gather_time
	return 0.0

func get_nearest_item() -> Area2D:
	"""Get the currently nearest pickable item"""
	return nearest_item
