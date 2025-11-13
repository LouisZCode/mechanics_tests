extends CanvasLayer

## Debug Console - F1 to toggle, execute commands in real-time
## Supports: stat changes, upgrades, item spawning, teleportation, and more

@onready var panel = $Panel
@onready var input_field = $Panel/VBoxContainer/InputContainer/Input
@onready var output_log = $Panel/VBoxContainer/OutputScroll/OutputLog

var is_open: bool = false
var command_history: Array[String] = []
var history_index: int = -1

# Predefined locations for goto command
var locations: Dictionary = {
	"spawn": Vector2(640, 400),
	"wall": Vector2(850, 400),
	"ground": Vector2(640, 450),
}

# Item resource paths
var item_paths: Dictionary = {
	"wood": "res://resources/items/wood.tres",
	"stone": "res://resources/items/stone.tres",
	"ore": "res://resources/items/ore.tres",
}

func _ready():
	panel.visible = false
	log_output("[color=lime]Debug Console Ready[/color]")
	log_output("Type 'help' for available commands")

func _input(event):
	# Toggle console with F1
	if event is InputEventKey and event.keycode == KEY_F1 and event.pressed and not event.echo:
		toggle_console()
		get_viewport().set_input_as_handled()

	# Command history navigation
	if is_open and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_UP:
			navigate_history(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			navigate_history(1)
			get_viewport().set_input_as_handled()

func toggle_console():
	is_open = !is_open
	panel.visible = is_open

	if is_open:
		input_field.grab_focus()
		# Pause the game when console is open
		get_tree().paused = true
	else:
		input_field.release_focus()
		get_tree().paused = false

func _on_input_text_submitted(text: String):
	if text.strip_edges().is_empty():
		return

	# Log the command
	log_output("[color=yellow]> " + text + "[/color]")

	# Add to history
	command_history.append(text)
	history_index = command_history.size()

	# Execute command
	execute_command(text.strip_edges())

	# Clear input
	input_field.clear()

func navigate_history(direction: int):
	if command_history.is_empty():
		return

	history_index = clamp(history_index + direction, 0, command_history.size())

	if history_index < command_history.size():
		input_field.text = command_history[history_index]
		input_field.caret_column = input_field.text.length()
	else:
		input_field.clear()

func execute_command(command: String):
	# Parse command and arguments
	var parts = command.split(" ", false)
	if parts.is_empty():
		return

	var cmd = parts[0].to_lower()
	var args = parts.slice(1)

	# Execute based on command type
	match cmd:
		"help":
			cmd_help()
		"clear":
			cmd_clear()
		"speed":
			cmd_speed(args)
		"climb_speed":
			cmd_climb_speed(args)
		"upgrade":
			cmd_upgrade(args)
		"give":
			cmd_give(args)
		"additem":
			cmd_additem(args)
		"goto":
			cmd_goto(args)
		"heal":
			cmd_heal(args)
		"damage":
			cmd_damage(args)
		"energy":
			cmd_energy(args)
		"reset":
			cmd_reset()
		"locations":
			cmd_locations()
		"items":
			cmd_items()
		_:
			log_output("[color=red]Unknown command: " + cmd + "[/color]")
			log_output("Type 'help' for available commands")

func cmd_help():
	log_output("[color=cyan]=== AVAILABLE COMMANDS ===[/color]")
	log_output("")
	log_output("[color=yellow]General:[/color]")
	log_output("  help - Show this help message")
	log_output("  clear - Clear console output")
	log_output("  locations - List teleport locations")
	log_output("  items - List available items")
	log_output("")
	log_output("[color=yellow]Stats:[/color]")
	log_output("  speed <value> - Set movement speed")
	log_output("  climb_speed <value> - Set climbing speed")
	log_output("  heal <amount> - Restore health")
	log_output("  damage <amount> - Take damage")
	log_output("  energy <amount> - Restore energy")
	log_output("  reset - Reset all stats to base values")
	log_output("")
	log_output("[color=yellow]Upgrades:[/color]")
	log_output("  upgrade <id> - Apply upgrade")
	log_output("    IDs: movement_speed_1, gathering_speed_1,")
	log_output("         inventory_upgrade_1, gathering_range_1,")
	log_output("         weight_capacity_1")
	log_output("")
	log_output("[color=yellow]Items:[/color]")
	log_output("  give <item> <amount> - Add item to inventory")
	log_output("  additem <item> <amount> - Spawn items at player")
	log_output("    Items: wood, stone, ore")
	log_output("")
	log_output("[color=yellow]Teleport:[/color]")
	log_output("  goto <location> - Teleport to location")
	log_output("  goto <x> <y> - Teleport to coordinates")

func cmd_clear():
	output_log.clear()
	log_output("[color=lime]Console cleared[/color]")

func cmd_speed(args: Array):
	if args.is_empty():
		log_output("[color=red]Usage: speed <value>[/color]")
		return

	var value = args[0].to_float()
	if value <= 0:
		log_output("[color=red]Speed must be positive[/color]")
		return

	PlayerGlobals.current_movement_speed = value
	log_output("[color=lime]Movement speed set to: " + str(value) + "[/color]")

func cmd_climb_speed(args: Array):
	if args.is_empty():
		log_output("[color=red]Usage: climb_speed <value>[/color]")
		return

	var value = args[0].to_float()
	if value <= 0:
		log_output("[color=red]Climb speed must be positive[/color]")
		return

	PlayerGlobals.current_climb_speed = value
	log_output("[color=lime]Climb speed set to: " + str(value) + "[/color]")

func cmd_upgrade(args: Array):
	if args.is_empty():
		log_output("[color=red]Usage: upgrade <upgrade_id>[/color]")
		log_output("Available: movement_speed_1, gathering_speed_1, inventory_upgrade_1,")
		log_output("           gathering_range_1, weight_capacity_1")
		return

	var upgrade_id = args[0]
	PlayerGlobals.apply_upgrade(upgrade_id)
	log_output("[color=lime]Applied upgrade: " + upgrade_id + "[/color]")

func cmd_give(args: Array):
	if args.size() < 1:
		log_output("[color=red]Usage: give <item> [amount][/color]")
		log_output("Available items: wood, stone, ore")
		return

	var item_name = args[0].to_lower()
	var amount = 1
	if args.size() >= 2:
		amount = args[1].to_int()

	if not item_paths.has(item_name):
		log_output("[color=red]Unknown item: " + item_name + "[/color]")
		log_output("Available: wood, stone, ore")
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_output("[color=red]Player not found[/color]")
		return

	var inventory = player.get_node_or_null("InventoryMechanic")
	if not inventory:
		log_output("[color=red]InventoryMechanic not found[/color]")
		return

	var item_data = load(item_paths[item_name])
	inventory.add_item(item_data, amount)
	log_output("[color=lime]Added to inventory: " + item_name + " x" + str(amount) + "[/color]")

func cmd_additem(args: Array):
	if args.size() < 1:
		log_output("[color=red]Usage: additem <item> [amount][/color]")
		log_output("Available items: wood, stone, ore")
		return

	var item_name = args[0].to_lower()
	var amount = 1
	if args.size() >= 2:
		amount = args[1].to_int()

	if not item_paths.has(item_name):
		log_output("[color=red]Unknown item: " + item_name + "[/color]")
		log_output("Available: wood, stone, ore")
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_output("[color=red]Player not found[/color]")
		return

	var main_scene = get_tree().root.get_node("main")
	if not main_scene:
		log_output("[color=red]Main scene not found[/color]")
		return

	var item_scene = load("res://scenes/pickable_item.tscn")
	var item_data = load(item_paths[item_name])

	for i in range(amount):
		var item_instance = item_scene.instantiate()
		item_instance.item_data = item_data

		# Spawn in a circle around player
		var angle = (i * TAU) / amount
		var offset = Vector2(cos(angle), sin(angle)) * 50.0
		item_instance.global_position = player.global_position + offset

		main_scene.add_child(item_instance)

	log_output("[color=lime]Spawned: " + item_name + " x" + str(amount) + "[/color]")

func cmd_goto(args: Array):
	if args.is_empty():
		log_output("[color=red]Usage: goto <location> OR goto <x> <y>[/color]")
		log_output("Type 'locations' to see available locations")
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_output("[color=red]Player not found[/color]")
		return

	# Check if it's coordinates (two numbers)
	if args.size() >= 2:
		var x = args[0].to_float()
		var y = args[1].to_float()
		player.global_position = Vector2(x, y)
		log_output("[color=lime]Teleported to: (" + str(x) + ", " + str(y) + ")[/color]")
		return

	# Check if it's a named location
	var location_name = args[0].to_lower()
	if locations.has(location_name):
		player.global_position = locations[location_name]
		log_output("[color=lime]Teleported to: " + location_name + "[/color]")
	else:
		log_output("[color=red]Unknown location: " + location_name + "[/color]")
		log_output("Type 'locations' to see available locations")

func cmd_heal(args: Array):
	if args.is_empty():
		log_output("[color=red]Usage: heal <amount>[/color]")
		return

	var amount = args[0].to_float()
	PlayerGlobals.heal(amount)
	log_output("[color=lime]Healed: " + str(amount) + " HP[/color]")
	log_output("Current health: " + str(PlayerGlobals.current_health) + "/" + str(PlayerGlobals.current_max_health))

func cmd_damage(args: Array):
	if args.is_empty():
		log_output("[color=red]Usage: damage <amount>[/color]")
		return

	var amount = args[0].to_float()
	PlayerGlobals.damage(amount)
	log_output("[color=orange]Took damage: " + str(amount) + " HP[/color]")
	log_output("Current health: " + str(PlayerGlobals.current_health) + "/" + str(PlayerGlobals.current_max_health))

func cmd_energy(args: Array):
	if args.is_empty():
		log_output("[color=red]Usage: energy <amount>[/color]")
		return

	var amount = args[0].to_float()
	PlayerGlobals.restore_energy(amount)
	log_output("[color=lime]Restored energy: " + str(amount) + "[/color]")
	log_output("Current energy: " + str(PlayerGlobals.current_energy) + "/" + str(PlayerGlobals.current_max_energy))

func cmd_reset():
	PlayerGlobals.reset_to_base_stats()
	log_output("[color=orange]All stats reset to base values[/color]")

func cmd_locations():
	log_output("[color=cyan]=== TELEPORT LOCATIONS ===[/color]")
	for loc_name in locations.keys():
		var pos = locations[loc_name]
		log_output("  " + loc_name + " - (" + str(pos.x) + ", " + str(pos.y) + ")")

func cmd_items():
	log_output("[color=cyan]=== AVAILABLE ITEMS ===[/color]")
	for item_name in item_paths.keys():
		var item_data = load(item_paths[item_name])
		log_output("  " + item_name + " - " + item_data.item_name + " (Weight: " + str(item_data.weight) + "kg)")

func log_output(text: String):
	output_log.append_text(text + "\n")
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll = $Panel/VBoxContainer/OutputScroll
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
