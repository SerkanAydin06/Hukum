extends Node

const GAME_ID := "hukum"
const NET_PROTOCOL := 1

var enabled := false
var dedicated := false
var private_mode := false
var session_code := ""
var player_id := ""
var player_name := ""
var role := "client"
var online_server_url := ""
var game_server_url := ""
var match_id := ""
var launch_ticket := ""
var session_token := ""

func _ready():
	_parse_user_args(OS.get_cmdline_user_args())
	if not player_name.is_empty(): Global.oyuncu_ismi = _safe_name(player_name)
	if should_auto_enter_lobby(): _route_launcher_client.call_deferred()

func _safe_name(value: String) -> String:
	return value.strip_edges().replace("[", "").replace("]", "").left(16)

func _parse_user_args(args: PackedStringArray):
	var fields = {
		"--pardex-session=": "session_code", "--pardex-player=": "player_id",
		"--pardex-name=": "player_name", "--pardex-role=": "role",
		"--pardex-online-server=": "online_server_url", "--pardex-url=": "online_server_url",
		"--pardex-game-server=": "game_server_url", "--pardex-match=": "match_id",
		"--pardex-ticket=": "launch_ticket", "--pardex-session-token=": "session_token"
	}
	for arg in args:
		if arg == "--pardex": enabled = true
		elif arg == "--pardex-dedicated": dedicated = true
		elif arg == "--private-game": private_mode = true
		for prefix in fields:
			if arg.begins_with(prefix): set(fields[prefix], arg.trim_prefix(prefix).strip_edges())
	if dedicated or private_mode: enabled = false
	session_code = session_code.to_upper()
	role = "host" if role == "host" else "client"

func has_online_link() -> bool:
	return not private_mode and not dedicated and not session_token.is_empty() and valid_url(online_server_url)

func valid_url(value: String) -> bool:
	return (value.begins_with("ws://") or value.begins_with("wss://")) and value.length() <= 2048 and not "@" in value and not " " in value

func should_auto_enter_lobby() -> bool:
	return enabled and not dedicated and not private_mode and valid_url(game_server_url) and not session_code.is_empty() and not player_id.is_empty() and not match_id.is_empty() and not launch_ticket.is_empty()

func enter_match(ticket: Dictionary) -> bool:
	var room = ticket.get("room", {})
	if not room is Dictionary: return false
	if str(ticket.get("game_id", GAME_ID)) != GAME_ID or str(room.get("game_id", GAME_ID)) != GAME_ID: return false
	var url = str(room.get("game_server_url", "")).strip_edges()
	var code = str(room.get("code", "")).strip_edges().to_upper()
	if not valid_url(url) or code.length() != 5: return false
	for field in ["match_id", "launch_ticket", "user_id"]:
		if str(ticket.get(field, "")).strip_edges().is_empty(): return false
	if Network.oturum_asamasi == "game": return false
	enabled = true
	private_mode = false
	game_server_url = url
	session_code = code
	player_id = str(ticket["user_id"])
	match_id = str(ticket["match_id"])
	launch_ticket = str(ticket["launch_ticket"])
	role = "host" if str(ticket.get("role", "")) == "host" else "client"
	if is_inside_tree(): _route_launcher_client.call_deferred()
	return true

func _route_launcher_client():
	if should_auto_enter_lobby() and not Network.pardex_oyununa_katil():
		Network.durum_degisti.emit("PARDEX oyun sunucusuna bağlantı başlatılamadı.", true)

func consume_launch_ticket():
	launch_ticket = ""

func leave_match():
	enabled = false
	session_code = ""
	match_id = ""
	launch_ticket = ""
	game_server_url = ""
	role = "client"
