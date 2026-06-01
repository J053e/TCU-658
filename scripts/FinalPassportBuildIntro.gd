extends Control

const DATA_PATH := "res://data/final_passport_build_intro.json"
const CHALLENGE_ID := "final_passport_build_intro"
const BACKGROUND_PATH := "res://assets/zones/zone_05_final_passport/backgrounds/minigames/build_your_intro.png"

const DropSlotScript = preload("res://scripts/DialogueDropSlot.gd")
const DragSentenceButtonScript = preload("res://scripts/DragSentenceButton.gd")
const BankDropAreaScript = preload("res://scripts/DialogueBankDropArea.gd")

var title_label: Label
var progress_label: Label
var prompt_label: Label
var prompt_panel: PanelContainer
var feedback_label: Label
var feedback_panel: PanelContainer
var summary_panel: PanelContainer
var summary_label: Label
var slots_box: VBoxContainer
var bank_flow: FlowContainer
var bank_title_label: Label
var bank_panel
var content_row: HBoxContainer
var check_button: Button
var continue_button: Button
var back_button: Button
var repeat_button: Button
var status_label: Label
var bottom_spacer: Control
var top_spacer: Control

var intro_data: Dictionary = {}
var block_text_by_id: Dictionary = {}
var requires_input_by_id: Dictionary = {}
var distractor_ids: Dictionary = {}
var correct_order: Array[String] = []
var total_slots: int = 7
var pass_ratio: float = 0.70

