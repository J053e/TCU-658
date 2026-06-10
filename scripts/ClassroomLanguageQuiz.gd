extends Control

const QUIZ_DATA_PATH := "res://data/classroom_language_quiz.json"
const PASS_RATIO := 0.70
const CHALLENGE_ID := "classroom_language"

var progress_label: Label
var question_label: Label
var situation_image: TextureRect
var feedback_label: Label
var options_top_spacer: Control
var options_box: VBoxContainer
var top_spacer: Control
var bottom_spacer: Control
var option_buttons := []
var continue_button: Button
var back_button: Button
var repeat_button: Button
var result_status_label: Label

var quiz_data: Dictionary = {}
var questions: Array = []
var current_index: int = 0
var correct_total: int = 0
var answered_current: bool = false
var quiz_finished: bool = false

func _ready() -> void:
	_build_ui()
	_load_quiz_data()
	if GameState.has_challenge_result(CHALLENGE_ID):
		_show_saved_summary()
	else:
		_start_new_attempt()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	GameState.decorate_screen(self, GameState.get_minigame_background("classroom_survival", "classroom_language"))

	var screen_margin := MarginContainer.new()
	screen_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_margin.add_theme_constant_override("margin_left", 64)
	screen_margin.add_theme_constant_override("margin_top", 18)
	screen_margin.add_theme_constant_override("margin_right", 64)
	screen_margin.add_theme_constant_override("margin_bottom", 64)
	add_child(screen_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.custom_minimum_size = Vector2(1060, 0)
	screen_margin.add_child(root)

	top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 20)
	root.add_child(top_spacer)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(progress_label, 24, true)
	root.add_child(progress_label)

	question_label = Label.new()
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_label.custom_minimum_size = Vector2(0, 72)
	GameState.style_label(question_label, 24, false)
	root.add_child(question_label)

	situation_image = TextureRect.new()
	situation_image.custom_minimum_size = Vector2(760, 190)
	situation_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	situation_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	situation_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(situation_image)

	options_top_spacer = Control.new()
	options_top_spacer.custom_minimum_size = Vector2(0, 4)
	root.add_child(options_top_spacer)

	options_box = VBoxContainer.new()
	options_box.add_theme_constant_override("separation", 6)
	root.add_child(options_box)
	for i in range(3):
		var button := Button.new()
		GameState.style_menu_button(button, ["blue", "green", "purple"][i])
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_on_option_pressed.bind(i))
		options_box.add_child(button)
		option_buttons.append(button)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_label.custom_minimum_size = Vector2(0, 14)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bottom_spacer.custom_minimum_size = Vector2(0, 0)
	root.add_child(bottom_spacer)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.custom_minimum_size = Vector2(0, 58)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
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

func _load_quiz_data() -> void:
	if not FileAccess.file_exists(QUIZ_DATA_PATH):
		return
	var file := FileAccess.open(QUIZ_DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	quiz_data = parsed as Dictionary
	questions = quiz_data.get("questions", [])

func _show_question() -> void:
	if questions.is_empty():
		question_label.text = "Quiz data missing."
		return
	if current_index >= questions.size():
		_finish_quiz()
		return

	var q: Dictionary = questions[current_index]
	progress_label.text = "Question " + str(current_index + 1) + "/" + str(questions.size())
	progress_label.add_theme_font_size_override("font_size", 24)
	progress_label.add_theme_constant_override("outline_size", 0)
	top_spacer.custom_minimum_size = Vector2(0, 20)
	question_label.custom_minimum_size = Vector2(0, 72)
	question_label.add_theme_font_size_override("font_size", 24)
	question_label.text = q.get("prompt", "")
	feedback_label.custom_minimum_size = Vector2(0, 14)
	feedback_label.add_theme_font_size_override("font_size", 20)
	feedback_label.text = ""
	answered_current = false
	quiz_finished = false
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.disabled = true
	repeat_button.visible = false
	result_status_label.visible = false
	situation_image.visible = true
	situation_image.custom_minimum_size = Vector2(760, 190)
	options_top_spacer.visible = true
	options_box.visible = true
	bottom_spacer.custom_minimum_size = Vector2(0, 0)

	var img_path: String = String(q.get("image", ""))
	if img_path != "" and ResourceLoader.exists(img_path):
		situation_image.texture = load(img_path)
	else:
		situation_image.texture = null

	var options: Array = q.get("options", [])
	for i in range(option_buttons.size()):
		var b: Button = option_buttons[i]
		if i < options.size():
			b.text = String(options[i])
			b.disabled = false
			b.visible = true
		else:
			b.visible = false

func _on_option_pressed(index: int) -> void:
	if answered_current or current_index >= questions.size():
		return
	answered_current = true
	var q: Dictionary = questions[current_index]
	var correct_index: int = int(q.get("correct_index", -1))
	var is_correct := index == correct_index
	var popup_text := ""

	if is_correct:
		correct_total += 1
		popup_text = String(q.get("correct_feedback", "Correct!"))
	else:
		popup_text = String(q.get("incorrect_feedback", "Try again."))

	for b in option_buttons:
		b.disabled = true
	feedback_label.text = ""
	continue_button.disabled = true
	GameState.show_answer_feedback_popup(self, popup_text, is_correct, Callable(self, "_on_continue_pressed"))

func _finish_quiz() -> void:
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
	var total := maxi(int(result.get("total_questions", questions.size())), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))

	quiz_finished = true
	progress_label.text = "Challenge Complete"
	progress_label.add_theme_font_size_override("font_size", 26)
	progress_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	progress_label.add_theme_constant_override("outline_size", 4)
	top_spacer.custom_minimum_size = Vector2(0, 84)
	question_label.custom_minimum_size = Vector2(0, 120)
	question_label.add_theme_font_size_override("font_size", 24)
	if passed:
		question_label.text = "Great! You passed Classroom Language.\nBest score: " + str(best_correct) + "/" + str(total)
		feedback_label.text = "Your classroom expressions are improving."
	else:
		question_label.text = "Keep practicing. You need at least 70%.\nBest score: " + str(best_correct) + "/" + str(total)
		feedback_label.text = "Read each classroom situation carefully."
	if attempts > 1:
		feedback_label.text += " Attempts: " + str(attempts)

	situation_image.texture = null
	situation_image.visible = false
	situation_image.custom_minimum_size = Vector2(0, 0)
	options_top_spacer.visible = false
	options_box.visible = false
	for b in option_buttons:
		b.visible = false
	feedback_label.custom_minimum_size = Vector2(0, 64)
	feedback_label.add_theme_font_size_override("font_size", 20)
	bottom_spacer.custom_minimum_size = Vector2(0, 0)
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

func _start_new_attempt() -> void:
	current_index = 0
	correct_total = 0
	answered_current = false
	quiz_finished = false
	_show_question()

func _on_repeat_pressed() -> void:
	_start_new_attempt()

func _on_continue_pressed() -> void:
	if quiz_finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	if not answered_current:
		return
	current_index += 1
	_show_question()

func _on_back_pressed() -> void:
	if quiz_finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)

func _exit_with_badge_popup(scene_path: String, is_back: bool) -> void:
	GameState.show_badge_popup_or_continue(
		self,
		"classroom_survival",
		Callable(self, "_change_scene_after_popup").bind(scene_path, is_back)
	)

func _change_scene_after_popup(scene_path: String, is_back: bool) -> void:
	GameState.change_scene_with_transition(scene_path, is_back)
