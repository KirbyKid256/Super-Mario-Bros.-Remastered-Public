extends Control

var active := false
var player_tags := {}

signal selected
signal cancelled

signal switched_teams()

func _ready() -> void:
	Input.joy_connection_changed.connect(func(d, c): if d != 0 or c: update_players())
	update_players()

func update_players() -> void:
	for i in PlayerManager.MAX_LOCAL_PLAYERS:
		if Global.connected_players.has(i) and not player_tags.has(i):
			var tag: HBoxContainer = %RacePlayerTag.duplicate()
			tag.name = "RacePlayerTag" + str(i)
			tag.get_child(0).text = "P" + str(i + 1)
			tag.get_child(1).get_child(0).resource_json = GameHUD.character_icons[int(Global.player_characters[i])]
			player_tags[i] = tag
			var default_team := i % 2
			if default_team == 0:
				%RedTeam.add_child(tag)
			elif default_team == 1:
				%BlueTeam.add_child(tag)
		elif not Global.connected_players.has(i) and player_tags.has(i):
			var tag: HBoxContainer = player_tags[i]
			if %RedTeam.has_node(%RedTeam.get_path_to(tag)):
				%RedTeam.remove_child(tag)
			elif %BlueTeam.has_node(%RedTeam.get_path_to(tag)):
				%BlueTeam.remove_child(tag)
			player_tags.erase(i)
			tag.queue_free()

func open() -> void:
	grab_focus()
	update_visuals()
	show()
	await get_tree().process_frame
	active = true

func update_visuals() -> void:
	for i in player_tags:
		player_tags[i].get_child(1).get_child(0).resource_json = GameHUD.character_icons[int(Global.player_characters[i])]

func _input(event: InputEvent) -> void:
	if not active: return
	if Global.player_action_just_pressed("ui_left", event.device):
		move_teammate(event.device, -1)
	if Global.player_action_just_pressed("ui_right", event.device):
		move_teammate(event.device, 1)
	if event.is_action_pressed("ui_back"):
		await get_tree().process_frame
		cancelled.emit()
		close()
	if event.is_action_pressed("ui_accept"):
		selected.emit()
		close()

# Used to change the given Player's teammate
func move_teammate(player_id: int, direction := 0) -> void:
	var tag: Control = player_tags[player_id]
	if direction > 0 and %RedTeam.get_children().has(tag):
		var index: int = tag.get_index()
		var rival = %BlueTeam.get_child(index)
		if rival != null: # Swap with opposite tag
			var rival_id: int = player_tags.find_key(rival)
			rival.reparent(%RedTeam, false)
			%RedTeam.move_child(rival, index)
			BooRaceHandler.session_teams["blue"].erase(rival_id)
			BooRaceHandler.session_teams["red"].append(rival_id)
		tag.reparent(%BlueTeam, false)
		%BlueTeam.move_child(tag, index)
		# Add Player IDs to Teams
		BooRaceHandler.session_teams["red"].erase(player_id)
		BooRaceHandler.session_teams["blue"].append(player_id)
	elif direction < 0 and %BlueTeam.get_children().has(tag):
		var index: int = tag.get_index()
		var rival = %RedTeam.get_child(index)
		if rival != null: # Swap with opposite tag
			var rival_id: int = player_tags.find_key(rival)
			rival.reparent(%BlueTeam, false)
			%BlueTeam.move_child(rival, index)
			BooRaceHandler.session_teams["red"].erase(rival_id)
			BooRaceHandler.session_teams["blue"].append(rival_id)
		tag.reparent(%RedTeam, false)
		%RedTeam.move_child(tag, index)
		# Add Player IDs to Teams
		BooRaceHandler.session_teams["blue"].erase(player_id)
		BooRaceHandler.session_teams["red"].append(player_id)
	# Re-sort Teams
	BooRaceHandler.session_teams["red"].sort()
	BooRaceHandler.session_teams["blue"].sort()
	switched_teams.emit()

func close() -> void:
	active = false
	hide()
