extends CharacterBody2D

# -------------------------------------------------------------------
# Player Movement Variables
# -------------------------------------------------------------------

# tweak for feel
const SPEED : float = 250.0          		# Horizontal movement speed
const JUMP_VELOCITY : float = -500.0 		# Negative = up in Godot
const GRAVITY : float = 900.0        		# Downward acceleration
const JUMP_CUT_MULTIPLIER : float = 0.5 	# Lower = shorter cut jump
const DASH_SPEED_MULTIPLIER : float = 5		# Higher = faster and farther dashes
const DASH_DURATION : float = 0.3		# How long in seconds a dash last

var dash_direction : float

# -------------------------------------------------------------------
# Define Player States
# -------------------------------------------------------------------

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	DASH
}

var current_state : PlayerState = PlayerState.IDLE

# -------------------------------------------------------------------
# Run Data Variables 
# ( Per Level. Updated by GameManager on level load. 
# Sent to GameManager after level completion )
# -------------------------------------------------------------------

@export var coins : int = 0
@export var health : int = 1
@export var hearts : int = 1
@export var energy_cells : int = 1
# Abilities:
@export var has_jump_ability : bool = false
@export var has_dash_ability : bool = false
@export var has_melee_ability : bool = false

# Save dictionary schema
const SAVE_SCHEMA := {
	"coins": TYPE_INT,
	"health": TYPE_INT,
	"hearts": TYPE_INT,
	"energy_cells": TYPE_INT,
	"has_jump_ability": TYPE_BOOL,
	"has_dash_ability": TYPE_BOOL,
	"has_melee_ability": TYPE_BOOL
}

# -------------------------------------------------------------------
# Ready and Processes
# -------------------------------------------------------------------

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("player")
	
	set_run_data(GameManager.get_save_data())
	print(coins)
	
func _physics_process(delta : float) -> void:
	if current_state != PlayerState.DASH:
		_apply_gravity(delta)
	
	match current_state:
		PlayerState.IDLE:
			_state_idle(delta)
		PlayerState.RUN:
			_state_run(delta)
		PlayerState.JUMP:
			_state_jump(delta)
		PlayerState.FALL:
			_state_fall(delta)
		PlayerState.DASH:
			_state_dash(delta)
	
	move_and_slide()
	
# -------------------------------------------------------------------
# Cooldown Variables & Methods
# -------------------------------------------------------------------

# Durations are in seconds
const COOLDOWN_DURATIONS : Dictionary[String, int] = {
	"dash": 1,
	"attack": 1
}

var cooldowns : Dictionary = {}		# Stores active cooldowns

func is_on_cooldown(action : String) -> bool:
	return cooldowns.has(action)

func start_cooldown(action: String) -> void:
	# Prevents timer from restarting if already active.
	if is_on_cooldown(action):
		return
		
	cooldowns[action] = true
	
	await get_tree().create_timer(COOLDOWN_DURATIONS[action]).timeout
	
	cooldowns.erase(action)
	
# -------------------------------------------------------------------
# Movement and State Logic
# -------------------------------------------------------------------

# Applies gravity when not on the floor
func _apply_gravity(delta : float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		# Prevents small downward accumulation when grounded
		velocity.y = 0

func _state_idle(_delta : float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if not is_on_floor():
		current_state = PlayerState.FALL
		return
	
	if Input.is_action_just_pressed("jump") and has_jump_ability:
		_start_jump()
		return
	
	if Input.is_action_just_pressed("dash") and has_dash_ability:
		_start_dash(direction)
		return
	
	if direction != 0:
		current_state = PlayerState.RUN
	
	velocity.x = move_toward(velocity.x, 0, SPEED) # Smooth deceleration if was moving

func _state_run(_delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if not is_on_floor():
		current_state = PlayerState.FALL
		return
	
	if Input.is_action_just_pressed("jump") and has_jump_ability:
		_start_jump()
		return
	
	if Input.is_action_just_pressed("dash") and has_dash_ability:
		_start_dash(direction)
		return
	
	if direction == 0:
		current_state = PlayerState.IDLE
		return
	
	velocity.x = direction * SPEED

func _start_jump() -> void:
	
	if not is_on_floor():
		return
	
	velocity.y = JUMP_VELOCITY
	current_state = PlayerState.JUMP	

func _state_jump(_delta : float) -> void:
	# Handle movement while in air
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED
	
	if Input.is_action_just_pressed("dash") and has_dash_ability:
		_start_dash(direction)
	
	# Cut jump short if button released while moving upward
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER
	elif velocity.y > 0:
		current_state = PlayerState.FALL

func _state_fall(_delta : float) -> void:
	# Handle movement while falling
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED
	
	if Input.is_action_just_pressed("dash") and has_dash_ability:
		_start_dash(direction)
	
	if is_on_floor():
		if direction == 0:
			current_state = PlayerState.IDLE
		else:
			current_state = PlayerState.RUN

func _start_dash(direction: float) -> void:
	if is_on_cooldown("dash") or direction == 0:
		return
	
	dash_direction = direction
	current_state = PlayerState.DASH
	start_cooldown("dash")
	
	await get_tree().create_timer(DASH_DURATION).timeout
	
	# Return to correct air/ground state
	if is_on_floor():
		current_state = PlayerState.IDLE
	else:
		current_state = PlayerState.FALL

func _state_dash(_delta: float) -> void:
	velocity.x = dash_direction * SPEED * DASH_SPEED_MULTIPLIER

# -------------------------------------------------------------------
#  Health Logic
# -------------------------------------------------------------------

func heal(amount: int) -> void:
	health = clamp(health + amount, 0, hearts)

func hit(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	GameManager.game_over() # Notify game_manager that the player died
	queue_free()

# -------------------------------------------------------------------
# Data Logic
# -------------------------------------------------------------------

# Packages player save data into a dictionary and returns it
func get_run_data() -> Dictionary:
	return {
		"coins": coins,
		"health": health,
		"hearts": hearts,
		"energy_cells": energy_cells,
		"has_jump_ability": has_jump_ability,
		"has_dash_ability": has_dash_ability,
		"has_melee_ability": has_melee_ability
	}

# Takes data from dictionary and updates save data variables with values from dictionary.
# Parameter: data -> a dictionary that stores saved values for save data.
# Returns: -1 if error. 0 if ok.
func set_run_data(data: Dictionary) -> int:
	for key in SAVE_SCHEMA.keys():
		if data.has(key) and typeof(data[key]) == SAVE_SCHEMA[key]:
			set(key, data[key]) # dynamically assigns variable
		else:
			push_warning("Using default for: %s" % key)
	
	return 0
