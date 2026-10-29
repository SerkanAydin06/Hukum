extends Node

signal succeeded(payload: Dictionary)
signal failed(message: String)

const REQUEST_TIMEOUT_SECONDS := 10.0
const BASE_RETRY_DELAY_SECONDS := 1.0
const MAX_RETRY_DELAY_SECONDS := 30.0

# "game_server_ended" (maç sonucu) ya da "game_server_started" (lobi maçı
# başlattı; PARDEX artık yeni oyuncu almaz). Onay türü "<tür>_ok".
var message_type := "game_server_ended"
# Mesaja eklenecek ek alanlar (ör. game_server_hello için game_protocol).
var extra: Dictionary = {}
var _server_url := ""
var _server_token := ""
var _game_id := ""
var _match_id := ""
var _room_code := ""
var _result: Dictionary = {}
var _socket: WebSocketPeer
var _attempt := 0
var _elapsed := 0.0
var _retry_delay := 0.0
var _sent := false
var _finished := false


func begin(
	server_url: String,
	server_token: String,
	game_id: String,
	match_id: String,
	room_code: String,
	result: Dictionary
) -> void:
	_server_url = server_url.strip_edges()
	_server_token = server_token.strip_edges()
	_game_id = game_id.strip_edges()
	_match_id = match_id.strip_edges()
	_room_code = room_code.strip_edges().to_upper()
	_result = result.duplicate(true)
	if (
		(not _server_url.begins_with("ws://") and not _server_url.begins_with("wss://"))
		or _server_token.is_empty()
		or _game_id.is_empty()
		or (message_type != "game_server_hello" and (_match_id.is_empty() or _room_code.is_empty()))
	):
		_finish_failed("PARDEX oyun sonucu bildirim bilgileri eksik.")
		return
	_start_attempt()


func _start_attempt() -> void:
	if _finished:
		return
	_attempt += 1
	_elapsed = 0.0
	_sent = false
	_retry_delay = 0.0
	_socket = WebSocketPeer.new()
	var error := _socket.connect_to_url(_server_url)
	if error != OK:
		_socket = null
		_schedule_retry("PARDEX sonuç bağlantısı başlatılamadı.")


func _process(delta: float) -> void:
	if _finished:
		return
	if _socket == null:
		if _retry_delay > 0.0:
			_retry_delay -= delta
			if _retry_delay <= 0.0:
				_start_attempt()
		return

	_elapsed += delta
	_socket.poll()
	var state := _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _sent:
			_sent = true
			var payload := {
				"type": message_type,
				"server_token": _server_token,
				"game_id": _game_id,
				"match_id": _match_id,
				"room_code": _room_code,
				"result": _result,
			}
			payload.merge(extra, true)
			var error := _socket.send_text(JSON.stringify(payload))
			if error != OK:
				_schedule_retry("PARDEX oyun sonucu gönderilemedi.")
				return
		while _socket != null and _socket.get_available_packet_count() > 0:
			var packet := _socket.get_packet().get_string_from_utf8()
			_handle_packet(packet)
			if _finished:
				return
	elif state == WebSocketPeer.STATE_CLOSED:
		_schedule_retry("PARDEX sonuç bağlantısı kapandı.")
		return

	if _elapsed >= REQUEST_TIMEOUT_SECONDS:
		_schedule_retry("PARDEX oyun sonucu bildirimi zaman aşımına uğradı.")


func _handle_packet(packet: String) -> void:
	var parsed = JSON.parse_string(packet)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var message: Dictionary = parsed
	match str(message.get("type", "")):
		var ack when ack == message_type + "_ok":
			_finish_success(message)
		"error":
			_schedule_retry(str(message.get("message", "PARDEX oyun sonucu reddedildi.")), false)


func _schedule_retry(message: String, retryable: bool = true) -> void:
	_close_socket()
	if retryable:
		# PARDEX result delivery is idempotent. Keep the dedicated match reserved
		# until the authoritative result is acknowledged instead of dropping the
		# room state after a short control-plane outage.
		var exponent := mini(maxi(_attempt - 1, 0), 5)
		_retry_delay = minf(
			BASE_RETRY_DELAY_SECONDS * pow(2.0, float(exponent)),
			MAX_RETRY_DELAY_SECONDS
		)
		return
	_finish_failed(message)


func _finish_success(payload: Dictionary) -> void:
	if _finished:
		return
	_finished = true
	_server_token = ""
	_close_socket()
	succeeded.emit(payload.duplicate(true))
	queue_free()


func _finish_failed(message: String) -> void:
	if _finished:
		return
	_finished = true
	_server_token = ""
	_close_socket()
	failed.emit(message)
	queue_free()


func _close_socket() -> void:
	if _socket == null:
		return
	var state := _socket.get_ready_state()
	if state in [WebSocketPeer.STATE_CONNECTING, WebSocketPeer.STATE_OPEN]:
		_socket.close(1000, "PARDEX game result reporter finished")
	_socket = null

