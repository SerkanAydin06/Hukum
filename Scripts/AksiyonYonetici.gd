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
					
					if ana.secili_kart_index != -1:
						ana.secili_kart_index = -1
						ana.deste._kart_gorsellerini_guncelle()
						return
					
					if ana.kart_insa_modu_aktif:
						ana.secili_kart_index = -1
						ana.kart_insa_modu_aktif = false
						ana.kurulabilir_hexler.clear()
						ana.deste._kart_gorsellerini_guncelle()
						ana.arayuz.olay_yaz("[color=gray]İnşa modu iptal edildi.[/color]")
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
						var oynanan_idx = ana.secili_kart_index
						
						if kart["hedef"] == "kendi_binasi": 
							bina_yukselt_rpc.rpc(k_isim, k, kart["odun_maliyet"], kart["tas_maliyet"])
						else: 
							kart_oyna_rpc.rpc(k_isim, kart["tur"], k, kart["odun_maliyet"], kart["tas_maliyet"])
						
						ana.deste.el.remove_at(oynanan_idx)
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
		savas_baslat_rpc.rpc(ana.secili_piyon_index, ana.savas.savas_piyon_savunan, -1, -1)
	elif ana.bekleyen_onay == "sehir" and ana.gecici_koordinat != Vector2i(-1, -1):
		bina_kur_rpc.rpc(ana.gecici_koordinat, ana.oyuncular[ana.benim_indexim], "sehir_merkezi", ana.secilen_baslangic_biyomu)
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

@rpc("any_peer", "call_local", "reliable")
func kesif_ve_hareket_rpc(p_idx, yeni_koor, biyom, k_isim):
	if not ana.rpc_sirada_mi(k_isim) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	if p_idx < 0 or p_idx >= ana.piyonlar.size() or ana.piyonlar[p_idx]["sahip"] != k_isim: return
	if not (biyom in ["cim", "orman", "dag"]): return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[k_isim]["yiyecek"] = max(0, ana.oyuncu_kaynaklari[k_isim]["yiyecek"] - 1)
	ana.harita.kesfedilen_hexler[yeni_koor] = biyom
	ana.piyonlar[p_idx]["koordinat"] = yeni_koor
	var tur_cevir = "ÇİM" if biyom == "cim" else "ORMAN" if biyom == "orman" else "DAĞ"
	ana.arayuz.olay_yaz("🧭 %s, bilinmeyen topraklara girerek [color=cyan]%s[/color] bölgesi keşfetti!" % [ana.arayuz.renkli_isim(k_isim), tur_cevir])
	ana.harita.gorus_haritasini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func bina_kur_rpc(koordinat, sahip_isim, bina_turu, baslangic_biyomu = ""):
	if not ana.rpc_sirada_mi(sahip_isim): return
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

