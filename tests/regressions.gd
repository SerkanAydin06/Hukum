extends Node

class TestGame extends AnaOyun:
	var sender = "A"
	func _ready(): pass
	func rpc_gonderen_ismi() -> String: return sender

class MapStub extends Node:
	const HARITA_GENISLIK = 16
	const HARITA_YUKSEKLIK = 12
	var kesfedilen_hexler = {}
	var gorus_haritasi = {}
	var bulutsuz_hexler = {}
	func hex_gorunur_mu(k): return gorus_haritasi.get(k, 3) < 3 or bulutsuz_hexler.has(k)
	func hex_komsu_mu(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_to(b) == 1
	func biyom_belirle(_koor: Vector2i) -> String: return "orman"
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
	var battle_states = []
	func arayuzu_guncelle():
		var b = get_parent().savas
		battle_states.append(b.savas_aktif or b.sonuc_gosteriliyor)
	func renkli_isim(isim): return isim
	func panel_yukari_cik(): pass

class LobbyFixture extends LobiPaneli:
	func _ready(): pass
	func lobi_arayuzunu_ciz(): pass

func make_lobby() -> LobbyFixture:
	var lobby = LobbyFixture.new()
	lobby.name = "Lobi"
	for key in ["SohbetGecmisi", "SohbetGirdisi", "GonderBtn", "OyuncuVBox", "MedeniyetButonlariKutusu", "HikayeYazisi", "BonusYazisi", "HazirBtn", "BaslatBtn", "IptalBtn", "LobidenCikBtn", "BaslikHikaye", "AltBaslikHikaye"]:
		var child = RichTextLabel.new() if key == "SohbetGecmisi" else Node.new()
		child.name = key
		lobby.add_child(child)
		child.owner = lobby
		child.unique_name_in_owner = true
	return lobby

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
	battle.sonuc_gosteriliyor = false
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
	# Verify the actual Godot SVG import and card texture assignment, not only a file path.
	var oncu_kart = load("res://Scripts/KartUI.gd").new()
	var oncu_kart_resmi = TextureRect.new()
	oncu_kart_resmi.name = "InsaResim"
	oncu_kart.add_child(oncu_kart_resmi)
	oncu_kart_resmi.owner = oncu_kart
	oncu_kart_resmi.unique_name_in_owner = true
	var cadir = TextureRect.new()
	cadir.name = "OncuKampiDetay"
	oncu_kart.add_child(cadir)
	cadir.owner = oncu_kart
	cadir.unique_name_in_owner = true
	cadir.texture = load("res://Assets/Resimler/kartresimleri/oncukampi_cadir.svg")
	get_tree().root.add_child(oncu_kart)
	oncu_kart.karti_doldur({"tur": "oncu_kampi", "hedef": "harita", "isim": "Öncü Kampı"}, 0)
	check(oncu_kart.insa_resim == oncu_kart_resmi and oncu_kart_resmi.texture != null and cadir.visible and cadir.texture != null and oncu_kart_resmi.texture.resource_path.ends_with("oduncu.png"), "Pioneer camp preserves frame and overlays campsite tent")
	oncu_kart.karti_doldur({"tur": "tarla", "hedef": "harita", "isim": "Tarla"}, 1)
	check(not cadir.visible, "Pioneer camp overlay hides on other construction cards")
	oncu_kart.free()
	await run_new_regressions()
	reset_state()
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
	actions.kesif_ve_hareket_rpc(0, Vector2i(-1, 0), "A")
	check(game.aktif_oyuncu_aksiyon_hakki == 3, "Out-of-bounds exploration rejected")
	reset_state()
	game.harita.kesfedilen_hexler.erase(Vector2i(1, 0))
	actions.kesif_ve_hareket_rpc(0, Vector2i(1, 0), "A")
	check(game.harita.kesfedilen_hexler.get(Vector2i(1, 0)) == "orman" and game.aktif_oyuncu_aksiyon_hakki == 2, "Exploration uses map biome rather than client-selected data")
	reset_state()
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


func run_new_regressions():
	var lobby = make_lobby()
	get_tree().root.add_child(lobby)
	check(not lobby.lobi_istegi_gecerli_mi(2, 1, "A", "Kirmizi", "Osmanlı", true, 1), "Lobby sender cannot impersonate host")
	check(not lobby.lobi_istegi_gecerli_mi(2, 3, "C", "Mavi", "Mısır", true, 1), "Lobby sender cannot impersonate another client")
	check(lobby.lobi_istegi_gecerli_mi(2, 2, "B", "Mavi", "Mısır", true, 2), "Lobby accepts own valid update")
	check(lobby.lobi_istegi_gecerli_mi(1, 2, "B", "Mavi", "Mısır", true, 2), "Lobby accepts trusted host snapshots")
	check(not lobby.lobi_istegi_gecerli_mi(2, 2, "B", "Geçersiz", "Mısır", true, 2), "Unknown lobby colors rejected")
	check(not lobby.lobi_istegi_gecerli_mi(2, 2, "B", "Mavi", "Yok", true, 2), "Unknown civilization rejected")
	check(not lobby.lobi_istegi_gecerli_mi(2, 2, "B", "Mavi", "Mısır", true, 99), "Unknown profile rejected")
	lobby.free()
	reset_state()
	game.medeniyetler_verisi["A"] = "Mısır"
	game.binalar_verisi[Vector2i(0, 0)] = {"tur": "tas_ocagi", "sahip": "A", "seviye": 1}
	game.binalar_verisi[Vector2i(0, 1)] = {"tur": "tas_ocagi", "sahip": "A", "seviye": 3}
	check(game.tur_ekonomi.bina_uretimi("A")["tas"] == 6, "Egypt adds one stone per quarry, independent of level")
	game.efendiler = {"A": "B"}
	check(game.tur_ekonomi._oyuncu_net_uretimini_hesapla("A")["net"]["tas"] == 3, "Egypt production bonus is included before vassal tax")
	game.medeniyetler_verisi["A"] = "Moğol"
	for b in game.binalar_verisi.values(): b["tur"] = "tarla"
	check(game.tur_ekonomi.bina_uretimi("A")["yiyecek"] == 6, "Mongol adds one food per farm")
	reset_state()
	game.binalar_verisi[Vector2i(0, 0)] = {"tur": "ticaret_merkezi", "sahip": "A", "seviye": 1}
	game.oyuncu_kaynaklari["A"]["odun"] = 4
	game.tur_ekonomi.ticaret_yap_rpc("A", "odun")
	check(game.oyuncu_kaynaklari["A"]["altin"] == 30, "Non-Venetian cannot trade four resources")
	game.medeniyetler_verisi["A"] = "Venedik"
	game.tur_ekonomi.ticaret_yap_rpc("A", "odun")
	check(game.oyuncu_kaynaklari["A"]["odun"] == 0 and game.oyuncu_kaynaklari["A"]["altin"] == 31, "Venice trades exactly four resources")
	reset_state()
	game.medeniyetler_verisi["A"] = "Bizans"
	check(battle.medeniyet_guc_bonuslari(10, 12, "A", "B", 2, 6) == [10, 6], "Byzantine attacker low roll halves opposing total")
	check(battle.medeniyet_guc_bonuslari(10, 12, "B", "A", 6, 1) == [5, 12], "Byzantine defender low roll halves opposing total")
	check(battle.medeniyet_guc_bonuslari(10, 12, "A", "B", 3, 6) == [10, 12], "Byzantine high roll has no reduction")
	check(battle.medeniyet_guc_bonuslari(11, 13, "A", "A", 1, 2) == [6, 7], "Both Byzantine reductions apply simultaneously, rounding up")
	reset_state()
	game.efendiler = {"B": "A", "C": "B"}
	check(game.muttefik_mi("A", "C") and game.koruyucu_efendi("C") == "A", "Entire vassal chain shares alliance and protection")
	check(not game.vasallik_gecerli_mi("A", "C"), "Vassal cycle rejected")
	game.piyonlar[0]["sahip"] = "C"
	game.piyonlar[1]["sahip"] = "A"
	game.binalar_verisi[Vector2i(1, 0)] = {"tur": "sehir_merkezi", "sahip": "A", "seviye": 1}
	game.sender = "C"
	game.aktif_sira = 2
	actions.savas_baslat_rpc(0, 1, 1, 0, "hukmet")
	check(not battle.savas_aktif and game.aktif_oyuncu_aksiyon_hakki == 3, "Nested vassal cannot attack supreme lord or spend AP")
	battle._sonucu_uygula_bina(true, "C", "A")
	check(not game.efendiler.has("A"), "Combat outcome cannot introduce vassal cycle")
	reset_state()
	game.binalar_verisi[Vector2i(1, 1)] = {"tur": "sehir_merkezi", "sahip": "B", "seviye": 1}
	game.piyonlar.append({"sahip": "B", "koordinat": Vector2i(1, 0)})
	game.kontrol_edilen_hexler[Vector2i(1, 0)] = "B"
	battle._sonucu_uygula_piyon(true, "A", "B")
	check(game.piyonlar[0]["koordinat"] == Vector2i(1, 0) and game.piyonlar[1]["koordinat"] == Vector2i(1, 1) and game.piyonlar[2]["koordinat"] == Vector2i(1, 1), "All defeated pioneers retreat before attacker occupies conquered land")
	reset_state()
	var real_map = load("res://Scripts/Harita.gd").new()
	Network.oyun_tohumu = 1973
	var beklenen_biyom = real_map.biyom_belirle(Vector2i(4, 7))
	check(beklenen_biyom in ["cim", "orman", "dag"] and beklenen_biyom == real_map.biyom_belirle(Vector2i(4, 7)), "Per-hex terrain is deterministic")
	real_map.kesif_yap(Vector2i(4, 7))
	check(real_map.kesfedilen_hexler[Vector2i(4, 7)] == beklenen_biyom, "Exploration matches deterministic terrain")
	Network.oyun_tohumu = 0
	check(not real_map.hex_gorunur_mu(Vector2i(15, 11)), "Production fog hides unseen tiles")
	real_map.gorus_haritasi[Vector2i(15, 11)] = 2
	check(real_map.hex_gorunur_mu(Vector2i(15, 11)), "Production fog reveals sight-radius edge")
	real_map.gorus_haritasi[Vector2i(15, 11)] = 20
	real_map.bulutsuz_hexler[Vector2i(15, 11)] = true
	check(real_map.hex_gorunur_mu(Vector2i(15, 11)), "Production fog preserves exploration memory")
	real_map.free()
	var ui = load("res://Scripts/ArayuzYonetici.gd").new()
	ui.ana = game
	var labels = {}
	for key in ["AraziLabel", "SahipLabel", "BinaLabel", "UretimBilgi", "SavunmaBonus", "SeciliIsim"]:
		var label = Label.new()
		label.name = key
		ui.add_child(label)
		label.owner = ui
		label.unique_name_in_owner = true
		labels[key] = label
	var hidden = Vector2i(15, 11)
	game.harita.kesfedilen_hexler[hidden] = "orman"
	game.harita.gorus_haritasi[hidden] = 20
	game.binalar_verisi[hidden] = {"tur": "sehir_merkezi", "sahip": "B", "seviye": 3}
	ui.sag_paneli_guncelle(hidden)
	check(labels["AraziLabel"].text == "Sisli Arazi" and labels["SahipLabel"].text == "-" and labels["BinaLabel"].text == "-", "Fog hides global discoveries, owner and buildings")
	game.harita.gorus_haritasi[hidden] = 1
	ui.sag_paneli_guncelle(hidden)
	check(labels["AraziLabel"].text == "Ormanlık Arazi" and labels["SahipLabel"].text == "Bizans", "Visible explored tile shows details")
	game.harita.gorus_haritasi[hidden] = 20
	game.harita.bulutsuz_hexler[hidden] = true
	ui.sag_paneli_guncelle(hidden)
	check(labels["AraziLabel"].text == "Ormanlık Arazi", "Previously seen tile remains available to inspect")
	ui.free()
	for winner in ["A", "B"]:
		reset_state()
		game.medeniyetler_verisi = {"A": "Osmanlı", "B": "Osmanlı", "C": "Mısır"}
		game.medeniyetler_verisi[winner] = "Viking"
		game.binalar_verisi[Vector2i(0, 1)] = {"tur": "sehir_merkezi", "sahip": "A", "seviye": 1}
		game.binalar_verisi[Vector2i(1, 1)] = {"tur": "sehir_merkezi", "sahip": "B", "seviye": 1}
		battle.savas_aktif = true
		battle.savas_cozumle({"A": [], "B": []}, 6 if winner == "A" else 1, 1 if winner == "A" else 6)
		check(game.oyuncu_kaynaklari[winner]["altin"] == 35, "Viking winner gets five gold for " + winner)
		battle.savas_cozumle({"A": [], "B": []}, 6, 1)
		check(game.oyuncu_kaynaklari[winner]["altin"] == 35, "Repeated resolution cannot award Viking gold twice")
		check(battle.sonuc_gosteriliyor and not game.rpc_sirada_mi(), "Result display blocks new actions")
		await get_tree().create_timer(4.1).timeout
		check(not battle.sonuc_gosteriliyor and not game.arayuz.battle_states.back(), "Result closes and refreshes unlocked controls")
