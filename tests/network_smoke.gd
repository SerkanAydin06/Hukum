extends Node

const Fixtures = preload("res://regressions.gd")
class NetworkGame extends AnaOyun:
	func _ready(): pass

var lobby
var game: NetworkGame
var peer = ENetMultiplayerPeer.new()
var client_id = 0
var is_host = false
var failed = false

func _ready():
	var args = OS.get_cmdline_user_args()
	is_host = args[0] == "server"
	var port = int(args[1])
	var status = peer.create_server(port, 2) if is_host else peer.create_client("127.0.0.1", port)
	assert(status == OK)
	multiplayer.multiplayer_peer = peer
	if is_host:
		multiplayer.peer_connected.connect(func(id): configure.rpc(id))
	get_tree().create_timer(15).timeout.connect(func():
		push_error("Network smoke timeout")
		get_tree().quit(1))

func check(condition: bool, message: String):
	if not condition:
		failed = true
		push_error(message)

@rpc("authority", "call_local", "reliable")
func configure(id: int):
	client_id = id
	var fixtures = Fixtures.new()
	lobby = fixtures.make_lobby()
	fixtures.free()
	add_child(lobby)
	game = NetworkGame.new()
	game.name = "AnaOyun"
	for spec in [["Harita", Fixtures.MapStub.new()], ["ArayuzYonetici", Fixtures.UIStub.new()],
		["TurEkonomiYonetici", TurEkonomiYonetici.new()], ["AksiyonYonetici", AksiyonYonetici.new()],
		["DesteYonetici", load("res://Scripts/DesteYonetici.gd").new()],
		["SavasYonetici", load("res://Scripts/SavasYonetici.gd").new()]]:
		var node = spec[1]
		node.name = spec[0]
		game.add_child(node)
		node.owner = game
		node.unique_name_in_owner = true
	get_tree().root.add_child(game)
	game.oyuncular = ["A", "B"]
	game.oyuncu_peer_idleri = [1, id]
	game.oyuncu_elleri = {"A": [], "B": []}
	game.benim_indexim = 0 if is_host else 1
	game.sehir_merkezleri = {"A": true, "B": true}
	game.oyuncu_kaynaklari = {}
	game.odenen_vergiler = {}
	for isim in game.oyuncular:
		game.oyuncu_kaynaklari[isim] = {"odun": 30, "tas": 30, "yiyecek": 30, "altin": 30, "koylu": 1, "max_nufus": 3}
		game.odenen_vergiler[isim] = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}
	game.kontrol_edilen_hexler = {Vector2i(0, 0): "A", Vector2i(1, 0): "B"}
	game.harita.kesfedilen_hexler = {Vector2i(0, 0): "cim", Vector2i(1, 0): "cim"}
	game.ilk_tur_bitti = true
	game.aktif_oyuncu_aksiyon_hakki = 3
	var camp = {"hedef": "harita", "tur": "oncu_kampi", "odun_maliyet": 6, "tas_maliyet": 2}
	game.deste.normal_deste = [camp.duplicate(true), camp.duplicate(true), camp.duplicate(true)]
	game.deste.normal_kalan = 3
	if not is_host: client_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func client_ready():
	if not is_host or multiplayer.get_remote_sender_id() != client_id: return
	lobby.lobi_bilgisi_gonder_rpc.rpc(1, "A", "Kirmizi", "Osmanlı", true, 1)
	lobby.lobi_bilgisi_gonder_rpc.rpc(client_id, "B", "Mavi", "Venedik", true, 2)
	game.istek("aksiyon", "normal_kart_cek_rpc", ["A"])
	game.istek("aksiyon", "normal_kart_cek_rpc", ["A"])
	game.istek("aksiyon", "kart_oyna_rpc", ["A", "oncu_kampi", Vector2i(0, 0), 6, 2, 0])
	game.istek("tur_ekonomi", "sirayi_degistir_rpc", [])
	client_turn.rpc_id(client_id)

