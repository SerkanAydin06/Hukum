extends Node
class_name ArayuzYonetici

@onready var ana = get_parent() as AnaOyun

# --- ALT YÖNETİCİLER (Modüller) ---
var log_yonetici: ArayuzLog
var diplomasi_yonetici: ArayuzDiplomasi
var panel_yonetici: ArayuzPanel

var flas_alfa = 0.4
var flas_yonu = 1
var sehir_kuruldu_animasyon_yapildi = false

# --- SAHNE REFERANSLARI ---
@onready var puan_konteyner = %PuanKonteyner
@onready var savas_deste_btn = %SavasDesteBtn
@onready var insa_deste_btn = %InsaDesteBtn
@onready var son_savas_paneli = get_node_or_null("%SonSavasPaneli")
@onready var insa_destesi_panel = %InsaDestesiPanel
@onready var savas_destesi_panel = %SavasDestesiPanel
@onready var insa_kart_eli_konteyner = %InsaKartEliKonteyner
@onready var savas_kart_eli_konteyner = %SavasKartEliKonteyner
@onready var alt_orta_panel = get_node_or_null("%AltOrtaPanel")
@onready var ap_label = %APLabel
@onready var tur_yazisi = %TurYazisi
@onready var tur_butonu = %TurButonu
@onready var vasal_paneli = %VasalPaneli
@onready var vasal_bilgi_label = %VasalBilgiLabel
@onready var isyan_btn = %IsyanBtn
@onready var isyan_onay_paneli = %IsyanOnayPaneli
@onready var isyan_evet_butonu = %IsyanEvetButonu
@onready var isyan_hayir_butonu = %IsyanHayirButonu
@onready var ticaret_btn = %TicaretBtn
@onready var ticaret_paneli = %TicaretPaneli
@onready var odun_sat_btn = %OdunSatBtn
@onready var tas_sat_btn = %TasSatBtn
@onready var yiyecek_sat_btn = %YiyecekSatBtn
@onready var ticaret_kapat_btn = %TicaretKapatBtn
@onready var kurulum_paneli = %KurulumPaneli
@onready var cim_btn = %CimBtn
@onready var orman_btn = %OrmanBtn
@onready var dag_btn = %DagBtn
@onready var insa_cek_btn = %InsaCekBtn
@onready var savas_cek_btn = %SavasCekBtn
@onready var oncu_uret_btn = %OncuUretBtn
@onready var hakimiyet_paneli = %HakimiyetPaneli
@onready var hakimiyet_kur_btn = %HakimiyetKurBtn
@onready var hakimiyet_vazgec_btn = get_node_or_null("%VazgecBtn")
@onready var olay_logu = %OlayLogu
@onready var olay_paneli = %OlayPaneliKonteyner

# 🟢 YENİ SAVAŞ PANELLERİ
@onready var savas_onay_paneli = get_node_or_null("%SavasOnayPaneli")
@onready var bina_saldiri_paneli = get_node_or_null("%BinaSaldiriPaneli")

# Kaynak ve Logo Referansları
@onready var medeniyet_logo = %MedeniyetLogo
@onready var odun_miktar = %OdunMiktar
@onready var odun_uretim = %OdunUretim
@onready var tas_miktar = %TasMiktar
@onready var tas_uretim = %TasUretim
@onready var yiyecek_miktar = %YiyecekMiktar
@onready var yiyecek_uretim = %YiyecekUretim
@onready var altin_miktar = %AltinMiktar
@onready var altin_uretim = %AltinUretim

# --- KURULUM ONAY PANELİ VE BUTONLARI ---
@onready var kurulum_onay_paneli = get_node_or_null("%KurulumOnayPanel")
@onready var kurulum_evet_btn = get_node_or_null("%KurulumEvetBtn")
@onready var kurulum_hayir_btn = get_node_or_null("%KurulumHayirBtn")
@onready var onay_hexi_texture = get_node_or_null("%OnayHexi")

# --- DESTELER VE KALANLAR PANELLERİ ---
@onready var insa_deste_kalanlar_panel = get_node_or_null("%InsaDesteKalanlar")
@onready var savas_deste_kalanlar_panel = get_node_or_null("%SavasDesteKalanlar")

# --- ŞEHİR KURULUMU ÖNCESİ GİZLENECEK PANELLER ---
@onready var secim_paneli = get_node_or_null("%SecimPaneli")
@onready var olay_paneli_ui = get_node_or_null("%OlayPaneli")
@onready var zafer_paneli = get_node_or_null("%ZaferPaneli")
@onready var ticaret_oncu_vbox = get_node_or_null("%TicaretOncuVBox")
@onready var ust_panel = get_node_or_null("%UstPanel")
@onready var Insa_destesi_paneli = get_node_or_null("%InsaDestesiPanel")
@onready var Savas_destesi_paneli = get_node_or_null("%SavasDestesiPanel")
@onready var ap_uyari_paneli = get_node_or_null("%ApUyariPaneli")

