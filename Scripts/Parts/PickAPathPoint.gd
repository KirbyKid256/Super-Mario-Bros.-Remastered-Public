class_name PickAPathPoint
extends Node2D

var crossed := false

func on_player_entered(player: Player) -> void:
	if not crossed: 
		AudioManager.play_global_sfx("correct", 1, player.player_id)
	crossed = true
