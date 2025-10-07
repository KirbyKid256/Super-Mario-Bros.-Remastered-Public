# Source: https://www.youtube.com/watch?v=tkBgYD0R8R4 and https://www.youtube.com/watch?v=yu95fM-sYtI
class_name SplitscreenHandler
extends Control

const MAX_VIEWPORTS := 4

static var use_split_screen := false

@onready var default_viewport = $SubViewport

func _ready() -> void:
	Input.joy_connection_changed.connect(update_viewports)
	for i in Global.connected_players:
		# Add Viewports
		var viewport = $GridContainer/Viewport0
		if i != 0:
			viewport = viewport.duplicate()
			viewport.name = "Viewport" + str(i)
			$GridContainer.add_child(viewport)
		# Subviewport
		var subviewport: SubViewport = viewport.get_node("SubViewport")
		subviewport.canvas_cull_mask = Color("fff" + str(i + 1).pad_zeros(5)).to_rgba32()

func _enter_tree() -> void:
	if $GridContainer.get_child_count() == 1: await ready
	update_viewports()

func update_viewports(_device := -1, _connected := true):
	#for i in PlayerManager.MAX_LOCAL_PLAYERS:
		#if Global.connected_players.has(i % MAX_VIEWPORTS):
			#$GridContainer.get_child(i % MAX_VIEWPORTS).show()
		#elif i <= MAX_VIEWPORTS:
			#$GridContainer.get_child(i % MAX_VIEWPORTS).hide()
	# Re-parent Players
	for player: Player in get_tree().get_nodes_in_group("Players"):
		player.reparent($GridContainer.get_child(player.player_id).get_child(0))
		player.camera_make_current()
		player.recenter_camera()
	# Update Containers if in Level
	if get_parent() == Global.current_level:
		for child in get_parent().get_children():
			if not child == self and not get_parent().splitscreen_overlay_nodes.has(child):
				if not get_parent().splitscreen_duplicate_nodes.has(child):
					if child is CanvasItem: child.visibility_layer = default_viewport.canvas_cull_mask
					child.reparent(default_viewport)
				for viewport: SubViewportContainer in $GridContainer.get_children():
					var subviewport: SubViewport = viewport.get_node("SubViewport")
					subviewport.world_2d = default_viewport.world_2d
					if get_parent().splitscreen_duplicate_nodes.has(child):
						if viewport.get_index() == 0:
							if Global.current_game_mode == Global.GameMode.RACE and child.is_in_group("RaceBlocks"):
								var player: Player = PlayerManager.get_player_with_id(viewport.get_index())
								if player and player.is_in_group("RaceTeamBlue") and child.get("replace") != null:
									child.replace = true
							if child is CanvasItem: child.visibility_layer = subviewport.canvas_cull_mask
							child.reparent(subviewport)
						else:
							var new_child = child.duplicate()
							if new_child is CanvasItem: new_child.visibility_layer = subviewport.canvas_cull_mask
							subviewport.add_child(new_child)
