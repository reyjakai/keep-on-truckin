extends RigidBody2D
class_name ShipCab

const MAX_PARTICLE_SPEED: float = 5.0
const MIN_PARTICLE_SPEED: float = 0.1
const THRUST_FORCE: float = 40000.0
const DAMPING_AMOUNT: float = 0.02
const ROTATION_DAMPING: float = 0.8
var speed: float = 0.0
var rotation_speed = 65.0

@onready var has_lasers: bool = true
var lasers_ready: bool = true

const LASER_COOLDOWN: float = 0.5
var laser_timer: float = 0

var space_scene: Space
var hovering: bool = false
var hovering_jukebox: bool = false

# Handles emitting particles based on how long you've held any movement key down for
var movement_key_pressed: bool = false
var movement_key_timer: float = 0.0

func _ready() -> void:
	$ChainSprite.visible = false
	$DisconnectButtonPrompt.visible = false
	$ButtonPrompt.visible = false
	space_scene = find_parent("Space")
	
	if has_lasers:
		$LaserSprite2D.visible = true

func _physics_process(delta):
	var rotating: bool = false
	var movement_key_previously_pressed: bool = movement_key_pressed
	movement_key_pressed = false
	
	# Regenerate lasers
	if lasers_ready == false:
		laser_timer -= delta
		
		if laser_timer <= 0:
			laser_timer = 0
			lasers_ready = true
	
	# Apply forward thrust
	if Input.is_action_pressed("ui_up"):
		var direction = Vector2(0, -1).rotated(rotation)
		apply_central_force(direction * THRUST_FORCE)
		movement_key_pressed = true
	
	# Handle rotating left and right
	if Input.is_action_pressed("ui_left"):
		apply_torque(-rotation_speed * THRUST_FORCE)
		rotating = true
		movement_key_pressed = true
	elif Input.is_action_pressed("ui_right"):
		apply_torque(rotation_speed * THRUST_FORCE)
		rotating = true
		movement_key_pressed = true
	
	if Input.is_action_pressed("ui_down"):
		var direction = Vector2(0, 1).rotated(rotation)
		apply_central_force(direction * THRUST_FORCE)
		movement_key_pressed = true
	
	if Input.is_action_pressed("stop_ship"):
		slow_down_ship()
	
	if Input.is_action_just_pressed("connect"):
		toggle_connect()
	
	if Input.is_action_pressed("shoot_lasers") && lasers_ready && hovering_jukebox == false:
		shoot_lasers()
	
	if not rotating:
		angular_velocity *= ROTATION_DAMPING
	
	speed = abs(linear_velocity.x) + abs(linear_velocity.y)
	
	if movement_key_pressed && movement_key_previously_pressed:
		if movement_key_timer < MAX_PARTICLE_SPEED:
			movement_key_timer += delta
	elif movement_key_pressed == false:
		if movement_key_timer > 0:
			movement_key_timer -= (delta * 2)
	
	if movement_key_timer >= MAX_PARTICLE_SPEED:
		$SmokeParticles/GPUParticles2D.amount_ratio = 1.0
		$SmokeParticles/GPUParticles2D2.amount_ratio = 1.0
	elif movement_key_timer <= MIN_PARTICLE_SPEED:
		$SmokeParticles/GPUParticles2D.amount_ratio = 0.05
		$SmokeParticles/GPUParticles2D2.amount_ratio = 0.05
	else:
		$SmokeParticles/GPUParticles2D.amount_ratio = movement_key_timer / MAX_PARTICLE_SPEED
		$SmokeParticles/GPUParticles2D2.amount_ratio = movement_key_timer / MAX_PARTICLE_SPEED

#region Shooting

func shoot_lasers() -> void:
	lasers_ready = false
	laser_timer = LASER_COOLDOWN
	
	Globals.play_sound_effect("res://assets/sound_effects/LaserAttackMini.wav", global_position)
	
	for child in $LaserShootingPoints.get_children():
		var laser_pulse: LaserPulse = Globals.laser_pulse_packed_scene.instantiate()
		space_scene.add_child(laser_pulse)
		
		laser_pulse.global_transform = child.global_transform
		
		var direction = Vector2(0, -1).rotated(rotation)
		laser_pulse.apply_impulse(direction * (500.0 + speed))

#endregion Shooting

#region Cargo

func take_damage(_amount: int, damage_position: Vector2, direction: Vector2) -> void:
	var damage_effect: CPUParticles2D = Globals.damage_particle_emitter_packed_scene.instantiate()
	add_child(damage_effect)
	damage_effect.global_position = damage_position
	damage_effect.emitting = true
	
	apply_impulse(direction, damage_position * 20)
	Globals.play_sound_effect("res://assets/sound_effects/ImpactMini.wav", global_position)
	
	# Shake the container and see if any items fall off.
	release_contents(direction)
	
	await get_tree().create_timer(damage_effect.lifetime).timeout
	damage_effect.queue_free()

