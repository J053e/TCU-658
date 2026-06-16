extends Node

const SAVE_PATH := "user://savegame.json"
const CONTENT_PATH := "res://data/game_content.json"
const BACKGROUND_MANIFEST_PATH := "res://data/backgrounds_manifest.json"
const EXTERNAL_CONTENT_FEATURE := "editable_content"
const EXTERNAL_CONTENT_DIR := "content"
const EXTERNAL_DATA_FILES := [
	"school_gate_quiz.json",
	"classroom_read_listen_click.json",
	"classroom_language_quiz.json",
	"meet_choose_question.json",
	"meet_politeness_fix.json",
	"my_school_card_label_classroom.json"
]
const GLOBAL_ICONS_DIR := "res://assets/branding/global_icons"
const CLICK_SFX_PATH := "res://assets/audio/sfx/ui_click.wav"
const ANSWER_CORRECT_SFX_PATH := "res://assets/audio/sfx/answer_correct.wav"
const ANSWER_INCORRECT_SFX_PATH := "res://assets/audio/sfx/answer_incorrect.wav"
const MENU_MUSIC_PATH := "res://assets/audio/music_raw/menu_theme.audio"
const ZONE_MUSIC_PATH := "res://assets/audio/music_raw/zone_theme.audio"
const VICTORY_FANFARE_PATH := "res://assets/audio/music_raw/victory_fanfare.audio"
const MUSIC_CONTEXT_MENU := "menu"
const MUSIC_CONTEXT_ZONE := "zone"
const MUSIC_CONTEXT_VICTORY := "victory"
const DEFAULT_MUSIC_VOLUME := 0.20
const DEFAULT_SFX_VOLUME := 0.56
const DEFAULT_VOICE_VOLUME := 0.90
const ZONE_BADGE_PATHS := {
	"school_gate": "res://assets/ui/badges/medal_01.png",
	"classroom_survival": "res://assets/ui/badges/medal_02.png",
	"meet_classmates": "res://assets/ui/badges/medal_03.png",
	"my_school_card": "res://assets/ui/badges/medal_04.png",
	"final_passport": "res://assets/ui/badges/medal_05.png"
}
const ZONE_CHALLENGE_REQUIREMENTS := {
	"classroom_survival": ["classroom_read_listen_click", "classroom_language"],
	"meet_classmates": ["meet_order_dialogue", "meet_choose_question", "meet_politeness_fix"],
	"my_school_card": ["my_school_card_fill_profile", "my_school_card_label_classroom", "my_school_card_personal_sentences"],
	"final_passport": ["final_passport_build_intro", "final_passport_read_passport"]
}
const ZONE_BADGE_FEEDBACK := {
	"school_gate": "Great!\nYou can greet people at school!",
	"classroom_survival": "Great!\nYou can understand simple classroom language!",
	"meet_classmates": "Great!\nYou can start short conversations now.",
	"my_school_card": "Great!\nYou can share your school profile in English!",
	"final_passport": "Great!\nYou completed your English Passport!"
}

var content := {}
var current_zone_id := ""
var stamps := {}
var profile := {
	"name": "",
	"last_name": "",
	"age": "",
	"grade": "seventh",
	"country": "Costa Rica",
	"province": ""
}
var profile_setup_done: bool = false
var challenge_results: Dictionary = {}
var pending_badge_popups: Dictionary = {}
var ui_click_player: AudioStreamPlayer
var answer_sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var fanfare_player: AudioStreamPlayer
var answer_correct_stream: AudioStream
var answer_incorrect_stream: AudioStream
var menu_music_stream: AudioStream
var zone_music_stream: AudioStream
var victory_fanfare_stream: AudioStream
var current_music_context := ""
var pending_music_after_fanfare := ""
var music_volume_linear := DEFAULT_MUSIC_VOLUME
var sfx_volume_linear := DEFAULT_SFX_VOLUME
var voice_volume_linear := DEFAULT_VOICE_VOLUME
var voice_players: Array[AudioStreamPlayer] = []
var audio_settings_layer: CanvasLayer
var pretty_font: SystemFont
var background_manifest: Dictionary = {}
var is_scene_transitioning: bool = false

func _ready() -> void:
	load_content()
	load_background_manifest()
	_initialize_stamps()
	load_progress()
	_initialize_fonts()
	_initialize_ui_sfx()
	_initialize_answer_sfx()
	_initialize_music()
	call_deferred("apply_music_for_current_scene")

func load_json_data(res_data_path: String, allow_external_override: bool = true) -> Dictionary:
	var path := res_data_path
	if allow_external_override:
		var external_path := get_external_data_path(res_data_path)
		if external_path != "" and FileAccess.file_exists(external_path):
			path = external_path

	if not FileAccess.file_exists(path):
		push_error("JSON data file not found: " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open JSON data file: " + path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON data file: " + path)
		return {}

	return parsed as Dictionary

func get_external_data_path(res_data_path: String) -> String:
	if not is_external_content_enabled():
		return ""
	if not res_data_path.begins_with("res://data/"):
		return ""
	var file_name := res_data_path.get_file()
	if not EXTERNAL_DATA_FILES.has(file_name):
		return ""
	return get_external_content_root().path_join("data").path_join(file_name)