var medeniyet_gorunumu: Node

var insa_hover_timer = 0.0
var savas_hover_timer = 0.0
var insa_fare_ustunde = false
var savas_fare_ustunde = false
const HOVER_SURESI = 0.35 

var biyom_resimleri = {
	"cim": "res://Assets/Resimler/hex/cimen.png",
	"orman": "res://Assets/Resimler/hex/orman.png",
	"dag": "res://Assets/Resimler/hex/dag.png"
}

var flama_resimleri = {
	"Osmanlı": preload("res://Assets/Flamalar/osmanli_flama.png"),
	"Venedik": preload("res://Assets/Flamalar/venedik_flama.png"),
	"Mısır": preload("res://Assets/Flamalar/misir_flama.png"),
	"Moğol": preload("res://Assets/Flamalar/mogol_flama.png"),
	"Bizans": preload("res://Assets/Flamalar/bizans_flama.png"),
	"Viking": preload("res://Assets/Flamalar/viking_flama.png")
}

var dosya_isimleri = {
	"Osmanlı": "osmanli",
	"Venedik": "venedik",
	"Mısır": "misir",
	"Moğol": "mogol",
	"Bizans": "bizans",
	"Viking": "viking"
}

func _tur_normalize(text: String) -> String:
	return text.to_lower() \
		.replace("ı", "i").replace("İ", "i") \
		.replace("ş", "s").replace("Ş", "s") \
		.replace("ç", "c").replace("Ç", "c") \
		.replace("ğ", "g").replace("Ğ", "g") \
		.replace("ö", "o").replace("Ö", "o") \
		.replace("ü", "u").replace("Ü", "u") \
		.replace(" ", "_").replace("-", "_")

func _ready():
	if vasal_paneli: vasal_paneli.visible = false
	if isyan_onay_paneli: isyan_onay_paneli.visible = false
	if ticaret_paneli: ticaret_paneli.visible = false
	if kurulum_paneli: kurulum_paneli.visible = false
	if hakimiyet_paneli: hakimiyet_paneli.visible = false
	if kurulum_onay_paneli: kurulum_onay_paneli.visible = false
	if insa_deste_kalanlar_panel: insa_deste_kalanlar_panel.visible = false
	if savas_deste_kalanlar_panel: savas_deste_kalanlar_panel.visible = false
	if ap_uyari_paneli: ap_uyari_paneli.visible = false
	if savas_onay_paneli: savas_onay_paneli.visible = false
	if bina_saldiri_paneli: bina_saldiri_paneli.visible = false
	if son_savas_paneli: son_savas_paneli.visible = false 
	
	# 🟢 Oyun başında bu paneller ve tur butonu gizleniyor, şeffaflıkları 0 yapılıyor
	_paneli_sifirla(secim_paneli)
	_paneli_sifirla(olay_paneli_ui)
	_paneli_sifirla(zafer_paneli)
	_paneli_sifirla(ticaret_oncu_vbox)
	_paneli_sifirla(alt_orta_panel)
	_paneli_sifirla(ust_panel)
	_paneli_sifirla(tur_butonu)
	_paneli_sifirla(insa_destesi_panel)
	
	if cim_btn: cim_btn.toggle_mode = true
	if orman_btn: orman_btn.toggle_mode = true
	if dag_btn: dag_btn.toggle_mode = true
	
	log_yonetici = ArayuzLog.new()
	add_child(log_yonetici)
	log_yonetici.baslat(self)
	
	diplomasi_yonetici = ArayuzDiplomasi.new()
	add_child(diplomasi_yonetici)
	diplomasi_yonetici.baslat(self)
	
	panel_yonetici = ArayuzPanel.new()
	add_child(panel_yonetici)
	panel_yonetici.baslat(self)

func _paneli_sifirla(panel):
	if panel:
		panel.visible = false
		panel.modulate.a = 0.0
	
func _process(delta):
	if ana.kart_insa_modu_aktif and ana.kurulabilir_hexler.size() > 0:
		flas_alfa += delta * flas_yonu * 2.5
		if flas_alfa >= 0.65:
			flas_alfa = 0.65
			flas_yonu = -1
		elif flas_alfa <= 0.15:
			flas_alfa = 0.15
			flas_yonu = 1
		ana.harita.queue_redraw()
		
	if hakimiyet_paneli and hakimiyet_paneli.visible:
		if ana.secili_piyon_index != -1 and ana.secili_piyon_index < ana.piyonlar.size():
			var p_koor = ana.piyonlar[ana.secili_piyon_index]["koordinat"]
			var dunya_pos = ana.harita.hex_merkezi_hesapla(p_koor.x, p_koor.y)
			var ekran_koordinati = ana.harita.get_global_transform_with_canvas() * dunya_pos
			hakimiyet_paneli.global_position = Vector2(ekran_koordinati.x - (hakimiyet_paneli.size.x / 2.0), ekran_koordinati.y - 110.0)

	if insa_fare_ustunde:
		insa_hover_timer += delta
		if insa_hover_timer >= HOVER_SURESI:
			if insa_deste_kalanlar_panel and not insa_deste_kalanlar_panel.visible:
				insa_deste_kalanlar_panel.visible = true
	
	if savas_fare_ustunde:
		savas_hover_timer += delta
		if savas_hover_timer >= HOVER_SURESI:
			if savas_deste_kalanlar_panel and not savas_deste_kalanlar_panel.visible:
				savas_deste_kalanlar_panel.visible = true
	
