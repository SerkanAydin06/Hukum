extends Node
class_name ArayuzDiplomasi

var arayuz: Node
var ana: Node
var skor_etiketleri = {}

func baslat(_arayuz):
	arayuz = _arayuz
	ana = arayuz.ana

func guncelle(k_isim: String, savas_var_mi: bool):
	var efendim = ana.efendiler.get(k_isim, "")
	var vasallarim = []
	for v in ana.efendiler:
		if ana.efendiler[v] == k_isim: vasallarim.append(v)
		
	if not arayuz.vasal_paneli: return
	
	if savas_var_mi:
		arayuz.vasal_paneli.visible = false
	elif efendim != "" or vasallarim.size() > 0:
		arayuz.vasal_paneli.visible = true
		var v_metin = "[font_size=11][center][b]👑 DİPLOMASİ BİLGİSİ[/b][/center]\n\n"
		
		if efendim != "":
			v_metin += "[color=orange]Efendin:[/color] " + arayuz.renkli_isim(efendim) + "\n"
			var od_v = ana.odenen_vergiler[k_isim]
			v_metin += "[color=gray]Toplam Ödenen Vergi:[/color]\n%d🌲 %d🪨 %d🌾 %d🪙\n" % [od_v["odun"], od_v["tas"], od_v["yiyecek"], od_v["altin"]]
			
			var benim_ham = _kaynak_hesapla(k_isim)
			v_metin += "[color=light_coral]Bu Tur Ödenecek Vergi:[/color]\n%d🌲 %d🪨 %d🌾 %d🪙\n\n" % [int(benim_ham["odun"]/2), int(benim_ham["tas"]/2), int(benim_ham["yiyecek"]/2), int(benim_ham["altin"]/2)]
			if arayuz.isyan_btn: arayuz.isyan_btn.visible = true
		else:
			if arayuz.isyan_btn: arayuz.isyan_btn.visible = false
			
		if vasallarim.size() > 0:
			v_metin += "[color=gold]Vasalların:[/color]\n"
			for v in vasallarim:
				var od_v = ana.odenen_vergiler[v]
				v_metin += "- %s\n  [color=gray](Gelen Toplam: %d🌲 %d🪨 %d🌾 %d🪙)[/color]\n" % [arayuz.renkli_isim(v), od_v["odun"], od_v["tas"], od_v["yiyecek"], od_v["altin"]]
				var vasal_ham = _kaynak_hesapla(v)
				v_metin += "  [color=light_green](Bu Tur Gelecek: %d🌲 %d🪨 %d🌾 %d🪙)[/color]\n\n" % [int(vasal_ham["odun"]/2), int(vasal_ham["tas"]/2), int(vasal_ham["yiyecek"]/2), int(vasal_ham["altin"]/2)]
		v_metin += "[/font_size]"
		if arayuz.vasal_bilgi_label: arayuz.vasal_bilgi_label.text = v_metin
	else:
		arayuz.vasal_paneli.visible = false

func skor_tabelasi_kur():
	if not arayuz.puan_konteyner: return
	for child in arayuz.puan_konteyner.get_children(): child.queue_free()
	skor_etiketleri.clear()
	
	for o in ana.oyuncular:
		var med_ad = ana.medeniyetler_verisi.get(o, "Bilinmeyen")
		var satir_kutusu = HBoxContainer.new()
		satir_kutusu.add_theme_constant_override("separation", 8)
		
		var avatar = TextureRect.new()
		avatar.custom_minimum_size = Vector2(40, 25)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		if arayuz.flama_resimleri.has(med_ad) and arayuz.flama_resimleri[med_ad] != null:
			avatar.texture = arayuz.flama_resimleri[med_ad]
			
		var skor_yazisi = RichTextLabel.new()
		skor_yazisi.bbcode_enabled = true
		skor_yazisi.fit_content = true
		skor_yazisi.custom_minimum_size = Vector2(300, 0)
		skor_yazisi.scroll_active = false
		
		satir_kutusu.add_child(avatar)
		satir_kutusu.add_child(skor_yazisi)
		arayuz.puan_konteyner.add_child(satir_kutusu)
		skor_etiketleri[o] = {"kutu": satir_kutusu, "yazi": skor_yazisi}

func skor_guncelle():
	if not arayuz or not arayuz.puan_konteyner: return
	
	var satirlar = arayuz.puan_konteyner.get_children()
	
	for i in range(satirlar.size()):
		var satir = satirlar[i]
		var satir_no = i + 1
		
		if i < ana.oyuncular.size():
			satir.visible = true
			var oyuncu_ismi = ana.oyuncular[i]
			var med = ana.medeniyetler_verisi.get(oyuncu_ismi, "")
			
			# Puan hesaplaması
			var puan = 0
			
			# 🟢 Hex kontrolü: 1 puan/hex
			for k in ana.kontrol_edilen_hexler:
				if ana.kontrol_edilen_hexler[k] == oyuncu_ismi:
					puan += 1
					
			# 🟢 Bina seviyesi: 2 puan/seviye, ŞEHİR MERKEZİ HARİÇ
			for koor in ana.binalar_verisi:
				var b = ana.binalar_verisi[koor]
				if b["sahip"] == oyuncu_ismi and b["tur"] != "sehir_merkezi":   # 🟢 DÜZELTİLDİ: şehir merkezi artık puan vermiyor
					puan += b.get("seviye", 1) * 2
					
			# 🟢 YENİ: Vasal sayısı × 5 (canlı, kaybedince otomatik düşer)
			var vasal_sayisi = 0
			for v in ana.efendiler:
				if ana.efendiler[v] == oyuncu_ismi:
					vasal_sayisi += 1
			puan += vasal_sayisi * 5
			
			# 🟢 YENİ: Savaş puanı × 2 (kalıcı sayaç, kazanınca +1 kaybedince -1 birikir, sonra ×2 çarpılır)
			puan += ana.savas_puanlari.get(oyuncu_ismi, 0) * 2
			
			var logo_rect = satir.get_node_or_null("Logo")
			
			if logo_rect and med != "" and arayuz.flama_resimleri.has(med):
				logo_rect.texture = arayuz.flama_resimleri[med]
				logo_rect.visible = true
			elif logo_rect:
				logo_rect.texture = null
				
			var isim_etiket_adi = "Oyuncu%dIsmi" % satir_no
			var puan_etiket_adi = "Puan%dLabel" % satir_no
			
			var isim_lbl = satir.get_node_or_null(isim_etiket_adi)
			if not isim_lbl:
				isim_lbl = arayuz.find_child(isim_etiket_adi, true, false)
				
			var puan_lbl = satir.get_node_or_null(puan_etiket_adi)
			if not puan_lbl:
				puan_lbl = arayuz.find_child(puan_etiket_adi, true, false)
				
			if isim_lbl:
				isim_lbl.text = oyuncu_ismi
				
			if puan_lbl:
				puan_lbl.text = "%d ⭐" % puan
				
			# 🟢 YENİ: Puan hedefe ulaştıysa kazanma kontrolü (sadece sunucu tetiklesin)
			if puan >= ana.HEDEF_PUAN and multiplayer.is_server() and not ana.oyun_bitti:
				ana.aksiyon.oyunu_bitir_rpc.rpc(oyuncu_ismi, puan)
		else:
			satir.visible = false

func _kaynak_hesapla(sahip: String) -> Dictionary:
	return ana.tur_ekonomi.bina_uretimi(sahip)