func is_external_content_enabled() -> bool:
	var enabled_from_project := bool(ProjectSettings.get_setting("application/config/use_external_content", false))
	return OS.has_feature(EXTERNAL_CONTENT_FEATURE) or enabled_from_project

func get_external_content_root() -> String:
	var configured := String(ProjectSettings.get_setting("application/config/external_content_dir", EXTERNAL_CONTENT_DIR))
	if configured.is_absolute_path():
		return configured

	var base_dir := ""
	if OS.has_feature("editor"):
		base_dir = ProjectSettings.globalize_path("res://")
	else:
		base_dir = OS.get_executable_path().get_base_dir()
	if base_dir == "":
		base_dir = ProjectSettings.globalize_path("res://")
	return base_dir.path_join(configured)

func resolve_content_path(path: String) -> String:
	var clean_path := path.strip_edges()
	if clean_path.begins_with("content://"):
		var relative_path := clean_path.substr("content://".length()).replace("\\", "/")
		return get_external_content_root().path_join(relative_path)
	return clean_path

func load_texture_resource(path: String) -> Texture2D:
	var resolved_path := resolve_content_path(path)
	if resolved_path == "":
		return null
	if resolved_path.begins_with("res://"):
		if not ResourceLoader.exists(resolved_path):
			return null
		var loaded := load(resolved_path)
		if loaded is Texture2D:
			return loaded
		return null

	if not FileAccess.file_exists(resolved_path):
		return null
	var image := Image.new()
	var err := image.load(resolved_path)
	if err != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func load_audio_resource(path: String, loop_stream: bool = false) -> AudioStream:
	var resolved_path := resolve_content_path(path)
	if resolved_path == "":
		return null
	for candidate: String in _audio_path_candidates(resolved_path):
		var stream := _load_audio_stream(candidate, loop_stream)
		if stream != null:
			return stream
	return null

func load_background_manifest() -> void:
	background_manifest.clear()
	if not FileAccess.file_exists(BACKGROUND_MANIFEST_PATH):
		return
	var file := FileAccess.open(BACKGROUND_MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		background_manifest = parsed as Dictionary

func _initialize_fonts() -> void:
	pretty_font = SystemFont.new()
	pretty_font.font_names = PackedStringArray([
		"Trebuchet MS",
		"Segoe UI",
		"Calibri",
		"Verdana"
	])

func _initialize_ui_sfx() -> void:
	ui_click_player = AudioStreamPlayer.new()
	ui_click_player.name = "UIClickPlayer"
	if ResourceLoader.exists(CLICK_SFX_PATH):
		ui_click_player.stream = load(CLICK_SFX_PATH)
	add_child(ui_click_player)
	_apply_sfx_volume()

func _initialize_answer_sfx() -> void:
	answer_sfx_player = AudioStreamPlayer.new()
	answer_sfx_player.name = "AnswerSFXPlayer"
	add_child(answer_sfx_player)

	answer_correct_stream = _load_audio_stream(ANSWER_CORRECT_SFX_PATH, false)
	answer_incorrect_stream = _load_audio_stream(ANSWER_INCORRECT_SFX_PATH, false)
	_apply_sfx_volume()

func _initialize_music() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)

	fanfare_player = AudioStreamPlayer.new()
	fanfare_player.name = "VictoryFanfarePlayer"
	fanfare_player.finished.connect(_on_victory_fanfare_finished)
	add_child(fanfare_player)

	menu_music_stream = _load_audio_stream(MENU_MUSIC_PATH, true)
	zone_music_stream = _load_audio_stream(ZONE_MUSIC_PATH, true)
	victory_fanfare_stream = _load_audio_stream(VICTORY_FANFARE_PATH, false)
	_apply_music_volume()

func play_answer_sfx(is_correct: bool) -> void:
	if answer_sfx_player == null:
		return
	var selected_stream: AudioStream = answer_correct_stream if is_correct else answer_incorrect_stream
	if selected_stream == null:
		return
	answer_sfx_player.stop()
	answer_sfx_player.stream = selected_stream
	answer_sfx_player.play()

func set_music_volume(value: float, persist: bool = true) -> void:
	music_volume_linear = clampf(value, 0.0, 1.0)
	_apply_music_volume()
	if persist:
		save_progress()

func set_sfx_volume(value: float, persist: bool = true) -> void:
	sfx_volume_linear = clampf(value, 0.0, 1.0)
	_apply_sfx_volume()
	if persist:
		save_progress()

func set_voice_volume(value: float, persist: bool = true) -> void:
	voice_volume_linear = clampf(value, 0.0, 1.0)
	_apply_voice_volume()
	if persist:
		save_progress()

func register_voice_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	if not voice_players.has(player):
		voice_players.append(player)
	player.volume_db = _linear_volume_to_db(voice_volume_linear)

func unregister_voice_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	voice_players.erase(player)

func speak_voice_text(text: String, voice_id: String) -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	DisplayServer.tts_stop()
	var volume := clampi(roundi(voice_volume_linear * 100.0), 0, 100)
	DisplayServer.tts_speak(text, voice_id, volume)

