extends Area2D

func _on_portal_entered(_body: Node2D) -> void:
	if _body.is_in_group("player"):
		GameManager.complete_level(_body.get_run_data())
