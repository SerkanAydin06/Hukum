extends SceneTree

var failures := 0
var screenshots := false

func _initialize():
	screenshots = DisplayServer.get_name() != "headless"
	call_deferred("run")

func check(value: bool, message: String):
	if not value:
		failures += 1
		push_error(message)

func capture(label: String):
	await create_timer(0.8).timeout
	if screenshots:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/hukum-" + label + ".png")

func run():
	var dil = OS.get_environment("HUKUM_TEST_LOCALE")
	TranslationServer.set_locale(dil if dil != "" else "tr")
	print("HUKUM RUNTIME SMOKE locale: " + TranslationServer.get_locale())
	var network = root.get_node("Network")
	var global = root.get_node("Global")
	global.tam_ekran = false
	global.ayarlari_uygula()
	change_scene_to_file("res://AnaMenu.tscn")
	await create_timer(1.5).timeout
	var menu = current_scene
	check(menu.has_method("_cok_oyunculu_menu_ac"), "Actual main menu loads")
	menu.get_node("%AyarlarBtn").pressed.emit()
	check(menu.oyun_menusu.perde.visible, "Existing settings button opens settings")
	menu.oyun_menusu.perde.hide()
	var background = menu.get_node("HareketliArkaplan")
	check(background.get_node("UzakBulutlar").material != null and background.get_node("YakinBulutlar").material != null, "Both animated cloud layers are restored")
	check(background.get_node("SuKatmani").material != null and background.get_node("Bayrak/Cloth").material != null, "Water and flag shaders are restored")
	check(background.get_node("KusAnimasyonu").is_playing() and background.get_node("AtmosferIsiklari").emitting, "Birds and atmosphere remain animated")
	var shared_theme = load("res://UI/HukumTheme.tres")
	check(menu.theme == shared_theme and menu.oyun_menusu.perde.theme == shared_theme, "Main and game windows share the same theme")
	var panel_skin = shared_theme.get_stylebox("panel", "PanelContainer")
	check(panel_skin is StyleBoxTexture and panel_skin.texture.resource_path.ends_with("window.svg"), "Windows use one shaped opaque gold-and-black skin")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style = menu.get_node("%PardexBtn").get_theme_stylebox(state)
		check(style is StyleBoxTexture and style.texture.resource_path.ends_with(".svg"), "Scalable button state: " + state)
		check(style.texture_margin_left == 20.0 and style.texture_margin_right == 20.0, "Fixed button corners: " + state)
	await capture("menu")
	await capture("menu-motion")
	menu._pardex_ac()
	check(menu.get_node("%MasaKurBtn").disabled, "Official room action requires a launcher session")
	await capture("online")
	menu._pardex_kapat()
	menu._ozel_sunucu_ac()
	menu.get_node("%SunucuGiris").text = "invalid"
	menu._on_baglan_btn_pressed()
	check(not menu.baglan_btn.disabled and menu.baglanti_durumu.text == tr("Geçersiz adres. ws:// veya wss:// ile başlayan bir sunucu adresi gir."), "Private-server URL errors are retryable")
	await capture("private")
	menu._ana_menuye_don()
	menu._profil_duzenle_ac()
	menu.isim_giris_kutusu.text = "[bad]"
	menu.isim_giris_kutusu.text_changed.emit("[bad]")
	check(menu.kaydet_btn.disabled, "Invalid profile name cannot be saved")
	menu.isim_giris_kutusu.text = global.oyuncu_ismi
	menu.isim_giris_kutusu.text_changed.emit(global.oyuncu_ismi)
	check(menu.get_node("%ProfilResmi/PortraitBorder").texture != null, "Main profile portrait has a gold frame")
	check(menu.get_node("%ProfilResmi").material is ShaderMaterial, "Main profile clips its image inside the frame")
	check(menu.get_node("%DuzenleProfilResmi/PortraitBorder").texture != null, "Large profile preview has a gold frame")
	for number in range(1, 9):
		check(menu.get_node("%%Profil%d/PortraitBorder" % number).texture != null, "Avatar picker is framed: " + str(number))
		check(menu.get_node("%%Profil%d" % number).material is ShaderMaterial, "Avatar picker clips its image: " + str(number))
	await capture("profile")
	menu._profil_duzenle_kapat()
	menu._cok_oyunculu_menu_ac()
	menu.ip_giris.text = "invalid"
	menu._on_baglan_btn_pressed()
	check(not menu.baglan_btn.disabled and menu.baglanti_durumu.text == tr("Geçersiz IP adresi. Örnek: 192.168.1.10"), "Invalid IP is visible and retryable")
	await capture("lan")
	menu._on_kur_btn_pressed()
	await create_timer(1.2).timeout
	var lobby = current_scene
	check(lobby.has_method("_oyunu_baslat_istegi"), "Create room transitions to actual lobby")
	lobby._renk_sec("Kirmizi")
	lobby._medeniyet_bayragina_tiklandi("Osmanlı")
	lobby._hazir_butonuna_basildi()
	var viewport_rect = current_scene.get_global_rect() # logical canvas coordinates, including headless stretch
	for control_name in ["LobidenCikBtn", "BaslatBtn", "SohbetGirdisi"]:
		var control = current_scene.get_node("%" + control_name)
		check(viewport_rect.encloses(control.get_global_rect()), "Lobby control stays on screen: " + control_name)
	await capture("lobby")
	lobby._oyunu_baslat_istegi()
	await create_timer(1.0).timeout
	var game = current_scene
	check(game.has_method("puan_hesapla") and game.oyuncular.size() == 1, "Ready lobby starts actual game")
	await capture("setup")
	var isim = game.oyuncular[0]
	game.aksiyon.bina_kur_rpc(Vector2i(5, 4), isim, "sehir_merkezi", "cim")
	game.tur_ekonomi.sirayi_degistir_rpc()
	check(game.ilk_tur_bitti and game.aktif_oyuncu_aksiyon_hakki == 3, "Foundation advances to normal turns")
	game.aksiyon.normal_kart_cek_rpc(isim)
	check(game.deste.el.size() == 1, "Real card scene renders a drawn card")
	var sira_label = game.arayuz.get_node("%TurYazisi")
	check(not "·" in sira_label.text, "Solo practice shows no countdown")
	# The solo server clears any limit on its next frame, so check the display synchronously.
	game.sure_baslat_rpc("tur", 75.0)
	check(sira_label.text.ends_with("1:15") or sira_label.text.ends_with("1:14"), "HUD shows the server turn countdown")
	game.sure_baslat_rpc("zar", 9.0)
	check("⚔" in sira_label.text and (sira_label.text.ends_with("0:09") or sira_label.text.ends_with("0:08")), "HUD shows battle countdown")
	await process_frame
	await process_frame
	check(not "·" in sira_label.text, "Solo server clears a countdown that does not apply")
	await capture("game")
	var civ_style = game.arayuz.medeniyet_gorunumu
	var identity_before = game.medeniyetler_verisi.duplicate(true)
	var decorations_before = game.find_children("CivilizationOrnament", "Control", true, false).size()
	var crests = []
	var combat_icon = game.get_node("%SavasDesteBtn").icon
	var build_icon = game.get_node("%InsaDesteBtn").icon
	check(combat_icon.resource_path.ends_with("combat.svg") and build_icon.resource_path.ends_with("build.svg"), "Deck tabs have fixed combat and construction icons")

	var late_card = load("res://KartUI.tscn").instantiate()
	game.get_node("%InsaKartEliKonteyner").add_child(late_card)
	check(late_card.theme == civ_style.skin_for(game.medeniyetler_verisi[isim]).theme, "New card command buttons inherit the current civilization skin")
	late_card.free()

	for civ in ["Osmanlı", "Venedik", "Bizans", "Mısır", "Moğol", "Viking"]:
		civ_style.apply_to(game, civ)
		var emblem = game.get_node("%TurButonu").icon
		check(emblem != null and not emblem in crests, "Distinct end-turn crest for " + civ)
		crests.append(emblem)
		check(game.get_node("%SavasDesteBtn").icon == combat_icon and game.get_node("%InsaDesteBtn").icon == build_icon, "Deck icons stay fixed when civilization changes: " + civ)

		var card_area = game.get_node("%AltOrtaPanel/CivilizationOrnament")
		check(card_area.emblem == emblem and card_area.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Card-area ornament matches civilization and passes input: " + civ)
		check(card_area.get_motif_rect().get_center().is_equal_approx(card_area.size / 2.0), "Panel watermark is centered: " + civ)
		var command_skin = game.get_node("%TurButonu").get_theme_stylebox("normal")
		check(command_skin is StyleBoxTexture and command_skin.texture_margin_left == 20, "Civilization buttons keep fixed corners: " + civ)
		await capture("civ-" + str(civ_style.CIVS[civ].id))
	check(game.medeniyetler_verisi == identity_before, "Civilization skin preview never changes player identity or rules")
	check(game.find_children("CivilizationOrnament", "Control", true, false).size() == decorations_before, "Changing skins does not duplicate ornaments")
	civ_style.apply_to(game, game.medeniyetler_verisi[isim])

	var hud_settings = game.get_node("%OyunMenuBtn")
	check(hud_settings.get_parent().get_global_rect().grow(-10).encloses(hud_settings.get_global_rect()), "Menu button stays inside its transparent HUD layout area")
	check(hud_settings.get_parent() is Control and not hud_settings.get_parent() is NinePatchRect, "Menu button has no surrounding frame/background")
	hud_settings.pressed.emit()
	check(game.oyun_menusu.perde.visible and game.oyun_menusu.satirlar.get_child(0).text == tr("HÜKÜM"), "HUD button opens the menu with settings inside")
	await capture("hud-menu")
	game.oyun_menusu.perde.hide()

	# Visual fixture: inspect both painted building sprites at game scale.
	for pair in [[Vector2i(6, 4), "ticaret_merkezi"], [Vector2i(4, 4), "oncu_kampi"]]:
		game.binalar_verisi[pair[0]] = {"tur": pair[1], "sahip": isim, "seviye": 1}
		game.kontrol_edilen_hexler[pair[0]] = isim
		game.harita.kesfedilen_hexler[pair[0]] = "cim"
	var camp_texture = game.harita.ONCU_KAMPI_RESIM
	check(camp_texture.resource_path.ends_with("binalar/oncukampi.png"), "Map camp uses the painted PNG building sprite")
	check(camp_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Map camp sprite retains transparency")
	camp_texture = null
	game.harita.gorus_haritasini_guncelle()
	game.harita.queue_redraw()
	game.arayuz.sag_paneli_guncelle(Vector2i(6, 4))
	await capture("market")
	for portrait_name in ["SaldiranResim", "SavunanResim", "AtakResim", "DefansResim"]:
		var portrait = game.get_node("%" + portrait_name)
		portrait.texture = load("res://Assets/Resimler/Profil3.png")
		check(portrait.material is ShaderMaterial and portrait.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "Battle portrait stays clipped without inflating the window: " + portrait_name)
	for panel_name in ["SavasOnayPaneli", "SonSavasPaneli"]:
		var panel = game.get_node("%" + panel_name)
		panel.show()
		await capture(panel_name)
		for portrait in panel.find_children("*", "TextureRect", true, false):
			if portrait.has_node("PortraitBorder"):
				check(panel.get_global_rect().encloses(portrait.get_global_rect()), "Battle portrait fits window: " + str(portrait.name))
		panel.hide()
	for panel_name in ["TicaretPaneli", "TakasPaneli", "IsyanOnayPaneli", "BinaSaldiriPaneli"]:
		var modal = game.get_node("%" + panel_name)
		modal.show()
		await process_frame
		await process_frame
		for command in modal.find_children("*", "Button", true, false):
			check(modal.get_global_rect().grow(-12).encloses(command.get_global_rect()), "Command fits " + panel_name + ": " + str(command.name))
		await capture(panel_name)
		modal.hide()

	game.oyun_menusu.yardimi_ac()
	await capture("help")
	game.oyun_menusu.ayarlari_ac()
	await capture("settings")
	game.oyun_menusu.perde.hide()
	game.savas_puanlari[isim] = 25
	game.arayuz.arayuzu_guncelle()
	check(game.oyun_bitti and game.oyun_menusu.sonuc_acik and not paused, "Real victory overlay remains interactive")
	await capture("result")
	game.oyun_menusu.ana_menuye_don()
	await create_timer(1.0).timeout
	check(current_scene.has_method("_cok_oyunculu_menu_ac") and network.son_lobi_verisi.is_empty(), "Result returns to clean main menu")
	current_scene.get_node("%TekOyuncuBtn").pressed.emit()
	check(current_scene.oyun_menusu.perde.visible, "Practice button explains offline mode")
	current_scene._alistirma_baslat()
	await create_timer(1.2).timeout
	check(current_scene.has_method("puan_hesapla") and root.multiplayer.multiplayer_peer is OfflineMultiplayerPeer, "Practice starts without a network port")
	check(current_scene.oyuncular.size() == 1 and current_scene.get_node_or_null("YapayZeka") == null, "Opponent-free practice has no AI")
	current_scene.oyun_menusu.ana_menuye_don()
	await create_timer(1.0).timeout
	await run_tutorial()
	await run_save_load()
	await run_ai_match()
	print("HUKUM RUNTIME SMOKE: %d failures" % failures)
	quit(1 if failures else 0)

# Solo match against three AI rulers: they found cities, play the rules and
# never stall the turn order, including battles against the human.
func run_ai_match():
	current_scene._alistirma_baslat(3)
	await create_timer(1.2).timeout
	var game = current_scene
	var yz = game.get_node_or_null("YapayZeka")
	check(yz != null and game.oyuncular.size() == 4 and game.yapay_zeka_oyunculari.size() == 3, "Solo match seats three AI rulers")
	check(game.benim_indexim == 0 and game.aktif_sira == 0, "Human plays first")
	check(game.kalan_sure_saniye() == -1, "Solo match has no turn timer")
	if yz == null: return
	yz.hamle_araligi = 0.0
	var ben = game.oyuncular[0]
	game.istek("aksiyon", "bina_kur_rpc", [Vector2i(2, 2), ben, "sehir_merkezi", "cim"])
	var savas_sayisi = 0
	var son_tur = game.tur_sayaci
	for adim in range(6000):
		if game.oyun_bitti: break
		if game.savas.savas_aktif:
			var taraflar = game.savas.savas_taraflari()
			if ben in taraflar:
				if game.savas.son_kartlar_dict.is_empty() and not game.savas.secilen_savas_kartlari.has(ben):
					game.istek("aksiyon", "savas_hamlesi_yap_rpc", [ben, [], []])
					savas_sayisi += 1
				elif not game.savas.son_kartlar_dict.is_empty():
					var saldiran = taraflar[0] == ben
					if (game.savas.zar_saldiran_deger if saldiran else game.savas.zar_savunan_deger) == -1:
						game.istek("savas", "zar_at_istegi_rpc", [saldiran])
		elif game.aktif_sira == 0 and not game.savas.sonuc_gosteriliyor:
			if game.tur_sayaci >= 16: break
			game.istek("tur_ekonomi", "sirayi_degistir_rpc", [])
		await process_frame
	check(game.tur_sayaci >= 16 or game.oyun_bitti, "AI turns never stall the match (reached round %d)" % game.tur_sayaci)
	var gelisme = 0
	for bot in game.yapay_zeka_oyunculari:
		check(game.sehir_merkezleri[bot], "AI founded a city: " + bot)
		var toprak = 0
		for sahip in game.kontrol_edilen_hexler.values():
			if sahip == bot: toprak += 1
		var bina = 0
		for b in game.binalar_verisi.values():
			if b["sahip"] == bot and b["tur"] != "sehir_merkezi": bina += 1
		if toprak > 1 or bina > 0: gelisme += 1
	check(gelisme >= 2, "AI rulers expand or build over sixteen rounds")
	var gizli_dogru = true
	for bot in game.yapay_zeka_oyunculari:
		for kart in game.oyuncu_elleri[bot]:
			if kart.get("gizli", false): gizli_dogru = false
	check(gizli_dogru, "Server keeps real AI hands")
	print("AI match: round %d, battles with human %d, scores %s" % [game.tur_sayaci, savas_sayisi, str(game.puanlar)])
	if not game.oyun_bitti: await run_ai_trade(game, ben)
	if not game.oyun_bitti: await run_ai_battle(game, ben)
	game.oyun_menusu.ana_menuye_don()
	await create_timer(1.0).timeout

# An AI with an army attacks an adjacent human pioneer and the battle resolves.
func run_ai_battle(game, ben: String):
	var bot = game.yapay_zeka_oyunculari[0]
	var bot_idx = game.oyuncular.find(bot)
	var saldiran = -1
	var hedef = Vector2i(-1, -1)
	for i in range(game.piyonlar.size()):
		if game.piyonlar[i]["sahip"] != bot: continue
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var k = game.piyonlar[i]["koordinat"] + Vector2i(dx, dy)
				if not game.hex_gecerli_mi(k) or not game.harita.hex_komsu_mu(game.piyonlar[i]["koordinat"], k): continue
				if game.binalar_verisi.has(k) or game.kontrol_edilen_hexler.get(k, "") == bot: continue
				var bos = true
				for p in game.piyonlar:
					if p["koordinat"] == k: bos = false
				if bos and hedef == Vector2i(-1, -1):
					saldiran = i
					hedef = k
	check(hedef != Vector2i(-1, -1), "Found a hex next to an AI pioneer")
	if hedef == Vector2i(-1, -1): return
	game.piyonlar.append({"sahip": ben, "koordinat": hedef})
	game.harita.kesfedilen_hexler[hedef] = "cim"
	var asker = {"tur": "piyade", "kategori": "⚔️ PİYADE", "isim": "Piyade", "hedef": "savas", "guc": 1, "tanim": "Standart piyade birliği.", "bonus": ""}
	var tarla = {"tur": "tarla", "isim": "Tarla", "hedef": "harita", "odun_maliyet": 6, "tas_maliyet": 0}
	game.oyuncu_elleri[bot] = [asker.duplicate(true), asker.duplicate(true), asker.duplicate(true), tarla.duplicate(true), tarla.duplicate(true)]
	game.oyuncu_kaynaklari[bot]["yiyecek"] = 1
	game.oyuncu_kaynaklari[bot]["odun"] = 0
	var puan_once = game.savas_puanlari[bot]
	game.aktif_sira = bot_idx
	game.aktif_oyuncu_aksiyon_hakki = 3
	var basladi = false
	for adim in range(600):
		if game.savas.savas_aktif:
			basladi = true
			if game.savas.son_kartlar_dict.is_empty() and not game.savas.secilen_savas_kartlari.has(ben):
				game.istek("aksiyon", "savas_hamlesi_yap_rpc", [ben, [], []])
			elif not game.savas.son_kartlar_dict.is_empty() and game.savas.zar_savunan_deger == -1:
				game.istek("savas", "zar_at_istegi_rpc", [false])
		elif basladi and not game.savas.sonuc_gosteriliyor:
			break
		await process_frame
	check(basladi, "AI attacks an adjacent enemy pioneer when it has an army")
	check(game.savas_puanlari[bot] != puan_once and not game.savas.savas_aktif, "AI battle resolves with locked cards and server dice")

# The first-match guide advances only when the player performs each real action.
func run_tutorial():
	current_scene._ogretici_baslat()
	await create_timer(1.2).timeout
	var game = current_scene
	var rehber = game.get_node_or_null("Ogretici")
	check(rehber != null and rehber.adim == 0, "Tutorial opens on the first step")
	if rehber == null: return
	var panel = rehber.panel
	check(game.get_viewport().get_visible_rect().encloses(panel.get_global_rect()), "Tutorial panel stays on screen")
	var ben = game.oyuncular[0]
	await process_frame
	check(rehber.adim == 0, "Tutorial waits for the player")
	var ses = root.get_node("SesYoneticisi")
	check(ses._aktif_muzik == "oyun", "Match plays the game music")
	game.istek("aksiyon", "bina_kur_rpc", [Vector2i(5, 5), ben, "sehir_merkezi", "cim"])
	await process_frame
	check(rehber.adim == 1, "Founding the city advances the tutorial")
	check(ses.son_efekt == "insa", "Founding plays the construction sound")
	game.istek("tur_ekonomi", "sirayi_degistir_rpc", [])
	await process_frame
	check(rehber.adim == 2, "Ending the turn advances the tutorial")
	game.istek("aksiyon", "normal_kart_cek_rpc", [ben])
	await process_frame
	check(rehber.adim == 3, "Drawing a card advances the tutorial")
	var komsu = Vector2i(6, 5)
	game.istek("aksiyon", "kesif_ve_hareket_rpc", [0, komsu, ben])
	await process_frame
	check(rehber.adim == 4, "Exploring advances the tutorial")
	check(ses.son_efekt == "kesif", "Exploring plays the exploration sound")
	game.istek("aksiyon", "hakimiyet_kur_rpc", [ben, komsu])
	await process_frame
	check(rehber.adim == 5, "Claiming land advances the tutorial")
	rehber.gec_btn.pressed.emit()
	await process_frame
	check(rehber.adim == 6, "A step can be skipped")
	game.istek("tur_ekonomi", "sirayi_degistir_rpc", [])
	await process_frame
	check(rehber.adim == 7, "Collecting production advances the tutorial")
	game.istek("aksiyon", "savas_karti_cek_rpc", [ben])
	await process_frame
	check(rehber.adim == 8, "Drawing a war card advances the tutorial")
	check(ses.son_efekt == "kart_cek", "Drawing plays the card sound")
	game.oyun_menusu.ayarlari_ac()
	var muzik = game.oyun_menusu.satirlar.get_node_or_null("muzik_seviyesi")
	var efekt = game.oyun_menusu.satirlar.get_node_or_null("efekt_seviyesi")
	check(muzik != null and efekt != null, "Settings offer music and effect volume")
	if muzik:
		var global = root.get_node("Global")
		var eski = global.muzik_seviyesi
		muzik.value = 20
		check(is_equal_approx(global.muzik_seviyesi, 0.2) and AudioServer.get_bus_index("Muzik") != -1 and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Muzik")), linear_to_db(0.2)), "Music slider sets the music bus")
		muzik.value = eski * 100.0
	game.oyun_menusu.perde.hide()
	await capture("tutorial")
	rehber.gec_btn.pressed.emit()
	await process_frame
	await process_frame
	check(not is_instance_valid(rehber), "Finishing closes the tutorial")
	game.oyun_menusu.ana_menuye_don()
	await create_timer(1.0).timeout
	check(ses._aktif_muzik == "menu", "Main menu switches back to menu music")
	current_scene._alistirma_baslat(0)
	await create_timer(1.2).timeout
	check(current_scene.get_node_or_null("Ogretici") == null, "Plain practice opens without the tutorial")
	current_scene.oyun_menusu.ana_menuye_don()
	await create_timer(1.0).timeout

# Trade dialog and resource trades with an AI ruler; chat is hidden with one human.
func run_ai_trade(game, ben: String):
	check(not game.get_node("%MacSohbetGirdisi").visible, "Chat input is hidden in single-player")
	var bot = game.yapay_zeka_oyunculari[0]
	game.aktif_sira = 0
	game.aktif_oyuncu_aksiyon_hakki = 3
	game.oyuncu_kaynaklari[ben]["odun"] = 10
	game.oyuncu_kaynaklari[bot]["tas"] = 10
	game.iletisim.takas_penceresi_ac()
	var menu = game.oyun_menusu
	check(menu.perde.visible and menu.satirlar.get_node_or_null("TakasHedef") != null and menu.satirlar.get_node_or_null("TakasVer") != null, "Trade dialog lists rulers and resources")
	await capture("trade-dialog")
	menu.perde.hide()
	var once = game.oyuncu_kaynaklari.duplicate(true)
	game.iletisim.takas_teklif_et(bot, "odun", 3, "tas", 2)
	await process_frame
	check(game.oyuncu_kaynaklari[ben]["odun"] == once[ben]["odun"] - 3 and game.oyuncu_kaynaklari[ben]["tas"] == once[ben]["tas"] + 2 and game.oyuncu_kaynaklari[bot]["tas"] == once[bot]["tas"] - 2, "AI accepts a fair trade")
	once = game.oyuncu_kaynaklari.duplicate(true)
	game.iletisim.takas_teklif_et(bot, "odun", 1, "tas", 5)
	await process_frame
	check(game.oyuncu_kaynaklari == once, "AI rejects an unfair trade")
	game.iletisim.takas_teklif_et(bot, "odun", 99, "tas", 1)
	await process_frame
	check(game.oyuncu_kaynaklari == once, "Trade beyond own resources is rejected")

# Single-player autosaves at the start of the human turn and resumes exactly.
func run_save_load():
	MacKaydi.sil()
	current_scene._alistirma_baslat(1)
	await create_timer(1.2).timeout
	var game = current_scene
	game.get_node("YapayZeka").hamle_araligi = 0.0
	var ben = game.oyuncular[0]
	check(not game.kaydedilebilir_mi(), "No save before the city is founded")
	game.istek("aksiyon", "bina_kur_rpc", [Vector2i(3, 3), ben, "sehir_merkezi", "cim"])
	game.istek("tur_ekonomi", "sirayi_degistir_rpc", [])
	for i in range(300):
		if game.aktif_sira == 0 and game.ilk_tur_bitti: break
		await process_frame
	await process_frame
	check(MacKaydi.var_mi(), "Human turn start autosaves the match")
	game.istek("aksiyon", "normal_kart_cek_rpc", [ben])
	game.istek("aksiyon", "kesif_ve_hareket_rpc", [0, Vector2i(4, 3), ben])
	game.oyun_menusu.menuyu_ac()
	var kaydet_btn = null
	for b in game.oyun_menusu.satirlar.get_children():
		if b is Button and b.text == tr("Maçı kaydet"): kaydet_btn = b
	check(kaydet_btn != null and not kaydet_btn.disabled, "In-game menu offers saving in single-player")
	if kaydet_btn: kaydet_btn.pressed.emit()
	game.oyun_menusu.perde.hide()
	var beklenen = game.kayit_verisi()
	game.oyun_menusu.ana_menuye_don()
	await create_timer(1.0).timeout
	current_scene._alistirma_ac()
	var devam = null
	for b in current_scene.oyun_menusu.satirlar.get_children():
		if b is Button and b.text.begins_with(tr("Kayıtlı maça devam et · ")): devam = b
	check(devam != null and tr("%d rakip") % 1 in devam.text, "Single-player menu offers the saved match")
	if devam == null: return
	devam.pressed.emit()
	await create_timer(1.2).timeout
	game = current_scene
	var yuklenen = game.kayit_verisi()
	for anahtar in beklenen:
		check(yuklenen.get(anahtar) == beklenen[anahtar], "Loaded match restores " + anahtar)
	check(game.deste.el == beklenen["eller"][ben] and game.yapay_zeka_oyunculari.size() == 1 and game.get_node_or_null("YapayZeka") != null, "Loaded match restores own hand and the AI ruler")
	check(game.harita.kesfedilen_hexler.has(Vector2i(4, 3)), "Loaded map shows explored land")
	game.savas_puanlari[ben] = 25
	game.arayuz.arayuzu_guncelle()
	check(game.oyun_bitti and not MacKaydi.var_mi(), "A finished match deletes its save")
	game.oyun_menusu.ana_menuye_don()
	await create_timer(1.0).timeout
