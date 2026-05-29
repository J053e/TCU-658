extends Control

var zone_title: Label
var zone_title_panel: PanelContainer
var zone_description: Label
var minigame_title: Label
var minigame_title_panel: PanelContainer
var minigames_list: ItemList
var start_button: Button
var classroom_challenges_box: VBoxContainer
var classroom_read_listen_button: Button
var classroom_language_button: Button
var meet_classmates_challenges_box: VBoxContainer
var meet_dialogue_button: Button
var meet_question_button: Button
var meet_politeness_button: Button
var my_school_card_challenges_box: VBoxContainer
var my_school_card_profile_button: Button
var my_school_card_label_button: Button
var my_school_card_sentences_button: Button
var top_spacer: Control
var status_panel: PanelContainer
var status_label: Label
var complete_button: Button

var zone := {}

func _ready() -> void:
	zone = GameState.get_zone(GameState.current_zone_id)
	_build_ui()
	_render_zone()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	GameState.decorate_screen(self, GameState.get_zone_screen_background(GameState.current_zone_id))

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "VBox"
	root_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root_vbox.custom_minimum_size = Vector2(840, 560)
	root_vbox.add_theme_constant_override("separation", 12)
	center.add_child(root_vbox)

	top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 0)
	root_vbox.add_child(top_spacer)

	zone_title_panel = PanelContainer.new()
	zone_title_panel.add_theme_stylebox_override("panel", _description_panel_style())
	root_vbox.add_child(zone_title_panel)

	var zone_title_margin := MarginContainer.new()
	zone_title_margin.add_theme_constant_override("margin_left", 16)
	zone_title_margin.add_theme_constant_override("margin_top", 8)
	zone_title_margin.add_theme_constant_override("margin_right", 16)
	zone_title_margin.add_theme_constant_override("margin_bottom", 8)
	zone_title_panel.add_child(zone_title_margin)

	zone_title = Label.new()
	zone_title.text = "Zone Title"
	zone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(zone_title, 36, true)
	zone_title_margin.add_child(zone_title)

	var desc_panel := PanelContainer.new()
	desc_panel.add_theme_stylebox_override("panel", _description_panel_style())
	root_vbox.add_child(desc_panel)

	var desc_margin := MarginContainer.new()
	desc_margin.add_theme_constant_override("margin_left", 14)
	desc_margin.add_theme_constant_override("margin_top", 10)
	desc_margin.add_theme_constant_override("margin_right", 14)
	desc_margin.add_theme_constant_override("margin_bottom", 10)
	desc_panel.add_child(desc_margin)

	zone_description = Label.new()
	zone_description.text = "Zone description."
	zone_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zone_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(zone_description, 22, false)
	desc_margin.add_child(zone_description)

	minigame_title_panel = PanelContainer.new()
	minigame_title_panel.add_theme_stylebox_override("panel", _description_panel_style())
	root_vbox.add_child(minigame_title_panel)

	var minigame_title_margin := MarginContainer.new()
	minigame_title_margin.add_theme_constant_override("margin_left", 16)
	minigame_title_margin.add_theme_constant_override("margin_top", 8)
	minigame_title_margin.add_theme_constant_override("margin_right", 16)
	minigame_title_margin.add_theme_constant_override("margin_bottom", 8)
	minigame_title_panel.add_child(minigame_title_margin)

	minigame_title = Label.new()
	minigame_title.text = "Minigames"
	minigame_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(minigame_title, 28, false)
	minigame_title_margin.add_child(minigame_title)

	minigames_list = ItemList.new()
	minigames_list.custom_minimum_size = Vector2(560, 220)
	root_vbox.add_child(minigames_list)

	start_button = Button.new()
	start_button.text = "Start"
	GameState.style_menu_button(start_button, "green")
	start_button.custom_minimum_size = Vector2(360, 92)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.visible = false
	start_button.pressed.connect(_on_StartButton_pressed)
	root_vbox.add_child(start_button)

	classroom_challenges_box = VBoxContainer.new()
	classroom_challenges_box.visible = false
	classroom_challenges_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	classroom_challenges_box.alignment = BoxContainer.ALIGNMENT_CENTER
	classroom_challenges_box.add_theme_constant_override("separation", 12)
	root_vbox.add_child(classroom_challenges_box)

	classroom_read_listen_button = Button.new()
	classroom_read_listen_button.text = "Read, Listen and Click"
	classroom_read_listen_button.custom_minimum_size = Vector2(520, 76)
	classroom_read_listen_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(classroom_read_listen_button, "green")
	classroom_read_listen_button.pressed.connect(_on_ClassroomReadListen_pressed)
	classroom_challenges_box.add_child(classroom_read_listen_button)

	classroom_language_button = Button.new()
	classroom_language_button.text = "Classroom Language"
	classroom_language_button.custom_minimum_size = Vector2(520, 76)
	classroom_language_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(classroom_language_button, "purple")
	classroom_language_button.pressed.connect(_on_ClassroomLanguage_pressed)
	classroom_challenges_box.add_child(classroom_language_button)

	meet_classmates_challenges_box = VBoxContainer.new()
	meet_classmates_challenges_box.visible = false
	meet_classmates_challenges_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meet_classmates_challenges_box.alignment = BoxContainer.ALIGNMENT_CENTER
	meet_classmates_challenges_box.add_theme_constant_override("separation", 12)
	root_vbox.add_child(meet_classmates_challenges_box)

	meet_dialogue_button = Button.new()
	meet_dialogue_button.text = "Order the Dialogue"
	meet_dialogue_button.custom_minimum_size = Vector2(520, 76)
	meet_dialogue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(meet_dialogue_button, "blue")
	meet_dialogue_button.pressed.connect(_on_MeetDialogue_pressed)
	meet_classmates_challenges_box.add_child(meet_dialogue_button)

	meet_question_button = Button.new()
	meet_question_button.text = "Choose the Question"
	meet_question_button.custom_minimum_size = Vector2(520, 76)
	meet_question_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(meet_question_button, "pink")
	meet_question_button.pressed.connect(_on_MeetQuestion_pressed)
	meet_classmates_challenges_box.add_child(meet_question_button)

	meet_politeness_button = Button.new()
	meet_politeness_button.text = "Politeness Fix"
	meet_politeness_button.custom_minimum_size = Vector2(520, 76)
	meet_politeness_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(meet_politeness_button, "purple")
	meet_politeness_button.pressed.connect(_on_MeetPoliteness_pressed)
	meet_classmates_challenges_box.add_child(meet_politeness_button)

	my_school_card_challenges_box = VBoxContainer.new()
	my_school_card_challenges_box.visible = false
	my_school_card_challenges_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_school_card_challenges_box.alignment = BoxContainer.ALIGNMENT_CENTER
	my_school_card_challenges_box.add_theme_constant_override("separation", 12)
	root_vbox.add_child(my_school_card_challenges_box)

	my_school_card_profile_button = Button.new()
	my_school_card_profile_button.text = "Fill the Profile"
	my_school_card_profile_button.custom_minimum_size = Vector2(520, 76)
	my_school_card_profile_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(my_school_card_profile_button, "green")
	my_school_card_profile_button.pressed.connect(_on_MySchoolCardProfile_pressed)
	my_school_card_challenges_box.add_child(my_school_card_profile_button)

	my_school_card_label_button = Button.new()
	my_school_card_label_button.text = "Label the Classroom"
	my_school_card_label_button.custom_minimum_size = Vector2(520, 76)
	my_school_card_label_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(my_school_card_label_button, "blue")
	my_school_card_label_button.pressed.connect(_on_MySchoolCardLabel_pressed)
	my_school_card_challenges_box.add_child(my_school_card_label_button)

	my_school_card_sentences_button = Button.new()
	my_school_card_sentences_button.text = "Simple Personal Sentences"
	my_school_card_sentences_button.custom_minimum_size = Vector2(520, 76)
	my_school_card_sentences_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(my_school_card_sentences_button, "purple")
	my_school_card_sentences_button.pressed.connect(_on_MySchoolCardSentences_pressed)
	my_school_card_challenges_box.add_child(my_school_card_sentences_button)

	status_panel = PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", _status_panel_style())
	root_vbox.add_child(status_panel)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 12)
	status_margin.add_theme_constant_override("margin_top", 8)
	status_margin.add_theme_constant_override("margin_right", 12)
	status_margin.add_theme_constant_override("margin_bottom", 8)
	status_panel.add_child(status_margin)

	status_label = Label.new()
	status_label.text = "Complete this zone to earn your stamp."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(status_label, 21, false)
	status_margin.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(actions)

	complete_button = Button.new()
	complete_button.text = "Complete Zone"
	GameState.style_menu_button(complete_button, "green")
	complete_button.pressed.connect(_on_CompleteButton_pressed)
	actions.add_child(complete_button)

	var back_button := Button.new()
	back_button.text = "Back"
	GameState.style_menu_button(back_button, "orange")
	back_button.pressed.connect(_on_BackButton_pressed)
	actions.add_child(back_button)