func tur_buton_resimlerini_guncelle(medeniyet_adi: String):
	if not is_instance_valid(medeniyet_gorunumu):
		if not ResourceLoader.exists("res://UI/CivilizationStyle.gd"): return
		medeniyet_gorunumu = load("res://UI/CivilizationStyle.gd").new()
		add_child(medeniyet_gorunumu)
	medeniyet_gorunumu.apply_to(ana, medeniyet_adi)

func olay_yaz(metin: String):
	log_yonetici.olay_yaz(metin)

func panel_yukari_cik():
	pass

func panel_asagi_indir():
	panel_yonetici.zorla_asagi_indir()

func eldeki_kartlari_filtrele():
	panel_yonetici.eldeki_kartlari_filtrele()

func arayuzu_guncelle():
	ana.zaferi_kontrol_et()
	if ana.oyuncular.size() == 0: return
	var k_isim = ana.oyuncular[ana.benim_indexim]
	var k = ana.oyuncu_kaynaklari[k_isim]
	
	# 🟢 AP değerini burada güvenle tanımlıyoruz
	var ap = ana.aktif_oyuncu_aksiyon_hakki if ana.ilk_tur_bitti and ana.aktif_sira == ana.benim_indexim else 3
	
	if ana and "deste" in ana:
		var kalan_insa_sayilari = {
			"tarla": 0, "oduncu_kampi": 0, "tas_ocagi": 0, 
			"ticaret_merkezi": 0, "gelismis_sulama": 0, 
			"baltalari_bileme": 0, "derin_damarlar": 0
		}
		for kart in ana.deste.normal_deste:
			var t = kart.get("tur", kart.get("turu", ""))
			var temiz_t = _tur_normalize(t)
			for key in kalan_insa_sayilari.keys():
				if _tur_normalize(key) == temiz_t:
					kalan_insa_sayilari[key] += 1
					break
		
		var lbl_tarla = get_node_or_null("%KalanTarla")
		if lbl_tarla: lbl_tarla.text = str(kalan_insa_sayilari["tarla"])
		
		var lbl_oduncu = get_node_or_null("%KalanOduncu")
		if lbl_oduncu: lbl_oduncu.text = str(kalan_insa_sayilari["oduncu_kampi"])
		
		var lbl_tasci = get_node_or_null("%KalanTasci")
		if lbl_tasci: lbl_tasci.text = str(kalan_insa_sayilari["tas_ocagi"])
		
		var lbl_ticaret = get_node_or_null("%KalanTicaretMerkezi")
		if lbl_ticaret: lbl_ticaret.text = str(kalan_insa_sayilari["ticaret_merkezi"])
		
		var lbl_sulama = get_node_or_null("%KalanGelismisSulama")
		if lbl_sulama: lbl_sulama.text = str(kalan_insa_sayilari["gelismis_sulama"])
		
		var lbl_balta = get_node_or_null("%KalanBaltalariBileme")
		if lbl_balta: lbl_balta.text = str(kalan_insa_sayilari["baltalari_bileme"])
		
		var lbl_damar = get_node_or_null("%KalanDerinDamarlar")
		if lbl_damar: lbl_damar.text = str(kalan_insa_sayilari["derin_damarlar"])

	if ana and "deste" in ana:
		var kalan_savas_sayilari = {
			"piyade": 0, "okcu": 0, "suvari": 0, 
			"mancinik": 0, "kocbasi": 0, "komutan": 0
		}
		for kart in ana.deste.savas_destesi:
			var t = kart.get("tur", kart.get("turu", ""))
			var temiz_t = _tur_normalize(t)
			for key in kalan_savas_sayilari.keys():
				if _tur_normalize(key) == temiz_t:
					kalan_savas_sayilari[key] += 1
					break
		
		var lbl_piyade = get_node_or_null("%KalanPiyade")
		if lbl_piyade: lbl_piyade.text = str(kalan_savas_sayilari["piyade"])
		
		var lbl_okcu = get_node_or_null("%KalanOkcu")
		if lbl_okcu: lbl_okcu.text = str(kalan_savas_sayilari["okcu"])
		
		var lbl_suvari = get_node_or_null("%KalanSuvari")
		if lbl_suvari: lbl_suvari.text = str(kalan_savas_sayilari["suvari"])
		
		var lbl_mancinik = get_node_or_null("%KalanMancinik")
		if lbl_mancinik: lbl_mancinik.text = str(kalan_savas_sayilari["mancinik"])
		
		var lbl_kocbasi = get_node_or_null("%KalanKocbasi")
		if lbl_kocbasi: lbl_kocbasi.text = str(kalan_savas_sayilari["kocbasi"])
		
		var lbl_komutan = get_node_or_null("%KalanKomutan")
		if lbl_komutan: lbl_komutan.text = str(kalan_savas_sayilari["komutan"])
	
	var savas_destesi_kalan_lbl = get_node_or_null("%SavasDestesiKalan")
	if savas_destesi_kalan_lbl and ana and "deste" in ana:
		savas_destesi_kalan_lbl.text = str(ana.deste.savas_kalan)

	var insa_destesi_kalan_lbl = get_node_or_null("%InsaDestesiKalan")
	if insa_destesi_kalan_lbl and ana and "deste" in ana:
		insa_destesi_kalan_lbl.text = str(ana.deste.normal_kalan)
	
	if ap_label:
		var ap_metni = ""
		var ap_renk = Color.WHITE
		
		if not ana.ilk_tur_bitti:
			ap_metni = "0/0"
			ap_renk = Color.GRAY
		elif ana.aktif_sira != ana.benim_indexim:
			ap_metni = "⏳"
			ap_renk = Color.LIGHT_GRAY
		else:
			ap_metni = "%d/3" % ap
			
			if ap >= 3: ap_renk = Color(0.3, 0.9, 0.3)
			elif ap == 2: ap_renk = Color(0.7, 0.9, 0.2)
			elif ap == 1: ap_renk = Color(1.0, 0.8, 0.1)
			else: ap_renk = Color(0.9, 0.3, 0.3)
				
		ap_label.text = ap_metni
		if ap_label.has_method("add_theme_color_override"):
			ap_label.add_theme_color_override("font_color", ap_renk)
			
		# 🟢 AP uyarısı
		if ap_uyari_paneli and ana.ilk_tur_bitti and ana.aktif_sira == ana.benim_indexim:
			ap_uyari_paneli.visible = (ap == 0)
		else:
			if ap_uyari_paneli: ap_uyari_paneli.visible = false
			
	tur_yazisi.text = "TUR %d" % ana.tur_sayaci
		
	var oyun_sirasi_label = get_node_or_null("%Oyunsirasi")
	if oyun_sirasi_label:
		var aktif_oyuncu_ismi = ana.oyuncular[ana.aktif_sira]
		var aktif_medeniyet = ana.medeniyetler_verisi.get(aktif_oyuncu_ismi, "Bilinmiyor")
		oyun_sirasi_label.text = "Sıra: %s (%s)" % [aktif_oyuncu_ismi, aktif_medeniyet]

	var med_ad = ana.medeniyetler_verisi.get(k_isim, "")
	if med_ad != "" and flama_resimleri.has(med_ad):
		medeniyet_logo.texture = flama_resimleri[med_ad]
		tur_buton_resimlerini_guncelle(med_ad)

	var u = ana.tur_ekonomi._oyuncu_net_uretimini_hesapla(k_isim)
	_kaynak_guncelle(odun_miktar, odun_uretim, k["odun"], u["net"]["odun"], u["ham"]["odun"], u["kesinti"]["odun"])
	_kaynak_guncelle(tas_miktar, tas_uretim, k["tas"], u["net"]["tas"], u["ham"]["tas"], u["kesinti"]["tas"])
	_kaynak_guncelle(yiyecek_miktar, yiyecek_uretim, k["yiyecek"], u["net"]["yiyecek"], u["ham"]["yiyecek"], u["kesinti"]["yiyecek"])
	_kaynak_guncelle(altin_miktar, altin_uretim, k["altin"], u["net"]["altin"], u["ham"]["altin"], u["kesinti"]["altin"])

	diplomasi_yonetici.skor_guncelle()
	
	var sira_bende_mi = (ana.aktif_sira == ana.benim_indexim)
	var isyan_ekrani_acik = isyan_onay_paneli and isyan_onay_paneli.visible
	var so_acik = savas_onay_paneli and savas_onay_paneli.visible
	var bs_acik = bina_saldiri_paneli and bina_saldiri_paneli.visible
	
	var savas_var_mi = ana.savas.savas_aktif or ana.savas.sonuc_gosteriliyor or isyan_ekrani_acik or so_acik or bs_acik
	var sehir_kuruldu_mu = ana.sehir_merkezleri.get(k_isim, false)
	
	if alt_orta_panel:
		alt_orta_panel.visible = sehir_kuruldu_mu and not savas_var_mi
		
	# 🟢 Şehir ilk kez kurulduğunda üst panel, tur butonu ve diğer paneller animasyonla fade-in yapıyor
	if sehir_kuruldu_mu and not sehir_kuruldu_animasyon_yapildi:
		sehir_kuruldu_animasyon_yapildi = true
		_panelleri_animasyonla_goster()
	elif not sehir_kuruldu_mu:
		sehir_kuruldu_animasyon_yapildi = false
		
	var ap_yok = (ana.aktif_oyuncu_aksiyon_hakki <= 0) or (not ana.ilk_tur_bitti) or savas_var_mi or (not sira_bende_mi)
	
	if kurulum_paneli:
		kurulum_paneli.visible = (sira_bende_mi and not sehir_kuruldu_mu and not ana.insa_modu_aktif and not savas_var_mi)

	var tic_maliyet = ana.tur_ekonomi.ticaret_maliyeti(k_isim)
	if ticaret_paneli:
		var pazar_basligi = ticaret_paneli.get_node_or_null("MarginContainer/VBoxContainer/Label")
		if pazar_basligi: pazar_basligi.text = "⚖️ PAZAR YERİ (%d Kaynak = 1 Altın)" % tic_maliyet
	if odun_sat_btn: odun_sat_btn.text = "%d Odun ➔ 1 Altın" % tic_maliyet
	if tas_sat_btn: tas_sat_btn.text = "%d Taş ➔ 1 Altın" % tic_maliyet
	if yiyecek_sat_btn: yiyecek_sat_btn.text = "%d Yiyecek ➔ 1 Altın" % tic_maliyet
	var tic_var = false
	for koor in ana.binalar_verisi:
		if ana.binalar_verisi[koor]["sahip"] == k_isim and ana.binalar_verisi[koor]["tur"] == "ticaret_merkezi": 
			tic_var = true
			break

	var kart_secili_mi = (ana.secili_kart_index != -1)

	if insa_cek_btn: 
		insa_cek_btn.visible = true
		insa_cek_btn.disabled = ap_yok or not sehir_kuruldu_mu
		
	if savas_cek_btn: 
		savas_cek_btn.visible = true
		savas_cek_btn.disabled = ap_yok or not sehir_kuruldu_mu
		
	if oncu_uret_btn: 
		oncu_uret_btn.visible = true
		var kamp_var = false
		for bina in ana.binalar_verisi.values():
			if bina["sahip"] == k_isim and bina["tur"] == "oncu_kampi": kamp_var = true
		oncu_uret_btn.disabled = ap_yok or not kamp_var or k["yiyecek"] < 5
		
	if ticaret_btn: 
		ticaret_btn.visible = true
		ticaret_btn.disabled = not sira_bende_mi or savas_var_mi or not tic_var

	if savas_deste_btn: savas_deste_btn.disabled = (not sehir_kuruldu_mu) or kart_secili_mi
	if insa_deste_btn: insa_deste_btn.disabled = (not sehir_kuruldu_mu) or kart_secili_mi
	
	if tur_butonu: tur_butonu.disabled = savas_var_mi or not sira_bende_mi
	
	diplomasi_yonetici.guncelle(k_isim, savas_var_mi)
	
	ana.deste.eldeki_kartlari_ciz()
	panel_yonetici.eldeki_kartlari_filtrele()

