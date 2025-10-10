extends TileMapLayer

@export var player_id := 0

const SCENE_ID_MAP := {
	0: 1,	# BooOnOffSwitch
	1: 0,	# BooOnOffSwitchAlt
	2: 3,	# TimedBooBlock
	3: 2,	# TimedBooBlockAlt
	4: 5,	# BooOnOffBlock
	5: 4,	# BooOnOffBlueBlock
	6: 7,	# SwitchSpikeBlock
	7: 6	# SwitchSpikeBlockAlt
}

func _ready() -> void:
	var player := PlayerManager.get_player_with_id(player_id)
	if player and player.is_in_group("RaceTeamBlue"):
		for cell in get_used_cells():
			set_cell(cell, 0, Vector2i.ZERO, SCENE_ID_MAP[get_cell_alternative_tile(cell)])

func on_child_entered_tree(node: Node) -> void:
	if not node is PhysicsBody2D: return
	for player in get_tree().get_nodes_in_group("Players"):
		if player.player_id == player_id: continue
		node.add_collision_exception_with(player)