var slot_assignments: Array[String] = []
var slot_custom_values: Dictionary = {}
var slot_nodes: Dictionary = {}
var bank_ids: Array[String] = []
var answered_current: bool = false
var finished: bool = false
var last_issue_summary: String = ""

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
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 26)
	root.add_child(top_spacer)

	title_label = Label.new()
	title_label.text = "Build Your Intro"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title_label, 28, true)
	root.add_child(title_label)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(progress_label, 18, true)
	root.add_child(progress_label)

	prompt_panel = PanelContainer.new()
	prompt_panel.add_theme_stylebox_override("panel", _summary_panel_style())
	root.add_child(prompt_panel)

	var prompt_margin := MarginContainer.new()
	prompt_margin.add_theme_constant_override("margin_left", 8)
	prompt_margin.add_theme_constant_override("margin_top", 4)
	prompt_margin.add_theme_constant_override("margin_right", 8)
	prompt_margin.add_theme_constant_override("margin_bottom", 4)
	prompt_panel.add_child(prompt_margin)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.custom_minimum_size = Vector2(0, 24)
	GameState.style_label(prompt_label, 18, true)
	prompt_margin.add_child(prompt_label)

	content_row = HBoxContainer.new()
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content_row.custom_minimum_size = Vector2(0, 210)
	content_row.add_theme_constant_override("separation", 10)
	root.add_child(content_row)

	var slots_panel := PanelContainer.new()
	slots_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slots_panel.add_theme_stylebox_override("panel", _panel_style())
	content_row.add_child(slots_panel)

	var slots_margin := MarginContainer.new()
	slots_margin.add_theme_constant_override("margin_left", 8)
	slots_margin.add_theme_constant_override("margin_top", 8)
	slots_margin.add_theme_constant_override("margin_right", 8)
	slots_margin.add_theme_constant_override("margin_bottom", 8)
	slots_panel.add_child(slots_margin)

	slots_box = VBoxContainer.new()
	slots_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slots_box.custom_minimum_size = Vector2(430, 188)
	slots_box.add_theme_constant_override("separation", 4)
	slots_margin.add_child(slots_box)

	bank_panel = BankDropAreaScript.new()
	bank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_panel.custom_minimum_size = Vector2(470, 0)
	bank_panel.add_theme_stylebox_override("panel", _panel_style())
	bank_panel.sentence_returned.connect(_on_bank_sentence_returned)
	content_row.add_child(bank_panel)

	var bank_margin := MarginContainer.new()
	bank_margin.add_theme_constant_override("margin_left", 8)
	bank_margin.add_theme_constant_override("margin_top", 8)
	bank_margin.add_theme_constant_override("margin_right", 8)
	bank_margin.add_theme_constant_override("margin_bottom", 8)
	bank_panel.add_child(bank_margin)

	var bank_vbox := VBoxContainer.new()
	bank_vbox.add_theme_constant_override("separation", 8)
	bank_margin.add_child(bank_vbox)

	bank_title_label = Label.new()
	bank_title_label.text = "Available Blocks"
	bank_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(bank_title_label, 18, false)
	bank_vbox.add_child(bank_title_label)

	var bank_scroll := ScrollContainer.new()
	bank_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	bank_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	bank_vbox.add_child(bank_scroll)

	var bank_content_margin := MarginContainer.new()
	bank_content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_content_margin.add_theme_constant_override("margin_top", 26)
	bank_content_margin.add_theme_constant_override("margin_bottom", 6)
	bank_scroll.add_child(bank_content_margin)

	bank_flow = FlowContainer.new()
	bank_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_flow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bank_flow.add_theme_constant_override("h_separation", 18)
	bank_flow.add_theme_constant_override("v_separation", 18)
	bank_content_margin.add_child(bank_flow)

	feedback_panel = PanelContainer.new()
	feedback_panel.visible = false
	feedback_panel.add_theme_stylebox_override("panel", _summary_panel_style())
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
	feedback_label.custom_minimum_size = Vector2(0, 22)
	GameState.style_label(feedback_label, 18, true)
	feedback_margin.add_child(feedback_label)

	summary_panel = PanelContainer.new()
	summary_panel.visible = false
	summary_panel.add_theme_stylebox_override("panel", _summary_panel_style())
	root.add_child(summary_panel)

	var summary_margin := MarginContainer.new()
	summary_margin.add_theme_constant_override("margin_left", 12)
	summary_margin.add_theme_constant_override("margin_top", 8)
	summary_margin.add_theme_constant_override("margin_right", 12)
	summary_margin.add_theme_constant_override("margin_bottom", 8)
	summary_panel.add_child(summary_margin)

	summary_label = Label.new()
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.custom_minimum_size = Vector2(0, 90)
	GameState.style_label(summary_label, 18, false)
	summary_margin.add_child(summary_label)

	bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 0)
	root.add_child(bottom_spacer)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	actions.custom_minimum_size = Vector2(0, 56)
	root.add_child(actions)

	check_button = Button.new()
	check_button.text = "Check"
	GameState.style_menu_button(check_button, "green")
	check_button.pressed.connect(_on_check_pressed)
	actions.add_child(check_button)

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
	block_text_by_id.clear()
	requires_input_by_id.clear()
	distractor_ids.clear()
	correct_order.clear()
	total_slots = 7
	pass_ratio = 0.70
	if not FileAccess.file_exists(DATA_PATH):
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	intro_data = parsed as Dictionary
	total_slots = maxi(int(intro_data.get("total_slots", 7)), 1)
	pass_ratio = clampf(float(intro_data.get("pass_ratio", 0.70)), 0.0, 1.0)

	var order_raw: Array = intro_data.get("correct_order", [])
	for sid in order_raw:
		correct_order.append(String(sid))

	var blocks: Array = intro_data.get("blocks", [])
	for block_variant in blocks:
		if typeof(block_variant) != TYPE_DICTIONARY:
			continue
		var block: Dictionary = block_variant
		var id := String(block.get("id", ""))
		if id == "":
			continue
		block_text_by_id[id] = String(block.get("text", ""))
		var req := String(block.get("requires_input", ""))
		if req != "":
			requires_input_by_id[id] = req
		if String(block.get("kind", "")) == "distractor":
			distractor_ids[id] = true

