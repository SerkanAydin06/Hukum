extends Node

const Fixtures = preload("res://regressions.gd")
class NetworkGame extends AnaOyun:
	func _ready(): pass

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
	game.deste.normal_deste = [camp.duplicate(true), camp.duplicate(true)]
	if not is_host: client_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func client_ready():
	if not is_host or multiplayer.get_remote_sender_id() != client_id: return
	game.aksiyon.normal_kart_cek_rpc.rpc("A")
	game.aksiyon.kart_oyna_rpc.rpc("A", "oncu_kampi", Vector2i(0, 0), 6, 2, 0)
	game.tur_ekonomi.sirayi_degistir_rpc.rpc()
	client_turn.rpc_id(client_id)

@rpc("authority", "call_remote", "reliable")
func client_turn():
	check(game.aktif_sira == 1, "Client received host turn advancement")
	check(game.binalar_verisi.has(Vector2i(0, 0)), "Host construction replicated")
	check(game.oyuncu_elleri["A"].is_empty(), "Host card consumption replicated")
	game.aksiyon.normal_kart_cek_rpc.rpc("B")
	check(game.deste.el.size() == 1, "Client draws its local card")
	game.aksiyon.karti_feda_et_rpc.rpc("B", "odun", 0)
	game.aksiyon.oncu_uret_rpc.rpc("A", Vector2i(0, 0))
	game.tur_ekonomi.sirayi_degistir_rpc.rpc()
	check(game.oyuncu_kaynaklari["B"]["odun"] == 31 and game.deste.el.is_empty(), "Client sacrifice consumed exactly one card")
	report.rpc_id(1, failed)

@rpc("any_peer", "call_remote", "reliable")
func report(client_failed: bool):
	if not is_host or multiplayer.get_remote_sender_id() != client_id: return
	check(not client_failed, "Client checks passed")
	check(game.oyuncu_kaynaklari["A"]["odun"] == 24, "Host build cost charged once")
	check(game.oyuncu_kaynaklari["B"]["odun"] == 31, "Client resource gain replicated")
	check(game.oyuncu_elleri["B"].is_empty(), "Client hand consumption replicated")
	check(game.piyonlar.is_empty(), "Spoofed producer identity rejected on host")
	check(game.aktif_sira == 0 and game.aktif_oyuncu_aksiyon_hakki == 3, "Both peers advanced back to host consistently")
	print("HUKUM ENET SMOKE: " + ("FAIL" if failed else "PASS"))
	finish.rpc_id(client_id, failed)
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(1 if failed else 0)

@rpc("authority", "call_remote", "reliable")
func finish(host_failed: bool):
	print("HUKUM ENET CLIENT: " + ("FAIL" if failed or host_failed else "PASS"))
	get_tree().quit(1 if failed or host_failed else 0)
