extends RigidBody2D
class_name CargoContainer

var top_connected: bool = false
var hovering: bool = false
var connected_to_cab: bool = false
var space: Space

func _ready() -> void:
	space = find_parent("Space")
	
	$ButtonPrompt.visible = false
	$ChainSprite.visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("disconnect") && hovering:
		toggle_disconnect(true)

func toggle_connect(node: RigidBody2D, affected_area: Area2D) -> void:
	if $TopInteractionArea2D == affected_area:
		if top_connected == false:
			$TopPinJoint.node_a = node.get_path()
			$TopPinJoint.node_b = self.get_path()
			
			top_connected = true
		connected_to_cab = true
	
	# Try to connect the bottom node of this.
	var bottom_areas: Array[Area2D] = $BottomInteractionArea2D.get_overlapping_areas()
	
	if bottom_areas.is_empty() == false:
		for target_area in bottom_areas:
			if target_area.get_parent().has_method("toggle_connect"):
				target_area.get_parent().toggle_connect(self, target_area)
				$ChainSprite.visible = true
				break

func toggle_disconnect(recurse: bool) -> void:
	# Means we're hitting this for the object and still need to tell the other object to disconnect.
	if recurse:
		top_connected = false
		
		$TopPinJoint.node_a = NodePath("")
		$TopPinJoint.node_b = NodePath("")
		
		var connected_areas: Array[Area2D] = $TopInteractionArea2D.get_overlapping_areas()
		
		for area in connected_areas:
			if area.get_parent().has_method("toggle_disconnect"):
				area.get_parent().toggle_disconnect(false)
		
		# Disconnect all downstream cargo containers and mark them as disconnected from cab.
		chain_disconnect_from_cab()
	else:
		$ChainSprite.visible = false

func add_cargo_item(cargo_item: CargoItem) -> bool:
	var added: bool = false
	
	for cargo_item_slot in $CargoItemSlots.get_children():
		if cargo_item_slot.get_child_count() == 0:
			await cargo_item.freeze_cargo_item()
			
			cargo_item.get_parent().remove_child(cargo_item)
			cargo_item_slot.add_child(cargo_item)
			cargo_item.global_transform = cargo_item_slot.global_transform
			
			added = true
			break
	
	if added == false:
		# Grab the next cargo container and try to add it.
		var bottom_areas: Array[Area2D] = $BottomInteractionArea2D.get_overlapping_areas()
		
		if bottom_areas.is_empty() == false:
			for target_area in bottom_areas:
				if target_area.get_parent().has_method("add_cargo_item"):
					added = await target_area.get_parent().add_cargo_item(cargo_item)
					break
	
	return added

func sell_cargo(space_trader: SpaceTrader) -> void:
	for cargo_item_slot in $CargoItemSlots.get_children():
		if cargo_item_slot.get_child_count() > 0:
			var cargo_item: CargoItem = cargo_item_slot.get_child(0)
			
			space_trader.sell_cargo(cargo_item)
	
	# Sell to any attached cargo.
	var target_areas: Array[Area2D] = $BottomInteractionArea2D.get_overlapping_areas()
	
	if target_areas.is_empty() == false:
		for target_area in target_areas:
			if target_area.get_parent().has_method("sell_cargo"):
				target_area.get_parent().sell_cargo(space_trader)

func chain_disconnect_from_cab() -> void:
	connected_to_cab = false
	var connected_areas: Array[Area2D] = $BottomInteractionArea2D.get_overlapping_areas()
	
	if connected_areas.is_empty() == false:
		for area in connected_areas:
			if area.get_parent().has_method("chain_disconnect_from_cab"):
				area.get_parent().chain_disconnect_from_cab()

func slow_down(amount: float) -> void:
	linear_velocity = linear_velocity.lerp(Vector2.ZERO, amount)
	angular_velocity = lerp(angular_velocity, 0.0, amount)
	
	var bottom_areas: Array[Area2D] = $BottomInteractionArea2D.get_overlapping_areas()
	
	if bottom_areas.is_empty() == false:
		for target_area in bottom_areas:
			if target_area.get_parent().has_method("slow_down"):
				target_area.get_parent().slow_down(amount)

#region Combat

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
			space.call_deferred("add_cargo_item", cargo_item)
			
			cargo_item.call_deferred("un_freeze_cargo_item")
			
			await get_tree().physics_frame
			
			cargo_item.linear_velocity = linear_velocity + (direction)
			cargo_item.angular_velocity = angular_velocity + 0.1
			
			cargo_item.global_transform = cargo_item_slot.global_transform

#endregion Combat

# To handle disconnecting
func _on_mouse_entered() -> void:
	if connected_to_cab:
		hovering = true
		$Sprite2D.material.set_shader_parameter("enabled", true)
		
		$ButtonPrompt.visible = true

func _on_mouse_exited() -> void:
	hovering = false
	$Sprite2D.material.set_shader_parameter("enabled", false)
	$ButtonPrompt.visible = false
