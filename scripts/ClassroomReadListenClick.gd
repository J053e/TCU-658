extends Control

const DATA_PATH := "res://data/classroom_read_listen_click.json"
const PASS_RATIO := 0.70
const CHALLENGE_ID := "classroom_read_listen_click"

var instruction_label: Label
var progress_label: Label
var feedback_label: Label
var options_row: HBoxContainer
var top_spacer: Control
var summary_spacer: Control
var screen_title_label: Label
var option_buttons := []
var continue_button: Button
var back_button: Button
var repeat_button: Button
var replay_audio_button: Button
var result_status_label: Label

var quiz_data: Dictionary = {}
var questions: Array = []
var current_index := 0
var correct_total := 0
var answered_current := false
var finished := false
var tts_voice_id: String = ""
var question_audio_player: AudioStreamPlayer

func _ready() -> void:
	GameState.decorate_screen(self, GameState.get_minigame_background("classroom_survival", "read_listen_click"))
	_build_ui()
	_load_data()
	_prepare_tts_voice()
	if GameState.has_challenge_result(CHALLENGE_ID):
		_show_saved_summary()
	else:
		_start_new_attempt()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	question_audio_player = AudioStreamPlayer.new()
	add_child(question_audio_player)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 58)
	add_child(margin)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(center)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.custom_minimum_size = Vector2(1120, 560)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(root)

	screen_title_label = Label.new()
	screen_title_label.text = "Read, Listen and Click"
	screen_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(screen_title_label, 36, true)
	root.add_child(screen_title_label)

	top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 12)
	root.add_child(top_spacer)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(progress_label, 22, false)
	root.add_child(progress_label)

	instruction_label = Label.new()
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.custom_minimum_size = Vector2(0, 56)
	GameState.style_label(instruction_label, 28, true)
	root.add_child(instruction_label)

	replay_audio_button = Button.new()
	replay_audio_button.text = "Play Instruction Audio"
	replay_audio_button.custom_minimum_size = Vector2(340, 54)
	replay_audio_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(replay_audio_button, "blue")
	replay_audio_button.add_theme_font_size_override("font_size", 26)
	replay_audio_button.pressed.connect(_on_replay_audio_pressed)
	root.add_child(replay_audio_button)

	options_row = HBoxContainer.new()
	options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	options_row.add_theme_constant_override("separation", 12)
	root.add_child(options_row)

	for i in range(3):
		var option_button := _create_option_button(i)
		options_row.add_child(option_button)
		option_buttons.append(option_button)

	summary_spacer = Control.new()
	summary_spacer.visible = false
	summary_spacer.custom_minimum_size = Vector2(0, 0)
	root.add_child(summary_spacer)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.custom_minimum_size = Vector2(0, 34)
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.custom_minimum_size = Vector2(0, 58)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	root.add_child(actions)

	continue_button = Button.new()
	continue_button.text = "Continue"
	GameState.style_menu_button(continue_button, "yellow")
	continue_button.disabled = true
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
	GameState.style_menu_button(repeat_button, "purple")
	repeat_button.visible = false
	repeat_button.pressed.connect(_on_repeat_pressed)
	actions.add_child(repeat_button)

	result_status_label = Label.new()
	result_status_label.visible = false
	result_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(result_status_label, 18, true)
	actions.add_child(result_status_label)

func _create_option_button(index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(330, 250)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.clip_text = false
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.text = ""
	button.pressed.connect(_on_option_pressed.bind(index))
	button.mouse_entered.connect(_on_option_hover.bind(button, true))
	button.mouse_exited.connect(_on_option_hover.bind(button, false))
	_apply_option_style(button, false)
	return button

func _apply_option_style(button: Button, hovered: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.08, 0.16, 0.85)
	normal.border_color = Color(0.72, 0.82, 0.95, 0.9)
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_right = 12
	normal.corner_radius_bottom_left = 12
	normal.set_content_margin_all(8)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = Color(1.0, 0.95, 0.45, 1.0)
	hover.set_border_width_all(4)
	hover.shadow_color = Color(1.0, 0.92, 0.30, 0.45)
	hover.shadow_size = 8
	hover.shadow_offset = Vector2(0, 0)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.05, 0.08, 0.16, 0.48)
	disabled.border_color = Color(0.72, 0.82, 0.95, 0.55)

	var chosen := hover if hovered else normal
	button.add_theme_stylebox_override("normal", chosen)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)

func _on_option_hover(button: Button, entered: bool) -> void:
	if button.disabled:
		return
	_apply_option_style(button, entered)

func _load_data() -> void:
	quiz_data = GameState.load_json_data(DATA_PATH)
	questions = quiz_data.get("questions", [])