func _kaynak_guncelle(miktar_label: Label, uretim_label: RichTextLabel, miktar: int, net: int, ham: int, kesinti: int):
	miktar_label.text = str(miktar)
	
	if kesinti > 0:
		# 🟢 VASAL FORMATI: (5-3) +2/Tur  → ham yeşil, kesinti kırmızı, kalan+/Tur sarı/beyaz/kırmızı
		var kalan = ham - kesinti
		var kalan_renk = "yellow"
		var kalan_metin = "+%d" % kalan
		if kalan == 0:
			kalan_renk = "white"
			kalan_metin = "0"
		elif kalan < 0:
			kalan_renk = "red"
			kalan_metin = "%d" % kalan
		
		uretim_label.text = "([color=lightgreen]%d[/color]-[color=red]%d[/color]) [color=%s]%s/Tur[/color]" % [ham, kesinti, kalan_renk, kalan_metin]
	else:
		# 🟢 NORMAL FORMAT: rakam ve /tur aynı renkte
		var renk = "lightgreen"
		var metin = "+%d" % net
		if net == 0:
			renk = "white"
			metin = "0"
		elif net < 0:
			renk = "red"
			metin = "%d" % net
		
		uretim_label.text = "[color=%s]%s/tur[/color]" % [renk, metin]