func release_contents(direction: Vector2) -> void:
	for cargo_item_slot in $CargoItemSlots.get_children():
		if cargo_item_slot.get_child_count() == 0:
			continue
		
		# Roll dice to see if item falls off.
		var rando = randf()
		
		if rando > 0.5:
			# Knock item off of slot.
			var cargo_item: CargoItem = cargo_item_slot.get_child(0)
			
			cargo_item_slot.remove_child(cargo_item)
			space_scene.call_deferred("add_cargo_item", cargo_item)
			
			cargo_item.call_deferred("un_freeze_cargo_item")
			
			await get_tree().physics_frame
			
			cargo_item.linear_velocity = linear_velocity + (direction)
			cargo_item.angular_velocity = angular_velocity + 0.1
			
			cargo_item.global_transform = cargo_item_slot.global_transform

func add_cargo_item(cargo_item: CargoItem) -> void:
	var added: bool = false
	
	for cargo_item_slot in $CargoItemSlots.get_children():
		if cargo_item_slot.get_child_count() == 0:
			await cargo_item.freeze_cargo_item()
			
			cargo_item.get_parent().remove_child(cargo_item)
			cargo_item_slot.add_child(cargo_item)
			cargo_item.global_transform = cargo_item_slot.global_transform
			
			Globals.play_sound_effect("res://assets/sound_effects/GetAPowerUp.wav", global_position)
			added = true
			break
	
	if added == false:
		var target_areas: Array[Area2D] = $InteractionArea2D.get_overlapping_areas()
		
		if target_areas.is_empty() == false:
			for target_area in $InteractionArea2D.get_overlapping_areas():
				if target_area.get_parent().has_method("add_cargo_item"):
					added = await target_area.get_parent().add_cargo_item(cargo_item)
					
					if added:
						Globals.play_sound_effect("res://assets/sound_effects/GetAPowerUp.wav", global_position)
						break

func sell_cargo(space_trader: SpaceTrader) -> void:
	for cargo_item_slot in $CargoItemSlots.get_children():
		if cargo_item_slot.get_child_count() > 0:
			var cargo_item: CargoItem = cargo_item_slot.get_child(0)
			
			space_trader.sell_cargo(cargo_item)
	
	# Sell to any attached cargo.
	var target_areas: Array[Area2D] = $InteractionArea2D.get_overlapping_areas()
	
	if target_areas.is_empty() == false:
		for target_area in target_areas:
			if target_area.get_parent() is CargoContainer:
				target_area.get_parent().sell_cargo(space_trader)

#endregion Cargo

#region Connecting

func _on_interaction_area_2d_area_entered(area: Area2D) -> void:
	if area.get_collision_layer_value(Enums.CollisionLayer.CONNECTION):
		$ButtonPrompt/Label.text = "connect"
	elif area.get_collision_layer_value(Enums.CollisionLayer.TRADING):
		$ButtonPrompt/Label.text = "sell all items"
	$ButtonPrompt.visible = true

func _on_interaction_area_2d_area_exited(_area: Area2D) -> void:
	$ButtonPrompt.visible = false

func toggle_connect() -> void:
	var target_areas: Array[Area2D] = $InteractionArea2D.get_overlapping_areas()
	
	if target_areas.is_empty() == false:
		for target_area in target_areas:
			if target_area.get_parent().has_method("toggle_connect"):
				target_area.get_parent().toggle_connect(self, target_area)
				$ChainSprite.visible = true
				$ButtonPrompt.visible = false
			
			if target_area.get_parent() is SpaceTrader:
				var space_trader: SpaceTrader = target_area.get_parent()
				
				# loop through connected cargo containers and sell every item.
				sell_cargo(space_trader)

func toggle_disconnect(_recurse: bool) -> void:
	$ChainSprite.visible = false
	$ButtonPrompt.visible = true

# Handle item pickup.
func _on_body_entered(body: Node) -> void:
	if body is CargoItem:
		add_cargo_item(body)

#endregion Connecting

func slow_down_ship() -> void:
	linear_velocity = linear_velocity.lerp(Vector2.ZERO, DAMPING_AMOUNT)
	angular_velocity = lerp(angular_velocity, 0.0, DAMPING_AMOUNT)
	
	slow_down_containers(DAMPING_AMOUNT)

func slow_down_containers(amount: float) -> void:
	var target_areas: Array[Area2D] = $InteractionArea2D.get_overlapping_areas()
	
	if target_areas.is_empty() == false:
		for target_area in $InteractionArea2D.get_overlapping_areas():
			if target_area.get_parent().has_method("slow_down"):
				target_area.get_parent().slow_down(amount)

func _on_mouse_entered() -> void:
	hovering = true
	#$Sprite2D.material.set_shader_parameter("enabled", true)
	
	#if $ButtonPrompt.visible == false:
		#$DisconnectButtonPrompt.visible = true

func _on_mouse_exited() -> void:
	hovering = false
	#$Sprite2D.material.set_shader_parameter("enabled", false)
	#$DisconnectButtonPrompt.visible = false