@rpc("any_peer", "call_local", "reliable")
func bina_yukselt_rpc(sahip_isim, koordinat, mo, mt):
	if not ana.rpc_sirada_mi(sahip_isim): return
	if ana.aktif_sira >= ana.oyuncular.size() or ana.oyuncular[ana.aktif_sira] != sahip_isim: return
	if ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	
	# 🟢 YENİ: Asıl güvenlik kontrolü — seviye 3'ü asla geçemez
	if not ana.binalar_verisi.has(koordinat): return
	if ana.binalar_verisi[koordinat].get("seviye", 1) >= 3:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Bu bina zaten maksimum (Seviye 3) seviyede![/color]")
		return
	
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[sahip_isim]["odun"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["odun"] - mo)
	ana.oyuncu_kaynaklari[sahip_isim]["tas"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["tas"] - mt)
	ana.binalar_verisi[koordinat]["seviye"] += 1
	var yeni_lvl = ana.binalar_verisi[koordinat]["seviye"]
	var b_tur = ana.binalar_verisi[koordinat]["tur"].to_upper().replace("_"," ")
	ana.arayuz.olay_yaz("🔺 %s, (%d, %d) konumundaki %s yapısını [color=gold]Seviye %d[/color]'a yükseltti!" % [ana.arayuz.renkli_isim(sahip_isim), koordinat.x, koordinat.y, b_tur, yeni_lvl])
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func piyon_hareket_rpc(p_idx, yeni_koor):
	if not ana.rpc_sirada_mi() or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	if p_idx < 0 or p_idx >= ana.piyonlar.size() or ana.piyonlar[p_idx]["sahip"] != ana.rpc_gonderen_ismi(): return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	var sahip = ana.piyonlar[p_idx]["sahip"]
	var eski_koor = ana.piyonlar[p_idx]["koordinat"]
	ana.oyuncu_kaynaklari[sahip]["yiyecek"] = max(0, ana.oyuncu_kaynaklari[sahip]["yiyecek"] - 1)
	ana.piyonlar[p_idx]["koordinat"] = yeni_koor
	ana.arayuz.olay_yaz("🧍 %s, Öncüsünü (%d, %d) ➔ (%d, %d) konumuna yürüttü." % [ana.arayuz.renkli_isim(sahip), eski_koor.x, eski_koor.y, yeni_koor.x, yeni_koor.y])
	ana.harita.gorus_haritasini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func kart_oyna_rpc(sahip_isim, kart_turu, koordinat, mo, mt):
	if not ana.rpc_sirada_mi(sahip_isim): return
	if ana.aktif_sira >= ana.oyuncular.size() or ana.oyuncular[ana.aktif_sira] != sahip_isim: return
	if ana.aktif_oyuncu_aksiyon_hakki <= 0: return

	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[sahip_isim]["odun"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["odun"] - mo)
	ana.oyuncu_kaynaklari[sahip_isim]["tas"] = max(0, ana.oyuncu_kaynaklari[sahip_isim]["tas"] - mt)
	ana.binalar_verisi[koordinat] = {"tur": kart_turu, "sahip": sahip_isim, "seviye": 1}
	if kart_turu == "ev": ana.oyuncu_kaynaklari[sahip_isim]["max_nufus"] += 3
	ana.arayuz.olay_yaz("🏗️ %s, (%d, %d) konumuna [color=aqua]%s[/color] kurdu." % [ana.arayuz.renkli_isim(sahip_isim), koordinat.x, koordinat.y, kart_turu.to_upper().replace("_"," ")])
	ana.harita.gorus_haritasini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func hakimiyet_kur_rpc(oyuncu_ismi, koordinat):
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] = max(0, ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] - 3)
	ana.kontrol_edilen_hexler[koordinat] = oyuncu_ismi
	ana.arayuz.olay_yaz("🚩 %s, (%d, %d) bölgesinde [color=light_green]Hakimiyet[/color] kurarak topraklarına kattı!" % [ana.arayuz.renkli_isim(oyuncu_ismi), koordinat.x, koordinat.y])
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func karti_feda_et_rpc(oyuncu_ismi, kaynak_turu):
	if not ana.rpc_sirada_mi(oyuncu_ismi): return
	if not (kaynak_turu in ["odun", "tas", "yiyecek", "altin"]): return
	if ana.aktif_sira >= ana.oyuncular.size() or ana.oyuncular[ana.aktif_sira] != oyuncu_ismi: return
	if ana.aktif_oyuncu_aksiyon_hakki <= 0: return

	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[oyuncu_ismi][kaynak_turu] += 1
	ana.arayuz.arayuzu_guncelle()

@rpc("any_peer", "call_local", "reliable")
func savas_karti_cek_rpc(oyuncu_ismi):
	# Not: El limiti (7) kontrolü çağıran tarafta (_savas_karti_cek) yapılır; burada yalnızca
	# tüm oyuncularda aynı olan veriye bakılır, yoksa oyuncuların oyun durumu ayrışır.
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return

	if ana.deste.savas_destesi.is_empty():
		if ana.deste.atilan_savas_kartlari.is_empty():
			ana.arayuz.olay_yaz("[color=light_coral]❌ Savaş Destesi tamamen bitti![/color]")
			return
		ana.deste.savas_destesi = ana.deste.atilan_savas_kartlari.duplicate(true)
		ana.deste.karistir(ana.deste.savas_destesi)
		ana.deste.atilan_savas_kartlari.clear()
		ana.arayuz.olay_yaz("[color=yellow]🔄 Savaş Destesi bittiği için atılan kartlar yeniden karıştırıldı![/color]")

	if ana.oyuncu_kaynaklari[oyuncu_ismi]["altin"] < 3:
		if oyuncu_ismi == ana.oyuncular[ana.benim_indexim]:
			ana.arayuz.olay_yaz("[color=light_coral]❌ Savaş kartı çekmek için 3 Altın gerekli![/color]")
		return

	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[oyuncu_ismi]["altin"] -= 3
	
	var cekilen = ana.deste.savas_destesi.pop_front()
	if oyuncu_ismi == ana.oyuncular[ana.benim_indexim]: 
		ana.deste.el.append(cekilen)
		ana.deste.eldeki_kartlari_ciz()
		var kalan_lbl = ana.arayuz.get_node_or_null("%SavasDestesiKalan")
		if kalan_lbl: kalan_lbl.text = str(ana.deste.savas_destesi.size())
		
	ana.arayuz.olay_yaz("🃏 %s, kışladan bir [color=crimson]Savaş Kartı[/color] çekti." % ana.arayuz.renkli_isim(oyuncu_ismi))
	ana.arayuz.arayuzu_guncelle()

# Elden çöpe atılan / dönüştürülen savaş kartlarını herkesin atılanlar destesine ekler
@rpc("any_peer", "call_local", "reliable")
func savas_karti_atildi_rpc(kart: Dictionary):
	if ana.rpc_gonderen_ismi() == "": return
	if kart.get("hedef", "") == "savas":
		ana.deste.atilan_savas_kartlari.append(kart)

