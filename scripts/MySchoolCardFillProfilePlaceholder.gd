extends Control

const CHALLENGE_ID := "my_school_card_fill_profile"
const PASS_RATIO := 0.70

const DropSlotScript = preload("res://scripts/DialogueDropSlot.gd")
const DragSentenceButtonScript = preload("res://scripts/DragSentenceButton.gd")
const BankDropAreaScript = preload("res://scripts/DialogueBankDropArea.gd")

const VALID_PROVINCES := [
	"San Jose",
	"Heredia",
	"Guanacaste",
	"Puntarenas",
	"Limon",
	"Alajuela",
	"Cartago"
]

const VALID_GRADES := [
	"Sixth",
	"Seventh",
	"Eighth",
	"Ninth",
	"Tenth",
	"Eleventh",
	"Twelfth",
	"Thirteenth",
	"Fourteenth",
	"Fifteenth"
]

var title_label: Label
var instruction_label: Label
var feedback_panel: PanelContainer
var feedback_label: Label
var summary_panel: PanelContainer
var summary_details_label: Label
var summary_scroll: ScrollContainer
var card_panel: PanelContainer
var bank_panel
var content_row: HBoxContainer
var check_button: Button
var continue_button: Button
var back_button: Button
var repeat_button: Button
var status_label: Label
var bank_flow: FlowContainer

var slot_nodes: Dictionary = {}
var slot_assignments: Dictionary = {}
var slot_field_by_index: Array[String] = []
var token_text_by_id: Dictionary = {}
var bank_ids: Array[String] = []

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
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	title_label = Label.new()
	title_label.text = "Complete the Profile"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title_label, 38, true)
	root.add_child(title_label)

	instruction_label = Label.new()
	instruction_label.text = "Write your information. Use simple English. Check your spelling."
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.custom_minimum_size = Vector2(0, 44)
	GameState.style_label(instruction_label, 22, false)
	root.add_child(instruction_label)

	content_row = HBoxContainer.new()
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content_row.custom_minimum_size = Vector2(0, 430)
	content_row.add_theme_constant_override("separation", 12)
	root.add_child(content_row)

	card_panel = PanelContainer.new()
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_panel.custom_minimum_size = Vector2(0, 430)
	card_panel.add_theme_stylebox_override("panel", _panel_style())
	content_row.add_child(card_panel)

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

	_add_socket_field(fields_grid, "Name:", "name")
	_add_socket_field(fields_grid, "Last name:", "last_name")
	_add_socket_field(fields_grid, "Age:", "age")
	_add_socket_field(fields_grid, "Grade:", "grade", "grade")
	_add_field_with_label(fields_grid, "Country:", "Costa Rica")
	_add_socket_field(fields_grid, "Province:", "province")

	bank_panel = BankDropAreaScript.new()
	bank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_panel.custom_minimum_size = Vector2(340, 430)
	bank_panel.add_theme_stylebox_override("panel", _panel_style())
	bank_panel.sentence_returned.connect(_on_bank_sentence_returned)
	content_row.add_child(bank_panel)

	var bank_margin := MarginContainer.new()
	bank_margin.add_theme_constant_override("margin_left", 10)
	bank_margin.add_theme_constant_override("margin_top", 14)
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

	var bank_top_spacer := Control.new()
	bank_top_spacer.custom_minimum_size = Vector2(0, 8)
	bank_vbox.add_child(bank_top_spacer)

	var bank_scroll := ScrollContainer.new()
	bank_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	bank_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	bank_vbox.add_child(bank_scroll)

	var bank_content_margin := MarginContainer.new()
	bank_content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_content_margin.add_theme_constant_override("margin_top", 36)
	bank_content_margin.add_theme_constant_override("margin_bottom", 6)
	bank_scroll.add_child(bank_content_margin)

	bank_flow = FlowContainer.new()
	bank_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bank_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	bank_flow.add_theme_constant_override("h_separation", 8)
	bank_flow.add_theme_constant_override("v_separation", 8)
	bank_content_margin.add_child(bank_flow)

	feedback_panel = PanelContainer.new()
	feedback_panel.visible = false
	feedback_panel.add_theme_stylebox_override("panel", _result_text_panel_style())
	root.add_child(feedback_panel)

	var feedback_margin := MarginContainer.new()
	feedback_margin.add_theme_constant_override("margin_left", 12)
	feedback_margin.add_theme_constant_override("margin_top", 8)
	feedback_margin.add_theme_constant_override("margin_right", 12)
	feedback_margin.add_theme_constant_override("margin_bottom", 8)
	feedback_panel.add_child(feedback_margin)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(0, 36)
	GameState.style_label(feedback_label, 20, true)
	feedback_margin.add_child(feedback_label)

	summary_panel = PanelContainer.new()
	summary_panel.visible = false
	summary_panel.add_theme_stylebox_override("panel", _result_text_panel_style())
	root.add_child(summary_panel)

	var summary_margin := MarginContainer.new()
	summary_margin.add_theme_constant_override("margin_left", 12)
	summary_margin.add_theme_constant_override("margin_top", 10)
	summary_margin.add_theme_constant_override("margin_right", 12)
	summary_margin.add_theme_constant_override("margin_bottom", 10)
	summary_panel.add_child(summary_margin)

	summary_scroll = ScrollContainer.new()
	summary_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_scroll.custom_minimum_size = Vector2(0, 220)
	summary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	summary_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	summary_margin.add_child(summary_scroll)

	summary_details_label = Label.new()
	summary_details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_details_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	summary_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_details_label.custom_minimum_size = Vector2(0, 220)
	GameState.style_label(summary_details_label, 18, false)
	summary_scroll.add_child(summary_details_label)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.custom_minimum_size = Vector2(0, 56)
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

