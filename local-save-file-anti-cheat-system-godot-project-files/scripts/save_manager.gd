extends Node

# This is the server IP address (I have not made it a static IP yet and will change this once I do)
const SERVER_URL = "http://0.tcp.ngrok.io:16744/generate-hmac"

@onready var http_request = $HTTPRequest

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	http_request.request_completed.connect(_on_hmac_received)
	
	# Some testing script
	# Wait 1 second after game starts, then test
	await get_tree().create_timer(1.0).timeout
	print("Testing HMAC Server Connection...")
	request_signature("player_gold:100;player_level:5")

func request_signature(save_content: String):
	var headers = ["Content-Type: application/json",
	"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
	"x-pinggy-no-screen: true"]
	var body = JSON.stringify({"data": save_content})
	
	var error = http_request.request(SERVER_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _on_hmac_received(_result, response_code, _headers, body):
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		var hmac = response["hmac"]
		print("Successfully retrieved HMAC: ", hmac)
		# Go to save file from HMAC found
	else:
		print("Server returned error code: ", response_code)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