func _render_zone() -> void:
	if zone.is_empty():
		zone_title.text = "Zone not found"
		zone_description.text = "The selected zone is not available in data/game_content.json."
		complete_button.disabled = true
		return

	zone_title.text = zone.get("title", "Zone")
	zone_description.text = zone.get("description", "")

	var is_school_gate := GameState.current_zone_id == "school_gate"
	var is_classroom_survival := GameState.current_zone_id == "classroom_survival"
	var is_meet_classmates := GameState.current_zone_id == "meet_classmates"
	var is_my_school_card := GameState.current_zone_id == "my_school_card"
	minigames_list.clear()

	# Keep title backgrounds only for zone 4 readability.
	if is_my_school_card:
		zone_title_panel.add_theme_stylebox_override("panel", _description_panel_style())
		minigame_title_panel.add_theme_stylebox_override("panel", _description_panel_style())
	else:
		zone_title_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		minigame_title_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	if is_school_gate:
		top_spacer.custom_minimum_size = Vector2(0, 78)
		minigame_title.visible = false
		minigame_title_panel.visible = false
		minigames_list.visible = false
		start_button.visible = true
		classroom_challenges_box.visible = false
		meet_classmates_challenges_box.visible = false
		my_school_card_challenges_box.visible = false
		complete_button.visible = false
		status_label.text = "Press Start to begin the School Gate."
		return

	if is_classroom_survival:
		top_spacer.custom_minimum_size = Vector2(0, 38)
		minigame_title.visible = true
		minigame_title_panel.visible = true
		minigame_title.text = "Challenges"
		minigames_list.visible = false
		start_button.visible = false
		classroom_challenges_box.visible = true
		meet_classmates_challenges_box.visible = false
		my_school_card_challenges_box.visible = false
		complete_button.visible = false
		status_label.text = "Choose a challenge to start."
		return

	if is_meet_classmates:
		top_spacer.custom_minimum_size = Vector2(0, 30)
		minigame_title.visible = true
		minigame_title_panel.visible = true
		minigame_title.text = "Challenges"
		minigames_list.visible = false
		start_button.visible = false
		classroom_challenges_box.visible = false
		meet_classmates_challenges_box.visible = true
		my_school_card_challenges_box.visible = false
		complete_button.visible = false
		status_label.text = "Select one of the 3 challenges."
		return

	if is_my_school_card:
		top_spacer.custom_minimum_size = Vector2(0, 30)
		minigame_title.visible = true
		minigame_title_panel.visible = true
		minigame_title.text = "Challenges"
		minigames_list.visible = false
		start_button.visible = false
		classroom_challenges_box.visible = false
		meet_classmates_challenges_box.visible = false
		my_school_card_challenges_box.visible = true
		complete_button.visible = false
		status_label.text = "Select one of the 3 challenges."
		return

	top_spacer.custom_minimum_size = Vector2(0, 0)

	for minigame_name in zone.get("minigames", []):
		minigames_list.add_item(minigame_name + " (placeholder)")

	minigame_title.visible = true
	minigame_title_panel.visible = true
	minigame_title.text = "Minigames"
	minigames_list.visible = true
	start_button.visible = false
	classroom_challenges_box.visible = false
	meet_classmates_challenges_box.visible = false
	my_school_card_challenges_box.visible = false
	complete_button.visible = true

	if GameState.is_zone_completed(GameState.current_zone_id):
		status_label.text = "Stamp already earned for this zone."
		complete_button.disabled = true
	else:
		status_label.text = "Complete this zone to earn your stamp."
		complete_button.disabled = false

