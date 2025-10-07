extends PlayerState

const PLAYER_BUBBLE = preload("res://Scenes/Prefabs/Entities/PlayerBubble.tscn")
const START_BLOCK = preload("res://Scenes/Prefabs/Blocks/StartBlock.tscn")

@onready var respawn_timer = Timer.new()

var can_fall := false
var can_respawn := true
var old_collision := []

func _ready() -> void:
	Global.level_complete_begin.connect(func(): can_respawn = false)
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(on_timeout)
	add_child(respawn_timer)

func enter(msg := {}) -> void:
	player.z_index = 20
	can_fall = false
	player.velocity = Vector2.ZERO
	player.stop_all_timers()
	for i in 16:
		old_collision.append(player.get_collision_mask_value(i + 1))
		player.set_collision_mask_value(i + 1, false)
	await get_tree().create_timer(0.5).timeout
	if can_respawn:
		respawn_timer.start(PlayerManager.RESPAWN_TIME)
	can_fall = true
	player.gravity = player.JUMP_GRAVITY
	if msg["Pit"] == false: 
		player.velocity.y = -player.DEATH_JUMP_HEIGHT

func physics_update(delta: float) -> void:
	if can_fall:
		player.play_animation("Die")
	else:
		player.play_animation("DieFreeze")
	player.sprite.speed_scale = 1
	if can_fall:
		player.velocity.y += (player.JUMP_GRAVITY / delta) * delta
		player.velocity.y = clamp(player.velocity.y, -INF, player.MAX_FALL_SPEED)
		player.move_and_slide()
		if get_tree().get_nodes_in_group("Players").is_empty() and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump")):
			player.death_load()

func on_timeout() -> void:
	if not get_tree().get_nodes_in_group("Players").is_empty() and can_respawn:
		can_fall = false
		for i in range(old_collision.size() - 1, -1, -1):
			player.set_collision_mask_value(i + 1, old_collision.pop_at(i))
		if SplitscreenHandler.use_split_screen:
			PlayerManager.dead_players.erase(player)
			var default_player: Player = PlayerManager.get_first_player()
			player.do_i_frames()
			player.global_position = default_player.global_position
			player.is_dead = false
			player.power_state = player.get_node("PowerStates/Small")
			player.add_to_group("Players")
			player.show() # In-case of death by pit
			player.state_machine.transition_to("Normal")
			if not default_player.is_actually_on_floor():
				var respawn_platform = START_BLOCK.instantiate()
				respawn_platform.player_id = player.player_id
				respawn_platform.character = player.character
				respawn_platform.global_position = default_player.global_position
				player.get_parent().add_child(respawn_platform)
		else:
			player.hide()
			var default_player: Player = PlayerManager.get_first_player()
			var bubble = PLAYER_BUBBLE.instantiate()
			var scaled_window_width := get_window().size.x / get_window().get_stretch_transform().x.x / 2.0
			bubble.player_id = player.player_id
			bubble.global_position = Vector2(default_player.camera.global_position.x + scaled_window_width + 16, default_player.camera.global_position.y)
			Global.player_power_states[bubble.player_id] = 0
			Global.current_level.add_child(bubble)
