extends Node

const SAVE_PATH := "user://savegame.json"
const CONTENT_PATH := "res://data/game_content.json"
const BACKGROUND_MANIFEST_PATH := "res://data/backgrounds_manifest.json"
const GLOBAL_ICONS_DIR := "res://assets/branding/global_icons"
const CLICK_SFX_PATH := "res://assets/audio/sfx/ui_click.wav"

var content := {}
var current_zone_id := ""
var stamps := {}
var profile := {
	"name": "",
	"last_name": "",
	"age": "",
	"grade": "seventh",
	"country": "Costa Rica",
	"town": ""
}
var ui_click_player: AudioStreamPlayer
var pretty_font: SystemFont
var background_manifest: Dictionary = {}
var is_scene_transitioning: bool = false

func _ready() -> void:
	load_content()
	load_background_manifest()
	_initialize_stamps()
	load_progress()
	_initialize_fonts()
	_initialize_ui_sfx()

func load_background_manifest() -> void:
	background_manifest.clear()
	if not FileAccess.file_exists(BACKGROUND_MANIFEST_PATH):
		return
	var file := FileAccess.open(BACKGROUND_MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		background_manifest = parsed as Dictionary

func _initialize_fonts() -> void:
	pretty_font = SystemFont.new()
	pretty_font.font_names = PackedStringArray([
		"Trebuchet MS",
		"Segoe UI",
		"Calibri",
		"Verdana"
	])

func _initialize_ui_sfx() -> void:
	ui_click_player = AudioStreamPlayer.new()
	ui_click_player.name = "UIClickPlayer"
	ui_click_player.volume_db = -8.0
	if ResourceLoader.exists(CLICK_SFX_PATH):
		ui_click_player.stream = load(CLICK_SFX_PATH)
	add_child(ui_click_player)

func load_content() -> void:
	if not FileAccess.file_exists(CONTENT_PATH):
		push_error("Missing content file: " + CONTENT_PATH)
		return

	var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open content file: " + CONTENT_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON content.")
		return
	content = parsed as Dictionary

func _initialize_stamps() -> void:
	stamps.clear()
	for zone in get_zones():
		stamps[zone.get("id", "")] = false

func get_zones() -> Array:
	return content.get("zones", [])

func get_zone(zone_id: String) -> Dictionary:
	for zone in get_zones():
		if zone.get("id", "") == zone_id:
			return zone
	return {}

func completed_count() -> int:
	var total := 0
	for key in stamps.keys():
		if stamps[key]:
			total += 1
	return total

func total_stamps() -> int:
	return stamps.size()

func is_zone_completed(zone_id: String) -> bool:
	return stamps.get(zone_id, false)

func mark_zone_complete(zone_id: String) -> void:
	if stamps.has(zone_id):
		stamps[zone_id] = true

func all_zones_completed() -> bool:
	return completed_count() == total_stamps() and total_stamps() > 0

func reset_progress() -> void:
	_initialize_stamps()
	current_zone_id = ""
	save_progress()

func save_progress() -> void:
	var payload := {
		"stamps": stamps,
		"profile": profile
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to save progress at: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(payload))

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var payload: Variant = JSON.parse_string(file.get_as_text())
	if typeof(payload) != TYPE_DICTIONARY:
		return

	var payload_dict: Dictionary = payload as Dictionary
	if payload_dict.has("stamps") and typeof(payload_dict["stamps"]) == TYPE_DICTIONARY:
		for key in payload_dict["stamps"].keys():
			if stamps.has(key):
				stamps[key] = payload_dict["stamps"][key]
	if payload_dict.has("profile") and typeof(payload_dict["profile"]) == TYPE_DICTIONARY:
		for key in payload_dict["profile"].keys():
			if profile.has(key):
				profile[key] = payload_dict["profile"][key]

func decorate_screen(root: Control, background_path: String = "") -> void:
	_add_background(root, background_path)
	_add_global_icons(root)

func _add_background(root: Control, background_path: String) -> void:
	if background_path == "" or not ResourceLoader.exists(background_path):
		return
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.layout_mode = 1
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = load(background_path)
	root.add_child(bg)
	root.move_child(bg, 0)

