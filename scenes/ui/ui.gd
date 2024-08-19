extends CanvasLayer

const MIN_VOLUME: float = 0.0
const MAX_VOLUME: float = 1.0
const VOLUME_INCREMENT: float = 0.1

@onready var unmuted_texture: Texture2D = preload("res://assets/jukebox/sound.png")
@onready var muted_texture: Texture2D = preload("res://assets/jukebox/mute.png")

var current_song_index: int = 0
var muted: bool = false
var paused: bool = false
var playing: bool = false

var space: Space
var hovering_jukebox: bool = false

func _ready() -> void:
	space = find_parent("Space")
	
	play_song()
	
	$JukeBox/VolumeTexture/VSlider.value = db_to_linear(Globals.music_player.volume_db)

#region Jukebox

func _on_juke_box_off_on_button_pressed() -> void:
	if hovering_jukebox == false:
		return
	Globals.stop_music()

func _on_juke_box_previous_button_pressed() -> void:
	if hovering_jukebox == false:
		return
	
	paused = false
	playing = false
	previous_song()

func _on_juke_box_pause_button_pressed() -> void:
	if hovering_jukebox == false:
		return
	
	paused = true
	playing = false
	Globals.pause_music()

func _on_juke_box_play_button_pressed() -> void:
	if hovering_jukebox == false:
		return
	
	play_song()

func _on_juke_box_next_button_pressed() -> void:
	if hovering_jukebox == false:
		return
	
	paused = false
	playing = false
	next_song()

func _on_juke_box_sound_button_pressed() -> void:
	if hovering_jukebox == false:
		return
	if muted:
		$JukeBox/JukeBoxSoundButton.texture_normal = unmuted_texture
		muted = false
		Globals.unmute_music()
	else:
		$JukeBox/JukeBoxSoundButton.texture_normal = muted_texture
		muted = true
		Globals.mute_music()

func play_song() -> void:
	if playing:
		return
	
	playing = true
	
	if paused:
		Globals.unpause_music()
		paused = false
	else:
		Globals.play_music(current_song_index)
		
		var song_name = Globals.music_songs[current_song_index]["song_name"]
		$JukeBox/SongNameLabel.text = song_name

func next_song() -> void:
	if current_song_index == Globals.music_songs.size() - 1:
		current_song_index = 0
	else:
		current_song_index += 1
	
	play_song()

func previous_song() -> void:
	if current_song_index == 0:
		current_song_index = Globals.music_songs.size() - 1
	else:
		current_song_index -= 1
	
	play_song()

func _on_juke_box_mouse_entered() -> void:
	hovering_jukebox = true
	
	if space != null:
		space.hovering_jukebox = true

func _on_juke_box_mouse_exited() -> void:
	# check if the mouse really left the jukebox, because it lies
	var mouse_position: Vector2 = $JukeBox.get_global_mouse_position()
	
	if $JukeBox.get_global_rect().has_point(mouse_position) == false:
		hovering_jukebox = false
		
		if space != null:
			space.hovering_jukebox = false

func _on_volume_down_button_pressed() -> void:
	if hovering_jukebox == false:
		return
	
	var current_volume: float = db_to_linear(Globals.music_player.volume_db)
	if current_volume <= MIN_VOLUME:
		return
	else:
		current_volume -= VOLUME_INCREMENT
		Globals.music_player.volume_db = linear_to_db(current_volume)
		$JukeBox/VolumeTexture/VSlider.value = current_volume

func _on_volume_up_button_pressed() -> void:
	if hovering_jukebox == false:
		return
	
	var current_volume: float = db_to_linear(Globals.music_player.volume_db)
	if current_volume >= MAX_VOLUME:
		return
	else:
		current_volume += VOLUME_INCREMENT
		Globals.music_player.volume_db = linear_to_db(current_volume)
		$JukeBox/VolumeTexture/VSlider.value = current_volume

#endregion Jukebox