func _apply_music_volume() -> void:
	var volume_db := _linear_volume_to_db(music_volume_linear)
	if music_player != null:
		music_player.volume_db = volume_db
	if fanfare_player != null:
		fanfare_player.volume_db = volume_db

func _apply_sfx_volume() -> void:
	var volume_db := _linear_volume_to_db(sfx_volume_linear)
	if ui_click_player != null:
		ui_click_player.volume_db = volume_db
	if answer_sfx_player != null:
		answer_sfx_player.volume_db = volume_db

func _apply_voice_volume() -> void:
	var volume_db := _linear_volume_to_db(voice_volume_linear)
	for i in range(voice_players.size() - 1, -1, -1):
		var player := voice_players[i]
		if player == null or not is_instance_valid(player):
			voice_players.remove_at(i)
			continue
		player.volume_db = volume_db

func _linear_volume_to_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(value)

func play_menu_music() -> void:
	if current_music_context == MUSIC_CONTEXT_VICTORY and fanfare_player != null and fanfare_player.playing:
		pending_music_after_fanfare = MUSIC_CONTEXT_MENU
		return
	_play_loop_music(MUSIC_CONTEXT_MENU, menu_music_stream)

func play_zone_music() -> void:
	pending_music_after_fanfare = ""
	if fanfare_player != null:
		fanfare_player.stop()
	_play_loop_music(MUSIC_CONTEXT_ZONE, zone_music_stream)

func play_victory_music() -> void:
	if current_music_context == MUSIC_CONTEXT_VICTORY and fanfare_player != null and fanfare_player.playing:
		return
	current_music_context = MUSIC_CONTEXT_VICTORY
	pending_music_after_fanfare = MUSIC_CONTEXT_MENU
	if music_player != null:
		music_player.stop()
	if victory_fanfare_stream == null:
		current_music_context = ""
		play_menu_music()
		return
	fanfare_player.stop()
	fanfare_player.stream = victory_fanfare_stream
	fanfare_player.play()

func apply_music_for_current_scene() -> void:
	var current := get_tree().current_scene
	if current == null:
		return
	apply_music_for_scene(current.scene_file_path)

func apply_music_for_scene(scene_path: String) -> void:
	var scene_file := scene_path.get_file()
	if scene_file == "MainMenu.tscn" or scene_file == "CreditsScreen.tscn":
		play_menu_music()
	elif scene_file == "FinalScreen.tscn":
		if all_zones_completed():
			play_victory_music()
		else:
			play_zone_music()
	else:
		play_zone_music()

func _play_loop_music(context: String, stream: AudioStream) -> void:
	if music_player == null:
		return
	if current_music_context == context and music_player.playing:
		return
	if stream == null:
		current_music_context = ""
		music_player.stop()
		return
	current_music_context = context
	music_player.stop()
	music_player.stream = stream
	music_player.play()

func _on_victory_fanfare_finished() -> void:
	if pending_music_after_fanfare == MUSIC_CONTEXT_MENU:
		pending_music_after_fanfare = ""
		current_music_context = ""
		play_menu_music()

func _load_audio_stream(path: String, loop_stream: bool) -> AudioStream:
	var stream: AudioStream = null
	var bytes := PackedByteArray()

	if FileAccess.file_exists(path):
		bytes = FileAccess.get_file_as_bytes(path)
		if _is_mp3_data(bytes):
			stream = AudioStreamMP3.load_from_buffer(bytes)
		elif _is_ogg_data(bytes):
			stream = AudioStreamOggVorbis.load_from_buffer(bytes)
		elif _is_wav_data(bytes):
			stream = _load_wav_from_bytes(bytes)

	if stream == null and bytes.is_empty() and ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is AudioStream:
			stream = loaded

	_configure_stream_loop(stream, loop_stream)
	return stream

func _audio_path_candidates(audio_path: String) -> Array[String]:
	var candidates: Array[String] = [audio_path]
	var base := audio_path.get_basename()
	for extension: String in [".audio", ".ogg", ".mp3", ".wav"]:
		var candidate: String = base + extension
		if not candidates.has(candidate):
			candidates.append(candidate)
	return candidates

