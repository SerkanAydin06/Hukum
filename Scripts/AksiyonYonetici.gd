extends Node
class_name AksiyonYonetici

@onready var ana = get_parent() as AnaOyun

var sag_tik_baslangic = Vector2.ZERO

# --- ALT MODÜLLER ---
var insa_modul: AksiyonInsa
var savas_tetik_modul: AksiyonSavasTetik
var kart_modul: AksiyonKart

func _ready():
	insa_modul = AksiyonInsa.new()
	add_child(insa_modul)
	insa_modul.baslat(self)
	
	savas_tetik_modul = AksiyonSavasTetik.new()
	add_child(savas_tetik_modul)
	savas_tetik_modul.baslat(self)
	
	kart_modul = AksiyonKart.new()
	add_child(kart_modul)
	kart_modul.baslat(self)

func _unhandled_input(event):
	if ana.oyun_bitti: return
	if event is InputEventMouseButton:
		# 🟢 YENİ VE GÜVENLİ PANEL KONTROLLERİ
		var k_panel_1 = ana.arayuz.get_node_or_null("%KurulumOnayPanel")
		var k_panel_2 = ana.arayuz.get_node_or_null("%KurulumOnayPaneli")
		var son_savas = ana.arayuz.get_node_or_null("%SonSavasPaneli")
		var savas_onay = ana.arayuz.get_node_or_null("%SavasOnayPaneli")
		var bina_saldiri = ana.arayuz.get_node_or_null("%BinaSaldiriPaneli")
		var isyan_onay = ana.arayuz.get_node_or_null("%IsyanOnayPaneli")
		
		if (k_panel_1 and k_panel_1.visible) or (k_panel_2 and k_panel_2.visible) or \
		   (son_savas and son_savas.visible) or \
		   (savas_onay and savas_onay.visible) or \
		   (bina_saldiri and bina_saldiri.visible) or \
		   (isyan_onay and isyan_onay.visible) or \
		   ana.savas.savas_aktif: 
			return
		
		var k = ana.harita.tiklanan_hexi_bul(ana.get_global_mouse_position())
		if ana.oyuncular.size() == 0: return
		var k_isim = ana.oyuncular[ana.benim_indexim]
		
		# --- SAĞ TIKLAMA ---
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				sag_tik_baslangic = event.global_position
			else:
				var kaydirma_mesafesi = event.global_position.distance_to(sag_tik_baslangic)
				if kaydirma_mesafesi < 10.0:
					if ana.arayuz.hakimiyet_paneli and ana.arayuz.hakimiyet_paneli.visible:
						ana.arayuz.hakimiyet_paneli.visible = false
						ana.arayuz.arayuzu_guncelle()
						ana.harita.queue_redraw()
						return
					
					if ana.secili_kart_index != -1 or ana.kart_insa_modu_aktif:
						ana.secili_kart_index = -1
						ana.kart_insa_modu_aktif = false
						ana.kurulabilir_hexler.clear()
						ana.deste._kart_gorsellerini_guncelle()
						ana.arayuz.arayuzu_guncelle()
						ana.harita.queue_redraw()
						return

					if ana.insa_modu_aktif and not ana.sehir_merkezleri.get(k_isim, false):
						ana.insa_modu_aktif = false
						ana.secilen_baslangic_biyomu = ""
						if ana.arayuz.cim_btn: ana.arayuz.cim_btn.set_pressed_no_signal(false)
						if ana.arayuz.orman_btn: ana.arayuz.orman_btn.set_pressed_no_signal(false)
						if ana.arayuz.dag_btn: ana.arayuz.dag_btn.set_pressed_no_signal(false)
						ana.arayuz.olay_yaz("[color=gray]Şehir kurma işlemi iptal edildi. Yeni bir biyom seçebilirsiniz.[/color]")
						ana.arayuz.arayuzu_guncelle()
						ana.harita.queue_redraw()
						return
						
					if ana.aktif_sira == ana.benim_indexim and ana.aktif_oyuncu_aksiyon_hakki > 0 and ana.secili_piyon_index != -1 and k != Vector2i(-1,-1):
						var p_koor = ana.piyonlar[ana.secili_piyon_index]["koordinat"]
						if k == p_koor:
							var k_isim_ben = ana.oyuncular[ana.benim_indexim]
							var hex_sahibi = ana.kontrol_edilen_hexler.get(p_koor, "")
							if hex_sahibi != k_isim_ben and not ana.muttefik_mi(k_isim_ben, hex_sahibi) and ana.hex_dosta_komsu_mu(p_koor, k_isim_ben):
								if ana.arayuz.hakimiyet_paneli:
									ana.arayuz.hakimiyet_paneli.visible = true
									var biyom = ana.harita.kesfedilen_hexler.get(p_koor, "")
									var biyom_isim = "Çimenlik Arazi" if biyom == "cim" else "Ormanlık Arazi" if biyom == "orman" else "Dağlık Arazi" if biyom == "dag" else biyom
									var arazi_label = ana.arayuz.get_node_or_null("%AraziTurLabel")
									if arazi_label: arazi_label.text = biyom_isim
									ana.arayuz.arayuzu_guncelle()
									ana.harita.queue_redraw()
									return
						else:
							savas_tetik_modul._piyon_hareket_aksiyon(k, k_isim)
		
		# --- SOL TIKLAMA ---
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if k == Vector2i(-1, -1): return
			ana.arayuz.sag_paneli_guncelle(k)
			
			if ana.kart_insa_modu_aktif:
				if k in ana.kurulabilir_hexler:
					var kart = ana.deste.el[ana.secili_kart_index]
					if ana.oyuncu_kaynaklari[k_isim]["odun"] >= kart["odun_maliyet"] and ana.oyuncu_kaynaklari[k_isim]["tas"] >= kart["tas_maliyet"]:
						
						if kart["hedef"] == "kendi_binasi": 
							ana.istek("aksiyon", "bina_yukselt_rpc", [k_isim, k, kart["odun_maliyet"], kart["tas_maliyet"], ana.secili_kart_index])
						else: 
							ana.istek("aksiyon", "kart_oyna_rpc", [k_isim, kart["tur"], k, kart["odun_maliyet"], kart["tas_maliyet"], ana.secili_kart_index])
						
						ana.secili_kart_index = -1
						ana.kart_insa_modu_aktif = false
						ana.deste._kart_gorsellerini_guncelle()
						ana.arayuz.arayuzu_guncelle()
					else:
						ana.arayuz.olay_yaz("[color=light_coral]❌ Yetersiz Kaynak! Gerekli: %d 🌲, %d 🪨[/color]" % [kart["odun_maliyet"], kart["tas_maliyet"]])
				else:
					ana.arayuz.olay_yaz("[color=light_coral]❌ Geçersiz Alan! Sadece yanıp sönen topraklara kurabilirsin.[/color]")
				ana.arayuz.arayuzu_guncelle()
				ana.harita.queue_redraw()
				return
			
			if ana.insa_modu_aktif and not ana.sehir_merkezleri.get(k_isim, false):
				if ana.binalar_verisi.has(k):
					ana.arayuz.olay_yaz("[color=light_coral]❌ Burada zaten bir yapı var![/color]")
				else:
					if ana.oyuncu_kaynaklari[k_isim]["odun"] >= 10 and ana.oyuncu_kaynaklari[k_isim]["tas"] >= 10:
						ana.bekleyen_onay = "sehir"
						ana.gecici_koordinat = k
						
						var onay_hex = ana.arayuz.get_node_or_null("%OnayHexi")
						if onay_hex and onay_hex is TextureRect:
							var secilen_biyom = ana.secilen_baslangic_biyomu
							var yol = ana.arayuz.biyom_resimleri.get(secilen_biyom, "")
							if yol != "" and ResourceLoader.exists(yol): onay_hex.texture = load(yol)
							else: onay_hex.texture = null
						
						var kurulum_panel = ana.arayuz.get_node_or_null("%KurulumOnayPanel")
						if not kurulum_panel: kurulum_panel = ana.arayuz.get_node_or_null("%KurulumOnayPaneli")
						if kurulum_panel:
							kurulum_panel.visible = true
							if kurulum_panel.has_method("show"): kurulum_panel.show()
					else:
						ana.arayuz.olay_yaz("[color=light_coral]❌ Şehir Merkezi için 10 Odun ve 10 Taş gerekli![/color]")
						ana.insa_modu_aktif = false
						ana.arayuz.arayuzu_guncelle()
				return

			var p_idx = -1
			var ayni_karedeki_tum_piyonlar = []
			var ayni_karedeki_benim_piyonlarim = []

			for i in range(ana.piyonlar.size()):
				if ana.piyonlar[i]["koordinat"] == k:
					ayni_karedeki_tum_piyonlar.append(i)
					if ana.piyonlar[i]["sahip"] == k_isim:
						ayni_karedeki_benim_piyonlarim.append(i)

			if ayni_karedeki_benim_piyonlarim.size() == 1:
				p_idx = ayni_karedeki_benim_piyonlarim[0]
			elif ayni_karedeki_benim_piyonlarim.size() > 1:
				var f_pos = ana.get_global_mouse_position()
				var m = ana.harita.hex_merkezi_hesapla(k.x, k.y)
				var c = ayni_karedeki_tum_piyonlar.size()
				var min_d = 9999.0
				for j in range(c):
					var t_idx = ayni_karedeki_tum_piyonlar[j]
					if ana.piyonlar[t_idx]["sahip"] == k_isim:
						var p_pos = m
						if c == 2:
							if j == 0: p_pos += Vector2(-12, 0)
							if j == 1: p_pos += Vector2(12, 0)
						elif c == 3:
							if j == 0: p_pos += Vector2(0, -15)
							if j == 1: p_pos += Vector2(-15, 12)
							if j == 2: p_pos += Vector2(15, 12)
						elif c >= 4:
							if j == 0: p_pos += Vector2(-15, -15)
							if j == 1: p_pos += Vector2(15, -15)
							if j == 2: p_pos += Vector2(-15, 15)
							if j == 3: p_pos += Vector2(15, 15)
						var d = f_pos.distance_to(p_pos)
						if d < min_d:
							min_d = d
							p_idx = t_idx
			
			if p_idx != -1:
				ana.secili_piyon_index = p_idx
				ana.secili_kart_index = -1
			else:
				if ana.secili_kart_index == -1: ana.secili_piyon_index = -1
					
			if ana.aktif_sira == ana.benim_indexim and ana.aktif_oyuncu_aksiyon_hakki > 0:
				if ana.secili_kart_index != -1: insa_modul._kart_ve_harita_etkilesimi(k, k_isim)
					
			ana.arayuz.arayuzu_guncelle()
			ana.harita.queue_redraw()

