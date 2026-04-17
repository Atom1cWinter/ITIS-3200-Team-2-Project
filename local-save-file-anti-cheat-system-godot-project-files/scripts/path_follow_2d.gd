extends PathFollow2D

var speed := 0.1
var direction := 1.0  # 1 = forward, -1 = backward

func _process(_delta: float) -> void:
	#When reaching the end, flip direction
	if progress_ratio >= 1.0:
		direction = -1.0
	elif progress_ratio <= 0.0:
		direction = 1.0
		
	progress_ratio += direction * speed * _delta
