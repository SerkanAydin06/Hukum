extends Node

var role := 0
var failed := false
var ready_peers := []
var reports := {}
var game

func check(condition: bool, message: String):
	if not condition:
		failed = true
		push_error(message)

func _ready():
	role = int(OS.get_cmdline_user_args()[0])
	Global.oyuncu_ismi = "SceneTest%d" % role
	get_tree().create_timer(45).timeout.connect(func():
		push_error("Actual-scene network timeout, role %d" % role)
		get_tree().quit(1))
	if role == 0:
		check(Network.host_game(), "Actual host opens")
	else:
		check(Network.join_game("127.0.0.1"), "Actual client connects")
		await multiplayer.connected_to_server
	get_tree().change_scene_to_file("res://LobiPaneli.tscn")
	await get_tree().create_timer(1.5).timeout
	var lobby = get_tree().current_scene
	lobby._renk_sec(["Kirmizi", "Mavi", "Yesil"][role])
	lobby._medeniyet_bayragina_tiklandi(["Osmanlı", "Venedik", "Mısır"][role])
	lobby._hazir_butonuna_basildi()
	if role == 0:
		while lobby.lobi_verisi.size() != 3 or not all_ready(lobby):
			await get_tree().create_timer(0.1).timeout
		await get_tree().create_timer(0.3).timeout
		lobby._oyunu_baslat_istegi()
	while not is_instance_valid(get_tree().current_scene) or not get_tree().current_scene.has_method("puan_hesapla"):
		await get_tree().process_frame
	game = get_tree().current_scene
	loaded.rpc_id(1)

func all_ready(lobby) -> bool:
	for data in lobby.lobi_verisi.values():
		if not data.get("hazir_mi", false): return false
	return true

@rpc("any_peer", "call_local", "reliable")
func loaded():
	if not multiplayer.is_server(): return
	var id = multiplayer.get_remote_sender_id()
	if id == 0: id = 1
	ready_peers.append(id)
	if ready_peers.size() == 3: exercise.call_deferred()

func exercise():
	# Found cities and draw one combat card through each real peer's validated RPCs.
	for phase in [0, 1]:
		for id in game.oyuncu_peer_idleri:
			act.rpc_id(id, phase)
			await get_tree().create_timer(0.4).timeout
	check(game.ilk_tur_bitti and game.aktif_sira == 0, "Three real scenes completed setup and first round")
	game.aksiyon.savas_baslat_rpc.rpc(0, 1, 6, 4, "yagmala")
	await get_tree().create_timer(0.3).timeout
	check(game.savas.savas_aktif, "Actual multiplayer battle starts")
	choose.rpc()
	await get_tree().create_timer(0.5).timeout
	reveal_check.rpc()
	await get_tree().create_timer(0.3).timeout
	roll.rpc()
	await get_tree().create_timer(4.0).timeout
	snapshot.rpc()
	await get_tree().create_timer(0.4).timeout
	check(reports.size() == 3, "All participants and spectator reported state")
	for state in reports.values():
		check(state == reports.get(1), "Battle, resources, decks and hands agree on all three peers")
	# Disconnect a nonhost and then the server: remaining client must return to menu.
	var leaving = game.oyuncu_peer_idleri[2]
	disconnect_client.rpc_id(leaving)
	await get_tree().create_timer(0.5).timeout
	check(game.oyuncular[2] in game.ayrilan_oyuncular, "Real client disconnect is registered")
	print("HUKUM ACTUAL SCENE HOST: " + ("FAIL" if failed else "PASS"))
	Network.baglantiyi_kapat()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(1 if failed else 0)

@rpc("authority", "call_local", "reliable")
func act(phase: int):
	var index = game.benim_indexim
	var who = game.oyuncular[index]
	if phase == 0:
		game.aksiyon.bina_kur_rpc.rpc(Vector2i([5, 6, 10][index], 4), who, "sehir_merkezi", "cim")
	else:
		game.aksiyon.savas_karti_cek_rpc.rpc(who)
	game.tur_ekonomi.sirayi_degistir_rpc.rpc()

@rpc("authority", "call_local", "reliable")
func choose():
	if game.benim_indexim > 1: return
	var hand = game.deste.el
	game.savas.secilen_benim_kartlar = [hand[0]]
	game.savas.secilen_benim_idxler = [0]
	# Defenders cannot play siege cards; select no card in that deterministic case.
	if game.benim_indexim == 1 and hand[0].get("tur") in ["kocbasi", "mancinik"]:
		game.savas.secilen_benim_kartlar = []
		game.savas.secilen_benim_idxler = []
	game.savas._onayla_basildi()

@rpc("authority", "call_local", "reliable")
func reveal_check():
	check(game.savas.son_kartlar_dict.size() == 2, "Both real hands revealed")
	for i in range(2):
		var cards = game.savas.son_kartlar_dict.get(game.oyuncular[i], [])
		var slot = game.arayuz.get_node("%OyuncuKart1" if i == 0 else "%RakipKart1")
		check((slot.texture != null) == (not cards.is_empty()), "Revealed slot visible to participant/spectator")

	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/hukum-battle-spectator.png")

@rpc("authority", "call_local", "reliable")
func roll():
	if game.benim_indexim <= 1: game.savas._zar_at_basildi(game.benim_indexim == 0)

@rpc("authority", "call_local", "reliable")
func snapshot():
	check(game.savas.zar_saldiran_deger >= 2 and game.savas.zar_savunan_deger >= 1, "Host dice obey civilization bonus")
	var state = [game.oyuncu_kaynaklari, game.oyuncu_elleri, game.deste.savas_destesi, game.savas_puanlari, game.binalar_verisi, game.piyonlar, failed]
	report.rpc_id(1, state)
	if role != 0:
		await multiplayer.server_disconnected
		await get_tree().create_timer(1.0).timeout
		check(get_tree().current_scene.has_method("_cok_oyunculu_menu_ac"), "Host disconnect returns actual client to menu")
		print("HUKUM ACTUAL SCENE CLIENT %d: %s" % [role, "FAIL" if failed else "PASS"])
		get_tree().quit(1 if failed else 0)

@rpc("any_peer", "call_local", "reliable")
func report(state: Array):
	var id = multiplayer.get_remote_sender_id()
	if id == 0: id = 1
	reports[id] = state
	check(not state.back(), "Client scene assertions passed")

@rpc("authority", "call_remote", "reliable")
func disconnect_client():
	Network.baglantiyi_kapat()
	print("HUKUM ACTUAL SCENE CLIENT %d: %s" % [role, "FAIL" if failed else "PASS"])
	get_tree().quit(1 if failed else 0)
