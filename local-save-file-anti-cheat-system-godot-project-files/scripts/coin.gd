extends Area2D

@onready var animation_player = $AnimationPlayer

func _on_body_entered(_body: Node2D) -> void:
	print("Coin Collected!")
	if _body.is_in_group("player"):
		_body.coins += 1
		animation_player.play("pickup")

#func _ready() -> void:
	#print("Coin Spawned!")
