extends Control

const DATA_PATH := "res://data/final_passport_read_passport.json"
const CHALLENGE_ID := "final_passport_read_passport"
const PREREQ_CHALLENGE_ID := "final_passport_build_intro"
const PASS_RATIO := 0.70

var title_label: Label
var progress_label: Label
var instruction_label: Label
var question_hint_label: Label
var feedback_label: Label
var answers_panel: PanelContainer
var answers_box: VBoxContainer
var continue_button: Button
var back_button: Button
var repeat_button: Button
var status_label: Label
var replay_audio_button: Button
var layout_offset_spacer: Control

var challenge_data: Dictionary = {}
var questions: Array = []
var answer_templates: Array = []
var resolved_answers: Dictionary = {}
var answer_buttons: Dictionary = {}

var current_index: int = 0
var correct_total: int = 0
var answered_current: bool = false
var finished: bool = false
var attempt_issues: Array[String] = []

var tts_voice_id: String = ""
var question_audio_player: AudioStreamPlayer
var prereq_passport_values: Dictionary = {}

func _ready() -> void:
	if not _has_prerequisite_completed():
		_show_prerequisite_block()
		return
	_load_prereq_passport_values()
	var background := GameState.get_minigame_background("final_passport", "read_passport")
	if background == "" or not ResourceLoader.exists(background):
		background = GameState.get_zone_screen_background("final_passport")
	GameState.decorate_screen(self, background)
	_build_ui()
	_load_data()
	_prepare_tts_voice()
	if GameState.has_challenge_result(CHALLENGE_ID):
		_show_saved_summary()
	else:
		_start_new_attempt()
	GameState.play_enter_transition(self)

func _has_prerequisite_completed() -> bool:
	var prereq := GameState.get_challenge_result(PREREQ_CHALLENGE_ID)
	return not prereq.is_empty() and bool(prereq.get("passed", false))

func _show_prerequisite_block() -> void:
	GameState.decorate_screen(self, GameState.get_zone_screen_background("final_passport"))
	var dialog := AcceptDialog.new()
	dialog.title = "Challenge Locked"
	dialog.dialog_text = "You must pass Build Your Intro before playing Listen the Final Passport."
	dialog.ok_button_text = "Back"
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)
	)
	dialog.popup_centered(Vector2i(620, 220))

