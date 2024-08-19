extends Control

var daughter_visible: bool = true
var reading: bool = false
var boop_count: int = 0
const BOOPS_MAX_COUNT: int = 6
const TIMER_SPEED = 0.03

func _ready() -> void:
	start_dialogue("res://assets/characters/Space-Daughter-Sickly-1-Hologram.png")
	await read_dialogue("Ms. Karen", "Sup, idiot. Got my money? You owe us $500 or we'll mail you her ashes in a plastic bag.", false)
	await read_dialogue("Space Daughter", "Daddy, is that you?", true)
	await read_dialogue("Ms. Karen", "Hey there, sweetie. Yep, this is your amazing dad! What a brave, powerful man he is.", true)
	await read_dialogue("Space Daughter", "Daddy, I can't feel my legs. Is that supposed to happen? I can't wait until we can go running together!", true)
	await read_dialogue("Ms. Karen", "Don't worry, honey. Go back to the corner.", true)
	await read_dialogue("Ms. Karen", "$500. Don't forget it, idiot.", false)
	end_dialogue()

func _physics_process(delta: float) -> void:
	if reading:
		boop_count += 1
		
		if boop_count >= BOOPS_MAX_COUNT:
			boop_count = 0
			Globals.play_randomized_sound_effect("res://assets/sound_effects/OptionSelect.wav", global_position)

func start_dialogue(daughter_texture_path: String) -> void:
	$SpaceDaughter.texture = load(daughter_texture_path)
	Globals.play_sound_effect("res://assets/sound_effects/CloningScanningUnit.wav", global_position)

func end_dialogue() -> void:
	Globals.play_sound_effect("res://assets/sound_effects/CloningScanningUnit.wav", global_position)
	
	var tween: Tween = create_tween()
	tween.tween_property($Fader, "color", Color.TRANSPARENT, 1.0)
	
	await tween.finished
	queue_free()

func read_dialogue(display_name: String, line: String, daughter_visible: bool) -> void:
	if daughter_visible:
		await show_daughter()
	else:
		await hide_daughter()
	
	$Dialogue/CharacterNameLabel/Label.text = display_name
	$Dialogue/Label.text = line
	
	var dialogue_length = line.length() * TIMER_SPEED
	$Dialogue/Label.visible_ratio = 0.0
	
	var dialogue_tween: Tween = create_tween()
	dialogue_tween.tween_property($Dialogue/Label, "visible_ratio", 1.0, dialogue_length)
	
	reading = true
	await dialogue_tween.finished
	reading = false
	await get_tree().create_timer(2.0).timeout
	
	return

func hide_daughter() -> void:
	if daughter_visible:
		daughter_visible = false
		var tween: Tween = create_tween()
		tween.tween_property($SpaceDaughter, "modulate", Color.TRANSPARENT, 1.0)
		
		await tween.finished
	else:
		await get_tree().create_timer(1.0).timeout

func show_daughter() -> void:
	if daughter_visible == false:
		daughter_visible = true
		var tween: Tween = create_tween()
		tween.tween_property($SpaceDaughter, "modulate", Color.WHITE, 1.0)
		
		await tween.finished
	else:
		await get_tree().create_timer(1.0).timeout
