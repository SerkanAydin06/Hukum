extends Node
class_name AksiyonSavasTetik

var aksiyon: Node
var ana: Node

func baslat(_aksiyon):
	aksiyon = _aksiyon
	ana = aksiyon.ana

func _piyon_hareket_aksiyon(k, k_isim):
	var mevcut_p_pos = ana.piyonlar[ana.secili_piyon_index]["koordinat"]
	
	if not ana.harita.hex_komsu_mu(mevcut_p_pos, k):
		ana.arayuz.olay_yaz("[color=light_coral]❌ Öncüler sadece hemen yanlarındaki (komşu) alanlara girip keşfedebilir![/color]")
		return
		
	if ana.oyuncu_kaynaklari[k_isim]["yiyecek"] < 1:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Hareket etmek/Keşfetmek için en az 1 Yiyecek gerekli![/color]")
		return
		
	if not ana.harita.kesfedilen_hexler.has(k):
		aksiyon.kesif_ve_hareket_rpc.rpc(ana.secili_piyon_index, k, k_isim)
		return
		
	# 🟢 1. BİNA SALDIRISI (%BinaSaldiriPaneli)
	if ana.binalar_verisi.has(k) and ana.binalar_verisi[k]["sahip"] != k_isim:
		var b_sahip = ana.binalar_verisi[k]["sahip"] # <-- YENİ İSİM (Bina Sahibi)
		if ana.muttefik_mi(k_isim, b_sahip):
			ana.arayuz.olay_yaz("[color=yellow]🤝 Dost veya Müttefik yapılarına saldıramazsın![/color]")
			return
			
		var garnizon_idx = -1
		for i in range(ana.piyonlar.size()):
			if ana.piyonlar[i]["koordinat"] == k and ana.piyonlar[i]["sahip"] != k_isim: 
				garnizon_idx = i
				
		ana.bekleyen_onay = "savas"
		ana.savas.savas_bina_koordinat = k
		ana.savas.savas_piyon_savunan = garnizon_idx
		
		# Binanın ve Hex'in toplam savunma gücünü hesapla
		var b_tur = ana.binalar_verisi[k]["tur"]
		var b_isim = b_tur.to_upper().replace("_", " ")
		var b_lvl = ana.binalar_verisi[k].get("seviye", 1)
		
		var def_degeri = ana.savas.savunma_gucu(k)

		var b_panel = ana.arayuz.get_node_or_null("%BinaSaldiriPaneli")
		if b_panel:
			var lbl_sahip = ana.arayuz.get_node_or_null("%BinaSahip")
			if lbl_sahip: lbl_sahip.text = b_sahip
			
			var lbl_isim = ana.arayuz.get_node_or_null("%BinaIsim")
			if lbl_isim: lbl_isim.text = b_isim
			
			var lbl_guc = ana.arayuz.get_node_or_null("%SavunmaGucu")
			if lbl_guc: lbl_guc.text = str(def_degeri)
			
			# 🟢 ŞEHİR MERKEZİ İSE: Sadece Hükmet var, Yık yok.
			# 🟢 DİĞER BİNALAR İSE: Yık var, Hükmet yok.
			var btn_hukmet = ana.arayuz.get_node_or_null("%BinaHukmetBtn")
			if btn_hukmet: btn_hukmet.visible = (b_tur == "sehir_merkezi")
			
			var btn_yik = ana.arayuz.get_node_or_null("%BinaYikBtn")
			if btn_yik: btn_yik.visible = (b_tur != "sehir_merkezi")
			
			b_panel.visible = true
		return
		
	# 🟢 2. ÖNCÜ VEYA DÜŞMAN BÖLGESİ SALDIRISI (%SavasOnayPaneli)
	var r_idx = -1
	var d_sahip = "" # <-- YENİ İSİM (Düşman Sahibi)
	
	for i in range(ana.piyonlar.size()):
		if ana.piyonlar[i]["koordinat"] == k and ana.piyonlar[i]["sahip"] != k_isim: 
			r_idx = i
			d_sahip = ana.piyonlar[i]["sahip"]
			break
			
	# Eğer bölgede düşman öncüsü yoksa ama düşman bölgesiyse
	if d_sahip == "":
		var hex_sahip = ana.kontrol_edilen_hexler.get(k, "")
		if hex_sahip != "" and hex_sahip != k_isim:
			d_sahip = hex_sahip
	
	if d_sahip != "":
		if ana.muttefik_mi(k_isim, d_sahip):
			ana.arayuz.olay_yaz("[color=yellow]🤝 Dost veya Müttefik birliklerine/bölgesine saldıramazsın![/color]")
			return
			
		ana.bekleyen_onay = "savas"
		ana.savas.savas_piyon_savunan = r_idx
		ana.savas.savas_bina_koordinat = k
		ana.savas.savas_ozel_savunucu = d_sahip
		
		var s_panel = ana.arayuz.get_node_or_null("%SavasOnayPaneli")
		if s_panel:
			var lbl_sal = ana.arayuz.get_node_or_null("%SaldiranIsim")
			if lbl_sal: lbl_sal.text = k_isim
			
			var lbl_sav = ana.arayuz.get_node_or_null("%SavunanIsim")
			if lbl_sav: lbl_sav.text = d_sahip
			
			var tex_sal = ana.arayuz.get_node_or_null("%SaldiranResim")
			if tex_sal:
				var sal_no = ana.oyuncu_profil_no.get(k_isim, 1)
				var sal_yol = "res://Assets/Resimler/Profil%d.png" % sal_no
				tex_sal.texture = load(sal_yol) if ResourceLoader.exists(sal_yol) else null
				
			var tex_sav = ana.arayuz.get_node_or_null("%SavunanResim")
			if tex_sav:
				var sav_no = ana.oyuncu_profil_no.get(d_sahip, 1)
				var sav_yol = "res://Assets/Resimler/Profil%d.png" % sav_no
				tex_sav.texture = load(sav_yol) if ResourceLoader.exists(sav_yol) else null
				
			s_panel.visible = true
	else:
		# Piyon da yok, bina da yok, düşman toprağı da değil -> Normal Hareket
		aksiyon.piyon_hareket_rpc.rpc(ana.secili_piyon_index, k)
		
	ana.arayuz.arayuzu_guncelle()