func _paneli_fade_in_yap(panel):
	if not panel: return
	panel.visible = true
	panel.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _panelleri_animasyonla_goster():
	_paneli_fade_in_yap(secim_paneli)
	_paneli_fade_in_yap(olay_paneli_ui)
	_paneli_fade_in_yap(zafer_paneli)
	_paneli_fade_in_yap(ticaret_oncu_vbox)
	_paneli_fade_in_yap(alt_orta_panel)
	_paneli_fade_in_yap(ust_panel)
	_paneli_fade_in_yap(tur_butonu)
	_paneli_fade_in_yap(insa_destesi_panel)

func sag_paneli_guncelle(koordinat: Vector2i):
	var sahip_label = get_node_or_null("%SahipLabel")
	var arazi_label = get_node_or_null("%AraziLabel")
	var bina_label = get_node_or_null("%BinaLabel")
	var uretim_bilgi = get_node_or_null("%UretimBilgi")
	var savunma_bonus = get_node_or_null("%SavunmaBonus")
	var hex_resim = get_node_or_null("%HexResim")
	var secili_isim = get_node_or_null("%SeciliIsim")

	if not ana.harita.hex_gorunur_mu(koordinat) or not ana.harita.kesfedilen_hexler.has(koordinat):
		var sisli = not ana.harita.hex_gorunur_mu(koordinat)
		if arazi_label: arazi_label.text = "Sisli Arazi" if sisli else "Keşfedilmemiş"
		if sahip_label: sahip_label.text = "-"
		if bina_label: bina_label.text = "-"
		if uretim_bilgi: uretim_bilgi.text = "-"
		if savunma_bonus: savunma_bonus.text = "-"
		if secili_isim: secili_isim.text = "Sisli Bölge" if sisli else "Keşfedilmemiş Bölge"
		if hex_resim:
			var yol = "res://Assets/Resimler/hex/sis.png" if sisli else "res://Assets/Resimler/hex/kapali_hex.png"
			hex_resim.texture = load(yol) if ResourceLoader.exists(yol) else null
		return

	var biyom = ana.harita.kesfedilen_hexler[koordinat]
	var biyom_isim = "Çimenlik Arazi" if biyom == "cim" else "Ormanlık Arazi" if biyom == "orman" else "Dağlık Arazi" if biyom == "dag" else biyom
	if arazi_label: arazi_label.text = biyom_isim

	var piyon_sahibi = ""
	var piyon_var_mi = false
	for p in ana.piyonlar:
		if p.get("koordinat") == koordinat:
			piyon_var_mi = true
			piyon_sahibi = p.get("sahip", "")
			break

	var sahip_isim = ""
	if piyon_var_mi:
		sahip_isim = piyon_sahibi
	elif ana.binalar_verisi.has(koordinat):
		sahip_isim = ana.binalar_verisi[koordinat].get("sahip", "")
	elif ana.kontrol_edilen_hexler.has(koordinat):
		sahip_isim = ana.kontrol_edilen_hexler[koordinat]

	var medeniyet_adi = ""
	if sahip_isim != "":
		medeniyet_adi = ana.medeniyetler_verisi.get(sahip_isim, sahip_isim)
		if sahip_label: sahip_label.text = medeniyet_adi
	else:
		if sahip_label: sahip_label.text = "Sahipsiz"

	var bina_metni = "Yok"
	var uretim_metni = "Üretim Yok"
	var bina_var_mi = ana.binalar_verisi.has(koordinat)
	var isim_metni = ""
	var resim_yolu = ""
	
	if piyon_var_mi:
		isim_metni = "Öncü Birliği"
		bina_metni = "-"
		uretim_metni = "-"
		var med_dosya = dosya_isimleri.get(medeniyet_adi, "osmanli")
		resim_yolu = "res://Assets/Resimler/oncu/oncu_%s.png" % med_dosya
		
	elif bina_var_mi:
		var b = ana.binalar_verisi[koordinat]
		var b_tur = b["tur"]
		var lvl = b.get("seviye", 1)
		bina_metni = "%s (Seviye %d)" % [b_tur.to_upper().replace("_", " "), lvl]
		isim_metni = b_tur.to_upper().replace("_", " ")
		
		match b_tur:
			"sehir_merkezi":
				if biyom == "cim": uretim_metni = "+%d Yiyecek Üretimi" % lvl
				elif biyom == "orman": uretim_metni = "+%d Odun Üretimi" % lvl
				elif biyom == "dag": uretim_metni = "+%d Taş Üretimi" % lvl
			"tarla":
				uretim_metni = "+%d Yiyecek Üretimi" % (lvl + (1 if ana.medeniyetler_verisi.get(b["sahip"], "") == "Moğol" else 0))
			"oduncu_kampi":
				uretim_metni = "+%d Odun Üretimi" % lvl
			"tas_ocagi":
				uretim_metni = "+%d Taş Üretimi" % (lvl + (1 if ana.medeniyetler_verisi.get(b["sahip"], "") == "Mısır" else 0))
			"ticaret_merkezi":
				uretim_metni = "Ekonomik Ticaret Merkezi"
			"oncu_kampi":
				uretim_metni = "Öncü Üretimi: 5 Yiyecek + 1 AP"
				
		if b_tur == "sehir_merkezi":
			var med_dosya = dosya_isimleri.get(medeniyet_adi, "osmanli")
			resim_yolu = "res://Assets/Resimler/Sehirmerkezleri/sehirmerkezi_%s.png" % med_dosya
		else:
			# Bina görselleri dosya adlarında seviye taşır (oduncu1.png vb.).
			match b_tur:
				"oduncu_kampi":
					resim_yolu = "res://Assets/Resimler/binalar/oduncu%d.png" % clampi(lvl, 1, 3)
				"tas_ocagi":
					resim_yolu = "res://Assets/Resimler/binalar/tasocagi%d.png" % clampi(lvl, 1, 3)
				"tarla":
					resim_yolu = "res://Assets/Resimler/binalar/tarla%d.png" % clampi(lvl, 1, 3)
				"oncu_kampi":
					resim_yolu = "res://Assets/Resimler/kartresimleri/oncukampi_cadir.svg"
				"ticaret_merkezi":
					resim_yolu = "res://Assets/Resimler/binalar/ticaret_merkezi.png"
			
	else:
		isim_metni = biyom_isim
		var h_dosya = "cimen" if biyom == "cim" else "orman" if biyom == "orman" else "dag" if biyom == "dag" else biyom
		resim_yolu = "res://Assets/Resimler/hex/%s.png" % h_dosya
	
	if bina_label: bina_label.text = bina_metni
	if uretim_bilgi: uretim_bilgi.text = uretim_metni
	if secili_isim: secili_isim.text = isim_metni

	if piyon_var_mi:
		if savunma_bonus: savunma_bonus.text = "-"
	else:
		var def_degeri = 5 if biyom == "dag" else 2 if biyom == "orman" else 0
		if bina_var_mi:
			var b = ana.binalar_verisi[koordinat]
			if b["tur"] == "sehir_merkezi":
				def_degeri += 3 + ((b.get("seviye", 1) - 1) * 2)
			else:
				def_degeri += 1
				
		if savunma_bonus:
			savunma_bonus.text = "+%d Savunma Bonusu" % def_degeri if def_degeri > 0 else "Savunma Bonusu Yok"

	if hex_resim:
		if resim_yolu != "" and ResourceLoader.exists(resim_yolu):
			hex_resim.texture = load(resim_yolu)
		else:
			hex_resim.texture = null