func _evet_basildi():
	if ana.bekleyen_onay == "savas":
		ana.istek("aksiyon", "savas_baslat_rpc", [ana.secili_piyon_index, ana.savas.savas_piyon_savunan, -1, -1])
	elif ana.bekleyen_onay == "sehir" and ana.gecici_koordinat != Vector2i(-1, -1):
		ana.istek("aksiyon", "bina_kur_rpc", [ana.gecici_koordinat, ana.oyuncular[ana.benim_indexim], "sehir_merkezi", ana.secilen_baslangic_biyomu])
		ana.insa_modu_aktif = false
	
	ana.bekleyen_onay = ""
	
	if ana.arayuz.has_node("%KurulumOnayPaneli"):
		var k_panel = ana.arayuz.get_node_or_null("%KurulumOnayPaneli")
		if k_panel: k_panel.visible = false
	elif ana.arayuz.has_node("%KurulumOnayPanel"):
		var k_panel = ana.arayuz.get_node_or_null("%KurulumOnayPanel")
		if k_panel: k_panel.visible = false
		
	ana.arayuz.arayuzu_guncelle()

func _hayir_basildi():
	if ana.arayuz.has_node("%KurulumOnayPaneli"):
		var k_panel = ana.arayuz.get_node_or_null("%KurulumOnayPaneli")
		if k_panel: k_panel.visible = false
	elif ana.arayuz.has_node("%KurulumOnayPanel"):
		var k_panel = ana.arayuz.get_node_or_null("%KurulumOnayPanel")
		if k_panel: k_panel.visible = false
		
	if ana.bekleyen_onay == "sehir": ana.insa_modu_aktif = false
	ana.bekleyen_onay = ""
	ana.gecici_koordinat = Vector2i(-1, -1)
	ana.arayuz.arayuzu_guncelle()