func _configure_stream_loop(stream: AudioStream, loop_stream: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop_stream
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop_stream
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED

func _is_mp3_data(bytes: PackedByteArray) -> bool:
	if bytes.size() < 3:
		return false
	var header := _read_ascii(bytes, 0, 3)
	return header == "ID3" or (bytes[0] == 0xFF and (bytes[1] & 0xE0) == 0xE0)

func _is_ogg_data(bytes: PackedByteArray) -> bool:
	return bytes.size() >= 4 and _read_ascii(bytes, 0, 4) == "OggS"

func _is_wav_data(bytes: PackedByteArray) -> bool:
	return bytes.size() >= 12 and _read_ascii(bytes, 0, 4) == "RIFF" and _read_ascii(bytes, 8, 4) == "WAVE"

func _load_wav_from_bytes(bytes: PackedByteArray) -> AudioStreamWAV:
	if not _is_wav_data(bytes):
		return null

	var audio_format := 0
	var channels := 1
	var sample_rate := 44100
	var bits_per_sample := 16
	var data := PackedByteArray()
	var has_fmt := false
	var offset := 12

	while offset + 8 <= bytes.size():
		var chunk_id := _read_ascii(bytes, offset, 4)
		var chunk_size := _read_u32_le(bytes, offset + 4)
		var chunk_start := offset + 8
		var chunk_end := mini(chunk_start + chunk_size, bytes.size())

		if chunk_id == "fmt " and chunk_size >= 16:
			audio_format = _read_u16_le(bytes, chunk_start)
			channels = _read_u16_le(bytes, chunk_start + 2)
			sample_rate = _read_u32_le(bytes, chunk_start + 4)
			bits_per_sample = _read_u16_le(bytes, chunk_start + 14)
			has_fmt = true
		elif chunk_id == "data":
			data = bytes.slice(chunk_start, chunk_end)

		offset = chunk_end + int(chunk_size % 2)

	if not has_fmt or data.is_empty() or audio_format != 1:
		return null

	var wav := AudioStreamWAV.new()
	wav.mix_rate = sample_rate
	wav.stereo = channels > 1
	if bits_per_sample == 8:
		wav.format = AudioStreamWAV.FORMAT_8_BITS
	elif bits_per_sample == 16:
		wav.format = AudioStreamWAV.FORMAT_16_BITS
	else:
		return null
	wav.data = data
	return wav

func _read_ascii(bytes: PackedByteArray, offset: int, length: int) -> String:
	var text := ""
	for i in range(length):
		if offset + i >= bytes.size():
			break
		text += char(bytes[offset + i])
	return text

func _read_u16_le(bytes: PackedByteArray, offset: int) -> int:
	if offset + 1 >= bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)

func _read_u32_le(bytes: PackedByteArray, offset: int) -> int:
	if offset + 3 >= bytes.size():
		return 0
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)

func load_content() -> void:
	if not FileAccess.file_exists(CONTENT_PATH):
		push_error("Missing content file: " + CONTENT_PATH)
		return

	var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open content file: " + CONTENT_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON content.")
		return
	content = parsed as Dictionary

func _initialize_stamps() -> void:
	stamps.clear()
	for zone in get_zones():
		stamps[zone.get("id", "")] = false

func get_zones() -> Array:
	return content.get("zones", [])

func get_zone(zone_id: String) -> Dictionary:
	for zone in get_zones():
		if zone.get("id", "") == zone_id:
			return zone
	return {}

func completed_count() -> int:
	var total := 0
	for key in stamps.keys():
		if stamps[key]:
			total += 1
	return total

func total_stamps() -> int:
	return stamps.size()

func is_zone_completed(zone_id: String) -> bool:
	return stamps.get(zone_id, false)

func mark_zone_complete(zone_id: String) -> void:
	if stamps.has(zone_id):
		stamps[zone_id] = true

func all_zones_completed() -> bool:
	return completed_count() == total_stamps() and total_stamps() > 0

func reset_progress() -> void:
	_initialize_stamps()
	challenge_results.clear()
	pending_badge_popups.clear()
	current_zone_id = ""
	profile = {
		"name": "",
		"last_name": "",
		"age": "",
		"grade": "seventh",
		"country": "Costa Rica",
		"province": ""
	}
	profile_setup_done = false
	save_progress()

func save_progress() -> void:
	var payload := {
		"stamps": stamps,
		"profile": profile,
		"profile_setup_done": profile_setup_done,
		"challenge_results": challenge_results,
		"pending_badge_popups": pending_badge_popups,
		"music_volume": music_volume_linear,
		"sfx_volume": sfx_volume_linear,
		"voice_volume": voice_volume_linear
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to save progress at: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(payload))

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var payload: Variant = JSON.parse_string(file.get_as_text())
	if typeof(payload) != TYPE_DICTIONARY:
		return

	var payload_dict: Dictionary = payload as Dictionary
	if payload_dict.has("stamps") and typeof(payload_dict["stamps"]) == TYPE_DICTIONARY:
		for key in payload_dict["stamps"].keys():
			if stamps.has(key):
				stamps[key] = payload_dict["stamps"][key]
	if payload_dict.has("profile") and typeof(payload_dict["profile"]) == TYPE_DICTIONARY:
		for key in payload_dict["profile"].keys():
			if profile.has(key):
				profile[key] = payload_dict["profile"][key]
		# Backward compatibility for older saves that used "town".
		if String(profile.get("province", "")).strip_edges() == "" and payload_dict["profile"].has("town"):
			profile["province"] = String(payload_dict["profile"]["town"])
	if payload_dict.has("profile_setup_done"):
		profile_setup_done = bool(payload_dict["profile_setup_done"])
	if payload_dict.has("challenge_results") and typeof(payload_dict["challenge_results"]) == TYPE_DICTIONARY:
		challenge_results = payload_dict["challenge_results"].duplicate(true)
	if payload_dict.has("pending_badge_popups") and typeof(payload_dict["pending_badge_popups"]) == TYPE_DICTIONARY:
		pending_badge_popups = payload_dict["pending_badge_popups"].duplicate(true)
	if payload_dict.has("music_volume"):
		music_volume_linear = clampf(float(payload_dict["music_volume"]), 0.0, 1.0)
	if payload_dict.has("sfx_volume"):
		sfx_volume_linear = clampf(float(payload_dict["sfx_volume"]), 0.0, 1.0)
	if payload_dict.has("voice_volume"):
		voice_volume_linear = clampf(float(payload_dict["voice_volume"]), 0.0, 1.0)

