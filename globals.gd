extends Node

static var laser_pulse_packed_scene: PackedScene = preload("res://scenes/effects/laser_pulse.tscn")
static var meteor_packed_scene: PackedScene = preload("res://scenes/meteor.tscn")
static var damage_particle_emitter_packed_scene: PackedScene = preload("res://scenes/effects/laser_damage_effect.tscn")
static var cargo_item_packed_scene: PackedScene = preload("res://scenes/cargo_items/cargo_item.tscn")

static var warp_gate_packed_scene: PackedScene = preload("res://scenes/cargo_objects/warp_gate.tscn")

static var e_key_texture: Texture2D = preload("res://assets/e_key.png")
static var f_key_texture: Texture2D = preload("res://assets/e_key.png")

var player_money: int = 0
var minutes_until_daughter_dies: int = 10
var seconds_until_daughter_dies: int = 0
var daughter_treatment_amount: int = 500

var tutorial_completed: bool = false

func update_time(seconds: int) -> void:
	if seconds_until_daughter_dies == 0:
		seconds_until_daughter_dies = 59
		minutes_until_daughter_dies -= 1
	
	seconds_until_daughter_dies -= seconds

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	#music_player.bus = "Music"
	
	add_child(music_player)

#region Audio

@onready var music_player: AudioStreamPlayer
var playback_position: float = 0

var music_songs: Array = [
	{
		"song_name": "Keep On Truckin'",
		"song_stream": load("res://assets/music/Keep On Truckin.mp3")
	},
	{
		"song_name": "Beat the Odds",
		"song_stream": load("res://assets/music/Beat The Odds.mp3")
	},
	{
		"song_name": "Critical Cargo",
		"song_stream": load("res://assets/music/Critical Cargo.mp3")
	},
	{
		"song_name": "Dead Weight",
		"song_stream": load("res://assets/music/Dead Weight.mp3")
	},
	{
		"song_name": "Final Frontier",
		"song_stream": load("res://assets/music/Final Frontier.mp3")
	},
	{
		"song_name": "Load of a Lifetime",
		"song_stream": load("res://assets/music/Load of a Lifetime.mp3")
	},
	{
		"song_name": "Race for the Cure",
		"song_stream": load("res://assets/music/Race For The Cure.mp3")
	},
	{
		"song_name": "Stellar Surgery",
		"song_stream": load("res://assets/music/Stellar Surgery.mp3")
	}
]

func play_sound_effect(sound_path: String, position: Vector2) -> void:
	var audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	#audio_player.bus = "SoundEffect"
	add_child(audio_player)
	audio_player.global_position = position
	
	audio_player.stream = load(sound_path)
	audio_player.play()
	await audio_player.finished
	
	audio_player.queue_free()

func play_randomized_sound_effect(sound_path: String, position: Vector2) -> void:
	var audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	#audio_player.bus = "SoundEffect"
	add_child(audio_player)
	audio_player.global_position = position
	
	var pitch_scale: float = randf_range(0.95, 1.05)
	
	audio_player.stream = load(sound_path)
	audio_player.pitch_scale = pitch_scale
	audio_player.play()
	await audio_player.finished
	
	audio_player.queue_free()

func play_music(song_index: int) -> void:
	music_player.stream = music_songs[song_index]["song_stream"]
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func pause_music() -> void:
	playback_position = music_player.get_playback_position()
	music_player.stop()

func unpause_music() -> void:
	music_player.play(playback_position)

func mute_music() -> void:
	music_player.volume_db = linear_to_db(0)

func unmute_music() -> void:
	music_player.volume_db = linear_to_db(1)

#endregion Audio

func get_quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r
