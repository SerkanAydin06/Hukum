extends Node
class_name DesteYonetici

var normal_deste = []
var savas_destesi = []
var atilan_insa_kartlari = []
var atilan_savas_kartlari = [] 
var el = []
# Yalnızca sunucuda kullanılan gizli RNG: istemciler deste sırasını hesaplayamaz
var rng = RandomNumberGenerator.new()
const MAX_EL_LIMITI = 7 

@onready var ana = get_parent()
var kart_sahnesi = preload("res://KartUI.tscn")

# 🟢 HAFIZA SİSTEMİ (Redraw Spam'ını Engeller)
var son_el_durumu = []
var son_sira_bende_mi = false
var son_ap_var_mi = false

func karistir(dizi: Array) -> void:
	for i in range(dizi.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var gecici = dizi[i]
		dizi[i] = dizi[j]
		dizi[j] = gecici

# Kartı elden çıkarır; savaş kartıysa atılanlar destesine eklenmesi için herkese bildirir
func karti_elden_at(idx: int) -> void:
	if idx < 0 or idx >= el.size(): return
	ana.aksiyon.savas_karti_atildi_rpc.rpc(idx)

func desteleri_hazirla():
	normal_deste.clear()
	savas_destesi.clear()
	atilan_insa_kartlari.clear()
	atilan_savas_kartlari.clear()
	el.clear()
	son_el_durumu.clear()
	rng.randomize()
	# ==========================================
	# 1. YENİ SAVAŞ DESTESİ HAVUZU
	# ==========================================
	var savas_havuz = [
		# --- KOMUTANLAR (10 Adet) ---
		{"tur": "komutan", "isim": "Büyük İskender", "hedef": "savas", "guc": 0, "tanim": "Saldırı savaşlarında ordusunun toplam gücünü %50 artırır.", "bonus": {"tip": "carpan_yuzde_saldiri", "miktar": 50}},
		{"tur": "komutan", "isim": "Fatih Sultan Mehmet", "hedef": "savas", "guc": 0, "tanim": "Bina ve şehir saldırılarında her kartın gücüne +2 ekler.", "bonus": {"tip": "her_karta_ekle_bina_saldiri", "miktar": 2}},
		{"tur": "komutan", "isim": "Hannibal Barca", "hedef": "savas", "guc": 0, "tanim": "Saldırı savaşlarında zarına +1 ekler.", "bonus": {"tip": "zar_ekle_sartli", "kosul": "saldiri", "miktar": 1}},
		{"tur": "komutan", "isim": "Cengiz Han", "hedef": "savas", "guc": 0, "tanim": "Elindeki her Süvari kartına +5 bonus verir.", "bonus": {"tip": "kart_turu_bonus", "hedef": "suvari", "miktar": 5}},
		{"tur": "komutan", "isim": "Ragnar Lodbrok", "hedef": "savas", "guc": 0, "tanim": "Elindeki her Piyade kartına +5 bonus verir.", "bonus": {"tip": "kart_turu_bonus", "hedef": "piyade", "miktar": 5}},
		{"tur": "komutan", "isim": "Leonidas", "hedef": "savas", "guc": 0, "tanim": "Savunma savaşlarında her karta +2 güç ekler.", "bonus": {"tip": "her_karta_ekle_savunma", "miktar": 2}},
		{"tur": "komutan", "isim": "Belisarius", "hedef": "savas", "guc": 0, "tanim": "Rakipten az kartla savaşırken +10 güç kazandırır.", "bonus": {"tip": "az_kartla", "miktar": 10}},
		{"tur": "komutan", "isim": "Thutmose III", "hedef": "savas", "guc": 0, "tanim": "Açık arazi savaşlarında +10 güç kazandırır.", "bonus": {"tip": "sart_hedef_turu", "deger": "piyon", "miktar": 10}},
		{"tur": "komutan", "isim": "Selahaddin Eyyubi", "hedef": "savas", "guc": 0, "tanim": "Bina savunma savaşlarında zara +1 ekler.", "bonus": {"tip": "zar_ekle_sartli", "kosul": "savunma", "hedef_turu_sart": "bina", "miktar": 1}},
		{"tur": "komutan", "isim": "Enrico Dandolo", "hedef": "savas", "guc": 0, "tanim": "Hükmet saldırısında +10 güç kazandırır.", "bonus": {"tip": "sart_savas_tipi", "deger": "hukmet", "miktar": 10}},

		# --- PİYADELER (30 Adet) ---
		{"tur": "piyade", "kategori": "⚔️ PİYADE", "isim": "Piyade", "hedef": "savas", "guc": 1, "tanim": "Standart piyade birliği.", "bonus": ""},
		{"tur": "piyade", "kategori": "🛡️ AĞIR PİYADE", "isim": "Ağır Zırhlı Piyade", "hedef": "savas", "guc": 3, "tanim": "Zırhlı piyade birliği.", "bonus" : ""},
		{"tur": "piyade", "kategori": "🔱 MIZRAKLI", "isim": "Mızraklı Asker", "hedef": "savas", "guc": 2, "tanim": "Rakibin Süvari gücünü düşürür.", "bonus": {"tip": "dusur", "hedef": "suvari", "miktar": 2}},

		# --- OKÇULAR (20 Adet) ---
		{"tur": "okcu", "kategori": "🏹 OKÇU", "isim": "Kısa Yaylı", "hedef": "savas", "guc": 1, "tanim": "Savunmada fazladan güç kazanır.", "bonus": {"tip": "pozisyon", "kosul": "savunma", "miktar": 2}},
		{"tur": "okcu", "kategori": "🎯 ARBALETÇİ", "isim": "Arbaletçi", "hedef": "savas", "guc": 2, "tanim": "Rakibin Piyade gücünü düşürür.", "bonus": {"tip": "dusur", "hedef": "piyade", "miktar": 2}},
		{"tur": "okcu", "kategori": "🔥 UZUN YAYLI", "isim": "Uzun Yaylı", "hedef": "savas", "guc": 4, "tanim": "Yüksek hasarlı okçu birliği.", "bonus" : ""},

		# --- SÜVARİLER (20 Adet) ---
		{"tur": "suvari", "kategori": "🐎 HAFİF SÜVARİ", "isim": "Hafif Süvari", "hedef": "savas", "guc": 3, "tanim": "Hızlı hücum birliği.", "bonus" : ""},
		{"tur": "suvari", "kategori": "🏇 AĞIR SÜVARİ", "isim": "Ağır Süvari", "hedef": "savas", "guc": 4, "tanim": "Zırhlı süvari birliği.", "bonus" : ""},
		{"tur": "suvari", "kategori": "⚔️ SİPAHİ", "isim": "Zırhlı Sipahi", "hedef": "savas", "guc": 5, "tanim": "Rakibin Okçu gücünü düşürür.", "bonus": {"tip": "dusur", "hedef": "okcu", "miktar": 3}},

		# --- KUŞATMA (20 Adet) ---
		{"tur": "kocbasi", "kategori": "🪵 KUŞATMA", "isim": "Koçbaşı", "hedef": "savas", "guc": 7, "tanim": "Yalnızca şehirlere ve binalara saldırırken kullanılır.", "bonus" : ""},
		{"tur": "mancinik", "kategori": "💣 KUŞATMA", "isim": "Mancınık", "hedef": "savas", "guc": 8, "tanim": "Yalnızca şehirlere ve binalara saldırırken kullanılır.", "bonus" : ""}
	]

	# Savaş Destesini Belirlenen Sayılarda Dolduralım
	for i in range(10): savas_destesi.append(savas_havuz[i].duplicate())  # Komutanlar (10)
	
	for i in range(10): savas_destesi.append(savas_havuz[10].duplicate()) # Piyade (10)
	for i in range(10): savas_destesi.append(savas_havuz[11].duplicate()) # Ağır Piyade (10)
	for i in range(10): savas_destesi.append(savas_havuz[12].duplicate()) # Mızraklı (10)
	
	for i in range(10): savas_destesi.append(savas_havuz[13].duplicate()) # Kısa Yaylı (10)
	for i in range(5):  savas_destesi.append(savas_havuz[14].duplicate()) # Arbaletçi (5)
	for i in range(5):  savas_destesi.append(savas_havuz[15].duplicate()) # Uzun Yaylı (5)
	
	for i in range(10): savas_destesi.append(savas_havuz[16].duplicate()) # Hafif Süvari (10)
	for i in range(5):  savas_destesi.append(savas_havuz[17].duplicate()) # Ağır Süvari (5)
	for i in range(5):  savas_destesi.append(savas_havuz[18].duplicate()) # Sipahi (5)
	
	for i in range(10): savas_destesi.append(savas_havuz[19].duplicate()) # Koçbaşı (10)
	for i in range(10): savas_destesi.append(savas_havuz[20].duplicate()) # Mancınık (10)
	

	# ==========================================
	# 2. İNŞA VE GELİŞİM DESTESİ HAVUZU (110 Kart)
	# ==========================================
	var insa_havuz = [
		{"tur": "oduncu_kampi", "kategori": "🏗️ İNŞA", "isim": "Oduncu Kampı", "hedef": "harita", "odun_maliyet": 4, "tas_maliyet": 0, "tanim": "Ormana kurulur. Her tur odun üretir."},
		{"tur": "tas_ocagi", "kategori": "🏗️ İNŞA", "isim": "Taş Ocağı", "hedef": "harita", "odun_maliyet": 8, "tas_maliyet": 2, "tanim": "Dağa kurulur. Her tur taş üretir."},
		{"tur": "tarla", "kategori": "🏗️ İNŞA", "isim": "Tarla", "hedef": "harita", "odun_maliyet": 6, "tas_maliyet": 0, "tanim": "Çimene kurulur. Her tur yiyecek üretir."},
		{"tur": "ticaret_merkezi", "kategori": "🏗️ İNŞA", "isim": "Ticaret Merkezi", "hedef": "harita", "odun_maliyet": 12, "tas_maliyet": 12, "tanim": "Pazar menüsünü açar. (Nadir)"},
		{"tur": "oncu_kampi", "kategori": "🏗️ İNŞA", "isim": "Öncü Kampı", "hedef": "harita", "odun_maliyet": 6, "tas_maliyet": 2, "tanim": "Çimene kurulur. 5 yiyecek ve 1 AP ile Öncü yetiştirir."}
	]
	
	var gelisim_havuz = [
		{"tur": "baltalari_bileme", "kategori": "🏗️ GELİŞİM", "isim": "Baltaları Bileme", "hedef": "kendi_binasi", "bina_turu": "oduncu_kampi", "odun_maliyet": 5, "tas_maliyet": 3, "tanim": "Sadece bir Oduncu Kampını yükseltir."},
		{"tur": "derin_damarlar", "kategori": "🏗️ GELİŞİM", "isim": "Derin Damarlar", "hedef": "kendi_binasi", "bina_turu": "tas_ocagi", "odun_maliyet": 6, "tas_maliyet": 4, "tanim": "Sadece bir Taş Ocağını yükseltir."},
		{"tur": "gelismis_sulama", "kategori": "🏗️ GELİŞİM", "isim": "Gelişmiş Sulama", "hedef": "kendi_binasi", "bina_turu": "tarla", "odun_maliyet": 5, "tas_maliyet": 2, "tanim": "Sadece bir Tarlayı yükseltir."}
	]
	
	for i in range(20): normal_deste.append(insa_havuz[0].duplicate())
	for i in range(20): normal_deste.append(insa_havuz[1].duplicate())
	for i in range(20): normal_deste.append(insa_havuz[2].duplicate())
	for i in range(10): normal_deste.append(insa_havuz[3].duplicate())
	for i in range(10): normal_deste.append(insa_havuz[4].duplicate())
	
	for i in range(10): normal_deste.append(gelisim_havuz[0].duplicate())
	for i in range(10): normal_deste.append(gelisim_havuz[1].duplicate())
	for i in range(10): normal_deste.append(gelisim_havuz[2].duplicate())
	
	# Sıra yalnızca sunucuda belirlenir. İstemcilerde dizi kalan kartların
	# içeriğini tutar; sırası anlamsızdır ve kartları sunucu dağıtır.
	if _sunucu_mu():
		karistir(normal_deste)
		karistir(savas_destesi)

func _sunucu_mu() -> bool:
	return not is_inside_tree() or multiplayer.is_server()

# Sunucu: deste boşsa atıkları gizli RNG ile yeniden karıştırır.
# Karıştırma olduysa true döner; istemciler yalnızca bunu öğrenir.
func sunucu_desteyi_hazirla(savas_karti: bool) -> bool:
	var deste = savas_destesi if savas_karti else normal_deste
	var atik = atilan_savas_kartlari if savas_karti else atilan_insa_kartlari
	if not deste.is_empty(): return false
	deste.append_array(atik)
	atik.clear()
	karistir(deste)
	return true
	
func _ap_ile_normal_kart_cek():
	if ana.aktif_sira != ana.benim_indexim or not ana.ilk_tur_bitti: return
	
	if ana.aktif_oyuncu_aksiyon_hakki > 0:
		if not normal_deste.is_empty() or not atilan_insa_kartlari.is_empty():
			var insa_karti_sayisi = 0
			for kart in el: 
				if kart.get("hedef") != "savas":
					insa_karti_sayisi += 1
					
			if insa_karti_sayisi >= MAX_EL_LIMITI:
				ana.arayuz.olay_yaz("[color=light_coral]❌ Elinde zaten maksimum (7) İnşa/Gelişim Kartı var![/color]")
				return
				
			ana.aksiyon.normal_kart_cek_rpc.rpc_id(1, ana.oyuncular[ana.benim_indexim]) 
		else:
			ana.arayuz.olay_yaz("[color=light_coral]❌ Normal Deste bitti![/color]")

func hex_dosta_komsu_mu(hedef_koor: Vector2i, sahip_isim: String) -> bool:
	for k in ana.kontrol_edilen_hexler:
		if ana.kontrol_edilen_hexler[k] == sahip_isim:
			if ana.harita.hex_komsu_mu(k, hedef_koor):
				return true
	return false

func _el_degisti_mi() -> bool:
	if el.size() != son_el_durumu.size(): return true
	for i in range(el.size()):
		if el[i].get("isim") != son_el_durumu[i].get("isim"): return true
	return false

func eldeki_kartlari_ciz():
	if not ana.arayuz.insa_kart_eli_konteyner or not ana.arayuz.savas_kart_eli_konteyner: return 
	if not ana.ilk_tur_bitti: return

	var sira_bende_mi = (ana.aktif_sira == ana.benim_indexim)
	var ap_var_mi = (ana.aktif_oyuncu_aksiyon_hakki > 0)
	# ❌ Kullanılmayan "hamle_yapabilir" değişkeni buradan silindi!

	if not _el_degisti_mi() and son_sira_bende_mi == sira_bende_mi and son_ap_var_mi == ap_var_mi:
		_kart_gorsellerini_guncelle()
		return

	son_el_durumu = el.duplicate(true)
	son_sira_bende_mi = sira_bende_mi
	son_ap_var_mi = ap_var_mi

	for child in ana.arayuz.insa_kart_eli_konteyner.get_children(): child.queue_free()
	for child in ana.arayuz.savas_kart_eli_konteyner.get_children(): child.queue_free()

	for i in range(el.size()):
		var kart = el[i]
		var savas_karti_mi = (kart.get("hedef") == "savas")
		
		var hedef_konteyner = ana.arayuz.savas_kart_eli_konteyner if savas_karti_mi else ana.arayuz.insa_kart_eli_konteyner
		
		var kart_sutun = VBoxContainer.new()
		kart_sutun.alignment = BoxContainer.ALIGNMENT_END 
		kart_sutun.add_theme_constant_override("separation", 2)
		kart_sutun.mouse_filter = Control.MOUSE_FILTER_STOP
		hedef_konteyner.add_child(kart_sutun)
		
		var kart_btn = kart_sahnesi.instantiate()
		kart_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		kart_sutun.add_child(kart_btn)
		
		if kart_btn.has_method("karti_doldur"):
			kart_btn.karti_doldur(kart, i)
		
		kart_btn.pressed.connect(func(): kart_tiklandi(i))
		
	_kart_gorsellerini_guncelle()

func _kart_gorsellerini_guncelle():
	if not ana.arayuz.insa_kart_eli_konteyner or not ana.arayuz.savas_kart_eli_konteyner: return
	
	for konteyner in [ana.arayuz.insa_kart_eli_konteyner, ana.arayuz.savas_kart_eli_konteyner]:
		for sutun in konteyner.get_children():
			if sutun.get_child_count() == 0: continue
			
			var kart_ui = sutun.get_child(0)
			var idx = kart_ui.get("kart_index") if "kart_index" in kart_ui else -1
			
			if idx != -1 and idx == ana.secili_kart_index:
				if kart_ui.has_method("secim_yap"): kart_ui.secim_yap(true)
			else:
				if kart_ui.has_method("secim_yap"): kart_ui.secim_yap(false)

func kart_tiklandi(idx: int):
	if ana.secili_kart_index == idx:
		ana.secili_kart_index = -1
		ana.kart_insa_modu_aktif = false # Seçimi iptal edince inşa modunu kapat
	else:
		ana.secili_kart_index = idx
		ana.secili_piyon_index = -1 
		ana.kart_insa_modu_aktif = false # KARTA TIKLAYINCA DİREKT OYNATMA! Sadece menü açılsın.
		
	ana.harita.queue_redraw()
	_kart_gorsellerini_guncelle()
	
	# 🟢 YENİ EKLENEN SATIR: Karta tıklandığında arayüzü güncelle ki Deste butonları "Disabled" görsele geçsin!
	ana.arayuz.arayuzu_guncelle()