func _start_new_attempt() -> void:
	finished = false
	answered_current = false
	last_issue_summary = ""
	slot_assignments.clear()
	slot_assignments.resize(total_slots)
	for i in range(total_slots):
		slot_assignments[i] = ""
	slot_custom_values.clear()
	bank_ids.clear()
	for sid_variant in block_text_by_id.keys():
		bank_ids.append(String(sid_variant))
	bank_ids.shuffle()

	progress_label.text = "Intro Slots 0/" + str(total_slots)
	var instruction := String(intro_data.get("instruction", "Drag and order 7 blocks to build a personal introduction."))
	instruction = instruction.replace(" Put Hello first and Bye last.", "")
	if not instruction.to_lower().contains("order"):
		instruction += " The order of the blocks matters."
	prompt_label.text = instruction
	feedback_label.text = ""
	last_issue_summary = ""
	prompt_panel.visible = true
	feedback_panel.visible = false
	check_button.visible = true
	check_button.disabled = true
	continue_button.visible = true
	continue_button.text = "Continue"
	continue_button.disabled = true
	repeat_button.visible = false
	status_label.visible = false
	content_row.visible = true
	summary_panel.visible = false
	summary_label.text = ""
	top_spacer.custom_minimum_size = Vector2(0, 24)
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	feedback_label.custom_minimum_size = Vector2(0, 36)
	feedback_label.add_theme_font_size_override("font_size", 20)
	_render_slots()
	_render_bank()
	_update_check_availability()

func _render_slots() -> void:
	slot_nodes.clear()
	for child in slots_box.get_children():
		child.queue_free()

	for i in range(total_slots):
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)
		slots_box.add_child(row)

		var slot := DropSlotScript.new()
		slot.custom_minimum_size = Vector2(250, 30)
		slot.set_text_min_height(22)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", _slot_style())
		slot.configure(i)
		slot.set_locked(answered_current or finished)
		slot.sentence_dropped.connect(_on_slot_sentence_dropped)
		slot.sentence_cleared.connect(_on_slot_sentence_cleared)
		row.add_child(slot)
		slot_nodes[i] = slot

		var sid := String(slot_assignments[i])
		if sid != "" and block_text_by_id.has(sid):
			slot.set_sentence(sid, str(i + 1) + ". " + _resolved_slot_text(i, sid))
			var req := String(requires_input_by_id.get(sid, ""))
			if req != "":
				var req_input := LineEdit.new()
				req_input.custom_minimum_size = Vector2(160, 26)
				req_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				req_input.placeholder_text = req.capitalize()
				req_input.text = String(slot_custom_values.get(_slot_req_key(i), ""))
				req_input.editable = not answered_current and not finished
				req_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
				req_input.add_theme_font_override("font", GameState.pretty_font)
				req_input.add_theme_font_size_override("font_size", 14)
				req_input.text_changed.connect(_on_slot_required_changed.bind(i))
				row.add_child(req_input)
		else:
			slot.set_empty_text(str(i + 1) + ". Drop sentence here")
			slot.clear_sentence()

func _render_bank() -> void:
	for child in bank_flow.get_children():
		child.queue_free()
	for sid_variant in bank_ids:
		var sid := String(sid_variant)
		if not block_text_by_id.has(sid):
			continue
		var chip = DragSentenceButtonScript.new()
		chip.setup(sid, _resolved_bank_text(sid))
		chip.drag_enabled = not answered_current and not finished
		chip.custom_minimum_size = Vector2(220, 38)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip.set_chip_style(_bank_chip_style())
		if chip.has_method("set_label_style"):
			chip.set_label_style(GameState.pretty_font, 15)
		bank_flow.add_child(chip)
	if bank_panel != null:
		bank_panel.set_locked(answered_current or finished)

func _resolved_bank_text(block_id: String) -> String:
	var template := String(block_text_by_id.get(block_id, ""))
	template = template.replace("[NAME]", _profile_name())
	template = template.replace("[AGE]", _profile_age())
	return template

func _resolved_slot_text(slot_index: int, block_id: String) -> String:
	var text_value := _resolved_bank_text(block_id)
	if block_id == "country":
		var value := String(slot_custom_values.get(_slot_req_key(slot_index), ""))
		text_value = text_value.replace("[COUNTRY]", value if value != "" else "_____")
	if block_id == "province":
		var province := String(slot_custom_values.get(_slot_req_key(slot_index), ""))
		text_value = text_value.replace("[PROVINCE]", province if province != "" else "_____")
	return text_value

func _profile_name() -> String:
	var value := String(GameState.profile.get("name", "")).strip_edges()
	return value if value != "" else "Student"

func _profile_age() -> String:
	var value := String(GameState.profile.get("age", "")).strip_edges()
	return value if value != "" else "12"

func _profile_country() -> String:
	var value := String(GameState.profile.get("country", "")).strip_edges()
	return value if value != "" else "Costa Rica"