func kesif_ve_hareket_rpc(p_idx: int, yeni_koor: Vector2i, k_isim: String):
	if not ana.rpc_sirada_mi(k_isim) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	if not _hareket_gecerli(p_idx, yeni_koor, k_isim) or ana.harita.kesfedilen_hexler.has(yeni_koor): return
	var biyom = _kesif_biyomu(yeni_koor)
	if not biyom in ["cim", "orman", "dag"]: return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[k_isim]["yiyecek"] = max(0, ana.oyuncu_kaynaklari[k_isim]["yiyecek"] - 1)
	ana.harita.kesfedilen_hexler[yeni_koor] = biyom
	ana.piyonlar[p_idx]["koordinat"] = yeni_koor
	var tur_cevir = "ÇİM" if biyom == "cim" else "ORMAN" if biyom == "orman" else "DAĞ"
	ana.arayuz.olay_yaz("🧭 %s, bilinmeyen topraklara girerek [color=cyan]%s[/color] bölgesi keşfetti!" % [ana.arayuz.renkli_isim(k_isim), tur_cevir])
	ana.harita.gorus_haritasini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
	ana.islem_kabul = true

func bina_kur_rpc(koordinat: Vector2i, sahip_isim: String, bina_turu: String, baslangic_biyomu: String = ""):
	if not ana.rpc_sirada_mi(sahip_isim): return
	if bina_turu != "sehir_merkezi" or ana.sehir_merkezleri.get(sahip_isim, false): return
	if not ana.hex_gecerli_mi(koordinat) or ana.binalar_verisi.has(koordinat): return
	if ana.harita.kesfedilen_hexler.has(koordinat) or ana.kontrol_edilen_hexler.has(koordinat): return
	for piyon in ana.piyonlar:
		if piyon["koordinat"] == koordinat: return
	if not baslangic_biyomu in ["cim", "orman", "dag"]: return
	if ana.oyuncu_kaynaklari[sahip_isim]["odun"] < 10 or ana.oyuncu_kaynaklari[sahip_isim]["tas"] < 10: return
	if baslangic_biyomu != "": ana.harita.kesfedilen_hexler[koordinat] = baslangic_biyomu
	elif not ana.harita.kesfedilen_hexler.has(koordinat):
		var biyomlar = ["cim", "cim", "cim", "orman", "orman", "dag"]
		ana.harita.kesfedilen_hexler[koordinat] = biyomlar.pick_random()
	if bina_turu == "sehir_merkezi":
		ana.oyuncu_kaynaklari[sahip_isim]["odun"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["odun"] - 10)
		ana.oyuncu_kaynaklari[sahip_isim]["tas"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["tas"] - 10)
		ana.oyuncu_kaynaklari[sahip_isim]["koylu"] += 1
		ana.sehir_merkezleri[sahip_isim] = true
		ana.piyonlar.append({"koordinat": koordinat, "sahip": sahip_isim})
		ana.kontrol_edilen_hexler[koordinat] = sahip_isim
	ana.binalar_verisi[koordinat] = {"tur": bina_turu, "sahip": sahip_isim, "seviye": 1}
	ana.arayuz.olay_yaz("🏰 %s, (%d, %d) konumuna [color=aqua]%s[/color] inşa etti." % [ana.arayuz.renkli_isim(sahip_isim), koordinat.x, koordinat.y, bina_turu.to_upper().replace("_"," ")])
	ana.harita.gorus_haritasini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
	ana.islem_kabul = true

func bina_yukselt_rpc(sahip_isim: String, koordinat: Vector2i, mo: int, mt: int, kart_idx: int = -1):
	if not ana.rpc_sirada_mi(sahip_isim): return
	if ana.aktif_sira >= ana.oyuncular.size() or ana.oyuncular[ana.aktif_sira] != sahip_isim: return
	if ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	
	# 🟢 YENİ: Asıl güvenlik kontrolü — seviye 3'ü asla geçemez
	if not ana.binalar_verisi.has(koordinat): return
	var kart = _kart_getir(sahip_isim, kart_idx)
	var bina = ana.binalar_verisi[koordinat]
	if bina["sahip"] != sahip_isim or kart.get("hedef") != "kendi_binasi": return
	if kart.get("bina_turu") != "joker" and kart.get("bina_turu") != bina["tur"]: return
	if not _kart_maliyeti_gecerli(sahip_isim, kart, mo, mt): return
	if ana.binalar_verisi[koordinat].get("seviye", 1) >= 3:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Bu bina zaten maksimum (Seviye 3) seviyede![/color]")
		return
	
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[sahip_isim]["odun"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["odun"] - mo)
	ana.oyuncu_kaynaklari[sahip_isim]["tas"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["tas"] - mt)
	ana.binalar_verisi[koordinat]["seviye"] += 1
	_kart_tuket(sahip_isim, kart_idx)
	var yeni_lvl = ana.binalar_verisi[koordinat]["seviye"]
	var b_tur = ana.binalar_verisi[koordinat]["tur"].to_upper().replace("_"," ")
	ana.arayuz.olay_yaz("🔺 %s, (%d, %d) konumundaki %s yapısını [color=gold]Seviye %d[/color]'a yükseltti!" % [ana.arayuz.renkli_isim(sahip_isim), koordinat.x, koordinat.y, b_tur, yeni_lvl])
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
	ana.islem_kabul = true

