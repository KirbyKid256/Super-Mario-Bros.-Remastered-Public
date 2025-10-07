class_name TitleScreenOptions
extends VBoxContainer

@export var active := false

@export var can_exit := true

var selected_index := 0

@export var options: Array[Label] = []
@export var multiplayer_options: Array[Label] = []
@onready var title_screen_parent := owner

signal option_1_selected
signal option_2_selected
signal option_3_selected

signal closed

func _process(_delta: float) -> void:
	if active:
		handle_inputs()
		for i in multiplayer_options:
			if Global.connected_players.size() > 1:
				i.modulate = Color.WHITE
			else:
				i.modulate = Color.GRAY

func open() -> void:
	Global.world_num = clamp(Global.world_num, 1, Level.get_world_count())
	title_screen_parent.active_options = self
	show()
	await get_tree().physics_frame
	active = true

func close() -> void:
	active = false
	hide()

func handle_inputs() -> void:
	if Global.player_action_just_pressed("ui_down"):
		selected_index += 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	if Global.player_action_just_pressed("ui_up"):
		selected_index -= 1
		if Settings.file.audio.extra_sfx == 1:
			AudioManager.play_global_sfx("menu_move")
	var amount := []
	for i in options:
		if i.visible:
			amount.append(i)
	selected_index = clamp(selected_index, 0, amount.size() - 1)
	if Global.player_action_just_pressed("ui_accept"):
		option_selected()
	elif can_exit and Global.player_action_just_pressed("ui_back"):
		close()
		closed.emit()

func option_selected() -> void:
	if not multiplayer_options.has(options[selected_index]) or multiplayer_options.has(options[selected_index]) and Global.connected_players.size() > 1:
		active = false
		emit_signal("option_" + str(selected_index + 1) + "_selected")
	else:
		AudioManager.play_global_sfx("bump")
