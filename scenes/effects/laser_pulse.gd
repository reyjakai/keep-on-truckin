extends RigidBody2D
class_name LaserPulse

@export var damage_amount: int = 2

# Handle damage.
func _on_body_shape_entered(_body_rid: RID, body: Node, _body_shape_index: int, _local_shape_index: int) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage_amount, global_position, linear_velocity / 10)
	
	queue_free()

func _on_death_timer_timeout() -> void:
	queue_free()
