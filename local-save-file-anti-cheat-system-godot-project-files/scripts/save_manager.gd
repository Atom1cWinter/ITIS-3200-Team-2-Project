extends Node

# This is the server IP address, change if different deployment address
const SERVER_URL = "http://6.tcp.ngrok.io:13828" # This is a direct TCP endpoint, there were issues with deployment

@onready var http_request = $HTTPRequest

@export var is_secure = true
@export var is_encryption_enabled = false # Not implemented yet, 
# ^ will be used in future updates to encrypt save data in addition to HMAC signing.
# Note: Encryption is for obfuscation purposes only and not be considered a true security measure.
# If encryption key is stored on the client it can be extracted by an attacker. 
# Server side encryption would be more secure but cause performance overhead and complexity.
# The HMAC signature is the primary security mechanism to detect tampering. *Obfuscation secondary.
# * = May not be a valid secondary security mechanism.

# ----------- Saving -----------
func create_unsecure_save(save_dict: Dictionary):
	var save_path = "user://unsecure_save.json"

	# Try to write to file, if it fails, return
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open save file for writing")
		return

	# Write the JSON string to the file. If it fails, return
	var result = file.store_string(JSON.stringify(save_dict))
	if not result:
		push_error("Failed to write save data to file")
		return
	file.close()

	print("SUCCESS: Unsecure Save Created! (Save slot " + save_path + ")")
	

func create_secure_save(save_dict: Dictionary):
	if not is_secure:
		return create_unsecure_save(save_dict)
	
	var save_path = "user://secure_save.json"
	var stringified_data = JSON.stringify(save_dict)
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"data": stringified_data})
	
	var request_error = http_request.request(SERVER_URL + "/generate-hmac", headers, HTTPClient.METHOD_POST, body)
	if request_error != OK:
		push_error("Server request failed before send. Error: %s" % error_string(request_error))
	
	# Wait for server to respond
	var result = await http_request.request_completed
	var response_code = result[1]
	var response_body = result[3]
	
	if response_code == 200:
		var response = JSON.parse_string(response_body.get_string_from_utf8())
		var hmac_signature = response["hmac"]
		
		# Package the data and the signature together
		var file_contents = {
			"data": stringified_data,
			"hmac": hmac_signature
		}
		
		# Write to physical file
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		if not file:
			push_error("Failed to open save file for writing")
			return
		file.store_string(JSON.stringify(file_contents))
		file.close()
		print("SUCCESS: Save Created! (Save slot " + save_path + ")")
	else:
		var error_msg = response_body.get_string_from_utf8()
		push_error("Server failed to generate HMAC. HTTP Code: %s | Server says: %s" % [str(response_code), error_msg])
		

# ------------ Loading -----------------
func load_unsecure_save() -> Dictionary:
	var save_path = "user://unsecure_save.json"
	
	if not FileAccess.file_exists(save_path):
		print("No save file found. Starting fresh")
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file for reading")
		return {}
	var content = file.get_as_text()
	file.close()
	
	return JSON.parse_string(content)

func load_secure_save() -> Dictionary:
	if not is_secure:
		return load_unsecure_save()

	var save_path = "user://secure_save.json"
	
	if not FileAccess.file_exists(save_path):
		print("No save file found. Starting fresh")
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file for reading")
		return {}
	var content = file.get_as_text()
	file.close()
	
	var file_contents = JSON.parse_string(content)
	if not file_contents or not file_contents.has("hmac") or not file_contents.has("data"):
		push_error("Save file is corrupted")
		return {}
		
	var save_string = file_contents["data"]
	var saved_hmac = file_contents["hmac"]
	
	# Ask server to verify
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"data": save_string,
		"hmac": saved_hmac
	})
	
	var request_error = http_request.request(SERVER_URL + "/verify-hmac", headers, HTTPClient.METHOD_POST, body)
	if request_error != OK:
		push_error("Server request failed before verify. Error: %s" % error_string(request_error))
		return {}
	
	var result = await http_request.request_completed
	var response_code = result[1]
	var response_body = result[3]
	
	if response_code == 200:
		var response = JSON.parse_string(response_body.get_string_from_utf8())
		if response.get("valid", false) == true:
			print("SUCCESS: Save file verified! Loading data...")
			return JSON.parse_string(save_string)
		else:
			push_error("SECURITY ALERT: Save file was tampered with! Rejecting load")
			return {}
	else:
		var error_msg = response_body.get_string_from_utf8()
		push_error("Server failed to verify save file. HTTP Code: %s | Server says: %s" % [str(response_code), error_msg])
		return {}
