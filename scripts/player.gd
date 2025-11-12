extends CharacterBody2D

@export var speed = 170.0

@onready var anim = $player_animation
@onready var arm_pivot = $ArmPivot
@onready var arm = $ArmPivot/Arm
@onready var head_pivot = $HeadPivot
@onready var head = $HeadPivot/Head

var is_aiming = false

func _physics_process(_delta):
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
