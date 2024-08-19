extends StaticBody2D
class_name SpaceTrader

var space: Space

func _ready() -> void:
	space = find_parent("Space")

func sell_cargo(cargo_item: CargoItem) -> void:
	var target_position: Vector2 = cargo_item.global_position
	
	space.add_money_to_player(cargo_item.cargo_value)
	Globals.play_sound_effect("res://assets/sound_effects/SpaceCoinDropped.wav", cargo_item.global_position)
	
	if cargo_item.get_parent() != null:
		cargo_item.get_parent().remove_child(cargo_item)
	
	# Add the node to space
	space.call_deferred("add_cargo_item", cargo_item)
	await get_tree().physics_frame
	
	cargo_item.global_position = target_position
	cargo_item.sell(global_position)

# Just for the effect
func take_damage(_amount: int, damage_position: Vector2, _direction: Vector2) -> void:
	var damage_effect: CPUParticles2D = Globals.damage_particle_emitter_packed_scene.instantiate()
	add_child(damage_effect)
	damage_effect.global_position = damage_position
	damage_effect.emitting = true
	
	await get_tree().create_timer(damage_effect.lifetime).timeout
	damage_effect.queue_free()
