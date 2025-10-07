extends Node

static var selected_index := 0

var active := true

const levels := {
	"SMB1": SMB1_LEVELS,
	"SMBLL": SMBLL_LEVELS,
	"SMBS": SMBS_LEVELS
}

const SMB1_LEVELS := [
	"res://Scenes/Levels/SMB1/VSRace/Race1-1.tscn",
	"res://Scenes/Levels/SMB1/VSRace/Race1-2.tscn",
	"res://Scenes/Levels/SMB1/VSRace/Race1-3.tscn",
	"res://Scenes/Levels/SMB1/VSRace/Race1-4.tscn",
	"res://Scenes/Levels/SMB1/VSRace/Race2-1.tscn",
	"res://Scenes/Levels/SMB1/VSRace/Race2-2.tscn",
	"res://Scenes/Levels/SMB1/VSRace/Race2-3.tscn",
	"res://Scenes/Levels/SMB1/VSRace/Race2-4.tscn"
]

const SMBLL_LEVELS := [
	"res://Scenes/Levels/SMBLL/VSRace/Race1-1.tscn",
	"res://Scenes/Levels/SMBLL/VSRace/Race1-2.tscn",
	"res://Scenes/Levels/SMBLL/VSRace/Race1-3.tscn",
	"res://Scenes/Levels/SMBLL/VSRace/Race1-4.tscn",
	"res://Scenes/Levels/SMBLL/VSRace/Race2-1.tscn",
	"res://Scenes/Levels/SMBLL/VSRace/Race2-2.tscn",
	"res://Scenes/Levels/SMBLL/VSRace/Race2-3.tscn",
	"res://Scenes/Levels/SMBLL/VSRace/Race2-4.tscn",
]

const SMBS_LEVELS := [
	"res://Scenes/Levels/SMBS/VSRace/Race1-1.tscn", 
	"res://Scenes/Levels/SMBS/VSRace/Race1-2.tscn",
	"res://Scenes/Levels/SMBS/VSRace/Race1-3.tscn",
	"res://Scenes/Levels/SMBS/VSRace/Race1-4.tscn",
	"res://Scenes/Levels/SMBS/VSRace/Race2-1.tscn",
	"res://Scenes/Levels/SMBS/VSRace/Race2-2.tscn",
	"res://Scenes/Levels/SMBS/VSRace/Race2-3.tscn",
	"res://Scenes/Levels/SMBS/VSRace/Race2-4.tscn"
]

func _enter_tree() -> void:
	%RedLabel.text = "RED*%s" % str(BooRaceHandler.session_tallies["red"]).pad_zeros(3)
	%BluLabel.text = "BLU*%s" % str(BooRaceHandler.session_tallies["blue"]).pad_zeros(3)
	%TieLabel.text = "TIE*%s" % str(BooRaceHandler.session_tallies["draw"]).pad_zeros(3)

func _ready() -> void:
	Input.joy_connection_changed.connect(update_players)
	AudioManager.stop_all_music()
	Global.reset_power_states()
	Global.get_node("GameHUD").hide()
	Global.current_game_mode = Global.GameMode.RACE
	Global.reset_values()
	LevelPersistance.reset_states()
	Level.first_load = true
	Level.can_set_time = true
	%LevelLabels.get_child(BooRaceHandler.current_level_id).grab_focus()
	$PanelContainer.size.y -= 23
	$Music.play()
	update_players()

func _exit_tree() -> void:
	Global.get_node("GameHUD").show()

func open() -> void:
	active = true

func update_players(device: int = -1, connected: bool = true) -> void:
	var player_sprites = %PlayerSprites.find_children("PlayerSprite*")
	player_sprites.sort_custom(func(a, b): return int(a.name) < int(b.name))
	if device < 0:
		for i in range(1, 8): player_sprites[i].visible = Global.connected_players.has(i)
	else:
		if device == 0 or PlayerManager.test_players >= device: return
		if player_sprites[device].visible != connected:
			player_sprites[device].visible = connected
			var smoke = Player.SMOKE_PARTICLE.instantiate()
			smoke.animation_finished.connect(smoke.queue_free)
			smoke.global_position = player_sprites[device].global_position
			%PlayerSprites.add_child(smoke)
			AudioManager.play_sfx("magic", smoke.global_position, 1, device)
	if Global.connected_players.size() == 1:
		$NotEnoughPlayers.show()
		%LevelLabels.get_child(selected_index).release_focus()
	else:
		$NotEnoughPlayers.hide()
		regrab_focus()
	on_switched_teams()

func on_switched_teams() -> void:
	var player_sprites = %PlayerSprites.find_children("PlayerSprite*")
	player_sprites.sort_custom(func(a, b): return int(a.name) < int(b.name))
	for player in player_sprites:
		if BooRaceHandler.session_teams["red"].has(player.player_id):
			player.reparent(%RedTeam)
			%RedTeam.move_child(player, BooRaceHandler.session_teams["red"].find(player.player_id))
			player.position.x = -16 * player.get_index()
			player.flip_h = false
		elif BooRaceHandler.session_teams["blue"].has(player.player_id):
			player.reparent(%BlueTeam)
			%BlueTeam.move_child(player, BooRaceHandler.session_teams["blue"].find(player.player_id))
			player.position.x = 16 * player.get_index()
			player.flip_h = true

func set_current_level_idx(new_idx := 0) -> void:
	selected_index = new_idx

func _input(event: InputEvent) -> void:
	if not active: return
	if event.is_action_pressed("ui_back"):
		BooRaceHandler.reset_session()
		Global.transition_to_scene("res://Scenes/Levels/TitleScreen.tscn")
	if Global.connected_players.size() > 1 and event.is_action_pressed("ui_accept"):
		level_selected()

func regrab_focus() -> void:
	%LevelLabels.get_child(selected_index).grab_focus()

func level_selected() -> void:
	active = false
	Global.reset_values()
	Global.clear_saved_values()
	ResourceSetter.cache.clear()
	ResourceSetterNew.cache.clear()
	$TeamSelect.open()
	%LevelLabels.get_child(selected_index).release_focus()

func character_selected() -> void:
	SplitscreenHandler.use_split_screen = true
	PlayerManager.force_local_players = Global.connected_players
	Global.transition_to_scene(levels[Global.current_campaign][selected_index])
