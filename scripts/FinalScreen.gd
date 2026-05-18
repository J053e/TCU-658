extends Control

const FINAL_BG_PATH := "res://assets/ui/backgrounds/final_screen_bg.png"
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

var result_label: Label
var badge_slots := {}
var badge_gray_material: ShaderMaterial

func _ready() -> void:
	_build_ui()
	_render_summary()
	_update_badges()
	GameState.play_enter_transition(self)

func _build_ui() -> void:
	GameState.decorate_screen(self, FINAL_BG_PATH)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "VBox"
	root_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root_vbox.custom_minimum_size = Vector2(980, 500)
	root_vbox.add_theme_constant_override("separation", 14)
	center.add_child(root_vbox)

	var title := Label.new()
	title.text = "My English Passport"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(title, 40, true)
	root_vbox.add_child(title)

	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(result_label, 22, false)
	root_vbox.add_child(result_label)

	var badges_title := Label.new()
	badges_title.text = "Your Medals"
	badges_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(badges_title, 28, true)
	root_vbox.add_child(badges_title)

	_add_badges_row(root_vbox)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(actions)

	var play_again := Button.new()
	play_again.text = "Play Again"
	GameState.style_menu_button(play_again, "green")
	play_again.pressed.connect(_on_PlayAgainButton_pressed)
	actions.add_child(play_again)

	var main_menu := Button.new()
	main_menu.text = "Main Menu"
	GameState.style_menu_button(main_menu, "purple")
	main_menu.pressed.connect(_on_BackToMenuButton_pressed)
	actions.add_child(main_menu)

func _render_summary() -> void:
	if GameState.all_zones_completed():
		result_label.text = "Congratulations! You completed your English Passport."
	else:
		result_label.text = "You still need to complete all zones before final completion."

func _add_badges_row(container: VBoxContainer) -> void:
	var badges_row := HBoxContainer.new()
	badges_row.add_theme_constant_override("separation", 16)
	badges_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(badges_row)

	for zone_id in ZONE_ORDER:
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", _badge_frame_style())
		badges_row.add_child(frame)

		var inner_margin := MarginContainer.new()
		inner_margin.add_theme_constant_override("margin_left", 8)
		inner_margin.add_theme_constant_override("margin_top", 8)
		inner_margin.add_theme_constant_override("margin_right", 8)
		inner_margin.add_theme_constant_override("margin_bottom", 8)
		frame.add_child(inner_margin)

		var badge := TextureRect.new()
		badge.custom_minimum_size = Vector2(92, 92)
		badge.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var texture_path: String = String(BADGE_PATHS.get(zone_id, ""))
		if texture_path != "" and ResourceLoader.exists(texture_path):
			badge.texture = load(texture_path)
		inner_margin.add_child(badge)
		badge_slots[zone_id] = badge

func _badge_frame_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.26, 0.72)
	sb.border_color = Color(0.98, 0.95, 0.55, 1.0)
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_right = 16
	sb.corner_radius_bottom_left = 16
	sb.shadow_color = Color(1.0, 0.90, 0.30, 0.55)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 0)
	sb.set_content_margin_all(0)
	return sb

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

func _on_PlayAgainButton_pressed() -> void:
	GameState.reset_progress()
	GameState.change_scene_with_transition("res://scenes/WorldMap.tscn")

func _on_BackToMenuButton_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/MainMenu.tscn", true)
