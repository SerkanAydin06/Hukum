extends TextureButton

const ONCU_KAMPI_RESMI = preload("res://Assets/Resimler/kartresimleri/oncukampi.svg")

# --- SAVAŞ GÖRÜNÜMÜ NODELARI ---
@onready var savas_gorunumu = $SavasGorunumu if has_node("SavasGorunumu") else null
@onready var savas_arkaplan = $SavasGorunumu/Arkaplan if has_node("SavasGorunumu/Arkaplan") else null
@onready var asker_resim = get_node_or_null("%Asker")
@onready var guc_label = get_node_or_null("%Guc")
@onready var asker_isim_lbl = get_node_or_null("%AskerIsim")
@onready var savas_aciklama = get_node_or_null("%Aciklama")

# --- KOMUTAN GÖRÜNÜMÜ NODELARI ---
@onready var komutan_gorunumu = $KomutanGorunumu if has_node("KomutanGorunumu") else null
@onready var komutan_resim = get_node_or_null("%Komutan")
@onready var komutan_guc_lbl = get_node_or_null("%KomutanGuc")
@onready var komutan_isim_lbl = get_node_or_null("%KomutanIsim")
@onready var komutan_aciklama_lbl = get_node_or_null("%KomutanAciklama")

# --- İNŞA GÖRÜNÜMÜ NODELARI ---
@onready var insa_gorunumu = $InsaGorunumu if has_node("InsaGorunumu") else null
@onready var insa_arkaplan = $InsaGorunumu/Arkaplan if has_node("InsaGorunumu/Arkaplan") else null
@onready var insa_resim = get_node_or_null("%InsaResim")        # 🟢 DEĞİŞTİ
@onready var bina_baslik_lbl = get_node_or_null("%BinaBaslik")   # 🟢 DEĞİŞTİ
@onready var bina_aciklama_lbl = get_node_or_null("%BinaAciklama")   # 🟢 DEĞİŞTİ
@onready var insa_odun_lbl = get_node_or_null("%InsaOdun")       # 🟢 DEĞİŞTİ
@onready var insa_tas_lbl = get_node_or_null("%InsaTas") 

# --- GELİŞİM GÖRÜNÜMÜ NODELARI ---
@onready var gelisim_gorunumu = $GelisimGorunumu if has_node("GelisimGorunumu") else null
@onready var gelisim_arkaplan = $GelisimGorunumu/Arkaplan if has_node("GelisimGorunumu/Arkaplan") else null
@onready var gelisim_resim = get_node_or_null("%GelisimResim")        # 🟢 DEĞİŞTİ
@onready var gelisim_baslik_lbl = get_node_or_null("%GelisimBaslik")   # 🟢 DEĞİŞTİ
@onready var gelisim_aciklama_lbl = get_node_or_null("%GelisimAciklama")   # 🟢 DEĞİŞTİ
@onready var gelisim_odun_lbl = get_node_or_null("%GelisimOdun")       # 🟢 DEĞİŞTİ
@onready var gelisim_tas_lbl = get_node_or_null("%GelisimTas") 

# --- GÜVENLİ TANIMLAMALAR ---
@onready var secim_hbox = get_node_or_null("%SecimHBox")
@onready var kullan_btn = get_node_or_null("%KullanBtn")
@onready var cope_at_btn = get_node_or_null("%CopeAtBtn")
@onready var donustur_btn = get_node_or_null("%DonusturBtn")

@onready var parlama = $Parlama if has_node("Parlama") else null

