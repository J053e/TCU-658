extends Control

const DATA_PATH := "res://data/my_school_card_label_classroom.json"
const BACKGROUND_PATH := "res://assets/zones/zone_04_my_school_card/backgrounds/minigames/label_classroom.png"
const CHALLENGE_ID := "my_school_card_label_classroom"
const PASS_RATIO := 0.70

var title_label: Label
var progress_label: Label
var instruction_label: Label
var instruction_panel: PanelContainer
var object_image: TextureRect
var answer_input: LineEdit
var feedback_label: Label
var layout_spacer: Control
var actions_box: HBoxContainer
var check_button: Button
var continue_button: Button
var back_button: Button
var repeat_button: Button
var status_label: Label

var challenge_data: Dictionary = {}
var objects: Array = []
var current_index: int = 0
var correct_total: int = 0
var answered_current: bool = false
var challenge_finished: bool = false

func _ready() -> void:
	GameState.decorate_screen(self, BACKGROUND_PATH)
	_build_ui()
	_load_challenge_data()
	if GameState.has_challenge_result(CHALLENGE_ID):
		_show_saved_summary()
	else:
		_start_new_attempt()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	title_label = Label.new()
	title_label.text = "Label the Classroom Objects"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title_label, 40, true)
	root.add_child(title_label)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(progress_label, 24, true)
	root.add_child(progress_label)

	instruction_panel = PanelContainer.new()
	instruction_panel.add_theme_stylebox_override("panel", _instruction_panel_style())
	root.add_child(instruction_panel)

	var instruction_margin := MarginContainer.new()
	instruction_margin.add_theme_constant_override("margin_left", 14)
	instruction_margin.add_theme_constant_override("margin_top", 8)
	instruction_margin.add_theme_constant_override("margin_right", 14)
	instruction_margin.add_theme_constant_override("margin_bottom", 8)
	instruction_panel.add_child(instruction_margin)

	instruction_label = Label.new()
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.custom_minimum_size = Vector2(0, 46)
	GameState.style_label(instruction_label, 23, false)
	instruction_margin.add_child(instruction_label)

	object_image = TextureRect.new()
	object_image.custom_minimum_size = Vector2(0, 260)
	object_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	object_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	object_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(object_image)

	answer_input = LineEdit.new()
	answer_input.placeholder_text = "Type object name"
	answer_input.max_length = 64
	answer_input.custom_minimum_size = Vector2(0, 58)
	answer_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_input.add_theme_font_override("font", GameState.pretty_font)
	answer_input.add_theme_font_size_override("font_size", 30)
	root.add_child(answer_input)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(0, 42)
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	layout_spacer = Control.new()
	layout_spacer.custom_minimum_size = Vector2(0, 6)
	root.add_child(layout_spacer)

	actions_box = HBoxContainer.new()
	actions_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_box.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_box.add_theme_constant_override("separation", 10)
	root.add_child(actions_box)

	check_button = Button.new()
	check_button.text = "Check"
	GameState.style_menu_button(check_button, "green")
	check_button.pressed.connect(_on_check_pressed)
	actions_box.add_child(check_button)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.disabled = true
	GameState.style_menu_button(continue_button, "yellow")
	continue_button.pressed.connect(_on_continue_pressed)
	actions_box.add_child(continue_button)

	back_button = Button.new()
	back_button.text = "Back"
	GameState.style_menu_button(back_button, "orange")
	back_button.pressed.connect(_on_back_pressed)
	actions_box.add_child(back_button)

	repeat_button = Button.new()
	repeat_button.text = "Repeat"
	repeat_button.visible = false
	GameState.style_menu_button(repeat_button, "purple")
	repeat_button.pressed.connect(_on_repeat_pressed)
	actions_box.add_child(repeat_button)

	status_label = Label.new()
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(status_label, 20, true)
	actions_box.add_child(status_label)

func _load_challenge_data() -> void:
	objects.clear()
	challenge_data.clear()
	challenge_data = GameState.load_json_data(DATA_PATH)
	objects = challenge_data.get("objects", [])