func _build_ui() -> void:
	question_audio_player = AudioStreamPlayer.new()
	add_child(question_audio_player)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 5)
	margin.add_child(root)

	layout_offset_spacer = Control.new()
	layout_offset_spacer.custom_minimum_size = Vector2(0, 24)
	root.add_child(layout_offset_spacer)

	title_label = Label.new()
	title_label.text = "Listen the Final Passport"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title_label, 36, true)
	root.add_child(title_label)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(progress_label, 24, true)
	root.add_child(progress_label)

	instruction_label = Label.new()
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.custom_minimum_size = Vector2(0, 28)
	GameState.style_label(instruction_label, 22, true)
	root.add_child(instruction_label)

	question_hint_label = Label.new()
	question_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_hint_label.custom_minimum_size = Vector2(0, 0)
	GameState.style_label(question_hint_label, 24, true)
	question_hint_label.visible = false
	root.add_child(question_hint_label)

	replay_audio_button = Button.new()
	replay_audio_button.text = "Play Question Audio"
	replay_audio_button.custom_minimum_size = Vector2(360, 58)
	replay_audio_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(replay_audio_button, "blue")
	replay_audio_button.pressed.connect(_on_replay_audio_pressed)
	root.add_child(replay_audio_button)

	answers_panel = PanelContainer.new()
	answers_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	answers_panel.custom_minimum_size = Vector2(0, 306)
	answers_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(answers_panel)

	var answers_margin := MarginContainer.new()
	answers_margin.add_theme_constant_override("margin_left", 12)
	answers_margin.add_theme_constant_override("margin_top", 10)
	answers_margin.add_theme_constant_override("margin_right", 12)
	answers_margin.add_theme_constant_override("margin_bottom", 10)
	answers_panel.add_child(answers_margin)

	answers_box = VBoxContainer.new()
	answers_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answers_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	answers_box.alignment = BoxContainer.ALIGNMENT_CENTER
	answers_box.add_theme_constant_override("separation", 6)
	answers_margin.add_child(answers_box)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(0, 36)
	GameState.style_label(feedback_label, 22, true)
	root.add_child(feedback_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	actions.custom_minimum_size = Vector2(0, 60)
	root.add_child(actions)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.disabled = true
	GameState.style_menu_button(continue_button, "yellow")
	continue_button.pressed.connect(_on_continue_pressed)
	actions.add_child(continue_button)

	back_button = Button.new()
	back_button.text = "Back"
	back_button.focus_mode = Control.FOCUS_NONE
	GameState.style_menu_button(back_button, "orange")
	back_button.pressed.connect(_on_back_pressed)
	actions.add_child(back_button)

	repeat_button = Button.new()
	repeat_button.text = "Repeat"
	repeat_button.visible = false
	GameState.style_menu_button(repeat_button, "purple")
	repeat_button.pressed.connect(_on_repeat_pressed)
	actions.add_child(repeat_button)

	status_label = Label.new()
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(status_label, 20, true)
	actions.add_child(status_label)

func _load_data() -> void:
	questions.clear()
	answer_templates.clear()
	challenge_data.clear()
	challenge_data = GameState.load_json_data(DATA_PATH)
	questions = challenge_data.get("questions", [])
	answer_templates = challenge_data.get("answers", [])

func _prepare_tts_voice() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var english_voices: Array = DisplayServer.tts_get_voices_for_language("en")
	if not english_voices.is_empty():
		tts_voice_id = String(english_voices[0])
		return
	var all_voices: Array = DisplayServer.tts_get_voices()
	if not all_voices.is_empty():
		var first_voice: Variant = all_voices[0]
		if typeof(first_voice) == TYPE_DICTIONARY:
			tts_voice_id = String((first_voice as Dictionary).get("id", ""))
		else:
			tts_voice_id = String(first_voice)

func _load_prereq_passport_values() -> void:
	prereq_passport_values.clear()
	var prereq := GameState.get_challenge_result(PREREQ_CHALLENGE_ID)
	if prereq.is_empty():
		return
	prereq_passport_values = prereq.duplicate(true)

func _start_new_attempt() -> void:
	current_index = 0
	correct_total = 0
	answered_current = false
	finished = false
	attempt_issues.clear()
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.disabled = true
	repeat_button.visible = false
	status_label.visible = false
	layout_offset_spacer.custom_minimum_size = Vector2(0, 24)
	replay_audio_button.visible = true
	answers_panel.visible = true
	feedback_label.text = ""
	resolved_answers = _build_resolved_answers()
	_build_answer_buttons()
	_show_question()

func _build_resolved_answers() -> Dictionary:
	var map := {}
	for item_variant in answer_templates:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_variant
		var answer_id := String(item.get("id", ""))
		if answer_id == "":
			continue
		map[answer_id] = _resolve_text(String(item.get("text", "")))
	return map

func _resolve_text(raw_text: String) -> String:
	var out := raw_text
	out = out.replace("[NAME]", _profile_name())
	out = out.replace("[LAST_NAME]", _profile_last_name())
	out = out.replace("[AGE]", _profile_age())
	out = out.replace("[COUNTRY]", _profile_country())
	out = out.replace("[TOWN]", _profile_town())
	out = out.replace("[GRADE]", _profile_grade())
	return out

func _profile_name() -> String:
	var from_prereq := String(prereq_passport_values.get("passport_name", "")).strip_edges()
	if from_prereq != "":
		return from_prereq
	var value := String(GameState.profile.get("name", "")).strip_edges()
	return value if value != "" else "Student"

func _profile_last_name() -> String:
	var from_prereq := String(prereq_passport_values.get("passport_last_name", "")).strip_edges()
	if from_prereq != "":
		return from_prereq
	var value := String(GameState.profile.get("last_name", "")).strip_edges()
	return value if value != "" else "Lastname"

func _profile_age() -> String:
	var from_prereq := String(prereq_passport_values.get("passport_age", "")).strip_edges()
	if from_prereq != "":
		return from_prereq
	var value := String(GameState.profile.get("age", "")).strip_edges()
	return value if value != "" else "12"

func _profile_country() -> String:
	var from_prereq := String(prereq_passport_values.get("passport_country", "")).strip_edges()
	if from_prereq != "":
		return from_prereq
	var value := String(GameState.profile.get("country", "")).strip_edges()
	return value if value != "" else "Costa Rica"

func _profile_town() -> String:
	var from_prereq := String(prereq_passport_values.get("passport_town", "")).strip_edges()
	if from_prereq != "":
		return from_prereq
	var value := String(GameState.profile.get("province", "")).strip_edges()
	return value if value != "" else "Cartago"

func _profile_grade() -> String:
	var from_prereq := String(prereq_passport_values.get("passport_grade", "")).strip_edges()
	if from_prereq != "":
		return from_prereq.to_lower()
	var value := String(GameState.profile.get("grade", "")).strip_edges()
	return value.to_lower() if value != "" else "seventh"

func _build_answer_buttons() -> void:
	for child in answers_box.get_children():
		child.queue_free()
	answer_buttons.clear()
	for item_variant in answer_templates:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_variant
		var answer_id := String(item.get("id", ""))
		if answer_id == "":
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = String(resolved_answers.get(answer_id, ""))
		GameState.style_menu_button(button, "blue")
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_on_answer_pressed.bind(answer_id))
		answers_box.add_child(button)
		answer_buttons[answer_id] = button