# SAVAŞ KARTLARI RESİM EŞLEŞTİRME SÖZLÜĞÜ
var savas_resimleri = {
	"Piyade": "piyade", "Ağır Zırhlı Piyade": "agirpiyade", "Mızraklı Asker": "mizrakli",
	"Kısa Yaylı": "okcu", "Arbaletçi": "arbaletci", "Uzun Yaylı": "uzunyayli",
	"Hafif Süvari": "hafifsuvari", "Ağır Süvari": "agirsuvari", "Zırhlı Sipahi": "zirhlisipahi",
	"Koçbaşı": "kocbasi", "Mancınık": "mancinik", "Büyük İskender": "iskender",
	"Fatih Sultan Mehmet": "fatih", "Hannibal Barca": "hannibal", "Cengiz Han": "cengiz",
	"Ragnar Lodbrok": "lodbrok", "Leonidas": "leonidas", "Belisarius": "belisarius",
	"Thutmose III": "thutmose", "Selahaddin Eyyubi": "selahaddin", "Enrico Dandolo": "dondolo"
}

# İNŞA VE GELİŞİM KARTLARI RESİM EŞLEŞTİRME SÖZLÜĞÜ
var insa_gelisim_resimleri = {
	"oduncu_kampi": "oduncu", "tas_ocagi": "tasocagi", "tarla": "tarla",
	"ticaret_merkezi": "ticaretmerkezi", "baltalari_bileme": "baltalaribileme",
	"derin_damarlar": "derindamarlar", "gelismis_sulama": "gelismissulama"
}

var kart_index = -1
var orijinal_y_konumu = 0.0
var ilk_kurulum = false
var secili_mi = false
var dogrudan_savas_modu = false

var kart_hedefi = ""
var kart_turu = ""
var kart_verisi: Dictionary = {}

func _ready():
	pivot_offset = size / 2.0
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not pressed.is_connected(_on_kart_pressed):
		pressed.connect(_on_kart_pressed)
		
	if savas_gorunumu: savas_gorunumu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if insa_gorunumu: insa_gorunumu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gelisim_gorunumu: gelisim_gorunumu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if komutan_gorunumu: komutan_gorunumu.mouse_filter = Control.MOUSE_FILTER_IGNORE   # 🟢 YENİ

	if secim_hbox: secim_hbox.visible = false

	if kullan_btn: kullan_btn.pressed.connect(_on_kullan_pressed)
	if cope_at_btn: cope_at_btn.pressed.connect(_on_cope_at_pressed)
	if donustur_btn: donustur_btn.pressed.connect(_on_donustur_pressed)

func _process(delta):
	var aktif_y = 0.0
	var aktif_scale = Vector2.ONE
	var aktif_z = 0 
	
	if secili_mi:
		aktif_y = -140.0      
		aktif_scale = Vector2(1.35, 1.35)
		aktif_z = 100
	elif is_hovered():
		aktif_y = -60.0        
		aktif_scale = Vector2(1.15, 1.15)
		aktif_z = 50
	
	scale = scale.lerp(aktif_scale, delta * 15.0)
	position.y = lerp(position.y, orijinal_y_konumu + aktif_y, delta * 15.0)
	z_index = aktif_z

