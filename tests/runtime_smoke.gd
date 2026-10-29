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
	check(not menu.baglan_btn.disabled and "Geçersiz" in menu.baglanti_durumu.text, "Private-server URL errors are retryable")
	await capture("private")
	menu._ana_menuye_don()
	menu._profil_duzenle_ac()
	menu.isim_giris_kutusu.text = "[bad]"
	menu.isim_giris_kutusu.text_changed.emit("[bad]")
	check(menu.kaydet_btn.disabled, "Invalid profile name cannot be saved")
	menu.isim_giris_kutusu.text = global.oyuncu_ismi
	menu.isim_giris_kutusu.text_changed.emit(global.oyuncu_ismi)
	await capture("profile")
	menu._profil_duzenle_kapat()
	menu._cok_oyunculu_menu_ac()
	menu.ip_giris.text = "invalid"
	menu._on_baglan_btn_pressed()
	check(not menu.baglan_btn.disabled and "Geçersiz" in menu.baglanti_durumu.text, "Invalid IP is visible and retryable")
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
	await capture("game")
	var hud_settings = game.get_node("%OyunAyarlarBtn")
	check(hud_settings.get_parent().get_global_rect().grow(-10).encloses(hud_settings.get_global_rect()), "Settings button stays inside its HUD frame")
	hud_settings.pressed.emit()
	check(game.oyun_menusu.perde.visible and game.oyun_menusu.satirlar.get_child(0).text == "AYARLAR", "HUD settings opens settings directly")
	await capture("hud-settings")
	game.oyun_menusu.perde.hide()

	# Visual fixture: inspect the new trading sprite and existing camp SVG at game scale.
	for pair in [[Vector2i(6, 4), "ticaret_merkezi"], [Vector2i(4, 4), "oncu_kampi"]]:
		game.binalar_verisi[pair[0]] = {"tur": pair[1], "sahip": isim, "seviye": 1}
		game.kontrol_edilen_hexler[pair[0]] = isim
		game.harita.kesfedilen_hexler[pair[0]] = "cim"
	game.harita.gorus_haritasini_guncelle()
	game.harita.queue_redraw()
	game.arayuz.sag_paneli_guncelle(Vector2i(6, 4))
	await capture("market")
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
	current_scene.oyun_menusu.ana_menuye_don()
	await create_timer(1.0).timeout
	print("HUKUM RUNTIME SMOKE: %d failures" % failures)
	quit(1 if failures else 0)