func renkli_isim(oyuncu_ismi: String) -> String:
	var renk_adi = ana.secilen_renkler.get(oyuncu_ismi, "Beyaz")
	var renk = ana.oyuncu_renkleri.get(renk_adi, Color.WHITE)
	return "[color=#%s][b]%s[/b][/color]" % [renk.to_html(false), oyuncu_ismi]

func ui_sinyallerini_bagla():
	tur_butonu.pressed.connect(ana.tur_ekonomi._tur_butonuna_basildi)
	if insa_cek_btn: insa_cek_btn.pressed.connect(ana.deste._ap_ile_normal_kart_cek)
	if savas_cek_btn: savas_cek_btn.pressed.connect(ana.aksiyon.savas_tetik_modul._savas_karti_cek)
	if oncu_uret_btn: oncu_uret_btn.pressed.connect(ana.aksiyon.savas_tetik_modul._oncu_uret_istegi)
	
	if hakimiyet_kur_btn: 
		if not hakimiyet_kur_btn.is_connected("pressed", _hakimiyet_kur_butonuna_basildi):
			hakimiyet_kur_btn.pressed.connect(_hakimiyet_kur_butonuna_basildi)
	if hakimiyet_vazgec_btn: 
		if not hakimiyet_vazgec_btn.is_connected("pressed", _hakimiyet_vazgec_basildi):
			hakimiyet_vazgec_btn.pressed.connect(_hakimiyet_vazgec_basildi)
			
	if kurulum_evet_btn: kurulum_evet_btn.pressed.connect(ana.aksiyon._evet_basildi)
	if kurulum_hayir_btn: kurulum_hayir_btn.pressed.connect(ana.aksiyon._hayir_basildi)
	
	if insa_cek_btn:
		insa_cek_btn.mouse_entered.connect(func(): insa_fare_ustunde = true)
		insa_cek_btn.mouse_exited.connect(func(): 
			insa_fare_ustunde = false
			insa_hover_timer = 0.0
			if insa_deste_kalanlar_panel: insa_deste_kalanlar_panel.visible = false
		)
		
	if savas_cek_btn:
		savas_cek_btn.mouse_entered.connect(func(): savas_fare_ustunde = true)
		savas_cek_btn.mouse_exited.connect(func(): 
			savas_fare_ustunde = false
			savas_hover_timer = 0.0
			if savas_deste_kalanlar_panel: savas_deste_kalanlar_panel.visible = false
		)

	# --- YENİ SAVAŞ ONAY PANELİ (%SavasOnayPaneli) BUTONLARI ---
	var saldir_btn = get_node_or_null("%SaldirBtn")
	if saldir_btn: saldir_btn.pressed.connect(ana.aksiyon.savas_tetik_modul._tetikle_saldiri)
	
	var saldiri_iptal = get_node_or_null("%SaldiriIptalBtn")
	if saldiri_iptal: saldiri_iptal.pressed.connect(ana.aksiyon.savas_tetik_modul._tetikle_savas_iptal)

	# --- BİNA SALDIRI PANELİ (%BinaSaldiriPaneli) BUTONLARI ---
	var bina_yagmala_btn = get_node_or_null("%BinaYagmalaBtn")
	if bina_yagmala_btn: bina_yagmala_btn.pressed.connect(ana.aksiyon.savas_tetik_modul._tetikle_yagmala)
	
	var bina_hukmet_btn = get_node_or_null("%BinaHukmetBtn")
	if bina_hukmet_btn: bina_hukmet_btn.pressed.connect(ana.aksiyon.savas_tetik_modul._tetikle_hukmet)
	
	var bina_yik_btn = get_node_or_null("%BinaYikBtn")
	if bina_yik_btn: bina_yik_btn.pressed.connect(ana.aksiyon.savas_tetik_modul._tetikle_yikim)
	
	var bina_vazgec_btn = get_node_or_null("%BinaVazgecBtn")
	if bina_vazgec_btn: bina_vazgec_btn.pressed.connect(ana.aksiyon.savas_tetik_modul._tetikle_bina_saldiri_vazgec)
	
	if isyan_btn: 
		if not isyan_btn.is_connected("pressed", ana.aksiyon.savas_tetik_modul._isyan_btn_basildi):
			isyan_btn.pressed.connect(ana.aksiyon.savas_tetik_modul._isyan_btn_basildi)
			
	if isyan_evet_butonu: isyan_evet_butonu.pressed.connect(ana.aksiyon.savas_tetik_modul._isyan_onaylandi)
	if isyan_hayir_butonu: isyan_hayir_butonu.pressed.connect(func(): isyan_onay_paneli.visible = false)

	if ticaret_btn: ticaret_btn.pressed.connect(func(): ticaret_paneli.visible = true)
	if ticaret_kapat_btn: ticaret_kapat_btn.pressed.connect(func(): ticaret_paneli.visible = false)
	if odun_sat_btn: odun_sat_btn.pressed.connect(func(): ana.tur_ekonomi._kaynak_sat("odun"))
	if tas_sat_btn: tas_sat_btn.pressed.connect(func(): ana.tur_ekonomi._kaynak_sat("tas"))
	if yiyecek_sat_btn: yiyecek_sat_btn.pressed.connect(func(): ana.tur_ekonomi._kaynak_sat("yiyecek"))

	if cim_btn: cim_btn.toggled.connect(func(basildi): _baslangic_biyom_sec("cim", basildi))
	if orman_btn: orman_btn.toggled.connect(func(basildi): _baslangic_biyom_sec("orman", basildi))
	if dag_btn: dag_btn.toggled.connect(func(basildi): _baslangic_biyom_sec("dag", basildi))