func karti_doldur(veri: Dictionary, idx: int):
	kart_verisi = veri
	kart_index = idx
	kart_hedefi = veri.get("hedef", "")
	kart_turu = veri.get("tur", "")
	
	var orj_isim = veri.get("isim", veri.get("tur", "Bilinmeyen")) 
	var gosterilecek_isim = orj_isim.to_upper().replace("_", " ")
	
	var tanim = veri.get("tanim", "Özel etkili kart.")
	var hedef = veri.get("hedef", "")
	
	var odun_maliyet = str(veri.get("odun_maliyet", 0))
	var tas_maliyet = str(veri.get("tas_maliyet", 0))
	
	if hedef == "savas" and veri.get("tur") == "komutan":
		# 🟢 YENİ: KOMUTAN GÖRÜNÜMÜ
		if komutan_gorunumu: komutan_gorunumu.visible = true
		if savas_gorunumu: savas_gorunumu.visible = false
		if insa_gorunumu: insa_gorunumu.visible = false
		if gelisim_gorunumu: gelisim_gorunumu.visible = false
		
		if komutan_isim_lbl: komutan_isim_lbl.text = gosterilecek_isim
		if komutan_aciklama_lbl: komutan_aciklama_lbl.text = tanim
		if komutan_guc_lbl: komutan_guc_lbl.text = str(veri.get("guc", 0))
		
		if komutan_resim:
			var dosya_adi = savas_resimleri.get(orj_isim, "")
			if dosya_adi != "":
				var yol = "res://Assets/Resimler/komutanlar/%s.png" % dosya_adi
				komutan_resim.texture = load(yol) if ResourceLoader.exists(yol) else null
			else:
				komutan_resim.texture = null

	elif hedef == "savas":
		# ASKER GÖRÜNÜMÜ (aynen kalıyor)
		if savas_gorunumu: savas_gorunumu.visible = true
		if komutan_gorunumu: komutan_gorunumu.visible = false   # 🟢 YENİ: komutan görünümü kapalı
		if insa_gorunumu: insa_gorunumu.visible = false
		if gelisim_gorunumu: gelisim_gorunumu.visible = false
		
		if asker_isim_lbl: asker_isim_lbl.text = gosterilecek_isim
		if savas_aciklama: savas_aciklama.text = tanim
		
		if guc_label:
			guc_label.text = str(veri.get("guc", 0))   # 🟢 Artık "👑" özel durumu gerekmiyor, komutan zaten ayrı görünümde
				
		
		if asker_resim:
			var dosya_adi = savas_resimleri.get(orj_isim, "")
			if dosya_adi != "":
				var yol = "res://Assets/Resimler/askerler/%s.png" % dosya_adi
				asker_resim.texture = load(yol) if ResourceLoader.exists(yol) else null
			else:
				asker_resim.texture = null

	elif hedef == "kendi_binasi":
		if komutan_gorunumu: komutan_gorunumu.visible = false
		if savas_gorunumu: savas_gorunumu.visible = false
		if insa_gorunumu: insa_gorunumu.visible = false
		if gelisim_gorunumu: gelisim_gorunumu.visible = true
		
		if gelisim_baslik_lbl: gelisim_baslik_lbl.text = gosterilecek_isim
		if gelisim_aciklama_lbl: gelisim_aciklama_lbl.text = tanim
		
		if gelisim_odun_lbl: gelisim_odun_lbl.text = odun_maliyet
		if gelisim_tas_lbl: gelisim_tas_lbl.text = tas_maliyet
		
		if gelisim_resim:
			var tur = veri.get("tur", "")
			var dosya_adi = insa_gelisim_resimleri.get(tur, "")
			if dosya_adi != "":
				var yol = "res://Assets/Resimler/kartresimleri/%s.png" % dosya_adi
				gelisim_resim.texture = load(yol) if ResourceLoader.exists(yol) else null
			else:
				gelisim_resim.texture = null
		
	else:
		if komutan_gorunumu: komutan_gorunumu.visible = false
		if savas_gorunumu: savas_gorunumu.visible = false
		if gelisim_gorunumu: gelisim_gorunumu.visible = false
		if insa_gorunumu: insa_gorunumu.visible = true
		
		if bina_baslik_lbl: bina_baslik_lbl.text = gosterilecek_isim
		if bina_aciklama_lbl: bina_aciklama_lbl.text = tanim
		
		if insa_odun_lbl: insa_odun_lbl.text = odun_maliyet
		if insa_tas_lbl: insa_tas_lbl.text = tas_maliyet
		
		if insa_resim:
			var tur = veri.get("tur", "")
			if tur == "oncu_kampi":
				# Birim piyonu değil, kampa özel inşa kartı illüstrasyonu.
				insa_resim.texture = ONCU_KAMPI_RESMI
			else:
				var dosya_adi = insa_gelisim_resimleri.get(tur, "")
				if dosya_adi != "":
					var yol = "res://Assets/Resimler/kartresimleri/%s.png" % dosya_adi
					insa_resim.texture = load(yol) if ResourceLoader.exists(yol) else null
				else:
					insa_resim.texture = null