func _on_CompleteButton_pressed() -> void:
	if zone.is_empty():
		return
	GameState.mark_zone_complete(GameState.current_zone_id)
	GameState.save_progress()
	status_label.text = "Stamp earned! Zone complete."
	complete_button.disabled = true

func _on_StartButton_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/SchoolGateQuiz.tscn")

func _on_ClassroomReadListen_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/ClassroomReadListenClick.tscn")

func _on_ClassroomLanguage_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/ClassroomLanguageQuiz.tscn")

func _on_BackButton_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/WorldMap.tscn", true)

func _show_not_implemented_notice(challenge_name: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Coming Soon"
	dialog.dialog_text = challenge_name + " is not implemented yet."
	dialog.ok_button_text = "OK"
	add_child(dialog)
	dialog.popup_centered()

func _on_MeetDialogue_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/MeetOrderDialogue.tscn")

func _on_MeetQuestion_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/MeetChooseQuestion.tscn")

func _on_MeetPoliteness_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/MeetPolitenessFix.tscn")

func _on_MySchoolCardProfile_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/MySchoolCardFillProfilePlaceholder.tscn")

func _on_MySchoolCardLabel_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/MySchoolCardLabelClassroom.tscn")

func _on_MySchoolCardSentences_pressed() -> void:
	_show_not_implemented_notice("Simple Personal Sentences")

func _description_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.20, 0.80)
	sb.border_color = Color(0.76, 0.88, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	return sb

func _status_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.18, 0.82)
	sb.border_color = Color(0.72, 0.86, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	return sb
