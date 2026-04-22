extends Area2D

@onready var animation_player = $AnimationPlayer

func _on_body_entered(_body: Node2D) -> void:
	if _body.is_in_group("player"):
		print("Coin Collected!")
		_body.coins += 1
		animation_player.play("pickup")
