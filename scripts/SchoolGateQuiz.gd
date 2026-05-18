extends Control

const QUIZ_DATA_PATH := "res://data/school_gate_quiz.json"
const PASS_RATIO := 0.70

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

var quiz_data: Dictionary = {}
var questions: Array = []
var current_index: int = 0
var correct_total: int = 0
var answered_current: bool = false
var quiz_finished: bool = false

func _ready() -> void:
	_build_ui()
	_load_quiz_data()
	_show_question()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	GameState.decorate_screen(self, GameState.get_minigame_background("school_gate", "school_gate_challenge"))

	var screen_margin := MarginContainer.new()
	screen_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_margin.add_theme_constant_override("margin_left", 64)
	screen_margin.add_theme_constant_override("margin_top", 18)
	screen_margin.add_theme_constant_override("margin_right", 64)
	screen_margin.add_theme_constant_override("margin_bottom", 40)
	add_child(screen_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.custom_minimum_size = Vector2(1060, 0)
	screen_margin.add_child(root)

	top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 44)
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
	question_label.custom_minimum_size = Vector2(0, 54)
	GameState.style_label(question_label, 22, false)
	root.add_child(question_label)

	situation_image = TextureRect.new()
	situation_image.custom_minimum_size = Vector2(760, 210)
	situation_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	situation_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	situation_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(situation_image)

	options_top_spacer = Control.new()
	options_top_spacer.custom_minimum_size = Vector2(0, 10)
	root.add_child(options_top_spacer)

	options_box = VBoxContainer.new()
	options_box.add_theme_constant_override("separation", 8)
	root.add_child(options_box)
	for i in range(3):
		var button := Button.new()
		GameState.style_menu_button(button, ["blue", "green", "purple"][i])
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(_on_option_pressed.bind(i))
		options_box.add_child(button)
		option_buttons.append(button)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_label.custom_minimum_size = Vector2(0, 22)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	feedback_label.clip_text = true
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bottom_spacer.custom_minimum_size = Vector2(0, 0)
	root.add_child(bottom_spacer)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	root.add_child(actions)

	continue_button = Button.new()
	continue_button.text = "Continue"
	GameState.style_menu_button(continue_button, "yellow")
	continue_button.disabled = true
	continue_button.pressed.connect(_on_continue_pressed)
	actions.add_child(continue_button)

	back_button = Button.new()
	back_button.text = "Back"
	GameState.style_menu_button(back_button, "orange")
	back_button.pressed.connect(_on_back_pressed)
	actions.add_child(back_button)

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
	top_spacer.custom_minimum_size = Vector2(0, 44)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.custom_minimum_size = Vector2(0, 54)
	question_label.text = q.get("prompt", "")
	feedback_label.custom_minimum_size = Vector2(0, 22)
	feedback_label.text = ""
	answered_current = false
	quiz_finished = false
	continue_button.text = "Continue"
	continue_button.disabled = true
	situation_image.visible = true
	situation_image.custom_minimum_size = Vector2(760, 210)
	options_top_spacer.visible = true
	options_box.visible = true
	bottom_spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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

	if is_correct:
		correct_total += 1
		feedback_label.text = q.get("correct_feedback", "Correct!")
	else:
		feedback_label.text = q.get("incorrect_feedback", "Try again.")

	for b in option_buttons:
		b.disabled = true
	continue_button.disabled = false

func _finish_quiz() -> void:
	var pass_required: int = int(ceil(float(questions.size()) * PASS_RATIO))
	var passed: bool = correct_total >= pass_required
	if passed:
		GameState.mark_zone_complete("school_gate")
		GameState.save_progress()
	quiz_finished = true
	progress_label.text = "Challenge Complete"
	top_spacer.custom_minimum_size = Vector2(0, 252)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.custom_minimum_size = Vector2(0, 106)
	if passed:
		question_label.text = "Stamp earned! School Gate complete.\nScore: " + str(correct_total) + "/" + str(questions.size())
		feedback_label.text = "Great job!"
	else:
		question_label.text = "You need at least 70% to earn the badge.\nScore: " + str(correct_total) + "/" + str(questions.size())
		feedback_label.text = "Try again to unlock the School Gate badge."
	situation_image.texture = null
	situation_image.visible = false
	situation_image.custom_minimum_size = Vector2(0, 0)
	options_top_spacer.visible = false
	options_box.visible = false
	for b in option_buttons:
		b.visible = false
	feedback_label.custom_minimum_size = Vector2(0, 12)
	bottom_spacer.custom_minimum_size = Vector2(0, 0)
	continue_button.text = "Back to Zones"
	continue_button.disabled = false

func _on_continue_pressed() -> void:
	if quiz_finished:
		GameState.change_scene_with_transition("res://scenes/WorldMap.tscn", true)
		return
	if not answered_current:
		return
	current_index += 1
	_show_question()

func _on_back_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)
