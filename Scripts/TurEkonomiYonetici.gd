extends Node
class_name TurEkonomiYonetici

@onready var ana = get_parent() as AnaOyun

func _oyuncu_net_uretimini_hesapla(isim: String) -> Dictionary:
	var net_u = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}
	var ham_u = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}
	var kesinti_u = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}   # 🟢 YENİ
	
	for koor in ana.binalar_verisi:
		var b = ana.binalar_verisi[koor]
		if b["sahip"] == isim:
			var lvl = b.get("seviye", 1)
			match b["tur"]:
				"sehir_merkezi":
					var biyom = ana.harita.kesfedilen_hexler.get(koor, "")
					if biyom == "cim": ham_u["yiyecek"] += lvl
					elif biyom == "orman": ham_u["odun"] += lvl
					elif biyom == "dag": ham_u["tas"] += lvl
				"tarla": ham_u["yiyecek"] += lvl
				"oduncu_kampi": ham_u["odun"] += lvl
				"tas_ocagi": ham_u["tas"] += lvl
				
	var efendim = ana.efendiler.get(isim, "")
	for k in ham_u:
		if ham_u[k] > 0:
			if efendim != "":
				var kesinti = int(ham_u[k] / 2)   # 🟢 YENİ
				kesinti_u[k] = kesinti              # 🟢 YENİ
				net_u[k] += (ham_u[k] - kesinti)
			else:
				net_u[k] += ham_u[k]
				
	for v in ana.efendiler:
		if ana.efendiler[v] == isim:
			var v_ham = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}
			for koor in ana.binalar_verisi:
				var b = ana.binalar_verisi[koor]
				if b["sahip"] == v:
					var lvl = b.get("seviye", 1)
					match b["tur"]:
						"sehir_merkezi":
							var biyom = ana.harita.kesfedilen_hexler.get(koor, "")
							if biyom == "cim": v_ham["yiyecek"] += lvl
							elif biyom == "orman": v_ham["odun"] += lvl
							elif biyom == "dag": v_ham["tas"] += lvl
						"tarla": v_ham["yiyecek"] += lvl
						"oduncu_kampi": v_ham["odun"] += lvl
						"tas_ocagi": v_ham["tas"] += lvl
			for k in v_ham:
				if v_ham[k] > 0:
					net_u[k] += int(v_ham[k] / 2)
					
	return {"net": net_u, "ham": ham_u, "kesinti": kesinti_u}   # 🟢 DEĞİŞTİ: artık 3 parçalı dict

func _kaynak_sat(k_turu: String):
	# 🟢 AP kontrolü kaldırıldı, artık sadece sıra bende mi diye bakıyoruz
	if ana.aktif_sira != ana.benim_indexim:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Sadece kendi sıranızda ticaret yapabilirsiniz![/color]")
		return
		
	var k_isim = ana.oyuncular[ana.benim_indexim]
	if ana.oyuncu_kaynaklari[k_isim][k_turu] >= 5:
		ticaret_yap_rpc.rpc(k_isim, k_turu)
	else:
		var n = "Odun" if k_turu == "odun" else "Taş" if k_turu == "tas" else "Yiyecek"
		ana.arayuz.olay_yaz("[color=light_coral]❌ Yetersiz kaynak! Altın alabilmek için en az 5 %s gerekli.[/color]" % n)

@rpc("any_peer", "call_local", "reliable")
func ticaret_yap_rpc(oyuncu_ismi, k_turu):
	# 🟢 AP eksiltme satırı (ana.aktif_oyuncu_aksiyon_hakki -= 1) tamamen silindi!
	ana.oyuncu_kaynaklari[oyuncu_ismi][k_turu] -= 5
	ana.oyuncu_kaynaklari[oyuncu_ismi]["altin"] += 1
	var emoji = "🌲" if k_turu == "odun" else "🪨" if k_turu == "tas" else "🌾"
	ana.arayuz.olay_yaz("⚖️ %s, tüccarlara 5 %s %s vererek [color=gold]1 🪙 Altın[/color] kazandı." % [ana.arayuz.renkli_isim(oyuncu_ismi), emoji, k_turu.to_upper()])
	ana.arayuz.arayuzu_guncelle()