func piyon_hareket_rpc(p_idx: int, yeni_koor: Vector2i):
	if not ana.rpc_sirada_mi() or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	var isim = ana.rpc_gonderen_ismi()
	if not _hareket_gecerli(p_idx, yeni_koor, isim) or not ana.harita.kesfedilen_hexler.has(yeni_koor): return
	if ana.kontrol_edilen_hexler.get(yeni_koor, isim) != isim: return
	if ana.binalar_verisi.has(yeni_koor) and ana.binalar_verisi[yeni_koor]["sahip"] != isim: return
	for p in ana.piyonlar:
		if p["koordinat"] == yeni_koor and p["sahip"] != isim: return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	var sahip = ana.piyonlar[p_idx]["sahip"]
	var eski_koor = ana.piyonlar[p_idx]["koordinat"]
	ana.oyuncu_kaynaklari[sahip]["yiyecek"] = max(0, ana.oyuncu_kaynaklari[sahip]["yiyecek"] - 1)
	ana.piyonlar[p_idx]["koordinat"] = yeni_koor
	ana.arayuz.olay_yaz("🧍 %s, Öncüsünü (%d, %d) ➔ (%d, %d) konumuna yürüttü." % [ana.arayuz.renkli_isim(sahip), eski_koor.x, eski_koor.y, yeni_koor.x, yeni_koor.y])
	ana.harita.gorus_haritasini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
	ana.islem_kabul = true

func kart_oyna_rpc(sahip_isim: String, kart_turu: String, koordinat: Vector2i, mo: int, mt: int, kart_idx: int = -1):
	if not ana.rpc_sirada_mi(sahip_isim): return
	if ana.aktif_sira >= ana.oyuncular.size() or ana.oyuncular[ana.aktif_sira] != sahip_isim: return
	if ana.aktif_oyuncu_aksiyon_hakki <= 0: return

	var kart = _kart_getir(sahip_isim, kart_idx)
	if kart.get("hedef") != "harita" or kart.get("tur") != kart_turu: return
	if not _kart_maliyeti_gecerli(sahip_isim, kart, mo, mt): return
	if not ana.hex_gecerli_mi(koordinat) or ana.kontrol_edilen_hexler.get(koordinat) != sahip_isim or ana.binalar_verisi.has(koordinat): return
	var biyom = ana.harita.kesfedilen_hexler.get(koordinat, "")
	var gereken = "orman" if kart_turu == "oduncu_kampi" else "dag" if kart_turu == "tas_ocagi" else "cim"
	if biyom != gereken: return

	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[sahip_isim]["odun"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["odun"] - mo)
	ana.oyuncu_kaynaklari[sahip_isim]["tas"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["tas"] - mt)
	ana.binalar_verisi[koordinat] = {"tur": kart_turu, "sahip": sahip_isim, "seviye": 1}
	_kart_tuket(sahip_isim, kart_idx)
	if kart_turu == "ev": ana.oyuncu_kaynaklari[sahip_isim]["max_nufus"] += 3
	ana.arayuz.olay_yaz("🏗️ %s, (%d, %d) konumuna [color=aqua]%s[/color] kurdu." % [ana.arayuz.renkli_isim(sahip_isim), koordinat.x, koordinat.y, kart_turu.to_upper().replace("_"," ")])
	ana.harita.gorus_haritasini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
	ana.islem_kabul = true

func hakimiyet_kur_rpc(oyuncu_ismi: String, koordinat: Vector2i):
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	if not ana.hex_gecerli_mi(koordinat) or ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] < 3: return
	var sahip = ana.kontrol_edilen_hexler.get(koordinat, "")
	if sahip == oyuncu_ismi or ana.muttefik_mi(oyuncu_ismi, sahip) or not ana.hex_dosta_komsu_mu(koordinat, oyuncu_ismi): return
	var kendi_oncusu = false
	for p in ana.piyonlar:
		if p["koordinat"] == koordinat and p["sahip"] == oyuncu_ismi: kendi_oncusu = true
	if not kendi_oncusu: return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] = max(0, ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] - 3)
	ana.kontrol_edilen_hexler[koordinat] = oyuncu_ismi
	ana.arayuz.olay_yaz("🚩 %s, (%d, %d) bölgesinde [color=light_green]Hakimiyet[/color] kurarak topraklarına kattı!" % [ana.arayuz.renkli_isim(oyuncu_ismi), koordinat.x, koordinat.y])
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
	ana.islem_kabul = true

