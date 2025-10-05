extends PlayerState

var can_land := true
var can_slide := false

@export var flagpole: Node2D = null

func enter(msg := {}) -> void:
	player.direction = 1
	player.stop_all_timers()
	player.play_animation("FlagSlide")
	player.sprite.pause()
	flagpole = msg["FlagPole"]
	print(flagpole.timer)
	flagpole.timer.timeout.connect(on_timeout)
	await Global.level_complete_begin
	state_machine.transition_to("LevelExit")

func on_timeout() -> void:
	player.sprite.play()
	can_slide = true

func physics_update(_delta: float) -> void:
	if not can_slide: return
	player.velocity.y = 125
	player.velocity.x = 0
	player.sprite.scale.x = player.direction
	if player.is_on_floor():
		if can_land:
			can_land = false
			player.global_position.x += 10
			player.direction = -1
		player.sprite.speed_scale = 0
	else:
		player.sprite.speed_scale = 2
	player.play_animation("FlagSlide")
	player.move_and_slide()