func has_challenge_result(challenge_id: String) -> bool:
	var result := get_challenge_result(challenge_id)
	return not result.is_empty() and int(result.get("attempts", 0)) > 0

func get_challenge_result(challenge_id: String) -> Dictionary:
	if challenge_results.has(challenge_id) and typeof(challenge_results[challenge_id]) == TYPE_DICTIONARY:
		return challenge_results[challenge_id]
	return {}

func record_challenge_result(challenge_id: String, correct_answers: int, total_questions: int, pass_ratio: float) -> Dictionary:
	var safe_total := maxi(total_questions, 1)
	var safe_correct := clampi(correct_answers, 0, safe_total)
	var safe_ratio := clampf(pass_ratio, 0.0, 1.0)
	var previous := get_challenge_result(challenge_id)

	var previous_best := int(previous.get("best_correct", -1))
	var best_correct := safe_correct if safe_correct > previous_best else previous_best
	if previous_best < 0:
		best_correct = safe_correct

	var attempts := int(previous.get("attempts", 0)) + 1
	var passed_now := safe_correct >= int(ceil(float(safe_total) * safe_ratio))
	var passed := bool(previous.get("passed", false)) or passed_now

	var result := {
		"attempts": attempts,
		"best_correct": best_correct,
		"total_questions": safe_total,
		"pass_ratio": safe_ratio,
		"passed": passed,
		"last_correct": safe_correct
	}
	challenge_results[challenge_id] = result
	save_progress()
	return result

func unlock_zone_badge(zone_id: String) -> bool:
	if zone_id == "" or not stamps.has(zone_id):
		return false
	if is_zone_completed(zone_id):
		return false
	mark_zone_complete(zone_id)
	pending_badge_popups[zone_id] = true
	save_progress()
	return true

func update_zone_badge_from_requirements(zone_id: String) -> bool:
	if not ZONE_CHALLENGE_REQUIREMENTS.has(zone_id):
		return false
	if is_zone_completed(zone_id):
		return false
	var requirements: Array = ZONE_CHALLENGE_REQUIREMENTS[zone_id]
	for challenge in requirements:
		var challenge_id := String(challenge)
		var result := get_challenge_result(challenge_id)
		if result.is_empty() or not bool(result.get("passed", false)):
			return false
	return unlock_zone_badge(zone_id)

func has_pending_badge_popup(zone_id: String) -> bool:
	return bool(pending_badge_popups.get(zone_id, false))

func consume_badge_popup(zone_id: String) -> void:
	if pending_badge_popups.has(zone_id):
		pending_badge_popups.erase(zone_id)
		save_progress()

func get_badge_path(zone_id: String) -> String:
	return String(ZONE_BADGE_PATHS.get(zone_id, ""))

func show_badge_popup_or_continue(root: Control, zone_id: String, on_continue: Callable) -> void:
	if not has_pending_badge_popup(zone_id):
		if on_continue.is_valid():
			on_continue.call()
		return
	if root == null or not is_instance_valid(root):
		return

	var layer := CanvasLayer.new()
	layer.layer = 300
	root.add_child(layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 400)
	panel.add_theme_stylebox_override("panel", _medal_popup_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Congratulations!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_label(title, 38, true)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "You earned a new medal.\n" + String(ZONE_BADGE_FEEDBACK.get(zone_id, "Keep using your English skills!"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	style_label(subtitle, 24, false)
	content.add_child(subtitle)

	var badge := TextureRect.new()
	badge.custom_minimum_size = Vector2(156, 156)
	badge.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var badge_path := get_badge_path(zone_id)
	if badge_path != "" and ResourceLoader.exists(badge_path):
		badge.texture = load(badge_path)
	content.add_child(badge)

	var ok_button := Button.new()
	ok_button.text = "Great!"
	ok_button.custom_minimum_size = Vector2(220, 68)
	style_menu_button(ok_button, "green")
	content.add_child(ok_button)

	ok_button.pressed.connect(func() -> void:
		consume_badge_popup(zone_id)
		if is_instance_valid(layer):
			layer.queue_free()
		if all_zones_completed():
			change_scene_with_transition("res://scenes/FinalScreen.tscn")
			return
		if on_continue.is_valid():
			on_continue.call()
	)

func show_answer_feedback_popup(root: Control, feedback_text: String, is_correct: bool, on_continue: Callable) -> void:
	if root == null or not is_instance_valid(root):
		if on_continue.is_valid():
			on_continue.call()
		return
	play_answer_sfx(is_correct)

	var layer := CanvasLayer.new()
	layer.layer = 290
	root.add_child(layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.48)
	dim.modulate.a = 0.0
	layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 300)
	panel.add_theme_stylebox_override("panel", _answer_feedback_popup_style(is_correct))
	panel.scale = Vector2(0.82, 0.82)
	panel.modulate.a = 0.0
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var content_box := VBoxContainer.new()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.add_theme_constant_override("separation", 12)
	margin.add_child(content_box)

	var icon := Label.new()
	icon.text = "\u2713" if is_correct else "X"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_override("font", pretty_font)
	icon.add_theme_font_size_override("font_size", 74)
	icon.add_theme_color_override("font_color", Color(0.60, 1.0, 0.58) if is_correct else Color(1.0, 0.48, 0.48))
	icon.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	icon.add_theme_constant_override("outline_size", 5)
	content_box.add_child(icon)

	var message := Label.new()
	message.text = feedback_text
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(430, 72)
	style_label(message, 26, true)
	content_box.add_child(message)

	var continue_button := Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(220, 64)
	style_menu_button(continue_button, "green" if is_correct else "orange")
	content_box.add_child(continue_button)

	continue_button.pressed.connect(func() -> void:
		if is_instance_valid(layer):
			layer.queue_free()
		if on_continue.is_valid():
			on_continue.call()
	)

	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim, "modulate:a", 1.0, 0.16)
	tween.tween_property(panel, "modulate:a", 1.0, 0.16)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _answer_feedback_popup_style(is_correct: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.23, 0.98)
	sb.border_color = Color(0.62, 1.0, 0.58, 1.0) if is_correct else Color(1.0, 0.48, 0.48, 1.0)
	sb.set_border_width_all(4)
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_right = 22
	sb.corner_radius_bottom_left = 22
	sb.shadow_color = Color(0, 0, 0, 0.40)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	return sb

func _medal_popup_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.11, 0.25, 0.97)
	sb.border_color = Color(0.96, 0.91, 0.43, 1.0)
	sb.set_border_width_all(4)
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_right = 20
	sb.corner_radius_bottom_left = 20
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 2)
	return sb