func _profile_province() -> String:
	var value := String(GameState.profile.get("province", "")).strip_edges()
	return value if value != "" else "Cartago"

func _slot_req_key(slot_index: int) -> String:
	return "slot_" + str(slot_index)

func _on_slot_sentence_dropped(slot_index: int, sentence_id: String) -> void:
	if answered_current or finished:
		return
	if sentence_id == "" or not block_text_by_id.has(sentence_id):
		return
	if slot_index < 0 or slot_index >= slot_assignments.size():
		return

	var existing := String(slot_assignments[slot_index])
	if existing != "":
		_add_to_bank(existing)
		slot_custom_values.erase(_slot_req_key(slot_index))

	for i in range(slot_assignments.size()):
		if String(slot_assignments[i]) == sentence_id:
			slot_assignments[i] = ""
			slot_custom_values.erase(_slot_req_key(i))

	_remove_from_bank(sentence_id)
	slot_assignments[slot_index] = sentence_id
	if sentence_id == "country":
		slot_custom_values[_slot_req_key(slot_index)] = ""
	if sentence_id == "province":
		slot_custom_values[_slot_req_key(slot_index)] = ""
	_render_slots()
	_render_bank()
	_update_check_availability()

func _on_slot_sentence_cleared(slot_index: int) -> void:
	if answered_current or finished:
		return
	if slot_index < 0 or slot_index >= slot_assignments.size():
		return
	var sid := String(slot_assignments[slot_index])
	if sid == "":
		return
	slot_assignments[slot_index] = ""
	slot_custom_values.erase(_slot_req_key(slot_index))
	_add_to_bank(sid)
	_render_slots()
	_render_bank()
	_update_check_availability()

func _on_bank_sentence_returned(sentence_id: String) -> void:
	if answered_current or finished:
		return
	if sentence_id == "":
		return
	for i in range(slot_assignments.size()):
		if String(slot_assignments[i]) == sentence_id:
			slot_assignments[i] = ""
			slot_custom_values.erase(_slot_req_key(i))
			_add_to_bank(sentence_id)
			break
	_render_slots()
	_render_bank()
	_update_check_availability()

func _on_slot_required_changed(value: String, slot_index: int) -> void:
	slot_custom_values[_slot_req_key(slot_index)] = value.strip_edges()
	if slot_nodes.has(slot_index):
		var sid := String(slot_assignments[slot_index])
		if sid != "":
			var slot = slot_nodes[slot_index]
			slot.set_sentence(sid, str(slot_index + 1) + ". " + _resolved_slot_text(slot_index, sid))
	_update_check_availability()

func _update_check_availability() -> void:
	if check_button == null:
		return
	if answered_current or finished:
		check_button.disabled = true
		return
	var ready := true
	var has_country_block := false
	var has_town_block := false
	for i in range(slot_assignments.size()):
		var sid := String(slot_assignments[i])
		if sid == "":
			ready = false
			break
		if sid == "country":
			has_country_block = true
		elif sid == "province":
			has_town_block = true
		var req := String(requires_input_by_id.get(sid, ""))
		if req != "":
			var req_value := String(slot_custom_values.get(_slot_req_key(i), "")).strip_edges()
			if req_value == "":
				ready = false
				break
	if ready and (not has_country_block or not has_town_block):
		ready = false
	check_button.disabled = not ready
	progress_label.text = "Intro Slots " + str(_filled_slots_count()) + "/" + str(total_slots)

func _filled_slots_count() -> int:
	var count := 0
	for sid_variant in slot_assignments:
		if String(sid_variant) != "":
			count += 1
	return count

