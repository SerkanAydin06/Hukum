extends "res://tests/scene_network_driver.gd"

func _ready():
	TranslationServer.set_locale("tr")   # assertions read Turkish game text
	var args = OS.get_cmdline_user_args()
	role = int(args[0])
	var port = int(args[1])
	Global.oyuncu_ismi = "CentralTest%d" % role
	get_tree().create_timer(80).timeout.connect(func():
		push_error("Central network timeout, role %d" % role)
		get_tree().quit(1))
	if role == 0:
		check(Network.merkezi_sunucu_baslat(port), "Dedicated WebSocket server opens")
		while Network.merkezi_lobi.size() != 3 or not all_central_ready():
			await get_tree().create_timer(0.1).timeout
		check(not Network.merkezi_lobi.has(1), "Dedicated authority does not occupy a player seat")
		var ids = Network.merkezi_lobi.keys()
		var other = ids[0] if ids[0] != Network.oda_sahibi_id else ids[1]
		unauthorized_start.rpc_id(other)
		await get_tree().create_timer(0.3).timeout
		check(Network.oturum_asamasi == "lobby", "Nonowner cannot start the central match")
		bot_request.rpc_id(other, true)
		await get_tree().create_timer(0.3).timeout
		check(Network.merkezi_lobi.size() == 3, "Nonowner cannot add AI seats")
		bot_request.rpc_id(Network.oda_sahibi_id, true)
		await get_tree().create_timer(0.3).timeout
		var botlar = Network.merkezi_lobi.keys().filter(func(id): return id < 0)
		check(botlar.size() == 1 and Network.merkezi_lobi[botlar[0]]["zorluk"] == "zor", "Room owner adds an AI seat on the server")
		bot_request.rpc_id(Network.oda_sahibi_id, false)
		await get_tree().create_timer(0.3).timeout
		check(Network.merkezi_lobi.size() == 3, "Room owner removes the AI seat")
		begin_match.rpc_id(Network.oda_sahibi_id)
	else:
		check(Network.ozel_sunucuya_katil("ws://127.0.0.1:%d" % port), "WebSocket client connects")
		while not is_instance_valid(get_tree().current_scene) or not get_tree().current_scene.has_method("_hazir_butonuna_basildi"):
			await get_tree().process_frame
		var lobby = get_tree().current_scene
		lobby._renk_sec(["Kirmizi", "Mavi", "Yesil"][role - 1])
		await get_tree().create_timer(0.2).timeout
		lobby._medeniyet_bayragina_tiklandi(["Osmanlı", "Venedik", "Mısır"][role - 1])
		await get_tree().create_timer(0.2).timeout
		lobby._hazir_butonuna_basildi()
	while Network.oturum_asamasi != "game":
		await get_tree().process_frame
	game = get_tree().current_scene
	if role != 0: loaded.rpc_id(1)

func all_central_ready() -> bool:
	for data in Network.merkezi_lobi.values():
		if not data.get("hazir_mi", false): return false
	return true

@rpc("authority", "call_remote", "reliable")
func unauthorized_start():
	Network.maci_baslat_rpc.rpc_id(1)

@rpc("authority", "call_remote", "reliable")
func begin_match():
	Network.maci_baslat_rpc.rpc_id(1)

@rpc("authority", "call_remote", "reliable")
func bot_request(ekle: bool):
	if ekle: Network.yapay_zeka_ekle_rpc.rpc_id(1, "zor")
	else: Network.yapay_zeka_cikar_rpc.rpc_id(1)