func _start_new_attempt() -> void:
	current_index = 0
	correct_total = 0
	answered_current = false
	challenge_finished = false
	progress_label.add_theme_font_size_override("font_size", 24)
	check_button.visible = true
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.disabled = true
	repeat_button.visible = false
	status_label.visible = false
	feedback_label.text = ""
	feedback_label.custom_minimum_size = Vector2(0, 42)
	feedback_label.add_theme_font_size_override("font_size", 20)
	answer_input.visible = true
	answer_input.editable = true
	answer_input.custom_minimum_size = Vector2(0, 58)
	object_image.visible = true
	object_image.custom_minimum_size = Vector2(0, 260)
	layout_spacer.custom_minimum_size = Vector2(0, 6)
	_show_current_object()

func _show_current_object() -> void:
	if objects.is_empty():
		progress_label.text = "Object 0/0"
		instruction_label.text = "Challenge data missing."
		object_image.texture = null
		answer_input.text = ""
		answer_input.editable = false
		check_button.disabled = true
		continue_button.disabled = true
		return
	if current_index >= objects.size():
		_finish_challenge()
		return

	var current: Dictionary = objects[current_index]
	progress_label.text = "Object " + str(current_index + 1) + "/" + str(objects.size())
	instruction_label.text = String(challenge_data.get("instruction", "Type the correct object name."))
	feedback_label.text = ""

	var image_path := String(current.get("image", ""))
	object_image.texture = GameState.load_texture_resource(image_path)

	answer_input.text = ""
	answer_input.editable = true
	answer_input.grab_focus()
	check_button.disabled = false
	continue_button.disabled = true
	answered_current = false

func _on_check_pressed() -> void:
	if challenge_finished or answered_current:
		return
	if current_index < 0 or current_index >= objects.size():
		return

	var current: Dictionary = objects[current_index]
	var expected := _normalize_answer(String(current.get("answer", "")))
	var given := _normalize_answer(answer_input.text)
	var is_correct := expected != "" and given == expected
	var popup_text := ""
	if is_correct:
		correct_total += 1
		popup_text = "Great! You labelled this object."
	else:
		popup_text = "Not quite. Look carefully at the next object."

	answer_input.editable = false
	check_button.disabled = true
	continue_button.disabled = true
	feedback_label.text = ""
	answered_current = true
	GameState.show_answer_feedback_popup(self, popup_text, is_correct, Callable(self, "_on_continue_pressed"))

func _on_continue_pressed() -> void:
	if challenge_finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	if not answered_current:
		return
	current_index += 1
	_show_current_object()

func _finish_challenge() -> void:
	challenge_finished = true
	var total := maxi(objects.size(), 1)
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
	challenge_finished = true
	var total := maxi(int(result.get("total_questions", objects.size())), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))

	progress_label.text = "Challenge Complete"
	progress_label.add_theme_font_size_override("font_size", 26)
	if passed:
		instruction_label.text = "Great job! You labeled the classroom objects."
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

	object_image.visible = false
	object_image.custom_minimum_size = Vector2.ZERO
	answer_input.visible = false
	answer_input.custom_minimum_size = Vector2.ZERO
	feedback_label.custom_minimum_size = Vector2(0, 56)
	feedback_label.add_theme_font_size_override("font_size", 22)
	layout_spacer.custom_minimum_size = Vector2(0, 126)
	check_button.visible = false
	continue_button.visible = true
	continue_button.text = "Back to Zone"
	continue_button.disabled = false
	repeat_button.visible = true
	status_label.visible = true

func _normalize_answer(text_value: String) -> String:
	var lower := text_value.to_lower()
	var clean := ""
	for i in range(lower.length()):
		var c := lower[i]
		if c >= "a" and c <= "z":
			clean += c
	return clean

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

func _instruction_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.10, 0.20, 0.78)
	sb.border_color = Color(0.72, 0.86, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	return sb