func _on_check_pressed() -> void:
	if answered_current or finished:
		return
	if check_button.disabled:
		feedback_label.text = "Complete all 7 slots and include both country and town before checking."
		return

	answered_current = true
	var evaluation := _evaluate_intro()
	var score := int(evaluation.get("score", 0))
	var passed_now := bool(evaluation.get("passed", false))
	var issues: Array = evaluation.get("issues", [])
	var attempt_summary := ""
	if passed_now:
		attempt_summary = _build_success_summary()
	else:
		attempt_summary = _build_issue_summary(issues)
	last_issue_summary = attempt_summary

	var result := GameState.record_challenge_result(CHALLENGE_ID, score, total_slots, pass_ratio)
	var selected_country := _extract_required_value_for_block("country")
	var selected_town := _extract_required_value_for_block("province")
	result["passport_country"] = selected_country if selected_country != "" else _profile_country()
	result["passport_town"] = selected_town if selected_town != "" else _profile_province()
	result["passport_name"] = String(GameState.profile.get("name", "")).strip_edges()
	result["passport_last_name"] = String(GameState.profile.get("last_name", "")).strip_edges()
	result["passport_age"] = String(GameState.profile.get("age", "")).strip_edges()
	result["last_attempt_summary"] = attempt_summary
	result["last_attempt_passed"] = passed_now
	result["last_attempt_score"] = score
	if bool(result.get("passed", false)):
		last_issue_summary = _build_success_summary()
	result["last_issue_summary"] = last_issue_summary
	GameState.challenge_results[CHALLENGE_ID] = result
	GameState.save_progress()
	continue_button.disabled = false
	check_button.disabled = true

	if passed_now:
		feedback_label.text = "Checked. Press Continue to open your summary."
		feedback_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.76))
	else:
		feedback_label.text = "Checked. Press Continue to view what to fix."
		feedback_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.76))

	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("final_passport")

	_render_slots()
	_render_bank()

func _evaluate_intro() -> Dictionary:
	var correct_positions := 0
	var distractor_penalty := 0
	var hello_first := false
	var bye_last := false
	var issues: Array[String] = []
	var unique_issue_keys: Dictionary = {}

	if total_slots > 0:
		var first_id := String(slot_assignments[0])
		hello_first = first_id == "hello"
		if hello_first:
			correct_positions += 1
		elif distractor_ids.has(first_id):
			distractor_penalty += 1
			var wrong_first := String(block_text_by_id.get(first_id, first_id))
			_push_unique_issue(issues, unique_issue_keys, "hello_rule", "\"Hello\" is used at the beginning of a personal introduction, not \"" + wrong_first + "\".")
		else:
			_push_unique_issue(issues, unique_issue_keys, "hello_rule", "\"Hello\" should appear first in a personal introduction.")

	if total_slots > 1:
		var last_id := String(slot_assignments[total_slots - 1])
		bye_last = last_id == "bye"
		if bye_last:
			correct_positions += 1
		elif distractor_ids.has(last_id):
			distractor_penalty += 1
			var wrong_last := String(block_text_by_id.get(last_id, last_id))
			_push_unique_issue(issues, unique_issue_keys, "bye_rule", "\"Bye\" is used to close a personal introduction, not \"" + wrong_last + "\".")
		else:
			_push_unique_issue(issues, unique_issue_keys, "bye_rule", "\"Bye\" should appear last in a personal introduction.")

	for i in range(1, maxi(total_slots - 1, 1)):
		var sid := String(slot_assignments[i])
		if sid == "" or sid == "hello" or sid == "bye":
			if sid == "hello":
				_push_unique_issue(issues, unique_issue_keys, "hello_rule", "\"Hello\" should be placed at the start of your presentation.")
			elif sid == "bye":
				_push_unique_issue(issues, unique_issue_keys, "bye_rule", "\"Bye\" should be placed at the end of your presentation.")
			continue
		if distractor_ids.has(sid):
			distractor_penalty += 1
			var distractor_text := String(block_text_by_id.get(sid, sid))
			_push_unique_issue(issues, unique_issue_keys, "distractor_" + sid, "Saying \"" + distractor_text + "\" is not part of a personal introduction.")
		else:
			correct_positions += 1

	var score := maxi(correct_positions - distractor_penalty, 0)
	var pass_threshold := int(ceil(float(total_slots) * pass_ratio))
	var passed := score >= pass_threshold and hello_first and bye_last
	return {
		"score": score,
		"passed": passed,
		"distractor_penalty": distractor_penalty,
		"hello_first": hello_first,
		"bye_last": bye_last,
		"issues": issues
	}

func _show_saved_summary() -> void:
	var result := GameState.get_challenge_result(CHALLENGE_ID)
	if bool(result.get("passed", false)):
		GameState.update_zone_badge_from_requirements("final_passport")
	_show_summary(result)

