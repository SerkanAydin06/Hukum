extends Node
class_name AksiyonInsa

var aksiyon: Node
var ana: Node

func baslat(_aksiyon):
	aksiyon = _aksiyon
	ana = aksiyon.ana

func _sehir_kur_basildi():
	if ana.oyuncular.size() == 0 or ana.aktif_sira != ana.benim_indexim or ana.sehir_merkezleri[ana.oyuncular[ana.benim_indexim]]: return
	if ana.secilen_baslangic_biyomu == "":
		ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Şehrini kurmadan önce Çim, Orman veya Dağ arasından bir seçim yapmalısın![/color]"))
		return
	ana.insa_modu_aktif = true
	ana.arayuz.arayuzu_guncelle()
	ana.arayuz.olay_yaz(tr("[color=yellow]📍 Haritada şehrini kurmak istediğin SİSLİ BÖLGEYE tıkla.[/color]"))

func _kurulabilir_hexleri_hesapla(kart):
	ana.kurulabilir_hexler.clear()
	var k_isim = ana.oyuncular[ana.benim_indexim]
	var hedef = kart.get("hedef", "")
	var tur = kart.get("tur", "")

	# Eğer bu bir yükseltme (gelişim) kartıysa
	if hedef == "kendi_binasi":
		for koor in ana.binalar_verisi:
			var b = ana.binalar_verisi[koor]
			if b["sahip"] == k_isim and b.get("seviye", 1) < 3 and (kart.get("bina_turu") == "joker" or b["tur"] == kart.get("bina_turu", "")):
				ana.kurulabilir_hexler.append(koor)
	
	# Eğer bu bir sıfırdan inşa kartıysa
	else:
		var istenen_biyom = ""
		if tur == "oduncu_kampi": istenen_biyom = "orman"
		elif tur == "tas_ocagi": istenen_biyom = "dag"
		elif tur in ["tarla", "oncu_kampi", "ev", "kisla", "ticaret_merkezi"]: istenen_biyom = "cim"
		
		# Kendi kontrolümüzdeki topraklara bakıyoruz
		for koor in ana.kontrol_edilen_hexler:
			if ana.kontrol_edilen_hexler[koor] == k_isim:
				# Hexin üzerinde halihazırda başka bir bina YOKSA
				if not ana.binalar_verisi.has(koor):
					# Biyom kontrolü (İstenen bir biyom varsa ona uymalı, yoksa her yere kurulur)
					if istenen_biyom == "" or ana.harita.kesfedilen_hexler.get(koor, "") == istenen_biyom:
						ana.kurulabilir_hexler.append(koor)

func _kart_ve_harita_etkilesimi(k, k_isim):
	var kart = ana.deste.el[ana.secili_kart_index]
	if kart["hedef"] == "kendi_binasi":
		if not ana.binalar_verisi.has(k):
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Geliştirmek için kendi binanı seçmelisin![/color]"))
			return
		if ana.binalar_verisi[k]["sahip"] != k_isim:
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Bu bina sana ait değil![/color]"))
			return
		if kart["bina_turu"] != "joker" and kart["bina_turu"] != ana.binalar_verisi[k]["tur"]:
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Bu kart sadece '%s' binasını geliştirebilir![/color]") % kart["bina_turu"])
			return
		if ana.binalar_verisi[k].get("seviye", 1) >= 3:
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Bu bina zaten maksimum (Seviye 3) seviyede![/color]"))
			return
		if ana.oyuncu_kaynaklari[k_isim]["odun"] < kart["odun_maliyet"] or ana.oyuncu_kaynaklari[k_isim]["tas"] < kart["tas_maliyet"]:
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Yetersiz Kaynak! Gerekli: %d 🌲, %d 🪨[/color]") % [kart["odun_maliyet"], kart["tas_maliyet"]])
			return

		ana.istek("aksiyon", "bina_yukselt_rpc", [k_isim, k, kart["odun_maliyet"], kart["tas_maliyet"], ana.secili_kart_index])
		ana.secili_kart_index = -1
		
	elif kart["hedef"] == "harita":
		if ana.kontrol_edilen_hexler.get(k) != k_isim:
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Buraya inşa edemezsin! Önce Öncü ile bölgeyi ele geçir (🚩).[/color]"))
			return
		if ana.binalar_verisi.has(k):
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Bu alanda zaten bir yapı var![/color]"))
			return
			
		var biyom = ana.harita.kesfedilen_hexler.get(k, "")
		if kart["tur"] in ["kisla", "oncu_kampi", "ev", "ticaret_merkezi", "tarla"] and biyom != "cim":
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Bu bina sadece ÇİM araziye kurulabilir![/color]"))
			return
		if kart["tur"] == "oduncu_kampi" and biyom != "orman":
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Oduncu Kampı sadece ORMAN araziye kurulabilir![/color]"))
			return
		if kart["tur"] == "tas_ocagi" and biyom != "dag":
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Taş Ocağı sadece DAĞLIK araziye kurulabilir![/color]"))
			return

		if ana.oyuncu_kaynaklari[k_isim]["odun"] < kart["odun_maliyet"] or ana.oyuncu_kaynaklari[k_isim]["tas"] < kart["tas_maliyet"]:
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Yetersiz Kaynak! Gerekli: %d 🌲, %d 🪨[/color]") % [kart["odun_maliyet"], kart["tas_maliyet"]])
			return
			
		ana.istek("aksiyon", "kart_oyna_rpc", [k_isim, kart["tur"], k, kart["odun_maliyet"], kart["tas_maliyet"], ana.secili_kart_index])
		ana.secili_kart_index = -1
		
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
