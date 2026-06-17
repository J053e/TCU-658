extends Control

var zone_buttons := {}
var badge_slots := {}
var badge_gray_material: ShaderMaterial
var profile_setup_layer: CanvasLayer
var profile_setup_dim: ColorRect
var profile_setup_panel: PanelContainer
var profile_name_input: LineEdit
var profile_last_name_input: LineEdit
var profile_age_select: OptionButton
var profile_save_button: Button
const WORLD_MAP_BG_PATH := "res://assets/ui/backgrounds/world_map_bg.png"
const ZONE_ORDER := [
	"school_gate",
	"classroom_survival",
	"meet_classmates",
	"my_school_card",
	"final_passport"
]
const BADGE_PATHS := {
	"school_gate": "res://assets/ui/badges/medal_01.png",
	"classroom_survival": "res://assets/ui/badges/medal_02.png",
	"meet_classmates": "res://assets/ui/badges/medal_03.png",
	"my_school_card": "res://assets/ui/badges/medal_04.png",
	"final_passport": "res://assets/ui/badges/medal_05.png"
}

func _ready() -> void:
	GameState.play_zone_music()
	_build_ui()
	GameState.load_progress()
	_refresh()
	_maybe_show_profile_setup_dialog()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	GameState.decorate_screen(self, WORLD_MAP_BG_PATH)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "VBox"
	root_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root_vbox.custom_minimum_size = Vector2(520, 430)
	root_vbox.add_theme_constant_override("separation", 8)
	center.add_child(root_vbox)

	var header := Label.new()
	header.text = "Choose a Zone"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(header, 34, true)
	root_vbox.add_child(header)

	_add_zone_button(root_vbox, "school_gate", "1. School Gate")
	_add_zone_button(root_vbox, "classroom_survival", "2. Classroom Survival")
	_add_zone_button(root_vbox, "meet_classmates", "3. Meet Your Classmates")
	_add_zone_button(root_vbox, "my_school_card", "4. My School Card")
	_add_zone_button(root_vbox, "final_passport", "5. Final Passport Challenge")
	_add_badges_row(root_vbox)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(actions)

	var save_button := Button.new()
	save_button.text = "Save"
	GameState.style_menu_button(save_button, "yellow")
	save_button.pressed.connect(_on_SaveButton_pressed)
	actions.add_child(save_button)

	var back_button := Button.new()
	back_button.text = "Back"
	GameState.style_menu_button(back_button, "orange")
	back_button.pressed.connect(_on_BackButton_pressed)
	actions.add_child(back_button)

func _add_zone_button(container: VBoxContainer, zone_id: String, label: String) -> void:
	var button := Button.new()
	button.text = label
	var palettes := ["blue", "pink", "yellow", "green", "purple"]
	var idx := int(zone_buttons.size()) % palettes.size()
	GameState.style_menu_button(button, palettes[idx])
	button.pressed.connect(_on_zone_pressed.bind(zone_id))
	container.add_child(button)
	zone_buttons[zone_id] = {
		"button": button,
		"label": label
	}

func _refresh() -> void:
	_update_button_labels()
	_update_badges()

func _update_button_labels() -> void:
	for zone_key in zone_buttons.keys():
		var zone_id := String(zone_key)
		var zone_meta: Dictionary = zone_buttons[zone_id]
		var button: Button = zone_meta["button"]
		var base_label: String = zone_meta["label"]
		var suffix := " \u2705" if GameState.is_zone_completed(zone_id) else ""
		button.text = base_label + suffix

func _add_badges_row(container: VBoxContainer) -> void:
	var badges_title_panel := PanelContainer.new()
	badges_title_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badges_title_panel.add_theme_stylebox_override("panel", _readable_label_style())
	container.add_child(badges_title_panel)

	var badges_title_margin := MarginContainer.new()
	badges_title_margin.add_theme_constant_override("margin_left", 18)
	badges_title_margin.add_theme_constant_override("margin_top", 4)
	badges_title_margin.add_theme_constant_override("margin_right", 18)
	badges_title_margin.add_theme_constant_override("margin_bottom", 4)
	badges_title_panel.add_child(badges_title_margin)

	var badges_title := Label.new()
	badges_title.text = "Badges"
	badges_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(badges_title, 24, false)
	badges_title_margin.add_child(badges_title)

	var badges_row := HBoxContainer.new()
	badges_row.add_theme_constant_override("separation", 12)
	badges_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(badges_row)

	for zone_id in ZONE_ORDER:
		var badge := _create_badge(zone_id)
		badges_row.add_child(badge)
		badge_slots[zone_id] = badge

func _create_badge(zone_id: String) -> TextureRect:
	var badge := TextureRect.new()
	badge.custom_minimum_size = Vector2(64, 64)
	badge.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var texture_path: String = String(BADGE_PATHS.get(zone_id, ""))
	if texture_path != "" and ResourceLoader.exists(texture_path):
		badge.texture = load(texture_path)

	return badge

func _update_badges() -> void:
	var gray_material: ShaderMaterial = _gray_material()
	for zone_id in ZONE_ORDER:
		if not badge_slots.has(zone_id):
			continue
		var badge: TextureRect = badge_slots[zone_id]
		if GameState.is_zone_completed(zone_id):
			badge.material = null
		else:
			badge.material = gray_material