func _add_global_icons(root: Control) -> void:
	var overlay := Control.new()
	overlay.name = "GlobalBrandingOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	var icon_box := HBoxContainer.new()
	icon_box.name = "GlobalIcons"
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_theme_constant_override("separation", 10)
	icon_box.anchor_left = 0.0
	icon_box.anchor_right = 0.0
	icon_box.offset_left = 12
	icon_box.offset_top = 12
	icon_box.offset_right = 332
	icon_box.offset_bottom = 96
	overlay.add_child(icon_box)

	var icon_paths := [
		"%s/tcu658.png" % GLOBAL_ICONS_DIR,
		"%s/elm.png" % GLOBAL_ICONS_DIR,
		_get_ucr_icon_path()
	]

	for path in icon_paths:
		if path == "" or not ResourceLoader.exists(path):
			continue
		var texture := load(path)
		if texture == null:
			continue
		var rect := TextureRect.new()
		rect.texture = texture
		var fitted_size := _fit_icon_size(texture.get_size(), 151.0, 70.0)
		rect.custom_minimum_size = fitted_size
		rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		rect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_box.add_child(rect)

func _fit_icon_size(original: Vector2, max_width: float, max_height: float) -> Vector2:
	if original.x <= 0.0 or original.y <= 0.0:
		return Vector2(max_width, max_height)
	var ratio: float = minf(max_width / original.x, max_height / original.y)
	return Vector2(original.x * ratio, original.y * ratio)

func _get_ucr_icon_path() -> String:
	var preferred := "%s/ucr.png" % GLOBAL_ICONS_DIR
	if ResourceLoader.exists(preferred):
		return preferred

	var dir := DirAccess.open(GLOBAL_ICONS_DIR)
	if dir == null:
		return ""
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		var low := file_name.to_lower()
		if low.begins_with("ucr") and (low.ends_with(".png") or low.ends_with(".jpg") or low.ends_with(".jpeg")):
			dir.list_dir_end()
			return "%s/%s" % [GLOBAL_ICONS_DIR, file_name]
	dir.list_dir_end()
	return ""

func style_menu_button(button: Button, palette: String = "blue") -> void:
	var base_color := Color(0.22, 0.56, 0.95)
	var border_color := Color(0.75, 0.92, 1.0)
	var hover_color := Color(0.30, 0.62, 1.0)
	var pressed_color := Color(0.14, 0.46, 0.86)

	match palette:
		"pink":
			base_color = Color(0.90, 0.32, 0.86)
			border_color = Color(1.0, 0.80, 0.98)
			hover_color = Color(0.96, 0.44, 0.92)
			pressed_color = Color(0.78, 0.20, 0.74)
		"yellow":
			base_color = Color(0.95, 0.78, 0.25)
			border_color = Color(1.0, 0.94, 0.68)
			hover_color = Color(1.0, 0.84, 0.35)
			pressed_color = Color(0.90, 0.70, 0.16)
		"orange":
			base_color = Color(0.96, 0.45, 0.24)
			border_color = Color(1.0, 0.80, 0.70)
			hover_color = Color(1.0, 0.53, 0.34)
			pressed_color = Color(0.86, 0.34, 0.14)
		"green":
			base_color = Color(0.42, 0.78, 0.33)
			border_color = Color(0.84, 1.0, 0.76)
			hover_color = Color(0.52, 0.86, 0.43)
			pressed_color = Color(0.32, 0.64, 0.24)
		"purple":
			base_color = Color(0.52, 0.43, 0.93)
			border_color = Color(0.87, 0.82, 1.0)
			hover_color = Color(0.61, 0.53, 0.98)
			pressed_color = Color(0.42, 0.33, 0.83)

	var normal := _make_button_style(base_color, border_color)
	var hover := _make_button_style(hover_color, border_color.lightened(0.08))
	var pressed := _make_button_style(pressed_color, border_color.darkened(0.1))

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_constant_override("outline_size", 1)
	button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 170.0), maxf(button.custom_minimum_size.y, 52.0))
	button.add_theme_font_override("font", pretty_font)
	button.add_theme_font_size_override("font_size", 30)
	if not button.has_meta("_click_hooked"):
		button.set_meta("_click_hooked", true)
		button.pressed.connect(_on_menu_button_pressed)

