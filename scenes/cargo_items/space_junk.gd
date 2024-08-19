extends RigidBody2D

const SPAWN_OFFSET_RADIUS: float = 24.0
var cargo_items: Array[CargoItem] = []

var number_of_items: int = 0
@export var min_number_of_items: int = 1
@export var max_number_of_items: int = 3

@export var max_health: int = 6
var current_health: int = 6

func _ready() -> void:
	$HealthBar.visible = false
	current_health = max_health
	
	number_of_items = randi_range(min_number_of_items, max_number_of_items)
	
	for i in range(number_of_items):
		var cargo_item: CargoItem = Globals.cargo_item_packed_scene.instantiate()
		
		cargo_items.append(cargo_item)

func _physics_process(delta: float) -> void:
	$HealthBar.global_position = Vector2(global_position.x - 64, global_position.y - 64)

func update_health_bars() -> void:
	var expected_number_of_health_bars: int = int((float(current_health) / float(max_health)) * 10.0)
	
	if expected_number_of_health_bars <= 0:
		for child in $HealthBar/HBoxContainer.get_children():
			child.queue_free()
		return
	elif expected_number_of_health_bars < $HealthBar/HBoxContainer.get_child_count():
		while expected_number_of_health_bars < $HealthBar/HBoxContainer.get_child_count():
			$HealthBar/HBoxContainer.get_child(0).queue_free()
			
			await get_tree().physics_frame

func take_damage(amount: int, damage_position: Vector2, direction: Vector2) -> void:
	if $HealthBar.visible == false:
		$HealthBar.visible = true
	
	var damage_effect: CPUParticles2D = Globals.damage_particle_emitter_packed_scene.instantiate()
	add_child(damage_effect)
	damage_effect.global_position = damage_position
	damage_effect.emitting = true
	
	apply_impulse(direction / 2, damage_position)
	
	current_health -= amount
	
	update_health_bars()
	
	if current_health <= 0:
		# Shake the container and see if any items fall off.
		die(damage_position, direction)
		Globals.play_sound_effect("res://assets/sound_effects/GreaterHit.wav", global_position)
	else:
		Globals.play_sound_effect("res://assets/sound_effects/ImpactMini.wav", global_position)
	
	await get_tree().create_timer(damage_effect.lifetime).timeout
	damage_effect.queue_free()

func die(damage_position: Vector2, direction: Vector2) -> void:
	$Sprite2D.visible = false
	$HealthBar.visible = false
	
	call_deferred("set_collision_layer_value", Enums.CollisionLayer.PHYSICAL, false)
	call_deferred("set_collision_layer_value", Enums.CollisionLayer.DAMAGE, false)
	call_deferred("set_collision_mask_value", Enums.CollisionLayer.PHYSICAL, false)
	
	var space: Space = find_parent("Space")
	
	var damage_effect: CPUParticles2D = Globals.damage_particle_emitter_packed_scene.instantiate()
	add_child(damage_effect)
	damage_effect.amount *= 5
	damage_effect.global_position = damage_position
	damage_effect.emitting = true
	
	for cargo_item in cargo_items:
		space.call_deferred("add_cargo_item", cargo_item)
			
		cargo_item.linear_velocity = linear_velocity
		cargo_item.angular_velocity = angular_velocity
		
		cargo_item.global_transform = global_transform
		
		# Add a small random amount to that global transform.
		var random_x: float = randf_range(-SPAWN_OFFSET_RADIUS, SPAWN_OFFSET_RADIUS)
		var random_y: float = randf_range(-SPAWN_OFFSET_RADIUS, SPAWN_OFFSET_RADIUS)
		
		var random_offset: Vector2 = Vector2(random_x, random_y)
		cargo_item.global_position += random_offset
		
		cargo_item.apply_impulse(Vector2(0, 1), Vector2(0, 0))
	
	
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
