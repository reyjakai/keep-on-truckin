extends StaticBody2D
class_name WarpGate

func _on_warp_area_2d_area_entered(area: Area2D) -> void:
	var space: Space = find_parent("Space")
	
	space.start_next_day()

func _process(delta: float) -> void:
	$GateLeft.rotation_degrees += (delta * 5)
	$GateRight.rotation_degrees -= (delta * 5)
