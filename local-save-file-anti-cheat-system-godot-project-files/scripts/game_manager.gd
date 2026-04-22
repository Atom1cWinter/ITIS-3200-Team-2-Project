extends Node

# -------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------

const LAST_LEVEL : int = 2

# -------------------------------------------------------------------
# Save Data Variables (Cross Level and Saved)
# -------------------------------------------------------------------

var coins : int = 0
var health : int = 1
var hearts : int = 1
var energy_cells : int = 1
# Abilities:
var has_jump_ability : bool = true
var has_dash_ability : bool = true
var has_melee_ability : bool = false
# Current Level:
var current_game_level : String = "level_1"

# Save dictionary schema
const SAVE_SCHEMA := {
	"coins": TYPE_INT,
	"health": TYPE_INT,
	"hearts": TYPE_INT,
	"energy_cells": TYPE_INT,
	"has_jump_ability": TYPE_BOOL,
	"has_dash_ability" : TYPE_BOOL,
	"has_melee_ability": TYPE_BOOL,
	"current_game_level": TYPE_STRING
}

# -------------------------------------------------------------------
# Core Logic
# -------------------------------------------------------------------

func _ready() -> void:
	await load_save()
	print(get_save_data())
	load_current_level()

# Reload the current scene
func restart_level() -> void:
	get_tree().reload_current_scene()
	
func complete_level(run_data: Dictionary) -> void:
	# Override save data with run data
	commit_run_data(run_data)
	# Update current level
	current_game_level = "level_" + str( clamp(current_game_level.to_int() + 1 , 0, LAST_LEVEL) )
	# Save game using save data
	await save_game() # TODO If server is down player can't get past this point.
	# Load updated current level
	load_current_level()
	
func load_current_level() -> void:
	var scene_path = "res://scenes/levels/" + current_game_level + ".tscn"
	if get_tree().current_scene.name == current_game_level:
		print("Current level already loaded.")
	elif ResourceLoader.exists(scene_path):
		print( "Loading level " + str( scene_path.to_int() ) )
		get_tree().change_scene_to_file.call_deferred(scene_path)
	else:
		push_error("Level at -> " + scene_path + " -> does not exist or could not be found.")
	
func game_over() -> void:
	print("Player Died! Restarting Game.")
	Engine.time_scale = 0.25
	await get_tree().create_timer(0.25).timeout
	Engine.time_scale = 1
	restart_level()
	
# -------------------------------------------------------------------
# Save and Load System
# -------------------------------------------------------------------

# Called in complete_level().
func save_game() -> void:
	var current_data = get_save_data()
	var save_status = await SaveManager.create_secure_save(current_data)
	if save_status == 0:
		print("Successfull Save")
	elif save_status == -1:
		print("Error occurred while saving game!")
	else:
		print("Something unexpected happened while saving.")
	
func load_save() -> void:
	var validated_data = await SaveManager.load_secure_save()
	
	if not validated_data.is_empty():
		commit_run_data(validated_data)
	else:
		print("Using default starting stats")

# Player will call GameManager.get_save_data to request data
func get_save_data() -> Dictionary:
	return {
		"coins": coins,
		"health": health,
		"hearts": hearts,
		"energy_cells": energy_cells,
		"has_jump_ability": has_jump_ability,
		"has_dash_ability": has_dash_ability,
		"has_melee_ability": has_melee_ability,
		"current_game_level": current_game_level
	}

# Takes data from dictionary and updates save data variables with values from dictionary.
# Parameter: data -> a dictionary that stores saved values for save data.
# Returns: -1 if error. 0 if ok.
# Updated to handle int to float mismatch
func commit_run_data(data: Dictionary) -> int:
	for key in SAVE_SCHEMA.keys():
		if data.has(key):
			var expected_type = SAVE_SCHEMA[key]
			var value = data[key]
			
			if typeof(value) == expected_type:
				set(key, value)
			elif expected_type == TYPE_INT and typeof(value) == TYPE_FLOAT:
				# Godot JSON parses all numbers as floats. Safely cast it back!
				set(key, int(value))
			else: 
				push_warning("Type mismatch for: %s" % key)
		else:
			push_warning("Using default for: %s" % key)
	return 0
