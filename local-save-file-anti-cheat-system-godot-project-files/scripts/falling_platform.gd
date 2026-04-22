extends RigidBody2D

@onready var detection_area = $DetectionArea
@onready var timer = $Timer

func _ready() -> void:
	detection_area.body_entered.connect(_on_DetectionArea_body_entered)

func _on_DetectionArea_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		await get_tree().create_timer(0.3).timeout
		set_deferred("freeze", false)
		timer.timeout.connect(_on_timer_timeout)
		timer.start(3)
		
func _on_timer_timeout():
	queue_free()
