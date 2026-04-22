extends StaticBody2D

# -------------------------------------------------------------------
# Onready variables for fire point, cooldown, and fireball scene
# -------------------------------------------------------------------
@onready var fire_point = $FirePoint
@onready var fire_cooldown = $FireCooldown
var fireball_scene = preload("res://scenes/fireball.tscn")

# -------------------------------------------------------------------
# Function for ready and fire
# -------------------------------------------------------------------

func _ready() -> void:
	# Connect the timeout signal of the fire cooldown timer to the _fire function
	fire_cooldown.timeout.connect(_fire)
	fire_cooldown.start() # Start the cooldown timer
	fire_cooldown.autostart = true # Set the cooldown timer to start automatically
	fire_cooldown.one_shot = false # Set the cooldown timer to repeat
	fire_cooldown.wait_time = 2.0 # Set the cooldown time to 2 seconds
	
func _fire() -> void:
	# Create a new instance of the fireball scene and set its position and direction
	var fireball = fireball_scene.instantiate()
	fireball.look_at(fire_point.position)
	fireball.position = fire_point.position
	add_child(fireball) # Add fireball to the scene tree.
	
