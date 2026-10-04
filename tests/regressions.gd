extends Node

class TestGame extends AnaOyun:
	var sender = "A"
	func _ready(): pass
	func rpc_gonderen_ismi() -> String: return sender

class MapStub extends Node:
	const HARITA_GENISLIK = 16
	const HARITA_YUKSEKLIK = 12
	var kesfedilen_hexler = {}
	func hex_komsu_mu(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_to(b) == 1
	func gorus_haritasini_guncelle(): pass
	func queue_redraw(): pass
	func tiklanan_hexi_bul(_pos): return Vector2i(0, 0)

class UIStub extends Node:
	var alt_orta_panel = null
	var savas_kart_eli_konteyner = null
	var insa_kart_eli_konteyner = null
	var isyan_onay_paneli = null
	var puan_konteyner = null
	var hakimiyet_paneli = null
	func olay_yaz(_mesaj): pass
	func arayuzu_guncelle(): pass
	func renkli_isim(isim): return isim
	func panel_yukari_cik(): pass

var game: TestGame
var battle
var actions
var deck
var failures = 0
var checks = 0

func _ready():
	call_deferred("run_tests")

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func setup():
	game = TestGame.new()
	game.name = "AnaOyun"
	for spec in [["Harita", MapStub.new()], ["ArayuzYonetici", UIStub.new()],
		["TurEkonomiYonetici", TurEkonomiYonetici.new()], ["AksiyonYonetici", AksiyonYonetici.new()],
		["DesteYonetici", load("res://Scripts/DesteYonetici.gd").new()],
		["SavasYonetici", load("res://Scripts/SavasYonetici.gd").new()]]:
		var node = spec[1]
		node.name = spec[0]
		game.add_child(node)
		node.owner = game
		node.unique_name_in_owner = true
	get_tree().root.add_child(game)
	battle = game.savas
	actions = game.aksiyon
	deck = game.deste
	reset_state()

func reset_state():
	game.oyuncular = ["A", "B", "C"]
	game.oyuncu_peer_idleri = [1, 2, 3]
	game.oyuncu_elleri = {"A": [], "B": [], "C": []}
	game.oyuncu_kaynaklari = {}
	game.odenen_vergiler = {}
	for isim in game.oyuncular:
		game.oyuncu_kaynaklari[isim] = {"odun": 30, "tas": 30, "yiyecek": 30, "altin": 30, "koylu": 1, "max_nufus": 3}
		game.odenen_vergiler[isim] = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}
	game.sehir_merkezleri = {"A": true, "B": true, "C": true}
	game.medeniyetler_verisi = {"A": "Osmanlı", "B": "Bizans", "C": "Viking"}
	game.secilen_renkler = {"A": "Beyaz", "B": "Mavi", "C": "Yesil"}
	game.piyonlar = [{"sahip": "A", "koordinat": Vector2i(0, 0)}, {"sahip": "B", "koordinat": Vector2i(1, 0)}]
	game.binalar_verisi = {}
	game.kontrol_edilen_hexler = {Vector2i(0, 0): "A"}
	game.harita.kesfedilen_hexler = {Vector2i(0, 0): "cim", Vector2i(1, 0): "orman"}
	game.efendiler = {}
	game.ayrilan_oyuncular = []
	game.aktif_sira = 0
	game.benim_indexim = 0
	game.aktif_oyuncu_aksiyon_hakki = 3
	game.sender = "A"
	game.ilk_tur_bitti = true
	battle.savas_aktif = false
	battle.savas_piyon_saldiran = 0
	battle.savas_piyon_savunan = 1
	battle.savas_hedef_turu = "piyon"
	battle.savas_bina_koordinat = Vector2i(1, 0)
	battle.savas_ozel_saldiran = ""
	battle.savas_ozel_savunucu = ""
	battle.secilen_savas_kartlari = {}
	battle.son_kartlar_dict = {}
	battle.secilen_benim_idxler = []
	battle.secilen_benim_kartlar = []
	battle.kendi_kilitledi_mi = false
	deck.el = []
	deck.atilan_savas_kartlari = []

func hand(isim: String, cards: Array):
	game.oyuncu_elleri[isim] = cards.duplicate(true)
	if isim == game.oyuncular[game.benim_indexim]: deck.el = cards.duplicate(true)

