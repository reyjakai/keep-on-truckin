extends RigidBody2D
class_name CargoItem

@export var cargo_value: int = 50
const CARGO_ITEM_SIZE: int = 16

func _ready() -> void:
	set_physics_process(false)

func freeze_cargo_item() -> void:
	call_deferred("set_collision_layer_value", Enums.CollisionLayer.ITEMS, false)
	call_deferred("set_collision_mask_value", Enums.CollisionLayer.ITEMS, false)
	
	set_deferred("freeze", true)
	
	await get_tree().physics_frame
	return

func un_freeze_cargo_item() -> void:
	set_deferred("freeze", false)
	
	await get_tree().create_timer(1.0).timeout
	
	call_deferred("set_collision_layer_value", Enums.CollisionLayer.ITEMS, true)
	call_deferred("set_collision_mask_value", Enums.CollisionLayer.ITEMS, true)
	
	return

func sell(ending_point: Vector2) -> void:
	call_deferred("set_collision_layer_value", Enums.CollisionLayer.ITEMS, false)
	call_deferred("set_collision_mask_value", Enums.CollisionLayer.ITEMS, false)
	
	# For yeet to the space trader.
	var random_time: float = randf_range(0.75, 1.5)
	
	var starting_point: Vector2 = global_position
	var random_y: float = randf_range(ending_point.y - 50, ending_point.y + 50)
	
	var center_curve: Vector2 = starting_point.lerp(ending_point, 0.7)
	center_curve.y += random_y
	
	await yeet_item(starting_point, center_curve, ending_point, random_time)
	
	Globals.play_sound_effect("res://assets/sound_effects/GetAPowerUp.wav", global_position)
	queue_free()


#region Yeet Code

var _yeet_starting_position: Vector2
var _yeet_center_curve_position: Vector2
var _yeet_ending_position: Vector2

func yeet_item(starting_position: Vector2, center_curve: Vector2, ending_position: Vector2, time: float) -> CargoItem:
	_yeet_starting_position = starting_position
	_yeet_center_curve_position = center_curve
	_yeet_ending_position = ending_position
	
	var tween = create_tween()
	tween.tween_method(_update_yeet, 0.0, 1.0, time)
	
	await tween.finished
	return self

func _update_yeet(increment: float) -> void:
	self.set_global_position(Globals.get_quadratic_bezier(_yeet_starting_position, _yeet_center_curve_position, _yeet_ending_position, increment))

#endregion Yeet Code
