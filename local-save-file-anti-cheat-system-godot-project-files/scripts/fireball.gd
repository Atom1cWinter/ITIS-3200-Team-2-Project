extends Area2D

# -------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------
const SPEED = 75
const DAMAGE = 1
const LIFETIME = 10.0

# -------------------------------------------------------------------
# Function for physics process and body entered
# -------------------------------------------------------------------

func _ready() -> void:
	# Set a timer to queue free the fireball after its lifetime expires
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = LIFETIME
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(queue_free)
	add_child(lifetime_timer)
	lifetime_timer.start()

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Move the fireball in the direction it's facing
	position += Vector2.RIGHT.rotated(rotation) * SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		queue_free() # Remove the fireball when it hits the player
		body.hit(DAMAGE) # player takes damage when hit by fireball
		print("Player hit by fireball for " + str(DAMAGE) + " damage!")
	elif not body.is_in_group("geysers") and not body.is_in_group("fireballs") and not body.is_in_group("coins"):
		queue_free() # Remove the fireball when it hits any other object (like walls)