func _show_question() -> void:
	if questions.is_empty():
		instruction_label.text = "Question data missing."
		return
	if current_index >= questions.size():
		_finish()
		return

	var q: Dictionary = questions[current_index]
	screen_title_label.visible = true
	top_spacer.custom_minimum_size = Vector2(0, 12)
	progress_label.text = "Instruction " + str(current_index + 1) + "/" + str(questions.size())
	progress_label.add_theme_font_size_override("font_size", 22)
	progress_label.add_theme_constant_override("outline_size", 0)
	instruction_label.add_theme_font_size_override("font_size", 28)
	instruction_label.text = q.get("instruction", "")
	instruction_label.custom_minimum_size = Vector2(0, 56)
	feedback_label.add_theme_font_size_override("font_size", 20)
	feedback_label.text = ""
	answered_current = false
	finished = false
	continue_button.visible = false
	continue_button.disabled = true
	continue_button.text = "Continue"
	options_row.visible = true
	summary_spacer.visible = false
	summary_spacer.custom_minimum_size = Vector2(0, 0)
	repeat_button.visible = false
	result_status_label.visible = false
	replay_audio_button.visible = true
	replay_audio_button.disabled = false

	var options: Array = q.get("options", [])
	for i in range(option_buttons.size()):
		var b: Button = option_buttons[i]
		if i < options.size():
			var opt: Dictionary = options[i]
			b.visible = true
			b.disabled = false
			b.text = ""
			var img_path: String = String(opt.get("image", ""))
			b.icon = _load_fitted_icon(img_path, Vector2i(292, 188))
			_apply_option_style(b, false)
		else:
			b.visible = false
	_play_current_question_audio()

func _on_option_pressed(index: int) -> void:
	if answered_current or current_index >= questions.size():
		return
	answered_current = true
	var q: Dictionary = questions[current_index]
	var correct_index: int = int(q.get("correct_index", -1))
	var correct := index == correct_index
	var popup_text := ""

	if correct:
		correct_total += 1
		popup_text = String(q.get("correct_feedback", "Correct!"))
	else:
		popup_text = String(q.get("incorrect_feedback", "Try again."))

	for b in option_buttons:
		b.disabled = true
	feedback_label.text = ""
	continue_button.disabled = true
	GameState.show_answer_feedback_popup(self, popup_text, correct, Callable(self, "_on_continue_pressed"))

func _on_continue_pressed() -> void:
	if finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	if not answered_current:
		return
	current_index += 1
	_show_question()

func _finish() -> void:
	var result := GameState.record_challenge_result(CHALLENGE_ID, correct_total, questions.size(), PASS_RATIO)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("classroom_survival")
	_show_summary(result)

func _show_saved_summary() -> void:
	var result := GameState.get_challenge_result(CHALLENGE_ID)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("classroom_survival")
	_show_summary(result)

func _show_summary(result: Dictionary) -> void:
	finished = true
	var total := maxi(int(result.get("total_questions", questions.size())), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))

	progress_label.text = "Challenge Complete"
	screen_title_label.visible = false
	progress_label.add_theme_font_size_override("font_size", 26)
	progress_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	progress_label.add_theme_constant_override("outline_size", 4)
	top_spacer.custom_minimum_size = Vector2(0, 84)
	instruction_label.custom_minimum_size = Vector2(0, 120)
	instruction_label.add_theme_font_size_override("font_size", 24)
	if passed:
		instruction_label.text = "Great! You passed Read, Listen and Click.\nBest score: " + str(best_correct) + "/" + str(total)
		feedback_label.text = "You can understand simple classroom instructions."
	else:
		instruction_label.text = "Keep practicing. You need at least 70%.\nBest score: " + str(best_correct) + "/" + str(total)
		feedback_label.text = "Read carefully and try again."
	if attempts > 1:
		feedback_label.text += " Attempts: " + str(attempts)

	options_row.visible = false
	replay_audio_button.visible = false
	summary_spacer.visible = true
	summary_spacer.custom_minimum_size = Vector2(0, 0)
	feedback_label.custom_minimum_size = Vector2(0, 64)
	feedback_label.add_theme_font_size_override("font_size", 20)
	continue_button.visible = true
	continue_button.text = "Back to Zone"
	continue_button.disabled = false
	repeat_button.visible = true
	result_status_label.visible = true
	result_status_label.add_theme_font_size_override("font_size", 20)
	if passed:
		result_status_label.text = "Status: Approved"
		result_status_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.74))
	else:
		result_status_label.text = "Status: Failed"
		result_status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72))

func _on_back_pressed() -> void:
	if finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)

func _start_new_attempt() -> void:
	current_index = 0
	correct_total = 0
	answered_current = false
	finished = false
	_show_question()

func _on_repeat_pressed() -> void:
	_start_new_attempt()

func _on_replay_audio_pressed() -> void:
	if finished:
		return
	_play_current_question_audio()

func _exit_with_badge_popup(scene_path: String, is_back: bool) -> void:
	GameState.show_badge_popup_or_continue(
		self,
		"classroom_survival",
		Callable(self, "_change_scene_after_popup").bind(scene_path, is_back)
	)

func _change_scene_after_popup(scene_path: String, is_back: bool) -> void:
	GameState.change_scene_with_transition(scene_path, is_back)

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
		DisplayServer.tts_speak(String(q.get("instruction", "")), tts_voice_id)

func _load_question_audio_stream(audio_path: String) -> AudioStream:
	return GameState.load_audio_resource(audio_path)

func _load_fitted_icon(path: String, max_size: Vector2i) -> Texture2D:
	var tex := GameState.load_texture_resource(path)
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null or img.is_empty():
		return tex

	var source_w := img.get_width()
	var source_h := img.get_height()
	if source_w <= 0 or source_h <= 0:
		return tex

	var scale := minf(float(max_size.x) / float(source_w), float(max_size.y) / float(source_h))
	scale = minf(scale, 1.0)
	var target_w := maxi(int(round(float(source_w) * scale)), 1)
	var target_h := maxi(int(round(float(source_h) * scale)), 1)

	img.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)