func decorate_screen(root: Control, background_path: String = "") -> void:
	_add_background(root, background_path)
	_add_global_icons(root)

func _add_background(root: Control, background_path: String) -> void:
	if background_path == "" or not ResourceLoader.exists(background_path):
		return
	var texture: Texture2D = load(background_path)
	if texture == null:
		return
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.layout_mode = 1
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = texture
	if root.scene_file_path.get_file() == "MainMenu.tscn":
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		_fit_cover_background(bg, texture, root)
		root.resized.connect(func() -> void:
			_fit_cover_background(bg, texture, root)
		)
		call_deferred("_fit_cover_background", bg, texture, root)
	else:
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(bg)
	root.move_child(bg, 0)

func _fit_cover_background(bg: TextureRect, texture: Texture2D, root: Control) -> void:
	if bg == null or texture == null or root == null:
		return
	if not is_instance_valid(bg) or not is_instance_valid(root):
		return
	var target_size := root.size
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		target_size = get_viewport().get_visible_rect().size
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or target_size.x <= 0.0 or target_size.y <= 0.0:
		return
	var scale := maxf(target_size.x / texture_size.x, target_size.y / texture_size.y)
	var scaled_size := Vector2(ceil(texture_size.x * scale) + 2.0, ceil(texture_size.y * scale) + 2.0)
	bg.position = ((target_size - scaled_size) * 0.5).floor()
	bg.size = scaled_size

func _add_global_icons(root: Control) -> void:
	var overlay := Control.new()
	overlay.name = "GlobalBrandingOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	var icon_box := HBoxContainer.new()
	icon_box.name = "GlobalIcons"
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_theme_constant_override("separation", 10)
	var is_main_menu := root.scene_file_path.get_file() == "MainMenu.tscn"
	var icon_margin := 22 if is_main_menu else 12
	icon_box.anchor_left = 0.0
	icon_box.anchor_right = 0.0
	icon_box.offset_left = icon_margin
	icon_box.offset_top = icon_margin
	icon_box.offset_right = icon_margin + 320
	icon_box.offset_bottom = icon_margin + 84
	overlay.add_child(icon_box)

	var icon_paths := [
		"%s/tcu658.png" % GLOBAL_ICONS_DIR,
		"%s/elm.png" % GLOBAL_ICONS_DIR,
		_get_ucr_icon_path()
	]

	for path in icon_paths:
		if path == "" or not ResourceLoader.exists(path):
			continue
		var texture := load(path)
		if texture == null:
			continue
		var rect := TextureRect.new()
		rect.texture = texture
		var fitted_size := _fit_icon_size(texture.get_size(), 151.0, 70.0)
		rect.custom_minimum_size = fitted_size
		rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		rect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_box.add_child(rect)

	_add_audio_settings_button(root, overlay)

