extends Node

const SAVE_PATH := "user://savegame.json"
const CONTENT_PATH := "res://data/game_content.json"

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

func _ready() -> void:
	load_content()
	_initialize_stamps()
	load_progress()

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