# ==========================================
# 🟢 SAVAŞ BUTON AKSİYONLARI 
# ==========================================

func _tetikle_saldiri(): # (%SaldirBtn)
	var s_panel = ana.arayuz.get_node_or_null("%SavasOnayPaneli")
	if s_panel: s_panel.visible = false
	aksiyon.savas_baslat_rpc.rpc(ana.secili_piyon_index, ana.savas.savas_piyon_savunan, ana.savas.savas_bina_koordinat.x, ana.savas.savas_bina_koordinat.y, "normal", ana.oyuncular[ana.benim_indexim], ana.savas.savas_ozel_savunucu)

func _tetikle_savas_iptal(): # (%SaldiriIptalBtn)
	var s_panel = ana.arayuz.get_node_or_null("%SavasOnayPaneli")
	if s_panel: s_panel.visible = false
	ana.bekleyen_onay = ""
	ana.arayuz.arayuzu_guncelle()

func _tetikle_yagmala(): # (%BinaYagmalaBtn)
	var b_panel = ana.arayuz.get_node_or_null("%BinaSaldiriPaneli")
	if b_panel: b_panel.visible = false
	aksiyon.savas_baslat_rpc.rpc(ana.secili_piyon_index, ana.savas.savas_piyon_savunan, ana.savas.savas_bina_koordinat.x, ana.savas.savas_bina_koordinat.y, "yagmala")

func _tetikle_hukmet(): # (%BinaHukmetBtn)
	var b_panel = ana.arayuz.get_node_or_null("%BinaSaldiriPaneli")
	if b_panel: b_panel.visible = false
	aksiyon.savas_baslat_rpc.rpc(ana.secili_piyon_index, ana.savas.savas_piyon_savunan, ana.savas.savas_bina_koordinat.x, ana.savas.savas_bina_koordinat.y, "hukmet")

func _tetikle_yikim(): # (%BinaYikBtn)
	var b_panel = ana.arayuz.get_node_or_null("%BinaSaldiriPaneli")
	if b_panel: b_panel.visible = false
	aksiyon.savas_baslat_rpc.rpc(ana.secili_piyon_index, ana.savas.savas_piyon_savunan, ana.savas.savas_bina_koordinat.x, ana.savas.savas_bina_koordinat.y, "yikim")