func _add_socket_field(grid: GridContainer, label_text: String, field_id: String, suffix_text: String = "") -> void:
	var label := Label.new()
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameState.style_label(label, 22, false)
	grid.add_child(label)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	grid.add_child(row)

	var slot_index := slot_field_by_index.size()
	slot_field_by_index.append(field_id)

	var slot = DropSlotScript.new()
	slot.custom_minimum_size = Vector2(0, 52)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.add_theme_stylebox_override("panel", _slot_style())
	slot.configure(slot_index)
	slot.sentence_dropped.connect(_on_slot_sentence_dropped)
	slot.sentence_cleared.connect(_on_slot_sentence_cleared)
	row.add_child(slot)
	slot_nodes[field_id] = slot
	slot_assignments[field_id] = ""

	if suffix_text != "":
		var suffix := Label.new()
		suffix.text = suffix_text
		suffix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		GameState.style_label(suffix, 20, false)
		row.add_child(suffix)

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
	content_row.visible = true
	check_button.visible = true
	check_button.disabled = false
	continue_button.visible = false
	repeat_button.visible = false
	status_label.visible = false
	feedback_panel.visible = false
	feedback_label.text = ""
	summary_panel.visible = false
	summary_details_label.text = ""
	instruction_label.text = "Drag the correct blocks to complete your profile."

	for field_id in slot_field_by_index:
		slot_assignments[field_id] = ""

	_rebuild_word_bank()
	_render_slots()
	_render_bank()

func _on_slot_sentence_dropped(slot_index: int, sentence_id: String) -> void:
	if finished:
		return
	if sentence_id == "" or not token_text_by_id.has(sentence_id):
		return
	if slot_index < 0 or slot_index >= slot_field_by_index.size():
		return

	var field_id := slot_field_by_index[slot_index]
	var existing := String(slot_assignments.get(field_id, ""))
	if existing != "":
		_add_to_bank(existing)

	for other_field_variant in slot_assignments.keys():
		var other_field := String(other_field_variant)
		if String(slot_assignments[other_field]) == sentence_id:
			slot_assignments[other_field] = ""

	_remove_from_bank(sentence_id)
	slot_assignments[field_id] = sentence_id

	_render_slots()
	_render_bank()

func _on_slot_sentence_cleared(slot_index: int) -> void:
	if finished:
		return
	if slot_index < 0 or slot_index >= slot_field_by_index.size():
		return

	var field_id := slot_field_by_index[slot_index]
	var existing := String(slot_assignments.get(field_id, ""))
	if existing == "":
		return

	slot_assignments[field_id] = ""
	_add_to_bank(existing)
	_render_slots()
	_render_bank()

func _on_bank_sentence_returned(sentence_id: String) -> void:
	if finished:
		return
	if sentence_id == "":
		return

	for field_id_variant in slot_assignments.keys():
		var field_id := String(field_id_variant)
		if String(slot_assignments[field_id]) == sentence_id:
			slot_assignments[field_id] = ""
			_add_to_bank(sentence_id)
			break
	_render_slots()
	_render_bank()

