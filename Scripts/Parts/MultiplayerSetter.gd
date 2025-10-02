extends Node

func coop_style_changed(new_value := 0) -> void:
	Settings.file.multiplayer.coop_style = new_value

func set_value(value_name := "", value = null) -> void:
	{
		"coop_style": coop_style_changed
	}[value_name].call(value)