func _tetikle_bina_saldiri_vazgec(): # (%BinaVazgecBtn)
	var b_panel = ana.arayuz.get_node_or_null("%BinaSaldiriPaneli")
	if b_panel: b_panel.visible = false
	ana.bekleyen_onay = ""
	ana.arayuz.arayuzu_guncelle()


# ==========================================
# DİĞER FONKSİYONLAR
# ==========================================

func _savas_karti_cek():
	if ana.aktif_sira != ana.benim_indexim or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	var k_isim = ana.oyuncular[ana.benim_indexim]
	var savas_karti_sayisi = 0
	for kart in ana.deste.el:
		if kart.get("hedef") == "savas":
			savas_karti_sayisi += 1
	if savas_karti_sayisi >= ana.deste.MAX_EL_LIMITI:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Elinde zaten maksimum (7) Savaş Kartı var![/color]")
		return
	if ana.oyuncu_kaynaklari[k_isim]["altin"] < 3:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Savaş kartı çekmek için 3 Altın gerekli![/color]")
		return
	aksiyon.savas_karti_cek_rpc.rpc_id(1, k_isim)
	ana.arayuz.panel_yukari_cik()
	
func _oncu_uret_istegi():
	if ana.aktif_sira != ana.benim_indexim or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	var ben = ana.oyuncular[ana.benim_indexim]
	if ana.oyuncu_kaynaklari[ben]["yiyecek"] >= 5:
		var s_koor = Vector2i(-1, -1)
		for k in ana.binalar_verisi:
			if ana.binalar_verisi[k]["tur"] == "oncu_kampi" and ana.binalar_verisi[k]["sahip"] == ben:
				s_koor = k
				break
		if s_koor != Vector2i(-1, -1): 
			aksiyon.oncu_uret_rpc.rpc(ben, s_koor)
		else: 
			ana.arayuz.olay_yaz("[color=light_coral]❌ Öncü Kampı bulunamadı![/color]")
	else:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Öncü üretmek için 5 Yiyecek gerekli![/color]")

func _hakimiyet_kur_istegi():
	if ana.aktif_sira != ana.benim_indexim or ana.secili_piyon_index == -1 or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	var k_isim = ana.oyuncular[ana.benim_indexim]
	if ana.oyuncu_kaynaklari[k_isim]["yiyecek"] >= 3:
		var p_koor = ana.piyonlar[ana.secili_piyon_index]["koordinat"]
		aksiyon.hakimiyet_kur_rpc.rpc(k_isim, p_koor)
		ana.secili_piyon_index = -1
		ana.arayuz.arayuzu_guncelle()
	else:
		ana.arayuz.olay_yaz("[color=light_coral]❌ Bölgede hakimiyet kurmak için en az 3 Yiyecek gerekli![/color]")

func _isyan_btn_basildi():
	if ana.aktif_sira != ana.benim_indexim or ana.aktif_oyuncu_aksiyon_hakki <= 0:
		ana.arayuz.olay_yaz("[color=light_coral]❌ İsyan başlatmak için 1 AP gereklidir ve sıra sizde olmalıdır![/color]")
		return
	var k_isim = ana.oyuncular[ana.benim_indexim]
	var efendim = ana.efendiler.get(k_isim, "")
	if efendim == "": return
	
	var k = ana.oyuncu_kaynaklari[k_isim]
	if k["odun"] < 10 or k["tas"] < 10 or k["yiyecek"] < 10:
		ana.arayuz.olay_yaz("[color=light_coral]❌ İsyan hazırlığı yetersiz! Ordu kurabilmek için en az 10 🌲, 10 🪨 ve 10 🌾 stoklamalısın![/color]")
		return
		
	if ana.arayuz.isyan_onay_paneli: ana.arayuz.isyan_onay_paneli.visible = true
	ana.arayuz.arayuzu_guncelle()

func _isyan_onaylandi():
	var k_isim = ana.oyuncular[ana.benim_indexim]
	var efendim = ana.efendiler.get(k_isim, "")
	aksiyon.savas_baslat_rpc.rpc(-1, -1, -1, -1, "isyan_buton", k_isim, efendim)
	if ana.arayuz.isyan_onay_paneli: ana.arayuz.isyan_onay_paneli.visible = false