func karti_feda_et_rpc(oyuncu_ismi: String, kaynak_turu: String, kart_idx: int = -1):
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	var kart = _kart_getir(oyuncu_ismi, kart_idx)
	if kart.is_empty(): return
	var izinli = ["odun"]
	if kart.get("hedef") == "savas": izinli = ["altin"]
	elif kart.get("tur") == "ticaret_merkezi": izinli = ["odun", "tas", "yiyecek"]
	elif kart.get("tur") in ["tarla", "gelismis_sulama"]: izinli = ["yiyecek"]
	elif kart.get("tur") in ["tas_ocagi", "derin_damarlar"]: izinli = ["tas"]
	if not kaynak_turu in izinli: return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[oyuncu_ismi][kaynak_turu] += 1
	_kart_tuket(oyuncu_ismi, kart_idx, true)
	ana.arayuz.olay_yaz("♻️ %s, bir kartı 1 %s kaynağına dönüştürdü." % [ana.arayuz.renkli_isim(oyuncu_ismi), kaynak_turu.to_upper()])
	ana.arayuz.arayuzu_guncelle()
	ana.islem_kabul = true

# Yalnızca sunucuda çalışır: kartı gizli desteden sunucu seçer.
func savas_karti_cek_rpc(oyuncu_ismi):
	if not multiplayer.is_server(): return
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	if _el_siniri_doldu(oyuncu_ismi, true): return
	if ana.oyuncu_kaynaklari[oyuncu_ismi]["altin"] < 3: return
	if ana.deste.savas_destesi.is_empty() and ana.deste.atilan_savas_kartlari.is_empty(): return
	_karti_dagit(oyuncu_ismi, true)

# Elden çöpe atılan / dönüştürülen savaş kartlarını herkesin atılanlar destesine ekler
func savas_karti_atildi_rpc(kart_idx: int):
	var isim = ana.rpc_gonderen_ismi()
	if not ana.rpc_sirada_mi(isim): return
	if _kart_getir(isim, kart_idx).is_empty(): return
	_kart_tuket(isim, kart_idx, true)
	ana.arayuz.arayuzu_guncelle()
	ana.islem_kabul = true

func oncu_uret_rpc(oyuncu_ismi: String, koordinat: Vector2i):
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	var bina = ana.binalar_verisi.get(koordinat, {})
	if bina.get("tur") != "oncu_kampi" or bina.get("sahip") != oyuncu_ismi: return
	if ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] < 5: return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] = max(0, ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] - 5)
	ana.oyuncu_kaynaklari[oyuncu_ismi]["koylu"] += 1
	ana.piyonlar.append({"koordinat": koordinat, "sahip": oyuncu_ismi})
	ana.arayuz.olay_yaz("🧍 %s, kampında yeni bir [color=orange]Öncü[/color] yetiştirdi." % ana.arayuz.renkli_isim(oyuncu_ismi))
	ana.harita.gorus_haritasini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
	ana.islem_kabul = true

func aksiyon_karti_kullan_rpc(oyuncu_ismi: String, kart_turu: String, kart_idx: int = -1):
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	var kart = _kart_getir(oyuncu_ismi, kart_idx)
	if kart.get("hedef") != "direkt" or kart.get("tur") != kart_turu: return
	if not kart_turu in ["genisleme", "usta_isci"]: return
	_kart_tuket(oyuncu_ismi, kart_idx)
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	if kart_turu == "genisleme":
		ana.oyuncu_kaynaklari[oyuncu_ismi]["koylu"] += 1
		for k in ana.binalar_verisi:
			if ana.binalar_verisi[k]["tur"] == "sehir_merkezi" and ana.binalar_verisi[k]["sahip"] == oyuncu_ismi:
				ana.piyonlar.append({"koordinat": k, "sahip": oyuncu_ismi})
		ana.arayuz.olay_yaz("📜 %s, 'Hızlı Genişleme' kartını kullanarak anında 1 Öncü kazandı!" % ana.arayuz.renkli_isim(oyuncu_ismi))
	elif kart_turu == "usta_isci":
		ana.oyuncu_kaynaklari[oyuncu_ismi]["altin"] += 1
		ana.oyuncu_kaynaklari[oyuncu_ismi]["odun"] += 2
		ana.arayuz.olay_yaz("📜 %s, 'Usta İşçi' kartı ile kasasını doldurdu." % ana.arayuz.renkli_isim(oyuncu_ismi))
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
	ana.islem_kabul = true

