extends Node

const RESPAWN_TIME := 2.0
const VICTORY_WAIT_TIME := 2.5

const MAX_LOCAL_PLAYERS := 8
const PLAYER_ACTIONS := [
	# Menus
	"ui_left",
	"ui_right",
	"ui_down",
	"ui_up",
	"ui_accept",
	"ui_back",
	# Gameplay
	"jump",
	"run",
	"action",
	"move_left",
	"move_right",
	"move_down",
	"move_up",
	"pause",
	"drop_item"
]

@onready var colours:
	get():
		var i: = 0
		var new_colors: = []
		var default_colors: = [Color("5050FF"), Color("F73910"), Color("1A912E"), Color("FFB762"), 
		Color("A1F6FF"), Color("FFFF44"), Color("848484"), Color("AA1FBE")]
		var resource_getter = ResourceGetter.new()
		var texture: Texture2D = load("res://Assets/Sprites/Players/PlayerColours.png")
		texture = resource_getter.get_resource(texture)
		for y in texture.get_height(): for x in texture.get_width():
			if i >= MAX_LOCAL_PLAYERS: break
			var pixel: = texture.get_image().get_pixel(x, y)
			if pixel.a > 0:
				new_colors.append(pixel)
			else:
				new_colors.append(default_colors[wrapi(i, 0, default_colors.size())])
			i += 1
		return new_colors

var active_device: int = 0

var test_players := 1:
	get(): return clampi(test_players + 1, 0, MAX_LOCAL_PLAYERS)
var dead_players: Dictionary[int, Player] = {}
func _enter_tree() -> void:
	Input.joy_connection_changed.connect(joy_connection_changed)
	for i in MAX_LOCAL_PLAYERS:
		for action in PLAYER_ACTIONS:
			copy_action(action, i)

func joy_connection_changed(device: int, connected: bool) -> void:
	if device > 0: #TODO: Add a setting to allow Player 2 to use Device 0
		if connected:
			print("PLAYER %d has Connected" % (device + 1))
		else:
			print("PLAYER %d has Disconnected" % (device + 1))
			if active_device == device and test_players < device: # Reset Active Device if the current one is disconnected
				active_device = 0

## Duplicates an existing [code]action[/code] from the [InputMap] and assigns it to a specific [code]device[/code]. This automatically adds the newly created action to the Map.
## [br][br]For example, if [code]action[/code] is "ui_back" and [code]device[/code] is 2, the formatted name added to the [InputMap] would be "ui_back_2".
func copy_action(action: StringName, device: int) -> void:
	var new_action: = action + "_" + str(device)
	InputMap.add_action(action + "_" + str(device), InputMap.action_get_deadzone(action))
	for event in InputMap.action_get_events(action):
		event = event.duplicate(true)
		event.device = device
		InputMap.action_add_event(new_action, event)

#region Player Grabbing Functions
## Returns the Player with the lowest player_id. This usually grabs P1. However, if P1 doesn't exist, it will grab P2, then P3, and so on.
func get_first_player() -> Player:
	var players = get_tree().get_nodes_in_group("Players")
	if players.is_empty(): return null
	players.sort_custom(sort_by_player_id.bind)
	return players.front()

## Returns the Player with the specified [code]device[/code]. By default, this grabs P1, the Player with an ID of [code]0[/code]. Unlike `get_first_player`, this throws an error if the Player with the given ID doesn't exist in the Tree Group.
func get_player_with_id(device := 0) -> Player:
	return get_tree().get_nodes_in_group("Players").filter(filter_by_id.bind(device)).front()

## Returns the Player closest to a given [code]origin[/code] point. The origin is based on a [Node2D]s [code]global_position[/code]. By default, the origin is (0, 0).
func get_closest_player(origin: Vector2) -> Player:
	var players = get_tree().get_nodes_in_group("Players")
	if players.is_empty(): return null
	players.sort_custom(sort_by_closest.bind(origin))
	return players.front()

func filter_by_id(i, id := 0) -> bool:
	if i is Player: return i.player_id == id
	return i.get_meta("player_id", 0) == id

func sort_by_player_id(a: Player, b: Player) -> bool:
	return a.player_id < b.player_id

func sort_by_closest(a: Node2D, b: Node2D, origin: Vector2) -> bool:
	return abs(a.global_position) - abs(origin) < abs(b.global_position) - abs(origin)
#endregion