func _render_slots() -> void:
	for field_id_variant in slot_field_by_index:
		var field_id := String(field_id_variant)
		if not slot_nodes.has(field_id):
			continue
		var slot = slot_nodes[field_id]
		slot.set_locked(finished)
		var sentence_id := String(slot_assignments.get(field_id, ""))
		if sentence_id != "" and token_text_by_id.has(sentence_id):
			slot.set_sentence(sentence_id, String(token_text_by_id[sentence_id]))
		else:
			slot.clear_sentence()

func _render_bank() -> void:
	for child in bank_flow.get_children():
		child.queue_free()
	for sid_variant in bank_ids:
		var sid := String(sid_variant)
		if not token_text_by_id.has(sid):
			continue
		var chip = DragSentenceButtonScript.new()
		chip.setup(sid, String(token_text_by_id[sid]))
		chip.drag_enabled = not finished
		chip.custom_minimum_size = Vector2(130, 40)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip.set_chip_style(_bank_chip_style())
		if chip.has_method("set_label_style"):
			chip.set_label_style(GameState.pretty_font, 20)
		bank_flow.add_child(chip)
	if bank_panel != null and bank_panel.has_method("set_locked"):
		bank_panel.set_locked(finished)

func _on_check_pressed() -> void:
	if finished:
		return
	var evaluation := _evaluate_profile()
	var issues: Array = evaluation.get("issues", [])
	var passed := issues.is_empty()

	if passed:
		var values: Dictionary = evaluation.get("values", {})
		GameState.profile["name"] = String(values.get("name", ""))
		GameState.profile["last_name"] = String(values.get("last_name", ""))
		GameState.profile["age"] = String(values.get("age", ""))
		GameState.profile["grade"] = String(values.get("grade", ""))
		GameState.profile["country"] = "Costa Rica"
		GameState.profile["province"] = String(values.get("province", ""))
		GameState.save_progress()

	var result := GameState.record_challenge_result(CHALLENGE_ID, 1 if passed else 0, 1, PASS_RATIO)
	var details_text := _build_summary_details(evaluation, passed)
	result["last_summary_details"] = details_text
	GameState.challenge_results[CHALLENGE_ID] = result
	GameState.save_progress()
	if passed and bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("my_school_card")
	_show_summary(result, evaluation)

func _show_saved_summary() -> void:
	var result := GameState.get_challenge_result(CHALLENGE_ID)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("my_school_card")
	_show_summary(result, {})