func savas_baslat_rpc(saldiran_idx: int, savunan_idx: int, bx: int, by: int, t_tipi: String = "normal", ozel_saldiran: String = "", ozel_savunan: String = ""):
	if not ana.rpc_sirada_mi() or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	var gonderen = ana.rpc_gonderen_ismi()
	var hedef = Vector2i(bx, by)
	var savunan = ""
	if t_tipi == "isyan_buton":
		if saldiran_idx != -1 or savunan_idx != -1 or ozel_saldiran != gonderen: return
		if ana.efendiler.get(gonderen, "") != ozel_savunan or ozel_savunan == "": return
		var kaynak = ana.oyuncu_kaynaklari[gonderen]
		if kaynak["odun"] < 10 or kaynak["tas"] < 10 or kaynak["yiyecek"] < 10: return
		savunan = ozel_savunan
	else:
		if not t_tipi in ["normal", "yagmala", "hukmet", "yikim"]: return
		if not _hareket_gecerli(saldiran_idx, hedef, gonderen): return
		var bina = ana.binalar_verisi.get(hedef, {})
		if not bina.is_empty():
			savunan = bina["sahip"]
			if t_tipi == "normal": return
			if t_tipi == "hukmet" and (bina["tur"] != "sehir_merkezi" or not ana.vasallik_gecerli_mi(savunan, gonderen)): return
			if t_tipi == "yikim" and bina["tur"] == "sehir_merkezi": return
		else:
			if t_tipi != "normal": return
			savunan = ana.kontrol_edilen_hexler.get(hedef, "")
		if savunan_idx >= 0:
			if savunan_idx >= ana.piyonlar.size() or ana.piyonlar[savunan_idx]["koordinat"] != hedef: return
			if not bina.is_empty() and ana.piyonlar[savunan_idx]["sahip"] != savunan: return
			if bina.is_empty(): savunan = ana.piyonlar[savunan_idx]["sahip"]
		elif savunan_idx != -1: return
		if savunan == "" or ana.muttefik_mi(gonderen, savunan): return
		if bina.is_empty(): ozel_savunan = savunan
	var gercek_savunan = ana.koruyucu_efendi(savunan)
	if gercek_savunan not in ana.oyuncular or gercek_savunan in ana.ayrilan_oyuncular: return
	if gercek_savunan == gonderen: return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	var saldiran_isim = ozel_saldiran if saldiran_idx == -1 else ana.piyonlar[saldiran_idx]["sahip"]
	var orjinal_savunucu = ""
	var gercek_hedef_turu = "bina"
	var hedef_koor = Vector2i(bx, by)
	
	if t_tipi == "isyan_buton":
		orjinal_savunucu = ozel_savunan
		gercek_hedef_turu = "isyan_soyut"
	else:
		if hedef_koor != Vector2i(-1, -1) and ana.binalar_verisi.has(hedef_koor):
			gercek_hedef_turu = "bina"
			orjinal_savunucu = ana.binalar_verisi[hedef_koor]["sahip"]
		else:
			gercek_hedef_turu = "piyon"
			# savunan_idx -1 ise (öncüsüz düşman toprağı) piyonlar[-1] SON piyonu döndürürdü
			orjinal_savunucu = ana.piyonlar[savunan_idx]["sahip"] if savunan_idx != -1 else ozel_savunan

	ana.savas.savas_aktif = true
	ana.savas.savas_piyon_saldiran = saldiran_idx
	ana.savas.savas_bina_koordinat = hedef_koor
	ana.savas.savas_tipi = t_tipi
	ana.savas.savas_hedef_turu = gercek_hedef_turu
	ana.savas.savas_piyon_savunan = savunan_idx
	ana.savas.savas_ozel_saldiran = ozel_saldiran
	ana.savas.savas_ozel_savunucu = ozel_savunan
	ana.savas.secilen_savas_kartlari.clear()
	ana.savas.secilen_savas_idxleri.clear()
	
	var efendi_korumasi = ana.koruyucu_efendi(orjinal_savunucu)
	
	if t_tipi == "isyan_buton":
		ana.arayuz.olay_yaz("🔥 [color=red]BAĞIMSIZLIK SAVAŞI![/color] %s, efendisi %s'e isyan bayrağı çekti!" % [ana.arayuz.renkli_isim(saldiran_isim), ana.arayuz.renkli_isim(orjinal_savunucu)])
	elif efendi_korumasi != orjinal_savunucu:
		ana.arayuz.olay_yaz("🛡️ [color=red]EFENDİ KORUMASI![/color] %s, vasalı %s'i korumak için savaşa girdi!" % [ana.arayuz.renkli_isim(efendi_korumasi), ana.arayuz.renkli_isim(orjinal_savunucu)])
	else:
		ana.arayuz.olay_yaz("⚔️ [color=red]SAVAŞ BAŞLADI![/color] %s, saldırdı!" % ana.arayuz.renkli_isim(saldiran_isim))
	
	ana.savas.savas_panelini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.islem_kabul = true

# Yalnızca sunucuda çalışır: seçilen kartlar açılana kadar rakiplere gönderilmez.
func savas_hamlesi_yap_rpc(oyuncu_ismi: String, kartlar_array: Array, lokal_idx_array: Array):
	if not multiplayer.is_server(): return
	if not ana.savas.savas_aktif or ana.rpc_gonderen_ismi() != oyuncu_ismi: return
	var taraflar = ana.savas.savas_taraflari()
	if oyuncu_ismi not in taraflar or ana.savas.secilen_savas_kartlari.has(oyuncu_ismi): return
	if kartlar_array.size() != lokal_idx_array.size() or kartlar_array.size() > 7: return
	var dogrulanan = []
	var gorulen = []
	for i in range(lokal_idx_array.size()):
		var idx = lokal_idx_array[i]
		if typeof(idx) != TYPE_INT or idx in gorulen: return
		var kart = _kart_getir(oyuncu_ismi, idx)
		if kart.is_empty() or kart.get("hedef") != "savas" or kart != kartlar_array[i]: return
		if kart.get("tur") in ["kocbasi", "mancinik"] and (ana.savas.savas_hedef_turu != "bina" or oyuncu_ismi != taraflar[0]): return
		gorulen.append(idx)
		dogrulanan.append(kart.duplicate(true))
	ana.savas.secilen_savas_kartlari[oyuncu_ismi] = dogrulanan
	ana.savas.secilen_savas_idxleri[oyuncu_ismi] = gorulen
	ana.savas.taraf_kilitlendi_rpc.rpc(oyuncu_ismi == taraflar[0])
	if ana.savas.secilen_savas_kartlari.size() == 2:
		kartlari_ac_rpc.rpc(ana.savas.secilen_savas_kartlari, ana.savas.secilen_savas_idxleri)

