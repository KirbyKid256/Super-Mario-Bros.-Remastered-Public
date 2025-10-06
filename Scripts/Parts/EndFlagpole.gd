extends Node2D

const FLAG_POINTS := [100, 400, 800, 2000, 5000]

@onready var timer = $Timer

var players_reached: Array[Player]
var player_points: Dictionary[float, int]

signal player_reached(player: Player)
signal sequence_begin

func _ready() -> void:
	# Connect Signals
	$Animation.animation_started.connect(func(anim_name: StringName):
		if anim_name == "FlagDown": $ScoreLabels/Animation.play("ScoreRise"))
	Input.joy_connection_changed.connect(func(a, b): update_players_reached(null, a, b))
	player_reached.connect(give_points)
	timer.timeout.connect(on_timeout)
	# Remove 1-Up Top based on Settings
	if Settings.file.difficulty.flagpole_lives == 0:
		print(Settings.file.difficulty)
		$Top.queue_free()

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player and area.owner.is_in_group("Players"):
		player_touch(area.owner)

func _exit_tree() -> void:
	PlayerManager.active_device = 0

# Do this BEFORE the Victory Sequence
func player_touch(player: Player) -> void:
	player_reached.emit(player)
	Global.can_pause = false
	Global.can_time_tick = false
	if player.can_pose == false:
		player.z_index = -2
	player.global_position.x = $Flag.global_position.x + 3
	if timer and timer.is_stopped(): # First Player who touched the flagpole
		PlayerManager.active_device = player.player_id
		if get_tree().get_node_count_in_group("Players") > 1 and Global.current_game_mode != Global.GameMode.RACE:
			for p: Player in get_tree().get_nodes_in_group("Players"): p.dead.connect(update_players_reached)
			timer.start(PlayerManager.VICTORY_WAIT_TIME)
			player.state_machine.transition_to("FlagPole", {"FlagPole": self})
		else:
			player.state_machine.transition_to("FlagPole", {"FlagPole": self})
			update_players_reached(player)
	else:
		player.state_machine.transition_to("FlagPole", {"FlagPole": self})
		update_players_reached(player)

# Do this when the Victory Sequence STARTS
func on_timeout() -> void:
	for player: Player in get_tree().get_nodes_in_group("Players"):
		if not players_reached.has(player): # Stop input from players who haven't touched the flagpole
			sequence_begin.connect(func(): if player: player.process_mode = Node.PROCESS_MODE_INHERIT)
			player.process_mode = Node.PROCESS_MODE_DISABLED
			player.state_machine.transition_to("Normal", {"Input": false})
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		SpeedrunHandler.is_warp_run = false
		SpeedrunHandler.run_finished()
	if get_node_or_null("Top") != null:
		$Top.queue_free()
	$Hitbox.queue_free()
	get_tree().call_group("Enemies", "flag_die")
	$Animation.play("FlagDown")
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.FLAG_POLE, 99, false)
	await get_tree().create_timer(1.5, false).timeout
	sequence_begin.emit()
	if Global.current_game_mode == Global.GameMode.RACE or Global.current_game_mode == Global.GameMode.BOO_RACE:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.RACE_WIN, 99, false)
	else:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.LEVEL_COMPLETE, 99, false)
	Global.level_complete_begin.emit()
	await get_tree().create_timer(1, false).timeout
	if [Global.GameMode.RACE, Global.GameMode.BOO_RACE].has(Global.current_game_mode) == false:
		Global.tally_time()

func give_points(player: Player) -> void:
	var value = clamp(int(lerp(0, 4, (player.global_position.y / -144))), 0, 4)
	var nearest_value = FLAG_POINTS[value]
	player_points[player.global_position.y] = nearest_value
	player_points.sort()
	Global.score += nearest_value
	# Set the Score Labels
	if Global.connected_players.size() > 1:
		var new_score = %Score.duplicate()
		new_score.modulate = PlayerManager.colours[player.player_id]
		new_score.text = str(player_points[player.global_position.y])
		new_score.show()
		$ScoreLabels.add_child(new_score)
		$ScoreLabels.show()
	else:
		%Score.text = str(player_points[player.global_position.y])
		%Score.show()
	for player_position in player_points:
		for score in $ScoreLabels.get_children():
			if score is Label and player_points[player_position] == int(score.text):
				$ScoreLabels.move_child(score, player_points.keys().find(player_position))
				continue

# Called when all the Players reach the Flagpole
func update_players_reached(player: Player = null, device := -1, connected := true) -> void:
	if player != null and not players_reached.has(player):
		players_reached.append(player)
		players_reached.sort()
	if device > 0 and !connected:
		var removed_player = PlayerManager.get_player_with_id(device)
		if players_reached.has(removed_player):
			$ScoreLabels.get_child(player_points.keys().find(removed_player.global_position.y))
			players_reached.erase(removed_player)
		if players_reached.size() <= 1:
			$ScoreLabels.get_child(0).modulate = Color.WHITE
	var players = get_tree().get_nodes_in_group("Players")
	if not players_reached.is_empty() and timer and (players_reached.size() >= players.size() or players.size() <= 1 or players_reached.size() <= 1 and !connected):
		timer.stop()
		timer.timeout.emit()
		timer.queue_free()

# Gives a 1-Up if Setting is turned on
func on_player_entered(player: Player) -> void:
	player_touch(player)
	Global.lives += 1
	AudioManager.play_sfx("1_up", global_position)
