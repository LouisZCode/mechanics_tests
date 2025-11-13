extends CharacterBody2D

## Player coordinator - manages mechanics, animations, and input routing

# Visual nodes
@onready var anim = $player_animation
@onready var arm_pivot = $ArmPivot
@onready var arm = $ArmPivot/Arm
@onready var head_pivot = $HeadPivot
@onready var head = $HeadPivot/Head

# Mechanics (these will be added as child nodes in the scene)
@onready var movement: MovementMechanic = $MovementMechanic
@onready var gravity_mechanic: GravityMechanic = $GravityMechanic
@onready var gathering: GatheringMechanic = $GatheringMechanic
@onready var inventory: InventoryMechanic = $InventoryMechanic
@onready var climbing: ClimbingMechanic = $ClimbingMechanic

# State
var is_aiming = false

func _ready():
	# Add to player group (for UI and other systems to find)
	add_to_group("player")

	# Connect gathering signals
	gathering.item_gathered.connect(_on_item_gathered)

	# Connect inventory signals for feedback
	inventory.inventory_full.connect(_on_inventory_full)
	inventory.weight_changed.connect(_on_weight_changed)

func _on_item_gathered(item_data: ItemData, quantity: int):
	"""Handle when an item is gathered"""
	if item_data:
		print("Player gathered: %s x%d (weight: %.1f each)" % [item_data.item_name, quantity, item_data.weight])
	else:
		print("Player gathered: unknown item x%d" % quantity)
	# Note: Item is automatically added to inventory by GatheringMechanic

func _on_inventory_full():
	"""Handle when trying to add to full inventory"""
	print("Inventory is full! Can't pick up more items.")

func _on_weight_changed(current_weight: float, speed_multiplier: float):
	"""Handle when inventory weight changes"""
	var speed_percent = int(speed_multiplier * 100)
	if speed_multiplier < 1.0:
		print("Weight: %.1fkg - Speed reduced to %d%%" % [current_weight, speed_percent])
	# Visual feedback could be added here (screen tint, player color, etc.)

func _physics_process(delta):
	# Handle aiming
	is_aiming = Input.is_action_pressed("ui_right_click")
	arm.visible = is_aiming

	# Get mouse position
	var mouse_pos = get_global_mouse_position()

	# Update facing direction based on mouse
	movement.update_facing_direction(mouse_pos)

	# Update visuals based on facing
	update_sprite_facing(movement.facing_right)
	update_head_rotation(mouse_pos, movement.facing_right)

	# Update arm rotation if aiming
	if is_aiming:
		update_arm_rotation(mouse_pos, movement.facing_right)

	# Execute mechanics
	# Climbing takes priority over normal movement
	var climb_state = climbing.execute(delta)

	if not climb_state.is_climbing:
		# Normal movement and gravity when not climbing
		gravity_mechanic.execute(delta)
		var movement_state = movement.execute(delta, not is_aiming)
		gathering.execute(delta)

		# Update animations for normal movement
		update_animations(movement_state)
	else:
		# Climbing mode - disable gathering
		# Animations for climbing (for now, just show idle)
		anim.play("idle")

	# Apply physics
	move_and_slide()

func update_sprite_facing(facing_right: bool):
	"""Update main sprite facing direction"""
	anim.flip_h = not facing_right

func update_head_rotation(mouse_pos: Vector2, facing_right: bool):
	"""Rotate head to look at mouse"""
	# Flip HeadPivot based on direction
	if facing_right:
		head_pivot.scale.x = 1
		head.scale.y = 1
		head_pivot.position.x = -10
		head_pivot.position.y = -140
	else:
		head_pivot.scale.x = 1
		head.scale.y = -1
		head_pivot.position.x = 5
		head_pivot.position.y = -140

	# Point head at mouse
	head_pivot.look_at(mouse_pos)
	var target_angle = head_pivot.rotation

	# Clamp rotation limits
	target_angle = clamp(target_angle, deg_to_rad(-90), deg_to_rad(90))

	# Smooth rotation
	head_pivot.rotation = lerp_angle(head_pivot.rotation, target_angle, 0.15)

func update_arm_rotation(mouse_pos: Vector2, facing_right: bool):
	"""Rotate arm to point at mouse when aiming"""
	arm_pivot.look_at(mouse_pos)
	if facing_right:
		arm.scale.y = .25
	else:
		arm.scale.y = -.25
		arm.position.x = -10

func update_animations(movement_state: Dictionary):
	"""Update animations based on movement state"""
	var direction = movement_state.direction
	var is_running = movement_state.is_running
	var is_backwards = movement_state.is_backwards

	if direction != 0:
		if is_backwards:
			anim.play("walking_backwards")
		elif is_running:
			anim.play("running")
		else:
			anim.play("walking")
	else:
		if is_aiming:
			anim.play("idle_noarms")
		else:
			anim.play("idle")