func _tur_butonuna_basildi():
	if ana.aktif_sira == ana.benim_indexim:
		if not ana.sehir_merkezleri[ana.oyuncular[ana.benim_indexim]]: return
		
		# 🟢 YENİ KONTROL: İnşa ve Savaş kartlarını ayrı ayrı sayıyoruz (Her biri max 7 olabilir)
		var insa_sayisi = 0
		var savas_sayisi = 0
		
		for kart in ana.deste.el:
			if kart.get("hedef") == "savas":
				savas_sayisi += 1
			else:
				insa_sayisi += 1
				
		if insa_sayisi > 7 or savas_sayisi > 7:
			ana.arayuz.olay_yaz("[color=light_coral]❌ Elindeki İnşa (%d/7) veya Savaş (%d/7) kartı sınırı aşıldı! Fazlalıkları çöpe atmalısın.[/color]" % [insa_sayisi, savas_sayisi])
			return
			
		sirayi_degistir_rpc.rpc()

@rpc("any_peer", "call_local", "reliable")
func sirayi_degistir_rpc():
	var bitiren_oyuncu = ana.oyuncular[ana.aktif_sira]
	
	if ana.ilk_tur_bitti or ana.sehir_merkezleri.get(bitiren_oyuncu, false):
		var uretim = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}
		for koor in ana.binalar_verisi:
			var b = ana.binalar_verisi[koor]
			if b["sahip"] == bitiren_oyuncu:
				var lvl = b.get("seviye", 1)
				match b["tur"]:
					"sehir_merkezi":
						var biyom = ana.harita.kesfedilen_hexler.get(koor, "")
						if biyom == "cim": uretim["yiyecek"] += lvl
						elif biyom == "orman": uretim["odun"] += lvl
						elif biyom == "dag": uretim["tas"] += lvl
					"tarla": uretim["yiyecek"] += lvl
					"oduncu_kampi": uretim["odun"] += lvl
					"tas_ocagi": uretim["tas"] += lvl
					
		var efendisi = ana.efendiler.get(bitiren_oyuncu, "")
		var vergi_logu = ""
		
		for k in uretim:
			var kazanilan = uretim[k]
			if kazanilan > 0:
				if efendisi != "":
					var vergi = int(kazanilan / 2) 
					ana.oyuncu_kaynaklari[bitiren_oyuncu][k] += (kazanilan - vergi)
					ana.oyuncu_kaynaklari[efendisi][k] += vergi
					if vergi > 0:
						vergi_logu += "%d %s, " % [vergi, k.to_upper()]
						ana.odenen_vergiler[bitiren_oyuncu][k] += vergi 
				else:
					ana.oyuncu_kaynaklari[bitiren_oyuncu][k] += kazanilan
					
		if efendisi != "" and vergi_logu != "":
			ana.arayuz.olay_yaz("👑 [color=orange]Vasal Vergisi:[/color] %s, efendisine %s ödedi." % [ana.arayuz.renkli_isim(bitiren_oyuncu), vergi_logu])

	ana.aktif_sira = (ana.aktif_sira + 1) % ana.oyuncular.size()
	
	if ana.aktif_sira == 0:
		ana.ilk_tur_bitti = true
		ana.tur_sayaci += 1
		
	var aktif_oyuncu_ismi = ana.oyuncular[ana.aktif_sira]
	ana.secili_kart_index = -1
	ana.secili_piyon_index = -1
	ana.aktif_oyuncu_aksiyon_hakki = 3 if ana.ilk_tur_bitti else 0
	
	if ana.ilk_tur_bitti:
		ana.arayuz.olay_yaz("[color=yellow]➔ TUR %d:[/color] Sıra %s oyuncusunda! (⚡3 AP yenilendi)" % [ana.tur_sayaci, ana.arayuz.renkli_isim(aktif_oyuncu_ismi)])
	else:
		ana.arayuz.olay_yaz("[color=yellow]➔ TUR %d:[/color] Sıra %s oyuncusunda! Şehrini kur." % [ana.tur_sayaci, ana.arayuz.renkli_isim(aktif_oyuncu_ismi)])
		
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