func _add_audio_settings_button(root: Control, _overlay: Control) -> void:
	var layer := CanvasLayer.new()
	layer.name = "AudioSettingsButtonLayer"
	layer.layer = 240
	root.add_child(layer)

	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(holder)

	var audio_button := Button.new()
	audio_button.name = "AudioSettingsButton"
	audio_button.text = "\u266A"
	audio_button.tooltip_text = "Audio settings"
	audio_button.anchor_left = 1.0
	audio_button.anchor_right = 1.0
	audio_button.anchor_top = 0.0
	audio_button.anchor_bottom = 0.0
	audio_button.offset_left = -74
	audio_button.offset_top = 18
	audio_button.offset_right = -18
	audio_button.offset_bottom = 74
	audio_button.custom_minimum_size = Vector2(56, 56)
	audio_button.focus_mode = Control.FOCUS_NONE
	audio_button.mouse_filter = Control.MOUSE_FILTER_STOP
	audio_button.add_theme_font_override("font", pretty_font)
	audio_button.add_theme_font_size_override("font_size", 32)
	audio_button.add_theme_color_override("font_color", Color(1, 1, 1))
	audio_button.add_theme_stylebox_override("normal", _round_audio_button_style(Color(0.08, 0.13, 0.28, 0.88)))
	audio_button.add_theme_stylebox_override("hover", _round_audio_button_style(Color(0.15, 0.22, 0.42, 0.94)))
	audio_button.add_theme_stylebox_override("pressed", _round_audio_button_style(Color(0.05, 0.09, 0.20, 0.98)))
	audio_button.pressed.connect(func() -> void:
		_on_menu_button_pressed()
		show_audio_settings_popup(root)
	)
	holder.add_child(audio_button)

func _round_audio_button_style(fill_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.border_color = Color(0.78, 0.90, 1.0, 0.95)
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 28
	sb.corner_radius_top_right = 28
	sb.corner_radius_bottom_right = 28
	sb.corner_radius_bottom_left = 28
	sb.shadow_color = Color(0, 0, 0, 0.30)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 2)
	sb.set_content_margin_all(6)
	return sb

func show_audio_settings_popup(root: Control) -> void:
	if root == null or not is_instance_valid(root):
		return
	if audio_settings_layer != null and is_instance_valid(audio_settings_layer):
		audio_settings_layer.queue_free()

	var layer := CanvasLayer.new()
	layer.layer = 320
	audio_settings_layer = layer
	root.add_child(layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.45)
	layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 395)
	panel.add_theme_stylebox_override("panel", _audio_settings_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Audio Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_label(title, 34, true)
	content.add_child(title)

	_add_volume_slider(content, "Music Volume", music_volume_linear, func(value: float) -> void:
		set_music_volume(value, false)
	)
	_add_volume_slider(content, "Effects Volume", sfx_volume_linear, func(value: float) -> void:
		set_sfx_volume(value, false)
	)
	_add_volume_slider(content, "Voice Volume", voice_volume_linear, func(value: float) -> void:
		set_voice_volume(value, false)
	)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(220, 62)
	style_menu_button(close_button, "orange")
	content.add_child(close_button)

	close_button.pressed.connect(func() -> void:
		save_progress()
		if audio_settings_layer != null and is_instance_valid(audio_settings_layer):
			audio_settings_layer.queue_free()
		audio_settings_layer = null
	)

func _add_volume_slider(container: VBoxContainer, title_text: String, value: float, on_value_changed: Callable) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	container.add_child(row)

	var label := Label.new()
	label.text = title_text
	label.custom_minimum_size = Vector2(175, 32)
	style_label(label, 22, false)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size = Vector2(210, 32)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%d%%" % roundi(value * 100.0)
	value_label.custom_minimum_size = Vector2(70, 32)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	style_label(value_label, 20, false)
	row.add_child(value_label)

	slider.value_changed.connect(func(new_value: float) -> void:
		value_label.text = "%d%%" % roundi(new_value * 100.0)
		if on_value_changed.is_valid():
			on_value_changed.call(new_value)
	)

func _audio_settings_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.23, 0.97)
	sb.border_color = Color(0.78, 0.90, 1.0, 0.95)
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	sb.shadow_color = Color(0, 0, 0, 0.38)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 3)
	return sb

func _fit_icon_size(original: Vector2, max_width: float, max_height: float) -> Vector2:
	if original.x <= 0.0 or original.y <= 0.0:
		return Vector2(max_width, max_height)
	var ratio: float = minf(max_width / original.x, max_height / original.y)
	return Vector2(original.x * ratio, original.y * ratio)

func _get_ucr_icon_path() -> String:
	var preferred := "%s/ucr.png" % GLOBAL_ICONS_DIR
	if ResourceLoader.exists(preferred):
		return preferred

	var dir := DirAccess.open(GLOBAL_ICONS_DIR)
	if dir == null:
		return ""
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		var low := file_name.to_lower()
		if low.begins_with("ucr") and (low.ends_with(".png") or low.ends_with(".jpg") or low.ends_with(".jpeg")):
			dir.list_dir_end()
			return "%s/%s" % [GLOBAL_ICONS_DIR, file_name]
	dir.list_dir_end()
	return ""