func _make_button_style(fill_color: Color, line_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.border_color = line_color
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 24
	sb.corner_radius_top_right = 24
	sb.corner_radius_bottom_right = 24
	sb.corner_radius_bottom_left = 24
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.0
	sb.set_content_margin_all(10)
	return sb

func _on_menu_button_pressed() -> void:
	if ui_click_player != null and ui_click_player.stream != null:
		ui_click_player.stop()
		ui_click_player.play()

func style_label(label: Label, font_size: int = 28, with_outline: bool = false) -> void:
	label.add_theme_font_override("font", pretty_font)
	label.add_theme_font_size_override("font_size", font_size)
	if with_outline:
		label.add_theme_color_override("font_outline_color", Color(0.07, 0.10, 0.30))
		label.add_theme_constant_override("outline_size", 4)

func get_zone_screen_background(zone_id: String) -> String:
	var zones: Dictionary = background_manifest.get("zones", {})
	if not zones.has(zone_id):
		return ""
	var zone_data: Dictionary = zones[zone_id]
	var path: String = String(zone_data.get("zone_screen", ""))
	return path

func get_minigame_background(zone_id: String, minigame_id: String) -> String:
	var zones: Dictionary = background_manifest.get("zones", {})
	if not zones.has(zone_id):
		return ""
	var zone_data: Dictionary = zones[zone_id]
	var minigames: Dictionary = zone_data.get("minigames", {})
	var path: String = String(minigames.get(minigame_id, ""))
	return path

func play_enter_transition(root: Control) -> void:
	await get_tree().process_frame
	if root == null or not is_instance_valid(root):
		return
	root.pivot_offset = root.size * 0.5
	root.scale = Vector2(0.92, 0.92)
	var tween := get_tree().create_tween()
	tween.tween_property(root, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func change_scene_with_transition(scene_path: String, is_back: bool = false) -> void:
	if is_scene_transitioning:
		return
	is_scene_transitioning = true

	var overlay_layer: CanvasLayer = null
	var overlay_rect: TextureRect = null
	var captured := await _create_transition_overlay()
	if typeof(captured) == TYPE_DICTIONARY and captured.has("layer") and captured.has("rect"):
		overlay_layer = captured["layer"]
		overlay_rect = captured["rect"]

	var err: int = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Could not change scene to: " + scene_path)
		if overlay_layer != null and is_instance_valid(overlay_layer):
			overlay_layer.queue_free()
		is_scene_transitioning = false
		return

	if overlay_rect != null and is_instance_valid(overlay_rect):
		await get_tree().process_frame
		overlay_rect.pivot_offset = overlay_rect.size * 0.5
		overlay_rect.scale = Vector2.ONE
		overlay_rect.modulate = Color(1, 1, 1, 1)
		var end_scale: Vector2 = Vector2(0.92, 0.92) if is_back else Vector2(1.06, 1.06)
		var tween := get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(overlay_rect, "scale", end_scale, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(overlay_rect, "modulate:a", 0.0, 0.20)
		await tween.finished
		if overlay_layer != null and is_instance_valid(overlay_layer):
			overlay_layer.queue_free()
	is_scene_transitioning = false

func _create_transition_overlay() -> Dictionary:
	await RenderingServer.frame_post_draw
	var viewport_tex := get_viewport().get_texture()
	if viewport_tex == null:
		return {}
	var image: Image = viewport_tex.get_image()
	if image == null or image.is_empty():
		return {}

	var image_texture := ImageTexture.create_from_image(image)
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_tree().root.add_child(layer)

	var rect := TextureRect.new()
	rect.name = "TransitionOverlay"
	rect.texture = image_texture
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	return {
		"layer": layer,
		"rect": rect
	}