@rpc("authority", "call_local", "reliable")
func kartlari_ac_rpc(kartlar_dict: Dictionary, idx_dict: Dictionary):
	if not ana.savas.savas_aktif or not ana.savas.son_kartlar_dict.is_empty(): return
	var taraflar = ana.savas.savas_taraflari()
	if kartlar_dict.size() != 2 or not kartlar_dict.has(taraflar[0]) or not kartlar_dict.has(taraflar[1]): return
	# Sunucu seçilen kartları ve eldeki yerlerini açıklar; gizli elde yalnızca türü (savaş) doğrulanabilir.
	var siralar = {}
	for isim in taraflar:
		var kartlar = kartlar_dict[isim]
		var idxler = idx_dict.get(isim, [])
		if typeof(kartlar) != TYPE_ARRAY or typeof(idxler) != TYPE_ARRAY or kartlar.size() != idxler.size(): return
		var el = ana.oyuncu_elleri.get(isim, [])
		var ciftler = []
		for i in range(idxler.size()):
			var idx = idxler[i]
			if typeof(idx) != TYPE_INT or idx < 0 or idx >= el.size(): return
			var kart = kartlar[i]
			if typeof(kart) != TYPE_DICTIONARY or kart.get("hedef") != "savas": return
			if el[idx].get("hedef") != "savas": return
			if not el[idx].get("gizli", false) and el[idx] != kart: return
			for cift in ciftler:
				if cift[0] == idx: return
			ciftler.append([idx, kart])
		ciftler.sort_custom(func(a, b): return a[0] > b[0])
		siralar[isim] = ciftler
	for isim in taraflar:
		for cift in siralar[isim]:
			_kart_tuket(isim, cift[0], true, cift[1])
	SesYoneticisi.efekt_cal("kilic")
	ana.savas.rakip_kartlari_goster(kartlar_dict)
	ana.savas.zar_asamasini_baslat(kartlar_dict)

@rpc("authority", "call_local", "reliable")
func savas_cozumle_rpc(kd, zar_sal, zar_sav):
	if not ana.savas.savas_aktif: return
	SesYoneticisi.efekt_cal("savas_sonu")
	ana.savas.savas_cozumle(kd, zar_sal, zar_sav)
	ana.secili_piyon_index = -1
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()

# Yalnızca sunucuda çalışır: kartı gizli desteden sunucu seçer.
func normal_kart_cek_rpc(oyuncu_ismi):
	if not multiplayer.is_server(): return
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	if _el_siniri_doldu(oyuncu_ismi, false): return
	if ana.deste.normal_deste.is_empty() and ana.deste.atilan_insa_kartlari.is_empty(): return
	_karti_dagit(oyuncu_ismi, false)

# Sunucu: kartın kendisini yalnızca sahibine, diğer eşlere gizli kart gönderir.
func _karti_dagit(oyuncu_ismi: String, savas_karti: bool):
	var karisti = ana.deste.sunucu_desteyi_hazirla(savas_karti)
	var deste = ana.deste.savas_destesi if savas_karti else ana.deste.normal_deste
	var kart = deste.pop_front()
	ana.deste.sunucu_kalanlari_guncelle()
	var sahip_peer = ana.oyuncu_peer_id(oyuncu_ismi)
	var gizli = ana.deste.gizli_kart(savas_karti)
	for peer in multiplayer.get_peers():
		kart_dagit_rpc.rpc_id(peer, oyuncu_ismi, kart if peer == sahip_peer else gizli, savas_karti, karisti)
	_kart_dagitimini_uygula(oyuncu_ismi, kart, savas_karti, karisti)

@rpc("authority", "call_remote", "reliable")
func kart_dagit_rpc(oyuncu_ismi: String, kart: Dictionary, savas_karti: bool, yeniden_karisti: bool):
	if oyuncu_ismi not in ana.oyuncular or kart.is_empty(): return
	if (kart.get("hedef") == "savas") != savas_karti: return
	ana.deste.istemci_kart_cekildi(kart, savas_karti, yeniden_karisti)
	_kart_dagitimini_uygula(oyuncu_ismi, kart, savas_karti, yeniden_karisti)

func _kart_dagitimini_uygula(oyuncu_ismi: String, kart: Dictionary, savas_karti: bool, yeniden_karisti: bool):
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	if savas_karti:
		ana.oyuncu_kaynaklari[oyuncu_ismi]["altin"] -= 3
	ana.oyuncu_elleri[oyuncu_ismi].append(kart.duplicate(true))
	var benim = oyuncu_ismi == ana.oyuncular[ana.benim_indexim]
	SesYoneticisi.efekt_cal("kart_cek")
	if benim:
		ana.deste.el.append(kart.duplicate(true))
		if not savas_karti: ana.secili_kart_index = -1
		ana.deste.eldeki_kartlari_ciz()
	if yeniden_karisti:
		var deste_adi = "Savaş" if savas_karti else "İnşa"
		ana.arayuz.olay_yaz("[color=yellow]🔄 %s Destesi bittiği için atılan kartlar yeniden karıştırıldı![/color]" % deste_adi)
	if savas_karti:
		ana.arayuz.olay_yaz("🃏 %s, kışladan bir [color=crimson]Savaş Kartı[/color] çekti." % ana.arayuz.renkli_isim(oyuncu_ismi))
	else:
		ana.arayuz.olay_yaz("🃏 %s, destesinden bir İnşa/Gelişim kartı çekti." % ana.arayuz.renkli_isim(oyuncu_ismi))
	ana.arayuz.arayuzu_guncelle()
	if benim and not savas_karti: ana.arayuz.panel_yukari_cik()

 
