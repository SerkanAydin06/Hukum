extends Node

var role := 0
var failed := false
var ready_peers := []
var reports := {}
var rejoin_state := []
var trade_reports := {}
var game

func check(condition: bool, message: String):
	if not condition:
		failed = true
		push_error(message)

func _ready():
	role = int(OS.get_cmdline_user_args()[0])
	Global.oyuncu_ismi = "SceneTest%d" % role
	get_tree().create_timer(75).timeout.connect(func():
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
	if not Network.merkezi_mod:
		check(Network.oyun_hazir_peerleri.size() == 2, "Host knows both client scenes are loaded")
	check(game.sure_asamasi_adi == "tur" and game.kalan_sure_saniye() > 100, "Turn countdown runs once all scenes are ready")
	begin_battle.rpc_id(game.oyuncu_peer_idleri[0])
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
	check(reports.size() == game.oyuncular.size() + (1 if Network.dedicated_mode else 0), "All participants and spectator reported state")
	for state in reports.values():
		check(state == reports.get(1), "Battle, resources, deck counts and public hand sizes agree on all peers")
	# In-match chat and a player-to-player trade through the server.
	var veren = game.oyuncular[game.aktif_sira]
	var alan = game.oyuncular[(game.aktif_sira + 1) % 3]
	var once = game.oyuncu_kaynaklari.duplicate(true)
	impostor_trade.rpc_id(game.oyuncu_peer_idleri[(game.aktif_sira + 2) % 3], alan)
	await get_tree().create_timer(0.4).timeout
	check(game.oyuncu_kaynaklari == once, "Only the active player can offer a trade")
	chat_send.rpc_id(game.oyuncu_peer_idleri[(game.aktif_sira + 1) % 3])
	trade_offer.rpc_id(game.oyuncu_peer_idleri[game.aktif_sira], alan)
	await get_tree().create_timer(0.6).timeout
	trade_accept.rpc_id(game.oyuncu_peer_idleri[(game.aktif_sira + 1) % 3])
	await get_tree().create_timer(0.6).timeout
	check(game.oyuncu_kaynaklari[veren]["odun"] == once[veren]["odun"] - 2 and game.oyuncu_kaynaklari[alan]["odun"] == once[alan]["odun"] + 2, "Accepted trade moves wood")
	check(game.oyuncu_kaynaklari[veren]["tas"] == once[veren]["tas"] + 1 and game.oyuncu_kaynaklari[alan]["tas"] == once[alan]["tas"] - 1, "Accepted trade moves stone")
	trade_report.rpc()
	await get_tree().create_timer(0.5).timeout
	check(trade_reports.size() == game.oyuncular.size() + (1 if Network.dedicated_mode else 0), "Every peer reported the trade")
	for rapor in trade_reports.values():
		check(rapor[0] == game.oyuncu_kaynaklari, "Trade result is identical on every peer")
		check(rapor[1] or rapor[2], "Chat line reached every peer")
	# A client's connection drops mid-match; it returns from the main menu with its rejoin key.
	var donen = game.oyuncular[2]
	drop_and_return.rpc_id(game.oyuncu_peer_idleri[2])
	for i in range(240):
		if not rejoin_state.is_empty(): break
		await get_tree().create_timer(0.1).timeout
	check(not rejoin_state.is_empty(), "Dropped client came back into the running match")
	check(not donen in game.ayrilan_oyuncular and game.oyuncu_peer_idleri[2] != 0, "Server restored the returning player's seat")
	if not rejoin_state.is_empty():
		check(rejoin_state[0] == _donus_durumu(donen, true), "Returned client state matches the server (public state, own hand, deck counts)")
		check(rejoin_state[1], "Returned client sees no opponent card contents")
		print("HUKUM_REJOIN_OK")
	# Disconnect a nonhost and then the server: remaining client must return to menu.
	var leaving = game.oyuncu_peer_idleri[2]
	disconnect_client.rpc_id(leaving)
	await get_tree().create_timer(0.5).timeout
	check(game.oyuncular[2] in game.ayrilan_oyuncular, "Real client disconnect is registered")
	if Network.resmi_mod:
		game.savas_puanlari[game.oyuncular[0]] = 25
		game.arayuz.arayuzu_guncelle()
		check(game.oyun_bitti, "Official victory is resolved by the authority")
		await get_tree().create_timer(4.5).timeout
		check(Network.oturum_asamasi == "lobby" and Network.merkezi_lobi.is_empty(), "Official result acknowledged and server recycled")
	print("HUKUM ACTUAL SCENE HOST: " + ("FAIL" if failed else "PASS"))
	Network.baglantiyi_kapat()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(1 if failed else 0)

@rpc("authority", "call_local", "reliable")
func act(phase: int):
	var index = game.benim_indexim
	var who = game.oyuncular[index]
	if phase == 0:
		game.istek("aksiyon", "bina_kur_rpc", [Vector2i([5, 6, 10][index], 4), who, "sehir_merkezi", "cim"])
	else:
		game.istek("aksiyon", "savas_karti_cek_rpc", [who])
	game.istek("tur_ekonomi", "sirayi_degistir_rpc", [])

@rpc("authority", "call_local", "reliable")
func choose():
	if Network.dedicated_mode: return
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
	if Network.dedicated_mode: return
	if game.benim_indexim <= 1: game.savas._zar_at_basildi(game.benim_indexim == 0)

@rpc("authority", "call_local", "reliable")
func snapshot():
	check(game.savas.zar_saldiran_deger >= (2 if game.medeniyetler_verisi[game.oyuncular[0]] == "Osmanlı" else 1) and game.savas.zar_savunan_deger >= 1, "Host dice obey civilization bonus")
	_gizli_elleri_dogrula()
	var state = [game.oyuncu_kaynaklari, _el_gorunumu(), game.deste.savas_kalan, game.deste.normal_kalan, _deste_icerigi(game.deste.atilan_savas_kartlari), game.savas_puanlari, game.binalar_verisi, game.piyonlar, failed]
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

@rpc("authority", "call_local", "reliable")
func begin_battle():
	game.istek("aksiyon", "savas_baslat_rpc", [0, 1, 6, 4, "yagmala"])

# Deck order is server-only; peers must agree on what remains, not on its order.
func _deste_icerigi(deste: Array) -> Array:
	var icerik = []
	for kart in deste: icerik.append(var_to_str(kart))
	icerik.sort()
	return icerik

# Hands are private: peers agree on how many cards of each kind everyone holds.
func _el_gorunumu() -> Dictionary:
	var gorunum = {}
	for isim in game.oyuncular:
		var savas = 0
		var insa = 0
		for kart in game.oyuncu_elleri.get(isim, []):
			if kart.get("hedef") == "savas": savas += 1
			else: insa += 1
		gorunum[isim] = [savas, insa]
	return gorunum

func _gizli_elleri_dogrula():
	if multiplayer.is_server(): return
	var ben = game.oyuncular[game.benim_indexim]
	for isim in game.oyuncular:
		for kart in game.oyuncu_elleri.get(isim, []):
			if isim == ben:
				check(not kart.get("gizli", false), "Own hand is fully visible")
			else:
				check(kart.get("gizli", false), "Opponent card contents never reach this client")

# Public match state plus the named player's own hand, as that player should see it.
func _donus_durumu(isim: String, sunucu_gorusu: bool) -> Array:
	var el = game.oyuncu_elleri.get(isim, []) if sunucu_gorusu else game.deste.el
	return [_el_gorunumu(), game.oyuncu_kaynaklari, game.binalar_verisi, game.piyonlar,
		game.aktif_sira, game.tur_sayaci, game.ilk_tur_bitti, game.savas_puanlari,
		game.deste.normal_kalan, game.deste.savas_kalan, game.harita.kesfedilen_hexler, el]

@rpc("authority", "call_remote", "reliable")
func drop_and_return():
	check(not Network.donus_kaydi.is_empty(), "Client received a rejoin key")
	var isim = game.oyuncular[game.benim_indexim]
	# Simulate a lost connection: the transport closes without a voluntary leave.
	multiplayer.multiplayer_peer.close()
	Network._on_server_disconnected()
	while not is_instance_valid(get_tree().current_scene) or not get_tree().current_scene.has_method("_maca_don"):
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	var menu = get_tree().current_scene
	var dugme = menu.get_node_or_null("AnaKart/HBoxMenuAna/MacaDonBtn")
	check(dugme != null and dugme.visible, "Main menu offers to return to the match")
	if dugme: dugme.pressed.emit()
	while not (is_instance_valid(get_tree().current_scene) and get_tree().current_scene.get("donus_tamamlandi")):
		await get_tree().process_frame
	game = get_tree().current_scene
	check(game.oyuncular[game.benim_indexim] == isim, "Returned to the same seat")
	var gizli_dogru = true
	for o in game.oyuncular:
		for kart in game.oyuncu_elleri.get(o, []):
			if (o == isim) == kart.get("gizli", false): gizli_dogru = false
	rejoined.rpc_id(1, [_donus_durumu(isim, false), gizli_dogru])

@rpc("any_peer", "call_remote", "reliable")
func rejoined(state: Array):
	if multiplayer.is_server(): rejoin_state = state

@rpc("authority", "call_remote", "reliable")
func impostor_trade(hedef: String):
	game.iletisim.takas_teklif_et(hedef, "odun", 2, "tas", 1)

@rpc("authority", "call_remote", "reliable")
func chat_send():
	game.iletisim._sohbet_gonder("Selam hükümdarlar")

@rpc("authority", "call_local", "reliable")
func trade_offer(hedef: String):
	game.iletisim.takas_teklif_et(hedef, "odun", 2, "tas", 1)

@rpc("authority", "call_remote", "reliable")
func trade_accept():
	var panel = game.get_node("%TakasPaneli")
	check(panel.visible and "2 Odun" in game.get_node("%TakasMetni").text, "Trade offer shows on the target's screen")
	game.get_node("%TakasKabulBtn").pressed.emit()

@rpc("authority", "call_local", "reliable")
func trade_report():
	var sohbet = false
	var takas = false
	for satir in game.arayuz.olay_logu.get_children():
		if satir is RichTextLabel:
			var metin = satir.get_parsed_text()
			if "Selam hükümdarlar" in metin: sohbet = true
			if "Takas:" in metin: takas = true
	trade_reported.rpc_id(1, [game.oyuncu_kaynaklari, sohbet and takas, Network.dedicated_mode and multiplayer.is_server()])

@rpc("any_peer", "call_local", "reliable")
func trade_reported(rapor: Array):
	if not multiplayer.is_server(): return
	var id = multiplayer.get_remote_sender_id()
	trade_reports[id if id != 0 else 1] = rapor
