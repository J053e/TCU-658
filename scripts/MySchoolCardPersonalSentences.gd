extends Control

const DATA_PATH := "res://data/my_school_card_personal_sentences.json"
const CHALLENGE_ID := "my_school_card_personal_sentences"
const PASS_RATIO := 0.70
const BACKGROUND_PATH := "res://assets/zones/zone_04_my_school_card/backgrounds/minigames/personal_sentences.png"

var title_label: Label
var progress_label: Label
var sentence_label: Label
var instruction_label: Label
var feedback_label: Label
var option_buttons: Array[Button] = []
var continue_button: Button
var back_button: Button
var repeat_button: Button
var status_label: Label
var layout_spacer: Control

var challenge_data: Dictionary = {}
var questions: Array = []
var current_index: int = 0
var correct_total: int = 0
var answered_current: bool = false
var challenge_finished: bool = false

func _ready() -> void:
	GameState.decorate_screen(self, BACKGROUND_PATH)
	_build_ui()
	_load_data()
	if GameState.has_challenge_result(CHALLENGE_ID):
		_show_saved_summary()
	else:
		_start_new_attempt()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_bottom", 42)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	title_label = Label.new()
	title_label.text = "Simple Personal Sentences"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title_label, 38, true)
	root.add_child(title_label)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(progress_label, 24, true)
	root.add_child(progress_label)

	instruction_label = Label.new()
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.custom_minimum_size = Vector2(0, 54)
	GameState.style_label(instruction_label, 22, false)
	root.add_child(instruction_label)

	sentence_label = Label.new()
	sentence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sentence_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sentence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sentence_label.custom_minimum_size = Vector2(0, 96)
	GameState.style_label(sentence_label, 34, true)
	root.add_child(sentence_label)

	var options_box := VBoxContainer.new()
	options_box.add_theme_constant_override("separation", 8)
	root.add_child(options_box)

	for i in range(3):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 58)
		GameState.style_menu_button(btn, ["blue", "green", "purple"][i])
		btn.pressed.connect(_on_option_pressed.bind(i))
		options_box.add_child(btn)
		option_buttons.append(btn)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(0, 54)
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	layout_spacer = Control.new()
	layout_spacer.custom_minimum_size = Vector2(0, 8)
	root.add_child(layout_spacer)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.disabled = true
	GameState.style_menu_button(continue_button, "yellow")
	continue_button.pressed.connect(_on_continue_pressed)
	actions.add_child(continue_button)

	back_button = Button.new()
	back_button.text = "Back"
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
	challenge_data.clear()
	if not FileAccess.file_exists(DATA_PATH):
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	challenge_data = parsed as Dictionary
	questions = challenge_data.get("questions", [])

func _start_new_attempt() -> void:
	current_index = 0
	correct_total = 0
	answered_current = false
	challenge_finished = false
	continue_button.text = "Continue"
	continue_button.visible = true
	continue_button.disabled = true
	repeat_button.visible = false
	status_label.visible = false
	feedback_label.text = ""
	layout_spacer.custom_minimum_size = Vector2(0, 8)
	_show_current_question()

func _show_current_question() -> void:
	if questions.is_empty():
		progress_label.text = "Question 0/0"
		instruction_label.text = "Challenge data missing."
		sentence_label.text = ""
		continue_button.disabled = true
		for button in option_buttons:
			button.visible = false
		return
	if current_index >= questions.size():
		_finish_challenge()
		return

	var q: Dictionary = questions[current_index]
	progress_label.text = "Question " + str(current_index + 1) + "/" + str(questions.size())
	instruction_label.text = String(challenge_data.get("instruction", "Complete the sentences with the correct option."))
	sentence_label.text = String(q.get("sentence", ""))
	feedback_label.text = ""
	continue_button.disabled = true
	answered_current = false

	var raw_options: Array = q.get("options", [])
	for i in range(option_buttons.size()):
		var btn := option_buttons[i]
		if i < raw_options.size():
			btn.visible = true
			btn.disabled = false
			btn.text = _resolve_option_text(String(raw_options[i]))
		else:
			btn.visible = false

func _resolve_option_text(raw_text: String) -> String:
	var cleaned := raw_text.strip_edges()
	match cleaned:
		"[NAME]":
			return _get_profile_name()
		"[AGE]":
			return _get_profile_age()
		"[TOWN]":
			return _get_profile_town()
		_:
			return cleaned

func _get_profile_name() -> String:
	var profile_name := String(GameState.profile.get("name", "")).strip_edges()
	return profile_name if profile_name != "" else "Student"

func _get_profile_age() -> String:
	var profile_age := String(GameState.profile.get("age", "")).strip_edges()
	return profile_age if profile_age != "" else "12"

func _get_profile_town() -> String:
	var profile_town := String(GameState.profile.get("province", "")).strip_edges()
	return profile_town if profile_town != "" else "Cartago"

func _on_option_pressed(option_index: int) -> void:
	if challenge_finished or answered_current:
		return
	if current_index < 0 or current_index >= questions.size():
		return
	var q: Dictionary = questions[current_index]
	var correct_index := int(q.get("correct_index", -1))
	var is_correct := option_index == correct_index
	if is_correct:
		correct_total += 1
		feedback_label.text = String(q.get("correct_feedback", "Correct!"))
		feedback_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.76))
	else:
		feedback_label.text = String(q.get("incorrect_feedback", "Try again."))
		feedback_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.76))

	for btn in option_buttons:
		btn.disabled = true
	continue_button.disabled = false
	answered_current = true

func _on_continue_pressed() -> void:
	if challenge_finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	if not answered_current:
		return
	current_index += 1
	_show_current_question()

func _finish_challenge() -> void:
	challenge_finished = true
	var total := maxi(questions.size(), 1)
	var result := GameState.record_challenge_result(CHALLENGE_ID, correct_total, total, PASS_RATIO)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("my_school_card")
	_show_summary(result)

func _show_saved_summary() -> void:
	var result := GameState.get_challenge_result(CHALLENGE_ID)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("my_school_card")
	_show_summary(result)

func _show_summary(result: Dictionary) -> void:
	var total := maxi(int(result.get("total_questions", questions.size())), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))

	challenge_finished = true
	progress_label.text = "Challenge Complete"
	if passed:
		instruction_label.text = "Good work. Your personal sentences are clear."
		feedback_label.text = "Best score: " + str(best_correct) + "/" + str(total)
		status_label.text = "Status: Approved"
		status_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.74))
	else:
		instruction_label.text = "Keep practicing. You need at least 70%."
		feedback_label.text = "Best score: " + str(best_correct) + "/" + str(total)
		status_label.text = "Status: Failed"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72))
	if attempts > 1:
		feedback_label.text += " Attempts: " + str(attempts)

	sentence_label.text = "Complete the sentences with the correct option."
	for btn in option_buttons:
		btn.visible = false
	continue_button.visible = true
	continue_button.text = "Back to Zone"
	continue_button.disabled = false
	repeat_button.visible = true
	status_label.visible = true
	layout_spacer.custom_minimum_size = Vector2(0, 92)

func _on_repeat_pressed() -> void:
	_start_new_attempt()

func _on_back_pressed() -> void:
	if challenge_finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)

func _exit_with_badge_popup(scene_path: String, is_back: bool) -> void:
	GameState.show_badge_popup_or_continue(
		self,
		"my_school_card",
		Callable(self, "_change_scene_after_popup").bind(scene_path, is_back)
	)

func _change_scene_after_popup(scene_path: String, is_back: bool) -> void:
	GameState.change_scene_with_transition(scene_path, is_back)
