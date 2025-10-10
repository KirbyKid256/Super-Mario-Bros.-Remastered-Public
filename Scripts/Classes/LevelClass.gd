@icon("res://Assets/Sprites/Editor/Level.svg")
class_name Level
extends Node

@export var music: JSON = null
@export_enum("Overworld", "Underground", "Desert", "Snow", "Jungle", "Beach", "Garden", "Mountain", "Skyland", "Autumn", "Pipeland", "Space", "Underwater", "Volcano", "Castle", "CastleWater", "Airship", "Bonus") var theme := "Overworld"

@export_enum("Day", "Night") var theme_time := "Day"

const THEME_IDXS := ["Overworld", "Underground", "Desert", "Snow", "Jungle", "Beach", "Garden", "Mountain", "Skyland", "Autumn", "Pipeland", "Space", "Underwater", "Volcano", "GhostHouse", "Castle", "CastleWater", "Airship", "Bonus"]

const WORLD_COUNTS := {
	"SMB1": 8,
	"SMBLL": 13,
	"SMBS": 8,
	"SMBANN": 8
}

const WORLD_THEMES := {
	"SMB1": SMB1_THEMES,
	"SMBLL": SMB1_THEMES,
	"SMBS": SMBS_THEMES,
	"SMBANN": SMB1_THEMES
}

const SMB1_THEMES := {
	-1: "Overworld",
	1: "Overworld",
	2: "Desert",
	3: "Snow",
	4: "Jungle",
	5: "Desert",
	6: "Snow",
	7: "Jungle",
	8: "Overworld",
	9: "Space",
	10: "Autumn",
	11: "Pipeland",
	12: "Skyland",
	13: "Volcano"
}

const SMBS_THEMES := {
	1: "Overworld",
	2: "Garden",
	3: "Beach",
	4: "Mountain",
	5: "Garden",
	6: "Beach",
	7: "Mountain",
	8: "Overworld"
}

const BONUS_ROOMS := {
	"SMB1": ["1-1a", "1-2a", "2-1a", "3-1a", "4-1a", "4-2a", "5-1a", "6-2a", "6-2c", "7-1a", "8-1a", "8-2a"],
	"SMBLL": ["1-1a", "2-1a", "2-2a", "3-1b", "4-2a", "5-1a", "5-3a", "7-1c", "7-2a", "10-1a", "12-1a", "13-1a", "13-2a", "13-4b"],
	"SMBS": ["1-1a", "1-2a", "6-2a", "6-2b", "6-2c", "6-2d", "6-3a", "7-1a", "7-3a"],
	"SMBANN": ["1-1a", "1-2a", "2-1a", "3-1a", "4-1a", "4-2a", "5-1a", "6-2a", "6-2c", "7-1a", "8-1a", "8-2a"]
}

@export var auto_set_theme := false

@export var time_limit := 400

@export var campaign := "SMB1"

@export var world_id := 1
@export var level_id := 1

@export var vertical_height := -208
@export var can_backscroll := false

@export var splitscreen_overlay_nodes: Array[Node] = []
@export var splitscreen_duplicate_nodes: Array[Node] = []

static var next_world := 1
static var next_level := 2
static var next_level_file_path := ""
static var first_load := true

static var start_level_path := ""
static var vine_warp_level := ""
static var vine_return_level := ""
static var in_vine_level := false

static var can_set_time := true

@onready var splitscreen_handler = load("res://Scenes/Prefabs/LevelObjects/SplitscreenHandler.tscn").instantiate()

func _enter_tree() -> void:
	Global.current_level = self
	update_theme()
	SpeedrunHandler.timer_active = true
	SpeedrunHandler.ghost_active = true
	if can_set_time:
		can_set_time = false
		Global.time = time_limit
	if first_load:
		start_level_path = scene_file_path
		Global.can_time_tick = true
		Global.level_num = level_id
		Global.world_num = world_id
		PlayerGhost.idx = 0
		SpeedrunHandler.current_recording = ""
		if SpeedrunHandler.timer <= 0:
			SpeedrunHandler.start_time = Time.get_ticks_msec()
	else:
		level_id = Global.level_num
		world_id = Global.world_num
	if Settings.file.difficulty.back_scroll == 1 and Global.current_game_mode != Global.GameMode.CUSTOM_LEVEL:
		can_backscroll = true
	first_load = false
	Global.current_campaign = campaign
	await get_tree().process_frame
	AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.NONE, true)

func _ready() -> void:
	# Spawn in extra players unless No Co-Op is enabled
	if not Global.no_coop:
		Input.joy_connection_changed.connect(spawn_in_extra_players)
		if Global.connected_players.size() > 1:
			spawn_in_extra_players()
	# Setup the Cameras
	if SplitscreenHandler.use_split_screen:
		if get_node_or_null("LevelBG") and not splitscreen_duplicate_nodes.has($LevelBG):
			splitscreen_duplicate_nodes.append($LevelBG)
		add_child(splitscreen_handler)

const PLAYER = preload("res://Scenes/Prefabs/Entities/Player.tscn")