@rpc("any_peer", "call_local", "reliable")
func oncu_uret_rpc(oyuncu_ismi, koordinat):
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] = max(0, ana.oyuncu_kaynaklari[oyuncu_ismi]["yiyecek"] - 5)
	ana.oyuncu_kaynaklari[oyuncu_ismi]["koylu"] += 1
	ana.piyonlar.append({"koordinat": koordinat, "sahip": oyuncu_ismi})
	ana.arayuz.olay_yaz("🧍 %s, kampında yeni bir [color=orange]Öncü[/color] yetiştirdi." % ana.arayuz.renkli_isim(oyuncu_ismi))
	ana.harita.gorus_haritasini_guncelle()
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func aksiyon_karti_kullan_rpc(oyuncu_ismi, kart_turu):
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
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

@rpc("any_peer", "call_local", "reliable")
func savas_baslat_rpc(saldiran_idx, savunan_idx, bx, by, t_tipi = "normal", ozel_saldiran = "", ozel_savunan = ""):
	if not ana.rpc_sirada_mi() or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	print("🔍 DEBUG: savas_baslat_rpc çalıştı. t_tipi=", t_tipi, " bx,by=", bx, by, " saldiran_idx=", saldiran_idx)
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
	
	var efendi_korumasi = ana.efendiler.get(orjinal_savunucu, orjinal_savunucu)
	
	if t_tipi == "isyan_buton":
		ana.arayuz.olay_yaz("🔥 [color=red]BAĞIMSIZLIK SAVAŞI![/color] %s, efendisi %s'e isyan bayrağı çekti!" % [ana.arayuz.renkli_isim(saldiran_isim), ana.arayuz.renkli_isim(orjinal_savunucu)])
	elif efendi_korumasi != orjinal_savunucu:
		ana.arayuz.olay_yaz("🛡️ [color=red]EFENDİ KORUMASI![/color] %s, vasalı %s'i korumak için savaşa girdi!" % [ana.arayuz.renkli_isim(efendi_korumasi), ana.arayuz.renkli_isim(orjinal_savunucu)])
	else:
		ana.arayuz.olay_yaz("⚔️ [color=red]SAVAŞ BAŞLADI![/color] %s, saldırdı!" % ana.arayuz.renkli_isim(saldiran_isim))
	
	ana.savas.savas_panelini_guncelle()
	ana.arayuz.arayuzu_guncelle()

@rpc("any_peer", "call_local", "reliable")
func savas_hamlesi_yap_rpc(oyuncu_ismi, kartlar_array, lokal_idx_array):
	if ana.rpc_gonderen_ismi() != oyuncu_ismi: return
	ana.savas.secilen_savas_kartlari[oyuncu_ismi] = kartlar_array
	# Savaşta kullanılan kartlar atılanlar destesine gider (savaş destesi bitince yeniden karıştırılır)
	ana.deste.atilan_savas_kartlari.append_array(kartlar_array)
	
	if oyuncu_ismi == ana.oyuncular[ana.benim_indexim]:
		lokal_idx_array.sort_custom(func(a, b): return a > b)
		for idx in lokal_idx_array:
			if idx != -1: ana.deste.el.remove_at(idx)
		ana.deste._kart_gorsellerini_guncelle()
			
	if multiplayer.is_server() and ana.savas.secilen_savas_kartlari.size() == 2:
		kartlari_ac_rpc.rpc(ana.savas.secilen_savas_kartlari)

@rpc("authority", "call_local", "reliable")
func kartlari_ac_rpc(kartlar_dict):
	ana.savas.rakip_kartlari_goster(kartlar_dict)
	ana.savas.zar_asamasini_baslat(kartlar_dict)   # ✅ otomatik zar atma YOK, sadece aşamayı başlatıyor

@rpc("authority", "call_local", "reliable")
func savas_cozumle_rpc(kd, zar_sal, zar_sav):
	ana.savas.savas_cozumle(kd, zar_sal, zar_sav)
	ana.secili_piyon_index = -1
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func normal_kart_cek_rpc(oyuncu_ismi):
	if not ana.rpc_sirada_mi(oyuncu_ismi) or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	if ana.deste.normal_deste.is_empty(): return
	ana.aktif_oyuncu_aksiyon_hakki -= 1
	var cekilen = ana.deste.normal_deste.pop_front()
	
	if oyuncu_ismi == ana.oyuncular[ana.benim_indexim]:
		ana.deste.el.append(cekilen)
		ana.secili_kart_index = -1
		
	ana.arayuz.olay_yaz("🃏 %s, destesinden bir İnşa/Gelişim kartı çekti." % ana.arayuz.renkli_isim(oyuncu_ismi))
	ana.arayuz.arayuzu_guncelle()
	ana.arayuz.panel_yukari_cik()
 
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
	ana.arayuz.olay_yaz("🏆 [color=gold][b]OYUN BİTTİ! %s, %d puanla ZAFERE ULAŞTI![/b][/color]" % [ana.arayuz.renkli_isim(kazanan_isim), puan])
	get_tree().paused = true   # 🟢 basit bir MVP: oyunu durdur, ekstra bir "kazanma ekranı" istersen ayrı konuşalım
