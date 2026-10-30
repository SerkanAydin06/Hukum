extends Node

signal status_changed(message: String, is_error: bool)
signal linked_changed(linked: bool)

var linked := false
var display_name := ""
var son_durum := ""
var son_hata := false
var _socket: WebSocketPeer
var _retry := 0.0
var _keepalive := 0.0
var _elapsed := 0.0
var _sent_link := false
var _pending: Dictionary = {}
var _enabled := false
var _busy := false
var _accept_tickets := true

func _ready():
	_enabled = PardexBridge.has_online_link()
	set_process(_enabled)
	if _enabled: _connect()

func is_available() -> bool:
	return PardexBridge.has_online_link()

func _status(message: String, error := false):
	son_durum = message
	son_hata = error
	status_changed.emit(message, error)

func use_private_mode():
	leave_match()
	_enabled = false
	_pending.clear()
	_busy = false
	if _socket: _socket.close()
	_socket = null
	_set_linked(false)
	set_process(false)

func use_official_mode():
	_accept_tickets = true
	if not is_available(): return
	_enabled = true
	set_process(true)
	if _socket == null: _connect()

func host_match():
	_request({"type": "host_match", "max_players": 6}, "Masa kuruluyor…")

func join_match(code: String):
	var clean = code.strip_edges().to_upper()
	if clean.length() != 5:
		_status(tr("Masa kodu 5 harf veya rakam olmalı."), true)
		return
	if not _code_valid(clean):
		_status(tr("Masa kodunda yalnız A–Z ve 0–9 kullan."), true)
		return
	_request({"type": "join_match", "code": clean}, "%s masasına bağlanılıyor…" % clean)

func _code_valid(code: String) -> bool:
	for c in code:
		if not c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789": return false
	return true

func leave_match():
	_accept_tickets = false
	_pending.clear()
	_busy = false
	if linked: _send({"type": "leave_match"})
	PardexBridge.leave_match()

func _request(message: Dictionary, waiting: String):
	if not is_available():
		_status(tr("Masa kurmak veya koda katılmak için HÜKÜM'ü PARDEX üzerinden aç."), true)
		return
	if _busy: return
	_busy = true
	_elapsed = 0.0
	use_official_mode()
	if linked: _send(message)
	else: _pending = message
	_status(waiting if linked else tr("PARDEX'e bağlanılıyor…"))

func _connect():
	_socket = WebSocketPeer.new()
	_sent_link = false
	_keepalive = 0.0
	if _socket.connect_to_url(PardexBridge.online_server_url) != OK:
		_socket = null
		_retry = 5.0
		_status(tr("PARDEX bağlantısı kurulamadı. Yeniden deneniyor…"), true)

func _process(delta: float):
	if not _enabled: return
	if _busy:
		_elapsed += delta
		if _elapsed >= 20.0:
			_busy = false
			_pending.clear()
			_status(tr("İstek zaman aşımına uğradı. Tekrar deneyebilirsin."), true)
	if _socket == null:
		_retry -= delta
		if _retry <= 0.0: _connect()
		return
	_socket.poll()
	if _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if not _sent_link:
			_sent_link = true
			_send({"type": "game_link", "token": PardexBridge.session_token, "game_protocol": PardexBridge.NET_PROTOCOL})
		while _socket != null and _socket.get_available_packet_count() > 0:
			handle_packet(_socket.get_packet().get_string_from_utf8())
		_keepalive += delta
		if linked and _keepalive >= 20.0:
			_keepalive = 0.0
			_send({"type": "ping"})
	elif _socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		_socket = null
		_retry = 5.0
		_set_linked(false)
		_status(tr("PARDEX bağlantısı kesildi. Yeniden deneniyor…"), true)

func handle_packet(packet: String):
	var message = JSON.parse_string(packet)
	if not message is Dictionary: return
	match str(message.get("type", "")):
		"game_link_ok":
			if str(message.get("game_id", "")) != PardexBridge.GAME_ID:
				_status(tr("PARDEX oturumu HÜKÜM'e ait değil. Oyunu yeniden aç."), true)
				_pending.clear()
				_busy = false
				_enabled = false
				if _socket: _socket.close()
				_set_linked(false)
				return
			display_name = str(message.get("display_name", "")).left(32)
			_set_linked(true)
			_status(tr("PARDEX'e bağlı · %s") % display_name)
			if not _pending.is_empty():
				_send(_pending)
				_pending.clear()
		"match_ticket":
			if not _accept_tickets:
				if linked: _send({"type": "leave_match"})
				return
			_busy = false
			if Network.oturum_asamasi != "game" and not PardexBridge.enter_match(message):
				_status(tr("Masa bileti eksik veya farklı oyuna ait. Tekrar dene."), true)
		"error":
			_busy = false
			_pending.clear()
			_status(str(message.get("message", tr("PARDEX isteği reddedildi."))).left(400), true)
			if str(message.get("code", "")) == "GAME_SESSION_INVALID":
				_set_linked(false)
				_enabled = false
				if _socket: _socket.close()

func _send(message: Dictionary):
	if _socket != null and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_socket.send_text(JSON.stringify(message))

func _set_linked(value: bool):
	if linked != value:
		linked = value
		linked_changed.emit(value)
