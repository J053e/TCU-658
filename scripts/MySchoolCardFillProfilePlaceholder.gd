extends Control

const CHALLENGE_ID := "my_school_card_fill_profile"
const PASS_RATIO := 0.70

const BASE_WORD_BANK := [
	"age",
	"grade",
	"country",
	"province",
	"seven",
	"twelve",
	"Costa Rica",
	"Cartago",
	"San Jos\u00e9",
	"Heredia",
	"Guanacaste",
	"Puntarenas",
	"Lim\u00f3n",
	"Alajuela"
]

var title_label: Label
var instruction_label: Label
var feedback_label: Label
var card_panel: PanelContainer
var bank_panel: PanelContainer
var check_button: Button
var continue_button: Button
var back_button: Button
var repeat_button: Button
var status_label: Label

var name_input: LineEdit
var last_name_input: LineEdit
var age_input: LineEdit
var province_input: LineEdit
var bank_flow: FlowContainer

var active_input: LineEdit = null
var finished: bool = false

func _ready() -> void:
	GameState.decorate_screen(self, GameState.get_minigame_background("my_school_card", "fill_profile"))
	_build_ui()
	if GameState.has_challenge_result(CHALLENGE_ID):
		_show_saved_summary()
	else:
		_show_form_state()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 44)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	title_label = Label.new()
	title_label.text = "Complete the Profile"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title_label, 38, true)
	root.add_child(title_label)

	instruction_label = Label.new()
	instruction_label.text = "Write your information.  Use simple English.  Check your spelling."
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.custom_minimum_size = Vector2(0, 44)
	GameState.style_label(instruction_label, 22, false)
	root.add_child(instruction_label)

	var content := HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	root.add_child(content)

	card_panel = PanelContainer.new()
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(card_panel)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 14)
	card_margin.add_theme_constant_override("margin_top", 12)
	card_margin.add_theme_constant_override("margin_right", 14)
	card_margin.add_theme_constant_override("margin_bottom", 12)
	card_panel.add_child(card_margin)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 10)
	card_margin.add_child(card_vbox)

	var card_title := Label.new()
	card_title.text = "My School Card"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(card_title, 30, true)
	card_vbox.add_child(card_title)

	var fields_grid := GridContainer.new()
	fields_grid.columns = 2
	fields_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields_grid.add_theme_constant_override("h_separation", 10)
	fields_grid.add_theme_constant_override("v_separation", 10)
	card_vbox.add_child(fields_grid)

	_add_field_with_input(fields_grid, "Name:", "name")
	name_input = fields_grid.get_child(fields_grid.get_child_count() - 1) as LineEdit

	_add_field_with_input(fields_grid, "Last name:", "last_name")
	last_name_input = fields_grid.get_child(fields_grid.get_child_count() - 1) as LineEdit

	_add_field_with_input(fields_grid, "Age:", "age")
	age_input = fields_grid.get_child(fields_grid.get_child_count() - 1) as LineEdit

	_add_field_with_label(fields_grid, "Grade:", "Seventh grade")
	_add_field_with_label(fields_grid, "Country:", "Costa Rica")

	_add_field_with_input(fields_grid, "Province:", "province")
	province_input = fields_grid.get_child(fields_grid.get_child_count() - 1) as LineEdit

	bank_panel = PanelContainer.new()
	bank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_panel.custom_minimum_size = Vector2(340, 0)
	content.add_child(bank_panel)

	var bank_margin := MarginContainer.new()
	bank_margin.add_theme_constant_override("margin_left", 10)
	bank_margin.add_theme_constant_override("margin_top", 10)
	bank_margin.add_theme_constant_override("margin_right", 10)
	bank_margin.add_theme_constant_override("margin_bottom", 10)
	bank_panel.add_child(bank_margin)

	var bank_vbox := VBoxContainer.new()
	bank_vbox.add_theme_constant_override("separation", 8)
	bank_margin.add_child(bank_vbox)

	var bank_title := Label.new()
	bank_title.text = "Word Bank"
	bank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(bank_title, 24, false)
	bank_vbox.add_child(bank_title)

	var bank_scroll := ScrollContainer.new()
	bank_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	bank_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	bank_vbox.add_child(bank_scroll)

	bank_flow = FlowContainer.new()
	bank_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bank_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	bank_flow.add_theme_constant_override("h_separation", 8)
	bank_flow.add_theme_constant_override("v_separation", 8)
	bank_scroll.add_child(bank_flow)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(0, 36)
	GameState.style_label(feedback_label, 20, true)
	root.add_child(feedback_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)

	check_button = Button.new()
	check_button.text = "Check"
	GameState.style_menu_button(check_button, "green")
	check_button.pressed.connect(_on_check_pressed)
	actions.add_child(check_button)

	continue_button = Button.new()
	continue_button.text = "Back to Zone"
	GameState.style_menu_button(continue_button, "yellow")
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	actions.add_child(continue_button)

	back_button = Button.new()
	back_button.text = "Back"
	GameState.style_menu_button(back_button, "orange")
	back_button.pressed.connect(_on_back_pressed)
	actions.add_child(back_button)

	repeat_button = Button.new()
	repeat_button.text = "Repeat"
	GameState.style_menu_button(repeat_button, "purple")
	repeat_button.visible = false
	repeat_button.pressed.connect(_on_repeat_pressed)
	actions.add_child(repeat_button)

	status_label = Label.new()
	status_label.visible = false
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(status_label, 20, true)
	actions.add_child(status_label)

