extends Control

var final_screen_button: Button
var zone_buttons := {}
var badge_slots := {}
var badge_gray_material: ShaderMaterial
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
	_build_ui()
	GameState.load_progress()
	_refresh()
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
	root_vbox.add_child(actions)

	var save_button := Button.new()
	save_button.text = "Save"
	GameState.style_menu_button(save_button, "yellow")
	save_button.pressed.connect(_on_SaveButton_pressed)
	actions.add_child(save_button)

	final_screen_button = Button.new()
	final_screen_button.text = "Final Screen"
	GameState.style_menu_button(final_screen_button, "green")
	final_screen_button.pressed.connect(_on_FinalScreenButton_pressed)
	actions.add_child(final_screen_button)

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
	final_screen_button.disabled = not GameState.all_zones_completed()
	_update_button_labels()
	_update_badges()

func _update_button_labels() -> void:
	for zone_key in zone_buttons.keys():
		var zone_id := String(zone_key)
		var zone_meta: Dictionary = zone_buttons[zone_id]
		var button: Button = zone_meta["button"]
		var base_label: String = zone_meta["label"]
		var suffix := " [STAMP]" if GameState.is_zone_completed(zone_id) else ""
		button.text = base_label + suffix

func _add_badges_row(container: VBoxContainer) -> void:
	var badges_title := Label.new()
	badges_title.text = "Badges"
	badges_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.style_label(badges_title, 24, false)
	container.add_child(badges_title)

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

func _on_FinalScreenButton_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/FinalScreen.tscn")

func _on_BackButton_pressed() -> void:
	GameState.change_scene_with_transition("res://scenes/MainMenu.tscn", true)
