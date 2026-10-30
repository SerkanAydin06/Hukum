extends SceneTree

# Yapay zekâ maç simülasyonu: bütün koltukları yapay zekâ oynar.
# Kullanım:
#   godot --headless --path . --script tests/ai_sim.gd -- MAC_SAYISI ZORLUK1,ZORLUK2,... [EN_COK_TUR]
# Örnek: -- 20 orta,orta,orta,orta 80
# Çıktı her maç için bir "HUKUM_SIM {...}" JSON satırıdır.

func _initialize():
	var args = OS.get_cmdline_user_args()
	var mac_sayisi = int(args[0]) if args.size() > 0 else 5
	var zorluklar = (args[1] if args.size() > 1 else "orta,orta,orta,orta").split(",")
	var en_cok_tur = int(args[2]) if args.size() > 2 else 80
	await process_frame
	Engine.time_scale = 40.0   # savaş sonucu bekleme süreleri kısalır
	TranslationServer.set_locale("tr")
	for mac in range(mac_sayisi):
		await _mac_oyna(mac, zorluklar, en_cok_tur)
	quit()

func _mac_oyna(no: int, zorluklar: PackedStringArray, en_cok_tur: int):
	var network = root.get_node("Network")
	network.baglantiyi_kapat()
	get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()
	network.oyun_tohumu = randi()
	network.alistirma_rakip_sayisi = zorluklar.size() - 1
	network.alistirma_zorluklari = Array(zorluklar).slice(1)
	change_scene_to_file("res://AnaOyun.tscn")
	await create_timer(0.5).timeout
	var game = current_scene
	# İnsan koltuğunu da yapay zekâya ver.
	var insan = game.oyuncular[0]
	game.yapay_zeka_oyunculari.append(insan)
	game.yapay_zeka_zorluk[insan] = zorluklar[0]
	var yz = game.get_node("YapayZeka")
	yz.hamle_araligi = 0.0
	var savas = 0
	var savas_acik = false
	var kare = 0
	while not game.oyun_bitti and game.tur_sayaci <= en_cok_tur:
		if game.savas.savas_aktif and not savas_acik: savas += 1
		savas_acik = game.savas.savas_aktif
		kare += 1
		if OS.get_environment("HUKUM_SIM_IZ") != "" and kare % 500 == 0:
			print("IZ tur=%d sira=%d ap=%d savas=%s kartlar=%d secilen=%s zar=%d/%d sonuc=%s altin=%s" % [game.tur_sayaci, game.aktif_sira, game.aktif_oyuncu_aksiyon_hakki, game.savas.savas_aktif, game.savas.son_kartlar_dict.size(), str(game.savas.secilen_savas_kartlari.keys()), game.savas.zar_saldiran_deger, game.savas.zar_savunan_deger, game.savas.sonuc_gosteriliyor, str(game.oyuncu_kaynaklari.values().map(func(k): return k["altin"]))])
		await process_frame
	game.puanlari_guncelle()
	var sonuc = {"mac": no, "tur": game.tur_sayaci, "bitti": game.oyun_bitti, "savas": savas, "oyuncular": []}
	for isim in game.oyuncular:
		var toprak = game.kontrol_edilen_hexler.values().count(isim)
		var bina = 0
		for b in game.binalar_verisi.values():
			if b["sahip"] == isim and b["tur"] != "sehir_merkezi": bina += b.get("seviye", 1)
		sonuc["oyuncular"].append({"medeniyet": game.medeniyetler_verisi[isim], "zorluk": game.yapay_zeka_zorluk.get(isim, "orta"),
			"puan": game.puanlar[isim], "toprak": toprak, "bina_seviyesi": bina, "savas_puani": game.savas_puanlari.get(isim, 0)})
	print("HUKUM_SIM " + JSON.stringify(sonuc))
	change_scene_to_file("res://AnaMenu.tscn")
	await create_timer(0.3).timeout
