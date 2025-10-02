extends Control

var selected_index := 0

@export var options: Array[Label]
@onready var cursor: TextureRect = $Control/Cursor

var active := false

@export var is_pause := true

signal option_1_selected
signal option_2_selected
signal option_3_selected
signal option_4_selected

signal closed

func _ready() -> void:
	Input.joy_connection_changed.connect(func(d, c): if d != 0 or c: update_colours())
	Global.level_theme_changed.connect(update_colours)

func _process(_delta: float) -> void:
	if active:
		handle_inputs()
	cursor.global_position.y = options[selected_index].global_position.y + 4
	cursor.global_position.x = options[selected_index].global_position.x - 10

func handle_inputs() -> void:
	if Global.player_action_just_pressed("ui_down"):
		selected_index += 1
	if Global.player_action_just_pressed("ui_up"):
		selected_index -= 1
	selected_index = clamp(selected_index, 0, options.size() - 1)
	if Global.player_action_just_pressed("ui_accept"):
		option_selected()
	elif Global.player_action_just_pressed("pause") or Global.player_action_just_pressed("ui_back"):
		close()

func option_selected() -> void:
	emit_signal("option_" + str(selected_index + 1) + "_selected")

func open_settings() -> void:
	active = false
	$SettingsMenu.open()
	await $SettingsMenu.closed
	active = true

func update_colours() -> void:
	if Global.connected_players > 1:
		$Control/PanelContainer.self_modulate = PlayerManager.colours[PlayerManager.active_device]
		$SettingsMenu/PanelContainer.self_modulate = $Control/PanelContainer.self_modulate
	else:
		$Control/PanelContainer.self_modulate = Color.WHITE
		$SettingsMenu/PanelContainer.self_modulate = Color.WHITE

func open(device := 0) -> void:
	if is_pause:
		Global.game_paused = true
		AudioManager.play_global_sfx("pause")
		get_tree().paused = true
	if Global.connected_players > 1:
		PlayerManager.active_device = device
	else:
		PlayerManager.active_device = 0
	update_colours()
	show()
	await get_tree().create_timer(0.1).timeout
	active = true

func close() -> void:
	active = false
	selected_index = 0
	PlayerManager.active_device = 0
	hide()
	closed.emit()
	await get_tree().create_timer(0.1).timeout
	Global.game_paused = false
	get_tree().paused = false
