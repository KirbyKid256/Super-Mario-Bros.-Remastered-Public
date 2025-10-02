extends HBoxContainer

@onready var player_icon = $CharacterIcon.duplicate()
@onready var player_icons: Dictionary[int, TextureRect] = {}

func _ready() -> void:
	$CharacterIcon.queue_free()

func update_character_info() -> void:
	for i in player_icons.keys():
		if (not Global.connected_joypads.has(i) or Global.no_coop) and i > 0: # Remove the Life Icon
			player_icons[i].queue_free()
			player_icons.erase(i)
	for i in Global.connected_joypads:
		if i > 0 and Global.no_coop: break
		if not player_icons.has(i): # Append a new Player Life Icon
			var icon = player_icon.duplicate()
			player_icons[i] = icon
			add_child(icon); move_child(icon, i)
		# Set the Life Icon
		player_icons[i].get_node("ResourceSetterNew").resource_json = (GameHUD.character_icons[int(Global.player_characters[i])])
		player_icons[i].get_node("Shadow").texture = player_icons[i].texture
		player_icons[i].get_child(1).text = "*" + (str(Global.lives).pad_zeros(2) if Settings.file.difficulty.inf_lives == 0 else "∞")
		player_icons[i].get_child(1).hide()
	# Show the label from the icon at the end
	player_icons.sort()
	player_icons[player_icons.keys()[clampi(Global.connected_players, 0, player_icons.size() - 1)]].get_child(1).show()
