extends Control

const DATA_PATH := "res://data/classroom_read_listen_click.json"

var instruction_label: Label
var progress_label: Label
var feedback_label: Label
var options_row: HBoxContainer
var option_buttons := []
var continue_button: Button
var back_button: Button

var quiz_data: Dictionary = {}
var questions: Array = []
var current_index := 0
var correct_total := 0
var answered_current := false
var finished := false

func _ready() -> void:
	GameState.decorate_screen(self, GameState.get_minigame_background("classroom_survival", "read_listen_click"))
	_build_ui()
	_load_data()
	_show_question()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 42)
	add_child(margin)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(center)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.custom_minimum_size = Vector2(1120, 590)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(root)

	var title := Label.new()
	title.text = "Read, Listen and Click"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title, 36, true)
	root.add_child(title)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(progress_label, 22, false)
	root.add_child(progress_label)

	instruction_label = Label.new()
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.custom_minimum_size = Vector2(0, 56)
	GameState.style_label(instruction_label, 28, true)
	root.add_child(instruction_label)

	options_row = HBoxContainer.new()
	options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	options_row.add_theme_constant_override("separation", 12)
	root.add_child(options_row)

	for i in range(3):
		var option_button := _create_option_button(i)
		options_row.add_child(option_button)
		option_buttons.append(option_button)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.custom_minimum_size = Vector2(0, 34)
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	GameState.style_menu_button(back_button, "orange")
	back_button.pressed.connect(_on_back_pressed)
	actions.add_child(back_button)

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

	var chosen := hover if hovered else normal
	button.add_theme_stylebox_override("normal", chosen)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

func _on_option_hover(button: Button, entered: bool) -> void:
	if button.disabled:
		return
	_apply_option_style(button, entered)

func _load_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		return
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	quiz_data = parsed as Dictionary
	questions = quiz_data.get("questions", [])

func _show_question() -> void:
	if questions.is_empty():
		instruction_label.text = "Question data missing."
		return
	if current_index >= questions.size():
		_finish()
		return

	var q: Dictionary = questions[current_index]
	progress_label.text = "Instruction " + str(current_index + 1) + "/" + str(questions.size())
	instruction_label.text = q.get("instruction", "")
	feedback_label.text = ""
	answered_current = false
	finished = false
	continue_button.disabled = true
	continue_button.text = "Continue"
	options_row.visible = true

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

func _on_option_pressed(index: int) -> void:
	if answered_current or current_index >= questions.size():
		return
	answered_current = true
	var q: Dictionary = questions[current_index]
	var correct_index: int = int(q.get("correct_index", -1))
	var correct := index == correct_index

	if correct:
		correct_total += 1
		feedback_label.text = q.get("correct_feedback", "Correct!")
	else:
		feedback_label.text = q.get("incorrect_feedback", "Try again.")

	for b in option_buttons:
		b.disabled = true
	continue_button.disabled = false

func _on_continue_pressed() -> void:
	if finished:
		GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)
		return
	if not answered_current:
		return
	current_index += 1
	_show_question()

func _finish() -> void:
	finished = true
	var required := int(ceil(float(questions.size()) * 0.7))
	var passed := correct_total >= required

	progress_label.text = "Challenge Complete"
	if passed:
		instruction_label.text = "Great! You passed Read, Listen and Click.\nScore: " + str(correct_total) + "/" + str(questions.size())
		feedback_label.text = "You can understand simple classroom instructions."
	else:
		instruction_label.text = "Keep practicing. You need at least 70%.\nScore: " + str(correct_total) + "/" + str(questions.size())
		feedback_label.text = "Read carefully and try again."

	options_row.visible = false
	continue_button.text = "Back to Zone"
	continue_button.disabled = false

func _on_back_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn", true)

func _load_fitted_icon(path: String, max_size: Vector2i) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
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
