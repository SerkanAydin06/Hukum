extends SceneTree

var failures := 0
class ValidatorProbe:
	extends Node
	var confirmations := 0
	var cancellations := 0
	func confirm_admission(): confirmations += 1
	func cancel(): cancellations += 1

func check(value: bool, message: String):
	if not value:
		failures += 1
		push_error(message)

func _initialize(): call_deferred("run")

func run():
	var bridge = load("res://Scripts/PardexBridge.gd").new()
	var valid = {"game_id": "hukum", "user_id": "fixture-user", "match_id": "fixture-match", "launch_ticket": "fixture-ticket", "room": {"game_server_url": "ws://127.0.0.1:8766", "code": "ABCDE", "game_id": "hukum"}}
	var invalid = valid.duplicate(true)
	invalid["game_id"] = "korsanlar"
	check(not bridge.enter_match(invalid), "Tickets for another game are rejected")
	invalid = valid.duplicate(true)
	invalid.erase("launch_ticket")
	check(not bridge.enter_match(invalid), "Missing one-use credential is rejected")
	check(not bridge.valid_url("https://example.com") and not bridge.valid_url("ws://user:password@example.com"), "Only credential-free WebSocket addresses are accepted")
	check(bridge.enter_match(valid) and bridge.should_auto_enter_lobby(), "Complete HUKUM handoff accepted")
	bridge.consume_launch_ticket()
	check(not bridge.should_auto_enter_lobby(), "Consumed launch credential cannot be reused")
	bridge.free()
	var link = load("res://Scripts/PardexLink.gd").new()
	link.handle_packet('{"type":"game_link_ok","game_id":"korsanlar"}')
	check(not link.linked and link.son_hata, "Link cannot bind a different game's session")
	link.join_match("TOO-LONG")
	check(link.son_hata and not link._busy, "Malformed room code is retryable")
	link.leave_match()
	link.handle_packet(JSON.stringify({"type": "match_ticket"}.merged(valid)))
	check(not root.get_node("PardexBridge").enabled, "Late room ticket after cancel does not reopen a lobby")
	link.free()
	var network = load("res://Scripts/Network.gd").new()
	var payload = {"game_id": "hukum", "match_id": "fixture-match", "room_code": "ABCDE", "user_id": "fixture-user", "role": "host"}
	var probes = []
	for id in [10, 11]:
		var probe = ValidatorProbe.new()
		probes.append(probe)
		network._bekleyen[id] = {"isim": "Player", "avatar": 1, "user_id": "fixture-user", "code": "ABCDE", "match_id": "fixture-match", "validator": probe, "role": ""}
	network._bilet_dogrulandi(payload, 10)
	network._bilet_dogrulandi(payload, 11)
	check(probes[0].confirmations == 1 and probes[1].cancellations == 1 and not network._bekleyen.has(11), "Concurrent admission cannot reserve two seats for one identity")
	network._onayli[12] = {"user_id": "fixture-user"}
	network.oturum_asamasi = "lobby"
	network._kabul_dogrulandi(payload, 10)
	check(probes[0].cancellations == 1 and network._onayli.size() == 1, "Admission rechecks identity before granting a seat")
	var invalid_role = ValidatorProbe.new()
	probes.append(invalid_role)
	network._bekleyen[13] = {"isim": "Player", "avatar": 1, "user_id": "other", "code": "ABCDE", "match_id": "fixture-match", "validator": invalid_role, "role": ""}
	payload["user_id"] = "other"
	payload.erase("role")
	network._bilet_dogrulandi(payload, 13)
	check(invalid_role.cancellations == 1, "Client-supplied owner claim cannot replace a verified role")
	network.free()
	for probe in probes: probe.free()
	print("HUKUM ONLINE CONTRACTS: %d failures" % failures)
	quit(1 if failures else 0)
