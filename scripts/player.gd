extends CharacterBody2D

@export var speed = 170.0
@export var gravity = 980.0
@export var climb_arm_reach = 150.0
@export var climb_pull_strength = 800.0
@export var climb_pull_strength_both_hands = 100.0

@onready var anim = $player_animation
@onready var arm_pivot = $ArmPivot
@onready var arm = $ArmPivot/Arm
@onready var head_pivot = $HeadPivot
@onready var head = $HeadPivot/Head

# Climbing nodes
@onready var left_climb_arm = $LeftClimbArm
@onready var left_arm_sprite = $LeftClimbArm/LeftArmSprite
@onready var left_arm_raycast = $LeftClimbArm/LeftArmRaycast

@onready var right_climb_arm = $RightClimbArm
@onready var right_arm_sprite = $RightClimbArm/RightArmSprite
@onready var right_arm_raycast = $RightClimbArm/RightArmRaycast

@onready var wall_detector = $WallDetector

var is_aiming = false
var is_climbing = false
var near_climbable_wall = false

# Climbing state
var left_arm_grabbed = false
var right_arm_grabbed = false
var left_grab_point = Vector2.ZERO
var right_grab_point = Vector2.ZERO

func _ready():
	wall_detector.body_entered.connect(_on_wall_entered)
	wall_detector.body_exited.connect(_on_wall_exited)

func _on_wall_entered(body):
	if body.collision_layer & 2:  # Check if it's on layer 2 (climbable)
		near_climbable_wall = true

func _on_wall_exited(body):
	if body.collision_layer & 2:
		near_climbable_wall = false
		# Exit climbing mode if we leave the wall
		if is_climbing:
			is_climbing = false

func _physics_process(_delta):
	# Toggle climbing mode with Q (only when near wall)
	if Input.is_action_just_pressed("grab_left_arm"):  # Q key
		if near_climbable_wall and not is_climbing:
			enter_climbing_mode()
		elif is_climbing:
			exit_climbing_mode()

	# Handle climbing or normal mode
	if is_climbing:
		handle_climbing(_delta)
	else:
		handle_normal_mode(_delta)

func enter_climbing_mode():
	is_climbing = true
	# Show both arms
	left_arm_sprite.visible = true
	right_arm_sprite.visible = true
	# Use idle_noarms animation
	anim.play("idle_noarms")

func exit_climbing_mode():
	is_climbing = false
	left_arm_grabbed = false
	right_arm_grabbed = false
	left_arm_sprite.visible = false
	right_arm_sprite.visible = false

func handle_climbing(_delta):
	var mouse_pos = get_global_mouse_position()

	# Left click = grab left hand
	if Input.is_action_pressed("ui_left_click"):
		if not left_arm_grabbed:
			attempt_grab_left(mouse_pos)
	else:
		left_arm_grabbed = false

	# Right click = grab right hand
	if Input.is_action_pressed("ui_right_click"):
		if not right_arm_grabbed:
			attempt_grab_right(mouse_pos)
	else:
		right_arm_grabbed = false

	# Make arms follow mouse when not grabbed
	if not left_arm_grabbed:
		left_climb_arm.look_at(mouse_pos)

	if not right_arm_grabbed:
		right_climb_arm.look_at(mouse_pos)

	# Apply climbing physics
	var pull_force = Vector2.ZERO
	var grabbed_count = 0

	if left_arm_grabbed:
		grabbed_count += 1
		var to_left_grab = left_grab_point - global_position
		pull_force += to_left_grab.normalized()

	if right_arm_grabbed:
		grabbed_count += 1
		var to_right_grab = right_grab_point - global_position
		pull_force += to_right_grab.normalized()

	# Determine pull strength based on how many hands are grabbed
	var current_pull_strength = climb_pull_strength
	if grabbed_count == 2:
		# Both hands grabbed = minimal movement (stable)
		current_pull_strength = climb_pull_strength_both_hands
	elif grabbed_count == 0:
		# No hands grabbed = just fall
		current_pull_strength = 0

	if grabbed_count > 0:
		pull_force = pull_force.normalized() * current_pull_strength

	# Apply gravity (reduced when grabbed)
	var gravity_multiplier = 0.3 if grabbed_count > 0 else 1.0
	velocity.y += gravity * _delta * gravity_multiplier

	# Apply pull force
	velocity += pull_force * _delta

	# Damping
	velocity *= 0.95

	move_and_slide()

func attempt_grab_left(mouse_pos):
	var direction = (mouse_pos - left_climb_arm.global_position).normalized()
	left_arm_raycast.target_position = direction * climb_arm_reach
	left_arm_raycast.force_raycast_update()

	print("Left arm attempting grab - Colliding: ", left_arm_raycast.is_colliding())
	if left_arm_raycast.is_colliding():
		left_arm_grabbed = true
		left_grab_point = left_arm_raycast.get_collision_point()
		left_climb_arm.look_at(left_grab_point)
		print("Left arm GRABBED at: ", left_grab_point)

func attempt_grab_right(mouse_pos):
	var direction = (mouse_pos - right_climb_arm.global_position).normalized()
	right_arm_raycast.target_position = direction * climb_arm_reach
	right_arm_raycast.force_raycast_update()

	print("Right arm attempting grab - Colliding: ", right_arm_raycast.is_colliding())
	if right_arm_raycast.is_colliding():
		right_arm_grabbed = true
		right_grab_point = right_arm_raycast.get_collision_point()
		right_climb_arm.look_at(right_grab_point)
		print("Right arm GRABBED at: ", right_grab_point)

func handle_normal_mode(_delta):
	# Aiming mode
	is_aiming = Input.is_action_pressed("ui_right_click")
	arm.visible = is_aiming

	# Get mouse position and determine facing
	var mouse_pos = get_global_mouse_position()
	var facing_right = mouse_pos.x > global_position.x
	anim.flip_h = not facing_right

	# Flip HeadPivot
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

	# Rotate arm to mouse
	if is_aiming:
		arm_pivot.look_at(mouse_pos)
		if facing_right:
			arm.scale.y = .25
		else:
			arm.scale.y = -.25
			arm.position.x = -10

	# Get input (no movement while aiming)
	var direction = 0
	if not is_aiming:
		direction = Input.get_axis("ui_left", "ui_right")

	# Check if moving backwards
	var is_backwards = (direction < 0 and facing_right) or (direction > 0 and not facing_right)

	# Only run when moving forward
	var is_running = Input.is_action_pressed("ui_shift") and not is_backwards
	var current_speed = speed * 2.5 if is_running else speed

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * _delta
	else:
		velocity.y = 0

	# Move
	velocity.x = direction * current_speed
	move_and_slide()

	# Animations
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