func _show_question() -> void:
	if questions.is_empty():
		progress_label.text = "Question 0/0"
		instruction_label.text = "Challenge data missing."
		question_hint_label.text = ""
		continue_button.disabled = true
		replay_audio_button.disabled = true
		return
	if current_index >= questions.size():
		_finish_challenge()
		return

	progress_label.text = "Question " + str(current_index + 1) + "/" + str(questions.size())
	instruction_label.text = String(challenge_data.get("instruction", "Listen to the question audio and choose the correct passport line."))
	question_hint_label.visible = false
	question_hint_label.text = ""
	feedback_label.text = ""
	continue_button.disabled = true
	replay_audio_button.disabled = false
	answered_current = false
	for button in answer_buttons.values():
		(button as Button).disabled = false
	_play_current_question_audio()

func _play_current_question_audio() -> void:
	if current_index < 0 or current_index >= questions.size():
		return
	var q: Dictionary = questions[current_index]
	var audio_path := String(q.get("audio_path", "")).strip_edges()
	var stream := _load_question_audio_stream(audio_path)
	if stream != null:
		question_audio_player.stop()
		question_audio_player.stream = stream
		question_audio_player.play()
		return
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(String(q.get("prompt", "")), tts_voice_id)

func _load_question_audio_stream(audio_path: String) -> AudioStream:
	if audio_path == "":
		return null

	for candidate: String in _audio_path_candidates(audio_path):
		if FileAccess.file_exists(candidate):
			var bytes := FileAccess.get_file_as_bytes(candidate)
			if _is_mp3_data(bytes):
				var mp3 := AudioStreamMP3.new()
				mp3.data = bytes
				return mp3
			if _is_ogg_data(bytes):
				return AudioStreamOggVorbis.load_from_buffer(bytes)

		if ResourceLoader.exists(candidate):
			var imported := load(candidate)
			if imported is AudioStream:
				return imported

	return null

func _audio_path_candidates(audio_path: String) -> Array[String]:
	var candidates: Array[String] = [audio_path]
	var base := audio_path.get_basename()
	for extension: String in [".ogg", ".mp3"]:
		var candidate: String = base + extension
		if not candidates.has(candidate):
			candidates.append(candidate)
	return candidates

func _is_mp3_data(bytes: PackedByteArray) -> bool:
	if bytes.size() >= 3 and bytes[0] == 0x49 and bytes[1] == 0x44 and bytes[2] == 0x33:
		return true
	return bytes.size() >= 2 and bytes[0] == 0xFF and (bytes[1] & 0xE0) == 0xE0

func _is_ogg_data(bytes: PackedByteArray) -> bool:
	return bytes.size() >= 4 and bytes[0] == 0x4F and bytes[1] == 0x67 and bytes[2] == 0x67 and bytes[3] == 0x53

func _on_replay_audio_pressed() -> void:
	if finished:
		return
	_play_current_question_audio()

