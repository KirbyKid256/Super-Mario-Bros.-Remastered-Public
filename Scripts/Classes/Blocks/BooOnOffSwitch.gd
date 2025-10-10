class_name BooOnOffSwitch
extends Block

@export var invert := false

var active := false

static var has_hit := false

func _ready() -> void:
	can_hit = true
	has_hit = false

func on_updated() -> void:
	if $Sprite.animation == "Default":
		if invert:
			$Sprite.set_frame_and_progress(1, 0)
		else:
			$Sprite.set_frame_and_progress(0, 0)

func on_block_hit() -> void:
	if can_hit == false or has_hit:
		return
	has_hit = true
	AudioManager.play_sfx("switch", global_position)
	can_hit = false
	get_tree().call_group("BooBlocks", "on_switch_hit")
	await get_tree().create_timer(0.25, false).timeout
	can_hit = true
	has_hit = false

func on_switch_hit() -> void:
	active = not active
	if active:
		if invert:
			$Sprite.play("Off")
		else:
			$Sprite.play("On")
	else:
		if invert:
			$Sprite.play("On")
		else:
			$Sprite.play("Off")

func on_boo_hit() -> void:
	if active:
		return
	AudioManager.play_global_sfx("switch")
	get_tree().call_group("BooBlocks", "on_switch_hit")
