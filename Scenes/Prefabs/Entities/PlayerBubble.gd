#Source: https://www.youtube.com/watch?v=AHno-nd2F_I
class_name PlayerBubble
extends PlayerSprite

@export var bubble_speed_cap := 50.0

var bubble_popped := false

var velocity := Vector2.ZERO

func _ready() -> void:
	super._ready()
	$BubbleSprite/PopParticles.finished.connect(queue_free)

func update() -> void:
	super.update()
	offset.y /= 2

func _physics_process(delta: float) -> void:
	if not bubble_popped:
		# Find Closest Player
		var target_player: Player = PlayerManager.get_closest_player(global_position)
		if target_player != null:
			# Adjust Bubble Speed
			var bubble_speed := bubble_speed_cap * global_position.direction_to(target_player.global_position)
			if Global.player_action_just_pressed("jump", player_id):
				velocity = bubble_speed * 5
			else:
				velocity = lerp(velocity, bubble_speed, delta * 5)
			global_position += velocity * delta
			#global_position.x = move_toward(global_position.x, target_player.global_position.x, delta * bubble_speed)
			#global_position.y = move_toward(global_position.y, target_player.global_position.y, delta * bubble_speed)

func on_player_entered(_player: Player) -> void:
	bubble_popped = true
	self_modulate = Color.TRANSPARENT
	$BubbleSprite.self_modulate = self_modulate
	$BubbleSprite/PlayerDetection.player_entered.disconnect(on_player_entered)
	$BubbleSprite/PopParticles.emitting = true
	# Re-add Player
	var player: Player = PlayerManager.dead_players[player_id]
	player.global_position = global_position
	player.is_dead = false
	player.power_state = player.get_node("PowerStates/Small")
	player.add_to_group("Players")
	player.show() # In-case of death by pit
	player.state_machine.transition_to("Normal")
	PlayerManager.dead_players.erase(player_id)
	# Do Invincibility and Jump
	player.do_i_frames()
	player.velocity.y = player.calculate_jump_height() * player.gravity_vector.y
	player.gravity = player.JUMP_GRAVITY
	AudioManager.play_sfx("bubble_pop", global_position, 1, _player.player_id)
	player.has_jumped = true