func _add_field_with_input(grid: GridContainer, label_text: String, profile_key: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameState.style_label(label, 22, false)
	grid.add_child(label)

	var input := LineEdit.new()
	input.custom_minimum_size = Vector2(0, 48)
	input.text = String(GameState.profile.get(profile_key, ""))
	input.focus_entered.connect(_on_input_focused.bind(input))
	grid.add_child(input)

func _add_field_with_label(grid: GridContainer, label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameState.style_label(label, 22, false)
	grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameState.style_label(value, 22, true)
	grid.add_child(value)

func _show_form_state() -> void:
	finished = false
	card_panel.visible = true
	bank_panel.visible = true
	check_button.visible = true
	check_button.disabled = false
	continue_button.visible = false
	repeat_button.visible = false
	status_label.visible = false
	feedback_label.text = ""
	instruction_label.text = "Write your information.  Use simple English.  Check your spelling."
	_rebuild_word_bank()

	if name_input != null:
		name_input.editable = true
		name_input.text = String(GameState.profile.get("name", ""))
	if last_name_input != null:
		last_name_input.editable = true
		last_name_input.text = String(GameState.profile.get("last_name", ""))
	if age_input != null:
		age_input.editable = true
		age_input.text = String(GameState.profile.get("age", ""))
	if province_input != null:
		province_input.editable = true
		province_input.text = String(GameState.profile.get("province", ""))

func _on_input_focused(input: LineEdit) -> void:
	active_input = input

func _on_word_bank_pressed(word: String) -> void:
	if finished:
		return
	if active_input == null:
		feedback_label.text = "Select a field first."
		return
	active_input.text = word
	feedback_label.text = ""

func _on_check_pressed() -> void:
	if finished:
		return

	var name_ok := _clean(name_input.text) != ""
	var last_name_ok := _clean(last_name_input.text) != ""
	var age_ok := _clean(age_input.text) != ""
	var province_ok := _clean(province_input.text) != ""

	if not (name_ok and last_name_ok and age_ok and province_ok):
		feedback_label.text = "Please complete all the spaces."
		return

	GameState.profile["name"] = _clean(name_input.text)
	GameState.profile["last_name"] = _clean(last_name_input.text)
	GameState.profile["age"] = _clean(age_input.text)
	GameState.profile["grade"] = "seventh"
	GameState.profile["country"] = "Costa Rica"
	GameState.profile["province"] = _clean(province_input.text)
	GameState.save_progress()

	var result := GameState.record_challenge_result(CHALLENGE_ID, 1, 1, PASS_RATIO)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("my_school_card")
	_show_summary(result)

func _show_saved_summary() -> void:
	var result := GameState.get_challenge_result(CHALLENGE_ID)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("my_school_card")
	_show_summary(result)

func _show_summary(result: Dictionary) -> void:
	finished = true
	var total := maxi(int(result.get("total_questions", 1)), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))

	card_panel.visible = false
	bank_panel.visible = false
	check_button.visible = false
	continue_button.visible = true
	repeat_button.visible = true
	status_label.visible = true

	instruction_label.text = "Challenge Complete"
	if passed:
		feedback_label.text = "Profile complete!\nBest score: " + str(best_correct) + "/" + str(total)
		status_label.text = "Status: Approved"
		status_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.74))
	else:
		feedback_label.text = "Please complete all the spaces.\nBest score: " + str(best_correct) + "/" + str(total)
		status_label.text = "Status: Failed"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72))
	if attempts > 1:
		feedback_label.text += " Attempts: " + str(attempts)

func _on_repeat_pressed() -> void:
	_show_form_state()

func _on_continue_pressed() -> void:
	_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)

func _on_back_pressed() -> void:
	if finished:
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

func _clean(value: String) -> String:
	return value.strip_edges()

func _rebuild_word_bank() -> void:
	if bank_flow == null:
		return
	for child in bank_flow.get_children():
		child.queue_free()

	var tokens: Array[String] = []
	for token_variant in BASE_WORD_BANK:
		tokens.append(String(token_variant))

	var profile_tokens := [
		String(GameState.profile.get("name", "")),
		String(GameState.profile.get("last_name", "")),
		String(GameState.profile.get("age", ""))
	]
	for profile_token_variant in profile_tokens:
		var profile_token := String(profile_token_variant).strip_edges()
		if profile_token != "":
			tokens.append(profile_token)

	var unique_tokens: Array[String] = []
	for token_variant in tokens:
		var token := String(token_variant).strip_edges()
		if token == "":
			continue
		if unique_tokens.find(token) < 0:
			unique_tokens.append(token)

	for token in unique_tokens:
		var word_button := Button.new()
		word_button.text = token
		word_button.custom_minimum_size = Vector2(130, 40)
		GameState.style_menu_button(word_button, "blue")
		word_button.custom_minimum_size = Vector2(130, 40)
		word_button.add_theme_font_size_override("font_size", 20)
		word_button.pressed.connect(_on_word_bank_pressed.bind(token))
		bank_flow.add_child(word_button)