func _on_answer_pressed(answer_id: String) -> void:
	if finished or answered_current:
		return
	if current_index < 0 or current_index >= questions.size():
		return
	var q: Dictionary = questions[current_index]
	var correct_id := String(q.get("answer_id", ""))
	var correct := answer_id == correct_id
	var correct_text := String(resolved_answers.get(correct_id, ""))
	var popup_text := ""
	if correct:
		correct_total += 1
		popup_text = String(q.get("correct_feedback", "Correct!"))
	else:
		popup_text = String(q.get("incorrect_feedback", "Try again."))
		var prompt := String(q.get("prompt", ""))
		attempt_issues.append("For \"%s\", the best answer was \"%s\"." % [prompt, correct_text])
	for button in answer_buttons.values():
		(button as Button).disabled = true
	feedback_label.text = ""
	continue_button.disabled = true
	answered_current = true
	GameState.show_answer_feedback_popup(self, popup_text, correct, Callable(self, "_on_continue_pressed"))

func _on_continue_pressed() -> void:
	if finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	if not answered_current:
		return
	current_index += 1
	_show_question()

func _finish_challenge() -> void:
	finished = true
	var total := maxi(questions.size(), 1)
	var passed_now := correct_total >= int(ceil(float(total) * PASS_RATIO))
	var result := GameState.record_challenge_result(CHALLENGE_ID, correct_total, total, PASS_RATIO)
	result["last_attempt_correct"] = correct_total
	result["last_attempt_passed"] = passed_now
	result["last_attempt_feedback"] = _build_attempt_feedback(passed_now)
	GameState.challenge_results[CHALLENGE_ID] = result
	GameState.save_progress()
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("final_passport")
	_show_summary(result)

func _show_saved_summary() -> void:
	var result := GameState.get_challenge_result(CHALLENGE_ID)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("final_passport")
	_show_summary(result)

func _build_attempt_feedback(passed_now: bool) -> String:
	if passed_now:
		return "Great listening and comprehension!"
	if attempt_issues.is_empty():
		return "Keep listening carefully and checking each answer."
	var lines: Array[String] = []
	lines.append("Latest attempt feedback:")
	for i in range(mini(attempt_issues.size(), 3)):
		lines.append("- " + attempt_issues[i])
	return "\n".join(lines)

func _show_summary(result: Dictionary) -> void:
	finished = true
	var total := maxi(int(result.get("total_questions", questions.size())), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))
	var last_feedback := String(result.get("last_attempt_feedback", "")).strip_edges()

	progress_label.text = "Challenge Complete"
	layout_offset_spacer.custom_minimum_size = Vector2(0, 74)
	instruction_label.text = "Audio comprehension of passport information."
	question_hint_label.visible = true
	question_hint_label.text = last_feedback
	question_hint_label.custom_minimum_size = Vector2(0, 86)
	question_hint_label.add_theme_font_size_override("font_size", 22)
	replay_audio_button.visible = false
	answers_panel.visible = false
	for button in answer_buttons.values():
		(button as Button).visible = false

	if passed:
		feedback_label.text = "Stamp progress saved!\nBest score: " + str(best_correct) + "/" + str(total)
		feedback_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.76))
		status_label.text = "Status: Approved"
		status_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.74))
	else:
		feedback_label.text = "You need at least 70%.\nBest score: " + str(best_correct) + "/" + str(total)
		feedback_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.76))
		status_label.text = "Status: Failed"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72))
	if attempts > 1:
		feedback_label.text += "\nAttempts: " + str(attempts)

	continue_button.visible = true
	continue_button.text = "Back to Zone"
	continue_button.disabled = false
	repeat_button.visible = true
	status_label.visible = true

func _on_repeat_pressed() -> void:
	_start_new_attempt()

func _on_back_pressed() -> void:
	if finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)

func _exit_with_badge_popup(scene_path: String, is_back: bool) -> void:
	GameState.show_badge_popup_or_continue(
		self,
		"final_passport",
		Callable(self, "_change_scene_after_popup").bind(scene_path, is_back)
	)

func _change_scene_after_popup(scene_path: String, is_back: bool) -> void:
	GameState.change_scene_with_transition(scene_path, is_back)

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.09, 0.18, 0.84)
	sb.border_color = Color(0.72, 0.86, 1.0, 0.92)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	return sb
