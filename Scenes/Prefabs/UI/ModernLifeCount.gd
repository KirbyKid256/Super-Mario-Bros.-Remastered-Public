extends HBoxContainer

@onready var life_count = $LifeCount.duplicate()
@onready var life_counts: Dictionary[int, HBoxContainer] = {}

func _ready() -> void:
	$LifeCount.queue_free()

func update_character_info() -> void:
	for i in life_counts.keys():
		if (not Global.connected_players.has(i) or Global.no_coop) and i > 0: # Remove the Life Icon
			life_counts[i].queue_free()
			life_counts.erase(i)
	for i in Global.connected_players:
		if i > 0 and Global.no_coop: break
		if not life_counts.has(i): # Append a new Player Life Icon
			var count = life_count.duplicate()
			life_counts[i] = count
			add_child(count)
			move_child(count, i)
		# Set the Life Icon
		life_counts[i].get_node("Icon/ResourceSetterNew").resource_json = GameHUD.character_icons[int(Global.player_characters[i])]
		life_counts[i].get_node("Icon/Shadow").texture = life_counts[i].get_node("Icon").texture
		life_counts[i].get_node("Label").text = "*" + (str(Global.lives).pad_zeros(2) if Settings.file.difficulty.inf_lives == 0 else "∞")
		life_counts[i].get_node("Label").hide()
	# Show the label from the icon at the end
	life_counts.sort()
	life_counts[life_counts.keys()[clampi(Global.connected_players.size(), 0, life_counts.size() - 1)]].get_node("Label").show()
