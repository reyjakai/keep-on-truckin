extends Node2D
class_name Space

const MAX_SPEED: float = 240.0
const MAX_SPEED_BARS: int = 12
@onready var amount_per_speed_bar: float
var current_speed_bars: int = 0

var warp_gate: WarpGate

const MAX_ZOOM: float = 5
const MIN_ZOOM: float = 2
const ZOOM_INCREMENT: float = 0.25
const METEOR_YEET_FORCE: int = 100

var seconds_timer: float = 0
var hovering_jukebox: bool:
	get:
		return hovering_jukebox
	set(value):
		$ShipCab/ShipCab.hovering_jukebox = value
		hovering_jukebox = value

@onready var ship_cab: ShipCab = $ShipCab/ShipCab

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	amount_per_speed_bar = MAX_SPEED / MAX_SPEED_BARS
	
	await get_tree().create_timer(2.0).timeout
	Globals.player_money = 1000
	Globals.tutorial_completed = true
	
	if Globals.tutorial_completed == true:
		start_next_day()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	seconds_timer += delta
	if seconds_timer >= 1.0:
		seconds_timer -= 1.0
		
		Globals.update_time(1)
	
	update_ui()
	
	if Input.is_action_just_pressed("spawn_meteors"):
		spawn_meteor_shower(10)
	
	if Input.is_action_just_pressed("zoom_in"):
		$ShipCab/ShipCab/Camera2D.zoom += Vector2(ZOOM_INCREMENT, ZOOM_INCREMENT)
		$ShipCab/ShipCab/Camera2D.zoom = Vector2(clamp($ShipCab/ShipCab/Camera2D.zoom.x, MIN_ZOOM, MAX_ZOOM), clamp($ShipCab/ShipCab/Camera2D.zoom.y, MIN_ZOOM, MAX_ZOOM))
	elif Input.is_action_just_pressed("zoom_out"):
		
		$ShipCab/ShipCab/Camera2D.zoom -= Vector2(ZOOM_INCREMENT, ZOOM_INCREMENT)
		$ShipCab/ShipCab/Camera2D.zoom = Vector2(clamp($ShipCab/ShipCab/Camera2D.zoom.x, MIN_ZOOM, MAX_ZOOM), clamp($ShipCab/ShipCab/Camera2D.zoom.y, MIN_ZOOM, MAX_ZOOM))

#region Resetting

func start_next_day() -> void:
	_fade_out(1.0)
	
	if Globals.tutorial_completed == false:
		Globals.tutorial_completed = true
	
	# All the code needed to reset the entire map.
	_clear_all_objects()
	warp_gate = null
	
	# Play daily dialogue
	

func _clear_all_objects() -> void:
	for child in $SpaceItems.get_children():
		child.queue_free()

func _cleanup_cargo_containers() -> void:
	pass

func _fade_out(time: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property($UI/ScreenFader, "color", Color.BLACK, time)

func _fade_in(time: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property($UI/ScreenFader, "color", Color.TRANSPARENT, time)

#endregion Resetting

#region Spawning

func spawn_meteor_shower(amount: int) -> void:
	# Grab player position + x amount ahead and spawn a bunch of meteors and launch them at the player.
	for i in range(amount):
		var meteor: Meteor = Globals.meteor_packed_scene.instantiate()
		
		$SpaceItems.add_child(meteor)
		
		# Spawn meteors in a random field going random directions well in front of the player
		var spawn_area: Vector2 = Vector2($ShipCab/ShipCab.global_position.x, $ShipCab/ShipCab.global_position.y - 750)
		
		# Meteor randomness
		var random_x: float = randf_range(-150, 150)
		var random_y: float = randf_range(-150, 150)
		
		var random_x_direction: float = randf_range(-0.1, 0.1)
		var target_direction: Vector2 = Vector2(random_x_direction, 1)
		
		var meteor_spawn_position: Vector2 = spawn_area + Vector2(random_x, random_y)
		
		meteor.global_position = meteor_spawn_position
		meteor.apply_impulse(target_direction * 400)

#region Spawning

#region Cargo

func add_cargo_item(cargo_item: CargoItem) -> void:
	$SpaceItems.add_child(cargo_item)

#endregion Cargo

func update_ui() -> void:
	#Figure out how many speed bars we should have.
	var expected_speed_bars: int = int(floor(ship_cab.speed / amount_per_speed_bar))
	
	if expected_speed_bars != current_speed_bars:
		for speed_bar in $UI/SpeedProgressBar/SpeedBars.get_children():
			speed_bar.modulate = "62626276"
		
		if expected_speed_bars >= MAX_SPEED_BARS:
			expected_speed_bars = MAX_SPEED_BARS
		current_speed_bars = expected_speed_bars
		
		# Set the correct number of speed bars
		for i in range(current_speed_bars):
			$UI/SpeedProgressBar/SpeedBars.get_child(i).modulate = Color.WHITE
	
	$UI/SpeedProgressBar/MoneyBox/Label.text = str(Globals.player_money).pad_zeros(5)
	$UI/Control/Info/TimeLeftLabel.text = "Time Left: " + str(Globals.minutes_until_daughter_dies).pad_zeros(2) + ":" + str(Globals.seconds_until_daughter_dies).pad_zeros(2)

func add_money_to_player(amount: int) -> void:
	Globals.player_money += amount