func _show_summary(result: Dictionary, evaluation: Dictionary) -> void:
	finished = true
	var total := maxi(int(result.get("total_questions", 1)), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var attempts := int(result.get("attempts", 0))

	content_row.visible = false
	check_button.visible = false
	continue_button.visible = true
	repeat_button.visible = true
	status_label.visible = true
	feedback_panel.visible = true
	summary_panel.visible = true

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

	var details_text := ""
	if evaluation.is_empty() and result.has("last_summary_details"):
		details_text = String(result.get("last_summary_details", ""))
	if details_text == "":
		details_text = _build_summary_details(evaluation, passed)
	summary_details_label.text = details_text
	summary_scroll.scroll_vertical = 0
	_render_slots()
	_render_bank()

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

func _slot_text(field_id: String) -> String:
	var sid := String(slot_assignments.get(field_id, ""))
	if sid == "":
		return ""
	return _clean(String(token_text_by_id.get(sid, "")))

func _evaluate_profile() -> Dictionary:
	var issues: Array[String] = []
	var values := {
		"name": _slot_text("name"),
		"last_name": _slot_text("last_name"),
		"age": _slot_text("age"),
		"grade": _slot_text("grade"),
		"country": "Costa Rica",
		"province": _slot_text("province")
	}

	if String(values["name"]) == "":
		issues.append("Name: missing value.")
	if String(values["last_name"]) == "":
		issues.append("Last name: missing value.")
	if String(values["age"]) == "":
		issues.append("Age: missing value.")
	if String(values["grade"]) == "":
		issues.append("Grade: missing value.")
	if String(values["province"]) == "":
		issues.append("Province: missing value.")

	var expected_name := _clean(String(GameState.profile.get("name", "")))
	var expected_last_name := _clean(String(GameState.profile.get("last_name", "")))
	var expected_age := _clean(String(GameState.profile.get("age", "")))

	if expected_name != "" and not _equals_nocase(String(values["name"]), expected_name):
		issues.append("Name: must match your initial profile name.")
	if expected_last_name != "" and not _equals_nocase(String(values["last_name"]), expected_last_name):
		issues.append("Last name: must match your initial profile last name.")
	if expected_age != "" and not _equals_nocase(String(values["age"]), expected_age):
		issues.append("Age: must match your initial profile age.")
	if String(values["age"]) != "" and not String(values["age"]).is_valid_int():
		issues.append("Age: must be numeric.")
	if String(values["grade"]) != "" and not _is_valid_grade(String(values["grade"])):
		issues.append("Grade: choose one value from Sixth to Fifteenth.")
	if String(values["province"]) != "" and not _is_valid_province(String(values["province"])):
		issues.append("Province: choose a valid Costa Rica province.")

	if _is_valid_grade(String(values["name"])) or _is_valid_grade(String(values["last_name"])):
		issues.append("Name/Last name: cannot use grade values.")
	if _is_valid_province(String(values["name"])) or _is_valid_province(String(values["last_name"])):
		issues.append("Name/Last name: cannot use province values.")
	if _equals_nocase(String(values["age"]), String(values["province"])) and String(values["age"]) != "":
		issues.append("Age and Province: cannot be the same value.")

	return {
		"issues": issues,
		"values": values
	}

func _build_summary_details(evaluation: Dictionary, passed: bool) -> String:
	var values: Dictionary = evaluation.get("values", {})
	if values.is_empty():
		values = {
			"name": String(GameState.profile.get("name", "")),
			"last_name": String(GameState.profile.get("last_name", "")),
			"age": String(GameState.profile.get("age", "")),
			"grade": String(GameState.profile.get("grade", "")),
			"country": "Costa Rica",
			"province": String(GameState.profile.get("province", ""))
		}

	var summary := "My School Card Result:\n"
	summary += "Name: " + String(values.get("name", "")) + "\n"
	summary += "Last name: " + String(values.get("last_name", "")) + "\n"
	summary += "Age: " + String(values.get("age", "")) + "\n"
	summary += "Grade: " + String(values.get("grade", "")) + " grade\n"
	summary += "Country: Costa Rica\n"
	summary += "Province: " + String(values.get("province", ""))

	var issues: Array = evaluation.get("issues", [])
	if passed:
		summary += "\n\nAll fields are valid."
	elif not issues.is_empty():
		summary += "\n\nFields to fix:"
		for issue_variant in issues:
			summary += "\n- " + String(issue_variant)

	return summary

func _rebuild_word_bank() -> void:
	token_text_by_id.clear()
	bank_ids.clear()

	var tokens: Array[String] = []
	for grade_variant in VALID_GRADES:
		tokens.append(String(grade_variant))
	for province_variant in VALID_PROVINCES:
		tokens.append(String(province_variant))

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

	var idx := 0
	for token in unique_tokens:
		var sid := "t" + str(idx)
		idx += 1
		token_text_by_id[sid] = token
		bank_ids.append(sid)

func _add_to_bank(sentence_id: String) -> void:
	if sentence_id == "":
		return
	if bank_ids.find(sentence_id) < 0:
		bank_ids.append(sentence_id)

func _remove_from_bank(sentence_id: String) -> void:
	var idx := bank_ids.find(sentence_id)
	if idx >= 0:
		bank_ids.remove_at(idx)

func _is_valid_grade(value: String) -> bool:
	for grade_variant in VALID_GRADES:
		if _equals_nocase(value, String(grade_variant)):
			return true
	return false

func _is_valid_province(value: String) -> bool:
	for province_variant in VALID_PROVINCES:
		if _equals_nocase(value, String(province_variant)):
			return true
	return false

func _equals_nocase(a: String, b: String) -> bool:
	return a.strip_edges().to_lower() == b.strip_edges().to_lower()

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

func _slot_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.24, 0.9)
	sb.border_color = Color(0.76, 0.88, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	sb.set_content_margin_all(10)
	return sb

func _bank_chip_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.21, 0.55, 0.93, 0.97)
	sb.border_color = Color(0.76, 0.92, 1.0, 0.98)
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_right = 20
	sb.corner_radius_bottom_left = 20
	sb.shadow_color = Color(0, 0, 0, 0.22)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb

func _result_text_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.11, 0.22, 0.82)
	sb.border_color = Color(0.74, 0.88, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	return sb
