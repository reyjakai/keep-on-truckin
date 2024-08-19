extends RigidBody2D
class_name Meteor

@export var damage_amount: int = 3
@onready var active: bool = true

# Handle damage.
func _on_body_shape_entered(_body_rid: RID, body: Node, _body_shape_index: int, _local_shape_index: int) -> void:
	if active == false:
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage_amount, global_position, linear_velocity)
	
	active = false
	
	take_damage(damage_amount, global_position, linear_velocity)

func take_damage(_amount: int, damage_position: Vector2, _direction: Vector2) -> void:
	# kill all impulse
	linear_velocity = linear_velocity.lerp(Vector2.ZERO, 1.0)
	angular_velocity = lerp(angular_velocity, 0.0, 1.0)
	
	$Sprite2D.visible = false
	call_deferred("set_collision_layer_value", 3, false)
	call_deferred("set_collision_mask_value", 3, false)
	
	var damage_effect: CPUParticles2D = Globals.damage_particle_emitter_packed_scene.instantiate()
	add_child(damage_effect)
	damage_effect.global_position = damage_position
	damage_effect.emitting = true
	
	await get_tree().create_timer(damage_effect.lifetime).timeout
	die()

func die() -> void:
	queue_free()