@rpc("authority", "call_remote", "reliable")
func client_turn():
	check(lobby.lobi_verisi[1]["isim"] == "A" and lobby.lobi_verisi[client_id]["isim"] == "B", "Trusted host lobby snapshots replicated")
	lobby.lobi_bilgisi_gonder_rpc.rpc(1, "Forged", "Yesil", "Mısır", true, 3)
	lobby.lobi_bilgisi_gonder_rpc.rpc(client_id, "B2", "Mavi", "Venedik", true, 2)
	lobby.sohbet_mesaji_al_rpc.rpc(1, "Forged chat")
	lobby.sohbet_mesaji_al_rpc.rpc(client_id, "Valid chat")
	check(game.aktif_sira == 1, "Client received host turn advancement")
	check(game.binalar_verisi.has(Vector2i(0, 0)), "Host construction replicated")
	var host_eli = game.oyuncu_elleri["A"]
	check(host_eli.size() == 1 and host_eli[0].get("gizli", false), "Host's unplayed card stays hidden from the client")
	check(game.deste.normal_kalan == 1 and game.deste.normal_deste.size() == 2, "Client tracks deck size and unseen cards only")
	game.aksiyon.kart_oyna_rpc("A", "oncu_kampi", Vector2i(1, 0), 6, 2, 0)
	check(not game.binalar_verisi.has(Vector2i(1, 0)), "Client cannot apply moves without the server")
	game.istek("aksiyon", "normal_kart_cek_rpc", ["B"])
	check(game.deste.el.is_empty(), "Client cannot deal itself a card")
	await _bekle(func(): return game.deste.el.size() == 1)
	check(game.deste.el.size() == 1 and game.deste.normal_kalan == 0 and game.deste.normal_deste.size() == 1, "Server deals the client its own card")
	game.istek("aksiyon", "karti_feda_et_rpc", ["B", "odun", 0])
	game.istek("aksiyon", "oncu_uret_rpc", ["A", Vector2i(0, 0)])
	game.istek_rpc.rpc_id(1, "deste", "desteleri_hazirla", [])
	game.istek("tur_ekonomi", "sirayi_degistir_rpc", [])
	await _bekle(func(): return game.aktif_sira == 0)
	check(game.oyuncu_kaynaklari["B"]["odun"] == 31 and game.deste.el.is_empty(), "Client sacrifice consumed exactly one card")
	report.rpc_id(1, failed)

func _bekle(kosul: Callable):
	for i in range(300):
		if kosul.call(): return
		await get_tree().process_frame

@rpc("any_peer", "call_remote", "reliable")
func report(client_failed: bool):
	if not is_host or multiplayer.get_remote_sender_id() != client_id: return
	check(lobby.lobi_verisi[1]["isim"] == "A" and lobby.lobi_verisi[client_id]["isim"] == "B2", "Host rejects spoofed lobby identity and accepts real client update")
	check(not "Forged chat" in lobby.sohbet_gecmisi.get_parsed_text() and "Valid chat" in lobby.sohbet_gecmisi.get_parsed_text(), "Chat sender identity validated")
	check(not client_failed, "Client checks passed")
	check(game.oyuncu_kaynaklari["A"]["odun"] == 24, "Host build cost charged once")
	check(game.oyuncu_kaynaklari["B"]["odun"] == 31, "Client resource gain replicated")
	check(game.oyuncu_elleri["B"].is_empty(), "Client hand consumption replicated")
	check(game.piyonlar.is_empty(), "Spoofed producer identity rejected on host")
	check(game.deste.normal_deste.is_empty() and game.oyuncu_elleri["A"].size() == 1, "Unlisted server request ignored")
	check(game.aktif_sira == 0 and game.aktif_oyuncu_aksiyon_hakki == 3, "Both peers advanced back to host consistently")
	print("HUKUM ENET SMOKE: " + ("FAIL" if failed else "PASS"))
	finish.rpc_id(client_id, failed)
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(1 if failed else 0)

@rpc("authority", "call_remote", "reliable")
func finish(host_failed: bool):
	print("HUKUM ENET CLIENT: " + ("FAIL" if failed or host_failed else "PASS"))
	get_tree().quit(1 if failed or host_failed else 0)

