extends Node

signal verified(payload: Dictionary)
signal admitted(payload: Dictionary)
signal failed(message: String)

const VERIFY_TIMEOUT_SECONDS := 15.0

var _socket: WebSocketPeer
var _elapsed := 0.0
var _verify_sent := false
var _admission_sent := false
var _finished := false
var _game_id := ""
var _match_id := ""
var _launch_ticket := ""
var _admission_token := ""


func begin(server_url: String, game_id: String, match_id: String, launch_ticket: String) -> void:
	_game_id = game_id.strip_edges()
	_match_id = match_id.strip_edges()
	_launch_ticket = launch_ticket.strip_edges()
	var clean_url := server_url.strip_edges()
	if (
		(not clean_url.begins_with("ws://") and not clean_url.begins_with("wss://"))
		or _game_id.is_empty()
		or _match_id.is_empty()
		or _launch_ticket.is_empty()
	):
		_finish_failed("PARDEX doğrulama bilgileri eksik.")
		return

	_socket = WebSocketPeer.new()
	var result := _socket.connect_to_url(clean_url)
	if result != OK:
		_socket = null
		_finish_failed("PARDEX doğrulama bağlantısı başlatılamadı.")


func confirm_admission() -> void:
	if _finished or _socket == null or _admission_token.is_empty() or _admission_sent:
		return
	_admission_sent = true
	var result := _socket.send_text(JSON.stringify({
		"type": "game_admitted",
		"game_id": _game_id,
		"match_id": _match_id,
		"admission_token": _admission_token,
	}))
	if result != OK:
		_finish_failed("PARDEX oyun kabul onayı gönderilemedi.")


func cancel() -> void:
	if _finished:
		return
	_finished = true
	_close_socket()
	queue_free()


func _process(delta: float) -> void:
	if _finished or _socket == null:
		return

	_elapsed += delta
	_socket.poll()
	var state := _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _verify_sent:
			_verify_sent = true
			var result := _socket.send_text(JSON.stringify({
				"type": "game_ticket_verify",
				"game_id": _game_id,
				"match_id": _match_id,
				"launch_ticket": _launch_ticket,
			}))
			if result != OK:
				_finish_failed("PARDEX ticket doğrulama mesajı gönderilemedi.")
				return

		while _socket != null and _socket.get_available_packet_count() > 0:
			var packet := _socket.get_packet().get_string_from_utf8()
			_handle_packet(packet)
			if _finished:
				return
	elif state == WebSocketPeer.STATE_CLOSED:
		_finish_failed("PARDEX doğrulama bağlantısı kapandı.")
		return

	if _elapsed >= VERIFY_TIMEOUT_SECONDS:
		_finish_failed("PARDEX oyun doğrulaması zaman aşımına uğradı.")


func _handle_packet(packet: String) -> void:
	var parsed = JSON.parse_string(packet)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var message: Dictionary = parsed
	match str(message.get("type", "")):
		"game_ticket_ok":
			var incoming_token := str(message.get("admission_token", "")).strip_edges()
			if incoming_token.is_empty():
				_finish_failed("PARDEX oyun kabul anahtarı alınamadı.")
				return
			_admission_token = incoming_token
			_launch_ticket = ""
			verified.emit(message.duplicate(true))
		"game_admitted_ok":
			_finish_admitted(message)
		"error":
			_finish_failed(str(message.get("message", "PARDEX oyun doğrulaması başarısız.")))


func _finish_admitted(payload: Dictionary) -> void:
	if _finished:
		return
	_finished = true
	_launch_ticket = ""
	_admission_token = ""
	_close_socket()
	admitted.emit(payload.duplicate(true))
	queue_free()


func _finish_failed(message: String) -> void:
	if _finished:
		return
	_finished = true
	_launch_ticket = ""
	_admission_token = ""
	_close_socket()
	failed.emit(message)
	queue_free()


func _close_socket() -> void:
	if _socket == null:
		return
	var state := _socket.get_ready_state()
	if state in [WebSocketPeer.STATE_CONNECTING, WebSocketPeer.STATE_OPEN]:
		_socket.close(1000, "PARDEX validation finished")
	_socket = null

