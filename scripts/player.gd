extends CharacterBody2D

@export var speed = 170.0
@export var fade_distance = 165.0  # Distance to fade over (pixels, 875 - 710)
@export var fade_start_offset = 710.0  # Pixels from sprite's left edge to start fading
@export var cave_interior_fade_distance = 250.0  # Distance over which cave interior fades in
@export var black_fade_in_offset = 800.0  # When black transition starts fading in
@export var black_fade_in_distance = 100.0  # Distance to fade black in (reach full black)
@export var black_fade_out_distance = 150.0  # Distance to fade black out (reveal cave)

@onready var anim = $player_animation
@onready var arm_pivot = $ArmPivot
@onready var arm = $ArmPivot/Arm
@onready var head_pivot = $HeadPivot
@onready var head = $HeadPivot/Head
@onready var cave_foreground = get_node("../Cave_Entry_Foreground/Sprite2D")  # Reference the sprite child, not parent
@onready var cave_int_bg = get_node("../Cave_Int_BG")  # Cave interior background parallax
@onready var cave_int_top = get_node("../Cave_Interior_Top")  # Cave interior top parallax
@onready var cave_int_foreground = get_node("../Cave_Interior_Foreground")  # Cave interior foreground parallax
@onready var black_transition = get_node("../TransitionLayer/BlackTransition")  # Black fade transition
@onready var shadow = get_node("../Shadow")  # CanvasModulate for cave darkness
@onready var flashlight = $HeadPivot/Flashlight  # PointLight2D for player illumination

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
		head_pivot.position.y = 145
	else:
		head_pivot.scale.x = 1
		head.scale.y = -1
		head_pivot.position.x = 5
		head_pivot.position.y = 150
	
	# Point head at mouse (gives us target angle)
	head_pivot.look_at(mouse_pos)
	var target_angle = head_pivot.rotation
	
	# Clamp rotation limits (-90 to 90 degrees)
	target_angle = clamp(target_angle, deg_to_rad(-90), deg_to_rad(90))
	
	# Apply clamped angle back to head_pivot (this makes it smooth)
	head_pivot.rotation = lerp_angle(head_pivot.rotation, target_angle, 0.15)
	
	# Rotate arm to mouse
	if is_aiming:
		arm_pivot.look_at(mouse_pos)
		# Flip arm vertically when facing left
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
		# Check if moving backwards (movement opposite to facing)		
		if is_backwards:
			anim.play("walking_backwards")
		elif is_running:
			anim.play("running")
		else:
			anim.play("walking")
	else:
		# Idle - choose based on aiming state
		if is_aiming:
			anim.play("idle_noarms")
		else:
			anim.play("idle")

	# Control breathing shader - only active during idle animations
	if anim.material:
		if anim.animation == "idle" or anim.animation == "idle_noarms":
			anim.material.set_shader_parameter("breath_strength", 0.05)
		else:
			anim.material.set_shader_parameter("breath_strength", 0.0)

	# Fade foreground when player enters the sprite
	if cave_foreground:
		# Calculate sprite's actual width and left edge
		var texture_width = cave_foreground.texture.get_width()
		var actual_width = texture_width * cave_foreground.scale.x
		var left_edge = cave_foreground.global_position.x - (actual_width / 2)

		# How far INTO the sprite from its left edge
		var distance_into_sprite = global_position.x - left_edge

		if distance_into_sprite < fade_start_offset:
			# Before fade zone - fully visible
			cave_foreground.modulate.a = 1.0
		elif distance_into_sprite < fade_start_offset + fade_distance:
			# Inside fade zone - fade proportionally
			var fade_progress = distance_into_sprite - fade_start_offset
			var alpha = 1.0 - (fade_progress / fade_distance)
			cave_foreground.modulate.a = alpha
		else:
			# Past fade zone - invisible
			cave_foreground.modulate.a = 0.0

		# Black transition fade effect
		if black_transition:
			var black_fade_start = black_fade_in_offset
			var black_fade_peak = black_fade_in_offset + black_fade_in_distance
			var black_fade_end = black_fade_peak + black_fade_out_distance

			if distance_into_sprite < black_fade_start:
				# Before black fade - transparent
				black_transition.modulate.a = 0.0
			elif distance_into_sprite < black_fade_peak:
				# Fading to black
				var fade_progress = (distance_into_sprite - black_fade_start) / black_fade_in_distance
				black_transition.modulate.a = fade_progress
			elif distance_into_sprite < black_fade_end:
				# Fading from black (revealing cave interior)
				var fade_progress = (distance_into_sprite - black_fade_peak) / black_fade_out_distance
				black_transition.modulate.a = 1.0 - fade_progress
			else:
				# Past black fade - fully transparent
				black_transition.modulate.a = 0.0

		# Fade in cave interior parallax as player enters
		# Start fading in at the point where cave foreground becomes invisible
		var cave_entry_point = fade_start_offset + fade_distance
		var distance_past_entry = distance_into_sprite - cave_entry_point

		if distance_past_entry < 0:
			# Before cave entry - cave interior invisible
			if cave_int_bg:
				cave_int_bg.visible = false
			if cave_int_top:
				cave_int_top.visible = false
			if cave_int_foreground:
				cave_int_foreground.visible = false
			# Turn off cave lighting effects when outside
			if shadow:
				shadow.visible = false
			if flashlight:
				flashlight.visible = false
		elif distance_past_entry < cave_interior_fade_distance:
			# Inside fade zone - gradually fade in cave interior
			var fade_alpha = distance_past_entry / cave_interior_fade_distance
			if cave_int_bg:
				cave_int_bg.visible = true
				cave_int_bg.modulate.a = fade_alpha
			if cave_int_top:
				cave_int_top.visible = true
				cave_int_top.modulate.a = fade_alpha
			if cave_int_foreground:
				cave_int_foreground.visible = true
				cave_int_foreground.modulate.a = fade_alpha
		else:
			# Past fade zone - cave interior fully visible
			if cave_int_bg:
				cave_int_bg.visible = true
				cave_int_bg.modulate.a = 1.0
			if cave_int_top:
				cave_int_top.visible = true
				cave_int_top.modulate.a = 1.0
			if cave_int_foreground:
				cave_int_foreground.visible = true
				cave_int_foreground.modulate.a = 1.0
			# Turn on cave lighting effects when fully inside
			if shadow:
				shadow.visible = true
			if flashlight:
				flashlight.visible = true
