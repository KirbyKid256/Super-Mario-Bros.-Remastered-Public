extends Node2D

@export var y_limit := -176

@onready var camera := get_viewport().get_camera_2d()

@onready var old_limit = Player.camera_right_limit


func enter_screen() -> void:
	if get_viewport().get_camera_2d().get_target_position().x > global_position.x: return
	Player.camera_right_limit = int(global_position.x)

func _physics_process(_delta: float) -> void:
	if camera != null:
		var player = PlayerManager.get_closest_player(global_position)
		if (player.global_position.y <= y_limit + 1 and player.global_position.x + player.camera_handler.camera_offset.x >= player.camera.get_screen_center_position().x) or player.global_position.x >= global_position.x - 16:
			return_to_normal()

func return_to_normal() -> void:
	Player.camera_right_limit = old_limit