func run_tests():
	for file in DirAccess.get_files_at("res://Scripts"):
		if file.ends_with(".gd"):
			var script = load("res://Scripts/" + file)
			check(script != null and script.can_instantiate(), "Godot compiles " + file)
	setup()
	await get_tree().process_frame
	var soldier = {"hedef": "savas", "tur": "piyade", "isim": "Piyade", "guc": 1}
	var siege = {"hedef": "savas", "tur": "kocbasi", "isim": "Koçbaşı", "guc": 7}
	check(battle.savunma_gucu(Vector2i(1, 0)) == 2, "Forest defense")
	game.harita.kesfedilen_hexler[Vector2i(1, 0)] = "dag"
	game.binalar_verisi[Vector2i(1, 0)] = {"tur": "sehir_merkezi", "seviye": 3, "sahip": "B"}
	check(battle.savunma_gucu(Vector2i(1, 0)) == 12, "Mountain plus level-three city defense")
	battle.savas_aktif = true
	game.benim_indexim = 2
	check(not battle._ben_savasta_miyim(), "Spectator must not be a participant")
	game.sender = "C"
	hand("C", [soldier])
	actions.savas_hamlesi_yap_rpc("C", [soldier], [0])
	check(battle.secilen_savas_kartlari.is_empty() and deck.el.size() == 1, "Spectator cannot submit or lose cards")
	game.oyuncu_ayrildi_rpc("C")
	check(battle.savas_aktif, "Spectator disconnect must preserve combat")
	reset_state()
	battle.savas_aktif = true
	hand("A", [soldier])
	actions.savas_hamlesi_yap_rpc("A", [soldier], [0])
	check(deck.el.size() == 1 and deck.atilan_savas_kartlari.is_empty(), "First lock must not consume cards")
	actions.savas_hamlesi_yap_rpc("A", [soldier], [0])
	check(battle.secilen_savas_kartlari.size() == 1, "Repeated lock rejected")
	battle.savasi_iptal_et()
	check(deck.el.size() == 1 and not battle.savas_aktif, "Cancellation before reveal retains hand")
	reset_state()
	battle.savas_aktif = true
	hand("A", [soldier])
	hand("B", [siege])
	game.sender = "B"
	battle.savas_hedef_turu = "bina"
	game.binalar_verisi[Vector2i(1, 0)] = {"tur": "tarla", "sahip": "B", "seviye": 1}
	actions.savas_hamlesi_yap_rpc("B", [siege], [0])
	check(battle.secilen_savas_kartlari.is_empty(), "Defender cannot use siege")
	game.sender = "A"
	actions.savas_hamlesi_yap_rpc("A", [soldier, soldier], [0, 0])
	check(battle.secilen_savas_kartlari.is_empty(), "Duplicate card indices rejected")
	var forged = soldier.duplicate(true)
	forged["guc"] = 1000
	actions.savas_hamlesi_yap_rpc("A", [forged], [0])
	check(battle.secilen_savas_kartlari.is_empty(), "Forged card strength rejected")
	hand("B", [soldier])
	actions.kartlari_ac_rpc({"A": [soldier], "B": [soldier]})
	check(deck.el.is_empty() and deck.atilan_savas_kartlari.size() == 2, "Reveal consumes both hands once")
	battle.savasi_iptal_et()
	check(deck.el.size() == 1 and game.oyuncu_elleri["B"].size() == 1 and deck.atilan_savas_kartlari.is_empty(), "Cancellation after reveal refunds both hands")
	reset_state()
	actions.piyon_hareket_rpc(0, Vector2i(15, 11))
	check(game.piyonlar[0]["koordinat"] == Vector2i(0, 0) and game.aktif_oyuncu_aksiyon_hakki == 3, "Distant movement rejected without charging AP")
	actions.kesif_ve_hareket_rpc(0, Vector2i(-1, 0), "cim", "A")
	check(game.aktif_oyuncu_aksiyon_hakki == 3, "Out-of-bounds exploration rejected")
	game.oyuncu_kaynaklari["A"]["yiyecek"] = 0
	actions.piyon_hareket_rpc(0, Vector2i(1, 0))
	check(game.aktif_oyuncu_aksiyon_hakki == 3, "Movement requires food")
	reset_state()
	var camp = {"hedef": "harita", "tur": "oncu_kampi", "odun_maliyet": 6, "tas_maliyet": 2}
	hand("A", [camp])
	actions.kart_oyna_rpc("A", "oncu_kampi", Vector2i(0, 0), -6, 2, 0)
	check(game.binalar_verisi.is_empty() and game.oyuncu_kaynaklari["A"]["odun"] == 30, "Negative construction cost rejected")
	actions.kart_oyna_rpc("A", "oncu_kampi", Vector2i(1, 0), 6, 2, 0)
	check(game.binalar_verisi.is_empty(), "Construction on enemy/uncontrolled territory rejected")
	actions.kart_oyna_rpc("A", "oncu_kampi", Vector2i(0, 0), 6, 2, 0)
	check(game.binalar_verisi[Vector2i(0, 0)]["tur"] == "oncu_kampi" and deck.el.is_empty(), "Camp can be built and consumes card")
	actions.oncu_uret_rpc("A", Vector2i(0, 0))
	check(game.piyonlar.size() == 3 and game.oyuncu_kaynaklari["A"]["yiyecek"] == 25, "Camp produces a pioneer for five food")
	reset_state()
	var upgrade = {"hedef": "kendi_binasi", "bina_turu": "tarla", "odun_maliyet": 5, "tas_maliyet": 2}
	hand("A", [upgrade])
	game.binalar_verisi[Vector2i(1, 0)] = {"tur": "tarla", "sahip": "B", "seviye": 1}
	actions.bina_yukselt_rpc("A", Vector2i(1, 0), 5, 2, 0)
	check(game.binalar_verisi[Vector2i(1, 0)]["seviye"] == 1 and deck.el.size() == 1, "Enemy building upgrade rejected")
	reset_state()
	hand("A", [soldier])
	actions.karti_feda_et_rpc("A", "altin", 0)
	check(deck.el.is_empty() and deck.atilan_savas_kartlari.size() == 1 and game.oyuncu_kaynaklari["A"]["altin"] == 31, "Sacrifice atomically grants resource and discards card")
	actions.karti_feda_et_rpc("A", "altin", 0)
	check(game.oyuncu_kaynaklari["A"]["altin"] == 31, "Consumed card cannot be sacrificed twice")
	reset_state()
	game.sender = "C"
	actions.savas_karti_atildi_rpc(0)
	check(deck.atilan_savas_kartlari.is_empty(), "Discard injection from out-of-turn peer rejected")
	game.sender = "A"
	game.piyonlar[0]["koordinat"] = Vector2i(0, 0)
	actions.savas_baslat_rpc(99, 1, 1, 0)
	check(not battle.savas_aktif and game.aktif_oyuncu_aksiyon_hakki == 3, "Invalid attacking index rejected")
	reset_state()
	game.secili_kart_index = 0
	game.kart_insa_modu_aktif = true
	game.kurulabilir_hexler = [Vector2i(0, 0)]
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = false
	actions._unhandled_input(click)
	check(game.secili_kart_index == -1 and not game.kart_insa_modu_aktif and game.kurulabilir_hexler.is_empty(), "One right click cancels the whole construction mode")
	reset_state()
	battle.savas_aktif = true
	game.binalar_verisi[Vector2i(0, 1)] = {"tur": "sehir_merkezi", "sahip": "A", "seviye": 1}
	game.binalar_verisi[Vector2i(1, 1)] = {"tur": "sehir_merkezi", "sahip": "B", "seviye": 1}
	game.savas_puanlari = {"A": 0, "B": 0}
	battle.savas_cozumle({"A": [soldier], "B": []}, 5, 5)
	check(game.savas_puanlari["B"] == 1 and game.savas_puanlari["A"] == -1, "Forest defense changes the actual winner")
	Network.oyun_tohumu = 12345
	deck.desteleri_hazirla()
	var camps = 0
	for card in deck.normal_deste:
		if card.get("tur") == "oncu_kampi": camps += 1
	check(camps == 10, "Deck contains camp cards")
	print("HUKUM REGRESSIONS: %d checks, %d failures" % [checks, failures])
	await get_tree().create_timer(4.1).timeout
	game.free()
	get_tree().quit(1 if failures else 0)
