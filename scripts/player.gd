extends CharacterBody2D

@export var speed = 170.0
@export var gravity = 980.0
@export var climb_arm_reach = 150.0
@export var climb_pull_strength = 300.0

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

var is_aiming = false
var is_climbing = false

# Climbing state
var left_arm_grabbed = false
var right_arm_grabbed = false
var left_grab_point = Vector2.ZERO
var right_grab_point = Vector2.ZERO

func _physics_process(_delta):
	# Handle climbing mode
	handle_climbing(_delta)

	# Normal mode only if not climbing
	if not is_climbing:
		handle_normal_mode(_delta)

func handle_climbing(_delta):
	# Check for arm grab input
	if Input.is_action_pressed("grab_left_arm"):
		if not left_arm_grabbed:
			attempt_grab_left()
	else:
		release_left_arm()

	if Input.is_action_pressed("grab_right_arm"):
		if not right_arm_grabbed:
			attempt_grab_right()
	else:
		release_right_arm()

	# Update climbing state
	is_climbing = left_arm_grabbed or right_arm_grabbed

	if is_climbing:
		# Hide normal sprites, show climb arms
		head_pivot.visible = false
		anim.play("idle_noarms")
		left_arm_sprite.visible = left_arm_grabbed
		right_arm_sprite.visible = right_arm_grabbed

		# Apply climbing physics
		var pull_force = Vector2.ZERO
		var anchor_count = 0

		if left_arm_grabbed:
			var to_left_grab = left_grab_point - global_position
			pull_force += to_left_grab.normalized() * climb_pull_strength
			anchor_count += 1

		if right_arm_grabbed:
			var to_right_grab = right_grab_point - global_position
			pull_force += to_right_grab.normalized() * climb_pull_strength
			anchor_count += 1

		if anchor_count > 0:
			pull_force /= anchor_count

		# Apply gravity and pull force
		velocity.y += gravity * _delta * 0.5  # Reduced gravity while climbing
		velocity += pull_force * _delta
		velocity *= 0.95  # Damping

		move_and_slide()
	else:
		# Not climbing - restore normal sprites
		head_pivot.visible = true
		left_arm_sprite.visible = false
		right_arm_sprite.visible = false

func attempt_grab_left():
	# Cast ray from mouse position toward climbable surfaces
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - left_climb_arm.global_position).normalized()
	left_arm_raycast.target_position = direction * climb_arm_reach
	left_arm_raycast.force_raycast_update()

	if left_arm_raycast.is_colliding():
		left_arm_grabbed = true
		left_grab_point = left_arm_raycast.get_collision_point()
		# Point arm toward grab point
		left_climb_arm.look_at(left_grab_point)

func attempt_grab_right():
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - right_climb_arm.global_position).normalized()
	right_arm_raycast.target_position = direction * climb_arm_reach
	right_arm_raycast.force_raycast_update()

	if right_arm_raycast.is_colliding():
		right_arm_grabbed = true
		right_grab_point = right_arm_raycast.get_collision_point()
		# Point arm toward grab point
		right_climb_arm.look_at(right_grab_point)

func release_left_arm():
	left_arm_grabbed = false

func release_right_arm():
	right_arm_grabbed = false

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