func _on_continue_pressed() -> void:
	if finished:
		_exit_with_badge_popup("res://scenes/ZoneScene.tscn", true)
		return
	if not answered_current:
		return
	_show_summary(GameState.get_challenge_result(CHALLENGE_ID))

func _show_summary(result: Dictionary) -> void:
	finished = true
	var total := maxi(int(result.get("total_questions", total_slots)), 1)
	var best_correct := clampi(int(result.get("best_correct", 0)), 0, total)
	var passed := bool(result.get("passed", false))
	var last_attempt_passed := bool(result.get("last_attempt_passed", passed))
	var attempts := int(result.get("attempts", 0))

	progress_label.text = "Challenge Complete"
	progress_label.add_theme_font_size_override("font_size", 26)
	prompt_label.text = "Build your personal intro in a logical order."
	prompt_label.custom_minimum_size = Vector2(0, 32)
	content_row.visible = false
	prompt_panel.visible = true
	check_button.visible = false
	feedback_panel.visible = true
	feedback_label.custom_minimum_size = Vector2(0, 52)
	feedback_label.add_theme_font_size_override("font_size", 20)
	bottom_spacer.custom_minimum_size = Vector2(0, 0)
	summary_panel.visible = true
	top_spacer.custom_minimum_size = Vector2(0, 42)
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	var summary_text := String(result.get("last_attempt_summary", "")).strip_edges()
	if summary_text == "":
		summary_text = String(result.get("last_issue_summary", "")).strip_edges()
	if passed:
		feedback_label.text = "Stamp progress saved!\nBest score: " + str(best_correct) + "/" + str(total)
		feedback_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.76))
		summary_label.text = summary_text if summary_text != "" else _build_success_summary()
		status_label.text = "Status: Approved"
		status_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.74))
	else:
		feedback_label.text = "You need at least 70%.\nBest score: " + str(best_correct) + "/" + str(total)
		feedback_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.76))
		summary_label.text = summary_text if summary_text != "" else "Things to improve:\n- Build a logical order.\n- Keep only sentences that belong to a personal introduction."
		status_label.text = "Status: Failed"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72))
	if passed and not last_attempt_passed:
		summary_label.text = "Latest attempt feedback:\n" + (summary_text if summary_text != "" else "Review the order and avoid distractor blocks.")
	if attempts > 1:
		feedback_label.text += "\nAttempts: " + str(attempts)

	continue_button.visible = true
	continue_button.text = "Back to Zone"
	continue_button.disabled = false
	repeat_button.visible = true
	status_label.visible = true

func _on_repeat_pressed() -> void:
	content_row.visible = true
	check_button.visible = true
	prompt_label.custom_minimum_size = Vector2(0, 28)
	_start_new_attempt()

func _build_issue_summary(issues: Array) -> String:
	if issues.is_empty():
		return ""
	var text := "Things to improve:\n"
	var max_items := mini(issues.size(), 4)
	for i in range(max_items):
		text += "- " + String(issues[i])
		if i < max_items - 1:
			text += "\n"
	return text

func _build_success_summary() -> String:
	return "Great work!\n- You organized a logical personal introduction!\n- You used greeting and closing correctly!\n- Your selected sentences fit the context!"

func _push_unique_issue(issues: Array[String], keys: Dictionary, key: String, message: String) -> void:
	if keys.has(key):
		return
	keys[key] = true
	issues.append(message)

func _extract_required_value_for_block(block_id: String) -> String:
	for i in range(slot_assignments.size()):
		if String(slot_assignments[i]) != block_id:
			continue
		return String(slot_custom_values.get(_slot_req_key(i), "")).strip_edges()
	return ""

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

func _add_to_bank(sentence_id: String) -> void:
	if sentence_id == "":
		return
	if bank_ids.find(sentence_id) < 0:
		bank_ids.append(sentence_id)

func _remove_from_bank(sentence_id: String) -> void:
	var idx := bank_ids.find(sentence_id)
	if idx >= 0:
		bank_ids.remove_at(idx)

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

func _summary_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.10, 0.20, 0.80)
	sb.border_color = Color(0.72, 0.86, 1.0, 0.92)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	return sb