func _baslangic_biyom_sec(biyom: String, basildi: bool):
	if basildi:
		ana.secilen_baslangic_biyomu = biyom
		ana.insa_modu_aktif = true
		
		var biyom_adi = "Çimenlik" if biyom == "cim" else "Ormanlık" if biyom == "orman" else "Dağlık"
		ana.arayuz.olay_yaz("[color=yellow]🏗️ %s seçildi! Haritada sol tıkla kur, sağ tıkla iptal et.[/color]" % biyom_adi)
		
		if biyom == "cim":
			if orman_btn: orman_btn.set_pressed_no_signal(false)
			if dag_btn: dag_btn.set_pressed_no_signal(false)
		elif biyom == "orman":
			if cim_btn: cim_btn.set_pressed_no_signal(false)
			if dag_btn: dag_btn.set_pressed_no_signal(false)
		elif biyom == "dag":
			if cim_btn: cim_btn.set_pressed_no_signal(false)
			if orman_btn: orman_btn.set_pressed_no_signal(false)
	else:
		if ana.secilen_baslangic_biyomu == biyom:
			ana.secilen_baslangic_biyomu = ""
			ana.insa_modu_aktif = false
			ana.arayuz.olay_yaz("[color=gray]Şehir kurma iptal edildi.[/color]")
			
	arayuzu_guncelle()
	
func _hakimiyet_kur_butonuna_basildi():
	if hakimiyet_paneli: hakimiyet_paneli.visible = false
	ana.aksiyon.savas_tetik_modul._hakimiyet_kur_istegi()
	arayuzu_guncelle()
	ana.harita.queue_redraw()

func _hakimiyet_vazgec_basildi():
	if hakimiyet_paneli: hakimiyet_paneli.visible = false
	ana.secili_piyon_index = -1
	ana.arayuz.olay_yaz("[color=gray]Hakimiyet kurma işlemi iptal edildi.[/color]")
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()


func sonuc_ekranini_goster(kazanan: String, puan: int):
	ana.oyun_menusu.sonucu_goster(kazanan, puan)