# 🟢 HATA 2 ÇÖZÜMÜ: Kart onaylama artık hangi karta tıklandığını bilecek!
func kart_onayla(gelen_index = -1):
	if gelen_index != -1:
		ana.secili_kart_index = gelen_index
		
	if ana.aktif_sira != ana.benim_indexim or not ana.ilk_tur_bitti:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Sıra senin değil![/color]")
		return
	if ana.aktif_oyuncu_aksiyon_hakki <= 0:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Aksiyon Puanın (AP) kalmadı![/color]")
		return

	if ana.secili_kart_index == -1: return
	
	var kart = ana.deste.el[ana.secili_kart_index]
	
	if kart["hedef"] == "direkt":
		kart_modul._secili_karti_direkt_kullan()
	else:
		insa_modul._kurulabilir_hexleri_hesapla(kart)
		
		if ana.kurulabilir_hexler.size() == 0:
			ana.kart_insa_modu_aktif = false 
			ana.arayuz.olay_yaz("[color=light_coral]❌ Bu kartı inşa edebileceğin veya kullanabileceğin uygun bir alan (Biyom) yok![/color]")
		else:
			ana.kart_insa_modu_aktif = true
			ana.arayuz.olay_yaz("[color=yellow]🏗️ İnşa Modu Başladı! Parlayan yeşil alanlardan birini seçin.[/color]")
	
	ana.arayuz.arayuzu_guncelle()

@rpc("authority", "call_local", "reliable")
func oyunu_bitir_rpc(kazanan_isim: String, puan: int):
	if ana.oyun_bitti: return
	ana.oyun_bitti = true
	if not multiplayer.is_server(): Network.donus_kaydini_sil()   # biten maça dönülmez
	if ana.oyuncular.is_empty(): return   # durum görüntüsünü bekleyen dönüş sahnesi
	var kazandim = ana.oyuncular[ana.benim_indexim] == kazanan_isim
	SesYoneticisi.efekt_cal("zafer" if kazandim else "yenilgi")
	ana.arayuz.olay_yaz("🏆 [color=gold][b]OYUN BİTTİ! %s, %d puanla ZAFERE ULAŞTI![/b][/color]" % [ana.arayuz.renkli_isim(kazanan_isim), puan])
	ana.puanlari_guncelle()
	ana.secili_kart_index = -1
	ana.secili_piyon_index = -1
	ana.kart_insa_modu_aktif = false
	ana.arayuz.sonuc_ekranini_goster(kazanan_isim, puan)
	Network.maci_sonuclandir(kazanan_isim)


# Keşfedilmemiş arazi yalnızca sunucuda bilinir; keşifle birlikte herkese açıklanır.
func _kesif_biyomu(koor: Vector2i) -> String:
	if multiplayer.is_server():
		var biyom = ana.harita.biyom_belirle(koor)
		ana.islem_ek["biyom"] = biyom
		return biyom
	return str(ana.islem_ek.get("biyom", ""))

# Gizli elde sunucunun açıkladığı kart (oynanan kart) gerçek kartın yerine kullanılır.
func _kart_getir(isim: String, idx: int) -> Dictionary:
	var el = ana.oyuncu_elleri.get(isim, [])
	if idx < 0 or idx >= el.size(): return {}
	var acik = ana.islem_ek.get("kartlar", {}).get("%s:%d" % [isim, idx], {})
	return acik if not acik.is_empty() else el[idx]

func _kart_tuket(isim: String, idx: int, savas_atigi: bool = false, acik_kart: Dictionary = {}):
	var el = ana.oyuncu_elleri.get(isim, [])
	if idx < 0 or idx >= el.size(): return
	var kart = acik_kart if not acik_kart.is_empty() else _kart_getir(isim, idx)
	if kart.is_empty() or kart.get("gizli", false): return
	# Sunucu, sıralı hamlede tüketilen kartı diğer eşlere açıklamak üzere kaydeder.
	if multiplayer.is_server() and acik_kart.is_empty() and ana._relay_gonderen != 0:
		if not ana.islem_ek.has("kartlar"): ana.islem_ek["kartlar"] = {}
		ana.islem_ek["kartlar"]["%s:%d" % [isim, idx]] = kart.duplicate(true)
	if el[idx].get("gizli", false):
		ana.deste.kart_acildi(kart)
	el.remove_at(idx)
	if kart.get("hedef") != "savas":
		ana.deste.atilan_insa_kartlari.append(kart)
	if savas_atigi and kart.get("hedef") == "savas":
		ana.deste.atilan_savas_kartlari.append(kart)
	if isim == ana.oyuncular[ana.benim_indexim]:
		ana.deste.el.remove_at(idx)

func _el_siniri_doldu(isim: String, savas_karti: bool) -> bool:
	var sayi = 0
	for kart in ana.oyuncu_elleri.get(isim, []):
		if (kart.get("hedef") == "savas") == savas_karti: sayi += 1
	return sayi >= ana.deste.MAX_EL_LIMITI

func _hareket_gecerli(p_idx: int, hedef: Vector2i, isim: String) -> bool:
	if not ana.hex_gecerli_mi(hedef) or p_idx < 0 or p_idx >= ana.piyonlar.size(): return false
	var p = ana.piyonlar[p_idx]
	return p["sahip"] == isim and ana.harita.hex_komsu_mu(p["koordinat"], hedef) and ana.oyuncu_kaynaklari[isim]["yiyecek"] >= 1

func _kart_maliyeti_gecerli(isim: String, kart: Dictionary, mo: int, mt: int) -> bool:
	return not kart.is_empty() and mo == kart.get("odun_maliyet", -1) and mt == kart.get("tas_maliyet", -1) and mo >= 0 and mt >= 0 and ana.oyuncu_kaynaklari[isim]["odun"] >= mo and ana.oyuncu_kaynaklari[isim]["tas"] >= mt

func _savas_kartlarini_iade_et(kartlar: Dictionary):
	for isim in ana.savas.savas_taraflari():
		for kart in kartlar.get(isim, []):
			ana.oyuncu_elleri[isim].append(kart.duplicate(true))
			var idx = ana.deste.atilan_savas_kartlari.rfind(kart)
			if idx != -1: ana.deste.atilan_savas_kartlari.remove_at(idx)
			if isim == ana.oyuncular[ana.benim_indexim]: ana.deste.el.append(kart.duplicate(true))
