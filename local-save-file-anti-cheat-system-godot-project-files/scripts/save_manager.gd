extends Node

# This is the server IP address, change if different deployment address
const SERVER_URL = "http://2.tcp.ngrok.io:15081" # This is a direct TCP endpoint, there were issues with deployment

@onready var http_request = $HTTPRequest

# ----------- Saving -----------
func create_secure_save(save_dict: Dictionary, slot_name: String = "default_save") -> int:
	var save_path = "user://" + slot_name + ".json"
	var stringified_data = JSON.stringify(save_dict)
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"data": stringified_data})
	
	http_request.request(SERVER_URL + "/generate-hmac", headers, HTTPClient.METHOD_POST, body)
	
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
		file.store_string(JSON.stringify(file_contents))
		file.close()
		print("SUCCESS: Save Created! (Save slot " + save_path + ")")
		return 0
	else:
		var error_msg = response_body.get_string_from_utf8()
		push_error("Server failed to generate HMAC. HTTP Code: ", response_code, " | Server says: ", error_msg)
		return -1
		

# ------------ Loading -----------------
func load_secure_save(slot_name: String = "default_save") -> Dictionary:
	var save_path = "user://" + slot_name + ".json"
	
	if not FileAccess.file_exists(save_path):
		print("No save file found. Starting fresh")
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
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
	
	http_request.request(SERVER_URL + "/verify-hmac", headers, HTTPClient.METHOD_POST, body)
	
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
		push_error("Server failed to verify save file. HTTP Code: ", response_code, " | Server says: ", error_msg)
		return {}