func style_menu_button(button: Button, palette: String = "blue") -> void:
	var base_color := Color(0.22, 0.56, 0.95)
	var border_color := Color(0.75, 0.92, 1.0)
	var hover_color := Color(0.30, 0.62, 1.0)
	var pressed_color := Color(0.14, 0.46, 0.86)

	match palette:
		"pink":
			base_color = Color(0.90, 0.32, 0.86)
			border_color = Color(1.0, 0.80, 0.98)
			hover_color = Color(0.96, 0.44, 0.92)
			pressed_color = Color(0.78, 0.20, 0.74)
		"yellow":
			base_color = Color(0.95, 0.78, 0.25)
			border_color = Color(1.0, 0.94, 0.68)
			hover_color = Color(1.0, 0.84, 0.35)
			pressed_color = Color(0.90, 0.70, 0.16)
		"orange":
			base_color = Color(0.96, 0.45, 0.24)
			border_color = Color(1.0, 0.80, 0.70)
			hover_color = Color(1.0, 0.53, 0.34)
			pressed_color = Color(0.86, 0.34, 0.14)
		"green":
			base_color = Color(0.42, 0.78, 0.33)
			border_color = Color(0.84, 1.0, 0.76)
			hover_color = Color(0.52, 0.86, 0.43)
			pressed_color = Color(0.32, 0.64, 0.24)
		"purple":
			base_color = Color(0.52, 0.43, 0.93)
			border_color = Color(0.87, 0.82, 1.0)
			hover_color = Color(0.61, 0.53, 0.98)
			pressed_color = Color(0.42, 0.33, 0.83)

	var normal := _make_button_style(base_color, border_color)
	var hover := _make_button_style(hover_color, border_color.lightened(0.08))
	var pressed := _make_button_style(pressed_color, border_color.darkened(0.1))
	var disabled := _make_button_style(base_color.darkened(0.28), border_color.darkened(0.18))
	disabled.bg_color.a = 0.52

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.48))
	button.add_theme_constant_override("outline_size", 1)
	button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 170.0), maxf(button.custom_minimum_size.y, 52.0))
	button.add_theme_font_override("font", pretty_font)
	button.add_theme_font_size_override("font_size", 30)
	if not button.has_meta("_click_hooked"):
		button.set_meta("_click_hooked", true)
		button.pressed.connect(_on_menu_button_pressed)

func _make_button_style(fill_color: Color, line_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.border_color = line_color
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 24
	sb.corner_radius_top_right = 24
	sb.corner_radius_bottom_right = 24
	sb.corner_radius_bottom_left = 24
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.0
	sb.set_content_margin_all(10)
	return sb

func _on_menu_button_pressed() -> void:
	if ui_click_player != null and ui_click_player.stream != null:
		ui_click_player.stop()
		ui_click_player.play()

func style_label(label: Label, font_size: int = 28, with_outline: bool = false) -> void:
	label.add_theme_font_override("font", pretty_font)
	label.add_theme_font_size_override("font_size", font_size)
	if with_outline:
		label.add_theme_color_override("font_outline_color", Color(0.07, 0.10, 0.30))
		label.add_theme_constant_override("outline_size", 4)

func get_zone_screen_background(zone_id: String) -> String:
	var zones: Dictionary = background_manifest.get("zones", {})
	if not zones.has(zone_id):
		return ""
	var zone_data: Dictionary = zones[zone_id]
	var path: String = String(zone_data.get("zone_screen", ""))
	return path

func get_minigame_background(zone_id: String, minigame_id: String) -> String:
	var zones: Dictionary = background_manifest.get("zones", {})
	if not zones.has(zone_id):
		return ""
	var zone_data: Dictionary = zones[zone_id]
	var minigames: Dictionary = zone_data.get("minigames", {})
	var path: String = String(minigames.get(minigame_id, ""))
	return path

func play_enter_transition(root: Control) -> void:
	await get_tree().process_frame
	if root == null or not is_instance_valid(root):
		return
	root.pivot_offset = root.size * 0.5
	root.scale = Vector2(0.92, 0.92)
	var tween := get_tree().create_tween()
	tween.tween_property(root, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func change_scene_with_transition(scene_path: String, is_back: bool = false) -> void:
	if is_scene_transitioning:
		return
	is_scene_transitioning = true

	var overlay_layer: CanvasLayer = null
	var overlay_rect: TextureRect = null
	var captured := await _create_transition_overlay()
	if typeof(captured) == TYPE_DICTIONARY and captured.has("layer") and captured.has("rect"):
		overlay_layer = captured["layer"]
		overlay_rect = captured["rect"]

	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Could not change scene to: " + scene_path)
		if overlay_layer != null and is_instance_valid(overlay_layer):
			overlay_layer.queue_free()
		is_scene_transitioning = false
		return
	apply_music_for_scene(scene_path)

	if overlay_rect != null and is_instance_valid(overlay_rect):
		await get_tree().process_frame
		overlay_rect.pivot_offset = overlay_rect.size * 0.5
		overlay_rect.scale = Vector2.ONE
		overlay_rect.modulate = Color(1, 1, 1, 1)
		var end_scale: Vector2 = Vector2(0.92, 0.92) if is_back else Vector2(1.06, 1.06)
		var tween := get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(overlay_rect, "scale", end_scale, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(overlay_rect, "modulate:a", 0.0, 0.20)
		await tween.finished
		if overlay_layer != null and is_instance_valid(overlay_layer):
			overlay_layer.queue_free()
	is_scene_transitioning = false

func _create_transition_overlay() -> Dictionary:
	await RenderingServer.frame_post_draw
	var viewport_tex := get_viewport().get_texture()
	if viewport_tex == null:
		return {}
	var image: Image = viewport_tex.get_image()
	if image == null or image.is_empty():
		return {}

	var image_texture := ImageTexture.create_from_image(image)
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_tree().root.add_child(layer)

	var rect := TextureRect.new()
	rect.name = "TransitionOverlay"
	rect.texture = image_texture
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	return {
		"layer": layer,
		"rect": rect
	}
