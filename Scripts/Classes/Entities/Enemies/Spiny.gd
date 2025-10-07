extends Enemy

var in_egg := false

const MOVE_SPEED := 40

func _physics_process(delta: float) -> void:
	handle_movement(delta)

func handle_movement(_delta: float) -> void:
	if in_egg:
		if is_on_floor():
			var player = PlayerManager.get_closest_player(global_position)
			direction = sign(player.global_position.x - global_position.x)
			in_egg = false
		$Sprite.play("Egg")
	else:
		$Sprite.play("Walk")
		$Sprite.scale.x = direction
	
