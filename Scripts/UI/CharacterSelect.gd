extends Control
@onready var cursor: TextureRect = %Cursor

var selected_index := 0

signal selected
signal cancelled
var active := false

var player_queue := []

var character_sprite_jsons := [
	"res://Assets/Sprites/Players/Mario/Small.json",
	"res://Assets/Sprites/Players/Luigi/Small.json",
	"res://Assets/Sprites/Players/Toad/Small.json",
	"res://Assets/Sprites/Players/Toadette/Small.json"
]

func _process(_delta: float) -> void:
	if active:
		handle_input()

func _ready() -> void:
	update_sprites()

func get_custom_characters() -> void:
	Player.CHARACTERS = ["Mario", "Luigi", "Toad", "Toadette"]
	Player.CHARACTER_NAMES = ["CHAR_MARIO", "CHAR_LUIGI", "CHAR_TOAD", "CHAR_TOADETTE"]
	AudioManager.character_sfx_map.clear()
	
	var idx := 0
	for i in Player.CHARACTERS:
		var path = ResourceSetter.get_pure_resource_path("res://Assets/Sprites/Players/" + i + "/CharacterInfo.json")
		print(path)
		if FileAccess.file_exists(path):
			var json = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
			Player.CHARACTER_NAMES[idx] = json.name
		path = ResourceSetter.get_pure_resource_path("res://Assets/Sprites/Players/" + i + "/CharacterColour.json")
		if FileAccess.file_exists(path):
			Player.CHARACTER_COLOURS[idx] = load(path)
		idx += 1
	print(Player.CHARACTER_NAMES)
	
	var base_path = Global.config_path
	var char_dir = base_path.path_join("custom_characters") 
	for i in DirAccess.get_directories_at(char_dir):
		var char_path = char_dir.path_join(i)
		var char_info_path = char_path.path_join("CharacterInfo.json")
		if FileAccess.file_exists(char_info_path):
			var json = JSON.parse_string(FileAccess.open(char_path.path_join("CharacterInfo.json"), FileAccess.READ).get_as_text())
			Player.CHARACTERS.append(i)
			Player.CHARACTER_NAMES.append(json.name)
			if FileAccess.file_exists(char_path.path_join("CharacterColour.json")):
				Player.CHARACTER_COLOURS.append(load(char_path.path_join("CharacterColour.json")))
			if FileAccess.file_exists(char_path.path_join("LifeIcon.json")):
				GameHUD.character_icons.append(load(char_path.path_join("LifeIcon.json")))
			if FileAccess.file_exists(char_path.path_join("ColourPalette.json")):
				Player.CHARACTER_PALETTES.append(load(char_path.path_join("ColourPalette.json")))
			if FileAccess.file_exists(char_path.path_join("SFX.json")):
				AudioManager.character_sfx_map[i] = JSON.parse_string(FileAccess.open(char_path.path_join("SFX.json"), FileAccess.READ).get_as_text())

func open(can_coop := false) -> void:
	PlayerManager.active_device = 0
	Global.no_coop = not can_coop
	if can_coop and Global.connected_players.size() > 1:
		player_queue = Global.connected_players
		player_queue.remove_at(0)
	else:
		player_queue.clear()
	get_custom_characters()
	show()
	grab_focus()
	selected_index = int(Global.player_characters[PlayerManager.active_device])
	update_sprites()
	await get_tree().create_timer(0.1).timeout
	active = true

func handle_input() -> void:
	if Global.player_action_just_pressed("ui_left"):
		selected_index = wrap(selected_index - 1, 0, Player.CHARACTERS.size())
		update_sprites()
	elif Global.player_action_just_pressed("ui_right"):
		selected_index = wrap(selected_index + 1, 0, Player.CHARACTERS.size())
		update_sprites()
	if Global.player_action_just_pressed("ui_accept"):
		Global.player_characters[PlayerManager.active_device] = selected_index
		Global.player_characters_changed.emit() # I don't know why it won't emit automatically
		var characters := Global.player_characters
		for i in characters:
			if int(i) > 3:
				characters = [0, 1, 2, 3, 0, 1, 2, 3]
		Settings.file.game.characters = characters
		Settings.save_settings()
		if player_queue.is_empty():
			player_queue.clear()
			selected.emit()
			close()
		else:
			PlayerManager.active_device = player_queue.pop_at(0)
			selected_index = int(Global.player_characters[PlayerManager.active_device])
			update_sprites()
	elif Input.is_action_just_pressed("ui_back_0"):
		close()
		cancelled.emit()
		Global.no_coop = false

func update_sprites() -> void:
	%Left.force_character = Player.CHARACTERS[wrap(selected_index - 1, 0, Player.CHARACTERS.size())]
	%Left.player_id = PlayerManager.active_device
	%Selected.force_character = Player.CHARACTERS[wrap(selected_index, 0, Player.CHARACTERS.size())]
	%Selected.player_id = PlayerManager.active_device
	%Right.force_character = Player.CHARACTERS[wrap(selected_index + 1, 0, Player.CHARACTERS.size())]
	%Right.player_id = PlayerManager.active_device
	for i in [%Left, %Selected, %Right]:
		i.update()
		i.play("Pose" if i == %Selected else "FaceForward")
	%PlayerColourTexture.resource_json = Player.CHARACTER_COLOURS[selected_index]
	%CharacterName.text = tr(Player.CHARACTER_NAMES[selected_index])
	$Panel/MarginContainer/VBoxContainer/CharacterName/TextShadowColourChanger/ColourPaletteSampler.texture = %ColourPaletteSampler.texture
	$Panel/MarginContainer/VBoxContainer/CharacterName/TextShadowColourChanger.handle_shadow_colours()
	if player_queue.is_empty() and PlayerManager.active_device < 1:
		$Panel.self_modulate = Color.WHITE
		%PlayerNumber.hide()
	else:
		$Panel.self_modulate = PlayerManager.colours[PlayerManager.active_device]
		%PlayerNumber.modulate = $Panel.self_modulate
		%PlayerNumber.text = "P%d" % (PlayerManager.active_device + 1)
		%PlayerNumber.show()

func close() -> void:
	PlayerManager.active_device = 0
	player_queue.clear()
	active = false
	hide()
