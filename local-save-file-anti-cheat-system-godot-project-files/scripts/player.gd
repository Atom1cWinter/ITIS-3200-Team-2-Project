extends CharacterBody2D

# -------------------------------------------------------------------
# Player Movement Variables
# -------------------------------------------------------------------

# tweak for feel
const SPEED : float = 250.0          		# Horizontal movement speed
const JUMP_VELOCITY : float = -450.0 		# Negative = up in Godot
const GRAVITY : float = 900.0        		# Downward acceleration
const JUMP_CUT_MULTIPLIER : float = 0.5 	# Lower = shorter cut jump

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
@export var has_melee_ability : bool = false

# Save dictionary schema
const SAVE_SCHEMA := {
	"coins": TYPE_INT,
	"health": TYPE_INT,
	"hearts": TYPE_INT,
	"energy_cells": TYPE_INT,
	"has_jump_ability": TYPE_BOOL,
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
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	move_and_slide()
	
# -------------------------------------------------------------------
# Movement Logic
# -------------------------------------------------------------------

# Applies gravity when not on the floor
func _apply_gravity(delta : float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		# Prevents small downward accumulation when grounded
		velocity.y = 0
		
# Handles jump input
func _handle_jump() -> void:
	# Start jump
	if not has_jump_ability:
		return
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Cut jump short if button released while moving upward
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER
		
# Handle left/right movement
func _handle_movement() -> void:
	var direction := Input.get_axis("move_left","move_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED) # Smooth deceleration

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
