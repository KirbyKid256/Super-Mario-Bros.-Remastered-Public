extends Node

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

func _enter_tree() -> void:
	Input.joy_connection_changed.connect(joy_connection_changed)
	for i in MAX_LOCAL_PLAYERS:
		for action in PLAYER_ACTIONS:
			copy_action(action, i)

# Debug Printing
func joy_connection_changed(device: int, connected: bool) -> void:
	if device > 0:
		if connected:
			print("PLAYER %d has Connected" % (device + 1))
		else:
			print("PLAYER %d has Disconnected" % (device + 1))
			if active_device == device:
				active_device = 0

## This function duplicates an existing action from the [InputMap] and re-assigns it to a specific Player/Device ID.
func copy_action(action: String, device: int) -> void:
	var new_action: = action + "_" + str(device)
	InputMap.add_action(action + "_" + str(device), InputMap.action_get_deadzone(action))
	for event in InputMap.action_get_events(action):
		event = event.duplicate(true)
		event.device = device
		InputMap.action_add_event(new_action, event)