func _on_kart_pressed():
	if dogrudan_savas_modu:
		var ana = find_parent("AnaOyun")
		if ana and "savas" in ana and ana.savas.savas_aktif:
			ana.savas.savas_kart_sec_ve_yerlestir(kart_verisi, kart_index, self)
		return
	secim_yap(not secili_mi)

func secim_yap(durum: bool):
	if dogrudan_savas_modu: return
	
	secili_mi = durum
	if parlama: parlama.visible = durum
	if secim_hbox: secim_hbox.visible = durum
	
	if durum:
		var ana = find_parent("AnaOyun")
		var savas_aktif_mi = ana and "savas" in ana and ana.savas.savas_aktif
		
		if kart_hedefi == "savas":
			if kullan_btn:
				kullan_btn.visible = false   # 🟢 Savaş kartında Kullan HER ZAMAN gizli
			if cope_at_btn:
				cope_at_btn.visible = true
				cope_at_btn.disabled = savas_aktif_mi   # 🟢 DÜZELTİLDİ: sadece aktif savaşta kilitli, incelerken serbest
			if donustur_btn:
				donustur_btn.visible = true
				donustur_btn.disabled = savas_aktif_mi   # 🟢 DÜZELTİLDİ
		else:
			if kullan_btn:
				kullan_btn.visible = true
				kullan_btn.disabled = false
			if cope_at_btn:
				cope_at_btn.visible = true
				cope_at_btn.disabled = false
			if donustur_btn:
				donustur_btn.visible = true
				donustur_btn.disabled = false

func _on_mouse_entered():
	if not ilk_kurulum:
		orijinal_y_konumu = position.y
		ilk_kurulum = true

# 🟢 HATA BURADAYDI, TAMAMEN GÜVENLİ HALE GETİRİLDİ!
func _on_kullan_pressed():
	var ana = find_parent("AnaOyun")
	if ana:
		# 1) SAVAŞ SIRASINDA (Node ismi yerine güvenli kontrol)
		if "savas" in ana and ana.savas.savas_aktif:
			ana.savas.savas_kart_sec_ve_yerlestir(kart_verisi, kart_index, self)
			secim_yap(false)
			return
			
		# 2) NORMAL OYUN İÇİ KART KULLANMA MANTIĞI
		if "aksiyon" in ana:
			if ana.aktif_sira != ana.benim_indexim or not ana.ilk_tur_bitti:
				ana.arayuz.olay_yaz("[color=light_coral]❌ Sıra senin değil![/color]")
				return
				
			if ana.aktif_oyuncu_aksiyon_hakki <= 0:
				ana.arayuz.olay_yaz("[color=light_coral]❌ Aksiyon Puanın (AP) kalmadı![/color]")
				return

			ana.aksiyon.kart_onayla(kart_index)
			secim_yap(false)

func _on_cope_at_pressed():
	var ana = find_parent("AnaOyun")
	if ana and "deste" in ana:
		if ana.aktif_sira != ana.benim_indexim or not ana.ilk_tur_bitti:
			ana.arayuz.olay_yaz("[color=light_coral]❌ Sıra senin değil![/color]")
			return
			
		if kart_index != -1 and kart_index < ana.deste.el.size():
			ana.deste.karti_elden_at(kart_index)
			ana.secili_kart_index = -1
			ana.arayuz.olay_yaz("[color=gray]🗑️ Kart çöpe atıldı.[/color]")
			ana.deste._kart_gorsellerini_guncelle()
			ana.arayuz.arayuzu_guncelle()
			secim_yap(false)

func _on_donustur_pressed():
	var ana = find_parent("AnaOyun")
	if ana and "aksiyon" in ana:
		ana.aksiyon.kart_modul.karti_kaynaga_cevir(kart_index)
		secim_yap(false)
