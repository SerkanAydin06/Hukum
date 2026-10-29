extends "res://tests/central_network_driver.gd"

func _ready():
	var args = OS.get_cmdline_user_args()
	role = int(args[0])
	Global.oyuncu_ismi = "OfficialTest%d" % role
	get_tree().create_timer(55).timeout.connect(func():
		push_error("Official network timeout, role %d" % role)
		get_tree().quit(1))
	if role == 0:
		while not Network.dedicated_mode:
			await get_tree().process_frame
		while Network.merkezi_lobi.size() != 3 or not all_central_ready():
			await get_tree().create_timer(0.1).timeout
		check(Network.resmi_mod and Network.oda_sahibi_id > 1, "Trusted admission assigns an actual player as owner")
		check(not Network.merkezi_lobi.has(1), "Official authority occupies no player seat")
		var other = Network.merkezi_lobi.keys().filter(func(id): return id != Network.oda_sahibi_id)[0]
		unauthorized_start.rpc_id(other)
		await get_tree().create_timer(0.3).timeout
		check(Network.oturum_asamasi == "lobby", "Official nonowner cannot start the match")
		begin_match.rpc_id(Network.oda_sahibi_id)
	else:
		var fixture = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("HUKUM_TEST_SESSION")))
		PardexBridge.session_token = fixture["session_token"]
		PardexBridge.online_server_url = fixture["online_url"]
		get_tree().change_scene_to_file("res://AnaMenu.tscn")
		while not is_instance_valid(get_tree().current_scene) or not get_tree().current_scene.is_node_ready():
			await get_tree().process_frame
		var menu = get_tree().current_scene
		menu._pardex_ac()
		if role == 1:
			menu.get_node("%MasaKurBtn").pressed.emit()
		else:
			menu.get_node("%KodGiris").text = fixture["code"].to_lower()
			menu.get_node("%KodlaKatilBtn").pressed.emit()
		while not is_instance_valid(get_tree().current_scene) or not get_tree().current_scene.has_method("_hazir_butonuna_basildi"):
			await get_tree().process_frame
		check(PardexBridge.launch_ticket.is_empty(), "One-use launch ticket is consumed after admission request")
		if role == 1: print("HUKUM_TEST_ROOM=" + Network.oda_kodu)
		var lobby = get_tree().current_scene
		lobby._renk_sec(["Kirmizi", "Mavi", "Yesil"][role - 1])
		await get_tree().create_timer(0.2).timeout
		lobby._medeniyet_bayragina_tiklandi(["Osmanlı", "Venedik", "Mısır"][role - 1])
		await get_tree().create_timer(0.2).timeout
		lobby._hazir_butonuna_basildi()
	while Network.oturum_asamasi != "game": await get_tree().process_frame
	game = get_tree().current_scene
	if role != 0: loaded.rpc_id(1)