func _gray_material() -> ShaderMaterial:
	if badge_gray_material != null:
		return badge_gray_material
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment(){\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(vec3(g), c.a);\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	badge_gray_material = mat
	return badge_gray_material

func _on_zone_pressed(zone_id: String) -> void:
	GameState.current_zone_id = zone_id
	GameState.change_scene_with_transition("res://scenes/ZoneScene.tscn")

func _on_SaveButton_pressed() -> void:
	GameState.save_progress()
	_refresh()

func _on_BackButton_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/MainMenu.tscn", true)

func _maybe_show_profile_setup_dialog() -> void:
	if GameState.profile_setup_done:
		return
	_build_profile_setup_dialog()
	_show_profile_setup_modal()
	_validate_profile_setup_inputs()

func _build_profile_setup_dialog() -> void:
	if profile_setup_layer != null:
		return
	profile_setup_layer = CanvasLayer.new()
	profile_setup_layer.layer = 220
	add_child(profile_setup_layer)

	profile_setup_dim = ColorRect.new()
	profile_setup_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	profile_setup_dim.color = Color(0, 0, 0, 0.45)
	profile_setup_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	profile_setup_layer.add_child(profile_setup_dim)

	var modal_margin := MarginContainer.new()
	modal_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Shift a bit down so it looks visually centered with branding at top.
	modal_margin.add_theme_constant_override("margin_top", 32)
	profile_setup_layer.add_child(modal_margin)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_margin.add_child(center)

	profile_setup_panel = PanelContainer.new()
	profile_setup_panel.custom_minimum_size = Vector2(520, 350)
	profile_setup_panel.add_theme_stylebox_override("panel", _profile_modal_style())
	center.add_child(profile_setup_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.custom_minimum_size = Vector2(480, 260)
	panel_margin.add_theme_constant_override("margin_left", 12)
	panel_margin.add_theme_constant_override("margin_top", 10)
	panel_margin.add_theme_constant_override("margin_right", 12)
	panel_margin.add_theme_constant_override("margin_bottom", 10)
	profile_setup_panel.add_child(panel_margin)

	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 8)
	panel_margin.add_child(form)

	var title := Label.new()
	title.text = "Set Your Student Profile"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title, 26, true)
	form.add_child(title)

	var helper := Label.new()
	helper.text = "Enter your name and last name, then select your age."
	helper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameState.style_label(helper, 20, false)
	form.add_child(helper)

	form.add_child(_make_form_label("Name"))
	profile_name_input = LineEdit.new()
	profile_name_input.text = String(GameState.profile.get("name", ""))
	profile_name_input.text_changed.connect(_validate_profile_setup_inputs)
	form.add_child(profile_name_input)

	form.add_child(_make_form_label("Last name"))
	profile_last_name_input = LineEdit.new()
	profile_last_name_input.text = String(GameState.profile.get("last_name", ""))
	profile_last_name_input.text_changed.connect(_validate_profile_setup_inputs)
	form.add_child(profile_last_name_input)

	form.add_child(_make_form_label("Age"))
	profile_age_select = OptionButton.new()
	profile_age_select.add_item("Select age")
	for age in range(13, 19):
		profile_age_select.add_item(str(age))
	var saved_age := String(GameState.profile.get("age", "")).strip_edges()
	if saved_age != "":
		for i in range(1, profile_age_select.item_count):
			if profile_age_select.get_item_text(i) == saved_age:
				profile_age_select.select(i)
				break
	profile_age_select.item_selected.connect(_validate_profile_setup_inputs)
	form.add_child(profile_age_select)

	profile_save_button = Button.new()
	profile_save_button.text = "Save"
	profile_save_button.custom_minimum_size = Vector2(220, 58)
	profile_save_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_menu_button(profile_save_button, "green")
	profile_save_button.pressed.connect(_on_profile_setup_confirmed)
	form.add_child(profile_save_button)

func _make_form_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	GameState.style_label(label, 18, false)
	return label

func _validate_profile_setup_inputs(_unused: Variant = null) -> void:
	if profile_setup_layer == null:
		return
	var name_ok := profile_name_input != null and profile_name_input.text.strip_edges() != ""
	var last_ok := profile_last_name_input != null and profile_last_name_input.text.strip_edges() != ""
	var age_ok := profile_age_select != null and profile_age_select.selected > 0
	var form_ok := name_ok and last_ok and age_ok
	if profile_save_button != null:
		profile_save_button.disabled = not form_ok

func _on_profile_setup_confirmed() -> void:
	var name_value := profile_name_input.text.strip_edges()
	var last_name_value := profile_last_name_input.text.strip_edges()
	var age_value := ""
	if profile_age_select.selected > 0:
		age_value = profile_age_select.get_item_text(profile_age_select.selected).strip_edges()

	if name_value == "" or last_name_value == "" or age_value == "":
		_validate_profile_setup_inputs()
		return

	GameState.profile["name"] = name_value
	GameState.profile["last_name"] = last_name_value
	GameState.profile["age"] = age_value
	GameState.profile_setup_done = true
	GameState.save_progress()
	_hide_profile_setup_modal()

func _show_profile_setup_modal() -> void:
	if profile_setup_layer != null:
		profile_setup_layer.visible = true

func _hide_profile_setup_modal() -> void:
	if profile_setup_layer != null:
		profile_setup_layer.visible = false

func _profile_modal_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.20, 0.22, 0.26, 0.98)
	sb.border_color = Color(0.72, 0.86, 1.0, 0.88)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	return sb

func _readable_label_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.09, 0.18, 0.74)
	sb.border_color = Color(0.72, 0.86, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	return sb