func spawn_in_extra_players(device := -1, connected := true) -> void:
	if device < 0:
		for i in Global.connected_players.size():
			if i == 0:
				# Add Player to VS. Race Teams as Early as Possible
				if Global.current_game_mode == Global.GameMode.RACE:
					if BooRaceHandler.session_teams["red"].has(i):
						PlayerManager.get_first_player().add_to_group("RaceTeamRed")
					elif BooRaceHandler.session_teams["blue"].has(i):
						PlayerManager.get_first_player().add_to_group("RaceTeamBlue")
				continue
			var player_node = PLAYER.instantiate()
			player_node.player_id = Global.connected_players[i]
			player_node.camera_handler = PlayerManager.get_first_player().camera_handler
			if Global.current_game_mode == Global.GameMode.RACE:
				# Make sure each Player starts at the same spot for fairness
				player_node.global_position = PlayerManager.get_first_player().global_position
				# Add Players to VS. Race Teams as Early as Possible
				if BooRaceHandler.session_teams["red"].has(i):
					player_node.add_to_group("RaceTeamRed")
				elif BooRaceHandler.session_teams["blue"].has(i):
					player_node.add_to_group("RaceTeamBlue")
			else:
				player_node.global_position = get_tree().get_nodes_in_group("Players")[i - 1].global_position + Vector2(16, 0)
			if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL or Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
				if not Global.level_editor.is_node_ready(): await Global.level_editor.ready
				Global.level_editor.entity_layer_nodes.front().add_child(player_node)
			else:
				add_child(player_node)
	else:
		if device == 0 or PlayerManager.test_players >= device or PlayerManager.force_local_players.has(device): return
		if connected:
			var player_node = PLAYER.instantiate()
			player_node.player_id = device
			player_node.global_position = PlayerManager.get_first_player().global_position
			do_smoke_effect(player_node)
			if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL or Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
				if not Global.level_editor.is_node_ready(): await Global.level_editor.ready
				Global.level_editor.entity_layer_nodes.front().add_child(player_node)
			else:
				add_child(player_node)
		else:
			var player_node: Player = PlayerManager.get_player_with_id(device)
			if player_node != null:
				do_smoke_effect(player_node)
				player_node.queue_free()

func do_smoke_effect(player: Player) -> void:
	for i in 2:
		var node = Player.SMOKE_PARTICLE.instantiate()
		node.process_mode = Node.PROCESS_MODE_ALWAYS
		node.global_position = player.global_position - Vector2(0, 16 * i)
		node.z_index = player.z_index
		add_child(node)
		if player.power_state.hitbox_size == "Small": break
	AudioManager.play_sfx("magic", player.global_position, 1, player.player_id)

func update_theme() -> void:
	if auto_set_theme:
		theme = WORLD_THEMES[Global.current_campaign][Global.world_num]
		campaign = Global.current_campaign
		if Global.world_num > 4 and Global.world_num < 9:
			theme_time = "Night"
		else:
			theme_time = "Day"
		if Global.current_campaign == "SMBANN":
			theme_time = "Night"
		ResourceSetterNew.cache.clear()
	if self is CoinHeaven:
		Global.current_room = Global.Room.COIN_HEAVEN
	else:
		Global.current_room = get_room_type()
	Global.current_campaign = campaign
	Global.level_theme = theme
	Global.theme_time = theme_time
	TitleScreen.last_theme = theme
	if get_node_or_null("LevelBG") != null:
		$LevelBG.update_visuals()

func update_next_level_info() -> void:
	next_level = wrap(level_id + 1, 1, 5)
	next_world = world_id if level_id != 4 else world_id + 1 
	next_level_file_path = get_scene_string(next_world, next_level)
	LevelTransition.level_to_transition_to = next_level_file_path

static func get_scene_string(world_num := 0, level_num := 0) -> String:
	return "res://Scenes/Levels/" + Global.current_campaign + "/World" + str(world_num) + "/" + str(world_num) + "-" + str(level_num) + ".tscn"

static func get_world_count() -> int:
	return WORLD_COUNTS[Global.current_campaign]

func transition_to_next_level() -> void:
	if Global.current_game_mode == Global.GameMode.CHALLENGE:
		Global.transition_to_scene("res://Scenes/Levels/ChallengeModeResults.tscn")
		return
	if Global.current_game_mode == Global.GameMode.RACE:
		Global.transition_to_scene("res://Scenes/Levels/RaceMenu.tscn")
		return
	if Global.current_game_mode == Global.GameMode.BOO_RACE:
		Global.transition_to_scene("res://Scenes/Levels/BooRaceMenu.tscn")
		return
	update_next_level_info()
	PipeCutscene.seen_cutscene = false
	if WarpPipeArea.has_warped == false:
		Global.level_num = next_level
		Global.world_num = next_world
		LevelTransition.level_to_transition_to = get_scene_string(next_world, next_level)
	first_load = true
	SaveManager.write_save()
	Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")
	Checkpoint.passed_checkpoints.clear()

func reload_level() -> void:
	LevelTransition.level_to_transition_to = Level.start_level_path
	if Global.current_game_mode == Global.GameMode.CUSTOM_LEVEL:
		LevelTransition.level_to_transition_to = "res://Scenes/Levels/LevelEditor.tscn"
	if Global.current_game_mode == Global.GameMode.RACE or Global.current_game_mode == Global.GameMode.BOO_RACE:
		LevelPersistance.reset_states()
		Global.transition_to_scene(LevelTransition.level_to_transition_to)
	else:
		Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn")

func get_room_type() -> Global.Room:
	if BONUS_ROOMS[campaign].has(scene_file_path.get_file().get_basename()):
		return Global.Room.BONUS_ROOM
	return Global.Room.MAIN_ROOM
