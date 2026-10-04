extends Node2D

const HARITA_GENISLIK = 16
const HARITA_YUKSEKLIK = 12
const HEX_RADIUS = 55.0
const HEX_BOSLUK = 2.0

const RENK_CIM = Color(0.38, 0.72, 0.38)
const RENK_ORMAN = Color(0.18, 0.44, 0.22)
const RENK_DAG = Color(0.58, 0.42, 0.26)
const RENK_SIS = Color(0.15, 0.15, 0.18)

var resim_orman = preload("res://Assets/Resimler/hex/orman.png")
var resim_cim = preload("res://Assets/Resimler/hex/cimen.png")
var resim_dag = preload("res://Assets/Resimler/hex/dag.png")
var resim_kapali_hex = preload("res://Assets/Resimler/hex/kapali_hex.png")
var resim_bulut = preload("res://Assets/Resimler/efektler/bulut.tres")

# --- ÖNCÜ VE BİNA GÖRSELLERİ ---
var piyon_resimleri = {
	"Osmanlı": preload("res://Assets/Resimler/oncu/oncu_osmanli.png"),
	"Venedik": preload("res://Assets/Resimler/oncu/oncu_venedik.png"),
	"Mısır": preload("res://Assets/Resimler/oncu/oncu_misir.png"),
	"Moğol": preload("res://Assets/Resimler/oncu/oncu_mogol.png"),
	"Bizans": preload("res://Assets/Resimler/oncu/oncu_bizans.png"),
	"Viking": preload("res://Assets/Resimler/oncu/oncu_viking.png")
}

var sehir_merkezi_resimleri = {
	"Osmanlı": preload("res://Assets/Resimler/Sehirmerkezleri/sehirmerkezi_osmanli.png"),
	"Venedik": preload("res://Assets/Resimler/Sehirmerkezleri/sehirmerkezi_venedik.png"),
	"Mısır": preload("res://Assets/Resimler/Sehirmerkezleri/sehirmerkezi_misir.png"),
	"Moğol": preload("res://Assets/Resimler/Sehirmerkezleri/sehirmerkezi_mogol.png"),
	"Bizans": preload("res://Assets/Resimler/Sehirmerkezleri/sehirmerkezi_bizans.png"),
	"Viking": preload("res://Assets/Resimler/Sehirmerkezleri/sehirmerkezi_viking.png")
}

# --- SEVİYE GÖRSELLERİ ---
var oduncu_resimleri = {
	1: preload("res://Assets/Resimler/binalar/oduncu1.png"),
	2: preload("res://Assets/Resimler/binalar/oduncu2.png"),
	3: preload("res://Assets/Resimler/binalar/oduncu3.png")
}

var tarla_resimleri = {
	1: preload("res://Assets/Resimler/binalar/tarla1.png"),
	2: preload("res://Assets/Resimler/binalar/tarla2.png"),
	3: preload("res://Assets/Resimler/binalar/tarla3.png")
}

var tasocagi_resimleri = {
	1: preload("res://Assets/Resimler/binalar/tasocagi1.png"),
	2: preload("res://Assets/Resimler/binalar/tasocagi2.png"),
	3: preload("res://Assets/Resimler/binalar/tasocagi3.png")
}

var bina_resimleri = {}

var kesfedilen_hexler = {}
var gorus_haritasi = {}
var bulutsuz_hexler = {}
@onready var ana_oyun = get_parent()

func _ready():
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func kesif_yap(koor: Vector2i):
	if not kesfedilen_hexler.has(koor):
		var biyomlar = ["cim", "cim", "cim", "orman", "orman", "dag"]
		kesfedilen_hexler[koor] = biyomlar.pick_random()
		gorus_haritasini_guncelle()
		queue_redraw()

func _process(_delta):
	queue_redraw()

func gorus_haritasini_guncelle():
	gorus_haritasi.clear()
	if not ana_oyun or ana_oyun.oyuncular.size() == 0: return
	
	var benim_ismim = ana_oyun.oyuncular[ana_oyun.benim_indexim]
	var isik_kaynaklari = []
	
	for koor in ana_oyun.binalar_verisi:
		if ana_oyun.binalar_verisi[koor].get("sahip") == benim_ismim:
			isik_kaynaklari.append(koor)
			
	for p in ana_oyun.piyonlar:
		if p.get("sahip") == benim_ismim:
			isik_kaynaklari.append(p["koordinat"])
			
	for k in ana_oyun.kontrol_edilen_hexler:
		if ana_oyun.kontrol_edilen_hexler[k] == benim_ismim:
			if not isik_kaynaklari.has(k):
				isik_kaynaklari.append(k)
			
	var hic_varlik_yok = isik_kaynaklari.is_empty()
			
	for x in range(HARITA_GENISLIK):
		for y in range(HARITA_YUKSEKLIK):
			var hex = Vector2i(x, y)
			
			if hic_varlik_yok:
				gorus_haritasi[hex] = 3
			else:
				var min_mesafe = 999
				for v_koor in isik_kaynaklari:
					var mesafe = hex_mesafesi(hex, v_koor)
					if mesafe < min_mesafe:
						min_mesafe = mesafe
						
				gorus_haritasi[hex] = min_mesafe
				
				if min_mesafe <= 2:
					bulutsuz_hexler[hex] = true

func _draw():
	var zaman = Time.get_ticks_msec() / 1000.0
	var bulut_hizi = Vector2(-0.025, 0.0)
	var bulut_kaymasi = zaman * bulut_hizi
	var bulut_olcegi = 0.0015
	
	for x in range(HARITA_GENISLIK):
		for y in range(HARITA_YUKSEKLIK):
			var koor = Vector2i(x, y)
			
			var gorus_mesafe = gorus_haritasi.get(koor, 3)
			var bulutsuz = bulutsuz_hexler.has(koor)
			
			var parlaklik = 1.0
			if gorus_mesafe == 2:
				parlaklik = 0.60
			elif gorus_mesafe >= 3:
				parlaklik = 0.30
			
			var renk_filtresi = Color(parlaklik, parlaklik, parlaklik, 1.0)
			
			var merkez = hex_merkezi_hesapla(x, y)
			var koseler = PackedVector2Array()
			var uv_ler = PackedVector2Array()
			var bulut_uv_ler = PackedVector2Array()
			
			for i in range(6):
				var aci = deg_to_rad(i * 60 + 30)
				var offset = Vector2(cos(aci), sin(aci))
				var dunya_noktasi = merkez + offset * (HEX_RADIUS - HEX_BOSLUK)
				
				koseler.append(dunya_noktasi)
				uv_ler.append(Vector2(0.5 + (offset.x / sqrt(3.0)), 0.5 + (offset.y / 2.0)))
				bulut_uv_ler.append((dunya_noktasi * bulut_olcegi) + bulut_kaymasi)
			
			if kesfedilen_hexler.has(koor):
				var biyom = kesfedilen_hexler[koor]
				var hex_rengi = RENK_CIM if biyom == "cim" else RENK_ORMAN if biyom == "orman" else RENK_DAG
				
				var secilen_resim = null
				if biyom == "cim": secilen_resim = resim_cim
				elif biyom == "orman": secilen_resim = resim_orman
				elif biyom == "dag": secilen_resim = resim_dag
				
				if secilen_resim != null:
					draw_polygon(koseler, PackedColorArray([renk_filtresi]), uv_ler, secilen_resim)
				else:
					draw_polygon(koseler, PackedColorArray([hex_rengi * renk_filtresi]))
					
				var sinir_rengi = Color(0.55 * parlaklik, 0.45 * parlaklik, 0.25 * parlaklik, 0.85)
				draw_polyline(koseler + PackedVector2Array([koseler[0]]), sinir_rengi, 2.0)
				
			else:
				if resim_kapali_hex != null:
					draw_polygon(koseler, PackedColorArray([renk_filtresi]), uv_ler, resim_kapali_hex)
				else:
					draw_polygon(koseler, PackedColorArray([RENK_SIS * renk_filtresi]))
					
				if resim_bulut != null and gorus_mesafe >= 3 and not bulutsuz:
					var bulut_rengi = Color(1.0, 1.0, 1.0, 0.65) * renk_filtresi
					draw_polygon(koseler, PackedColorArray([bulut_rengi]), bulut_uv_ler, resim_bulut)
					
				var sinir_rengi = Color(0.4 * parlaklik, 0.3 * parlaklik, 0.2 * parlaklik, 0.6)
				draw_polyline(koseler + PackedVector2Array([koseler[0]]), sinir_rengi, 2.0)

	if not ana_oyun: return
	
	for k in ana_oyun.kontrol_edilen_hexler:
		var gorus_mesafe = gorus_haritasi.get(k, 3)
		if gorus_mesafe >= 3 and not bulutsuz_hexler.has(k): continue
		
		var sahip = ana_oyun.kontrol_edilen_hexler[k]
		var sahip_renk_adi = ana_oyun.secilen_renkler.get(sahip, "Beyaz")
		var r = ana_oyun.oyuncu_renkleri.get(sahip_renk_adi, Color.WHITE)
		var cizgi_rengi = r   # 🟢 Artık HER ZAMAN sahibinin kendi rengi kalıyor (efendiye göre değişmiyor)
		var efendisi = ana_oyun.efendiler.get(sahip, "")
		
		var merkez = hex_merkezi_hesapla(k.x, k.y)
		var koseler = PackedVector2Array()
		for i in range(6):
			var aci = deg_to_rad(i * 60 + 30)
			koseler.append(merkez + Vector2(cos(aci), sin(aci)) * (HEX_RADIUS - HEX_BOSLUK))
		koseler.append(koseler[0])
		
		draw_polygon(koseler, PackedColorArray([Color(r.r, r.g, r.b, 0.15)]))
		draw_polyline(koseler, cizgi_rengi, 2.5)
		
		if efendisi != "":
			var efendi_renk_adi = ana_oyun.secilen_renkler.get(efendisi, "Beyaz")
			var efendi_renk = ana_oyun.oyuncu_renkleri.get(efendi_renk_adi, Color.WHITE)   # 🟢 YENİ
			
			var k_pos = merkez + Vector2(0, -HEX_RADIUS + 15)
			draw_arc(k_pos + Vector2(-8, 0), 5.0, 0, TAU, 8, efendi_renk, 2.0)   # 🟢 siyah yerine efendi_renk
			draw_arc(k_pos + Vector2(8, 0), 5.0, 0, TAU, 8, efendi_renk, 2.0)    # 🟢 siyah yerine efendi_renk
			draw_line(k_pos + Vector2(-3, 0), k_pos + Vector2(3, 0), efendi_renk, 2.0)   # 🟢 siyah yerine efendi_renk
	
	if ana_oyun.kart_insa_modu_aktif:
		var zaman_dalmasi = (sin(Time.get_ticks_msec() / 150.0) + 1.0) / 2.0
		var alfa = lerp(0.2, 0.9, zaman_dalmasi)
		var cizgi_rengi = Color(0.2, 1.0, 0.4, alfa)
		
		for koor in ana_oyun.kurulabilir_hexler:
			var gorus_mesafe = gorus_haritasi.get(koor, 3)
			if gorus_mesafe >= 3: continue
			
			var k_merkez = hex_merkezi_hesapla(koor.x, koor.y)
			var k_koseler = PackedVector2Array()
			for i in range(6):
				var aci = deg_to_rad(i * 60 + 30)
				k_koseler.append(k_merkez + Vector2(cos(aci), sin(aci)) * (HEX_RADIUS - HEX_BOSLUK))
				
			draw_polyline(k_koseler + PackedVector2Array([k_koseler[0]]), cizgi_rengi, 4.5)

	# 🟢 1. ÖNCÜNÜN KOMŞU HAREKET/SALDIRI HALKALARI (Binalar ve Öncülerden ÖNCE çiziliyor)
	var sira_bende_mi = (ana_oyun.aktif_sira == ana_oyun.benim_indexim)
	var ap_var_mi = (ana_oyun.aktif_oyuncu_aksiyon_hakki > 0)
	
	if ana_oyun.secili_piyon_index != -1 and ana_oyun.secili_piyon_index < ana_oyun.piyonlar.size() and not ana_oyun.kart_insa_modu_aktif and sira_bende_mi and ap_var_mi and ana_oyun.ilk_tur_bitti:
		var secili_piyon = ana_oyun.piyonlar[ana_oyun.secili_piyon_index]
		var benim_isim = ana_oyun.oyuncular[ana_oyun.benim_indexim]
		
		if secili_piyon["sahip"] == benim_isim:
			var p_koor = secili_piyon["koordinat"]
			var offsetler = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(0, 1), Vector2i(-1, 1)] if p_koor.y % 2 == 0 else [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(0, 1)]
			
			for offset in offsetler:
				var komsu_koor = p_koor + offset
				
				if komsu_koor.x >= 0 and komsu_koor.x < HARITA_GENISLIK and komsu_koor.y >= 0 and komsu_koor.y < HARITA_YUKSEKLIK:
					var dusman_var_mi = false
					
					if ana_oyun.binalar_verisi.has(komsu_koor):
						var b_sahip = ana_oyun.binalar_verisi[komsu_koor]["sahip"]
						if b_sahip != benim_isim:
							if ana_oyun.has_method("muttefik_mi") and ana_oyun.muttefik_mi(benim_isim, b_sahip):
								pass
							else:
								dusman_var_mi = true
								
					for d_piyon in ana_oyun.piyonlar:
						if d_piyon["koordinat"] == komsu_koor and d_piyon["sahip"] != benim_isim:
							if ana_oyun.has_method("muttefik_mi") and ana_oyun.muttefik_mi(benim_isim, d_piyon["sahip"]):
								pass
							else:
								dusman_var_mi = true
					
					var zaman_dalmasi = (sin(Time.get_ticks_msec() / 150.0) + 1.0) / 2.0
					var alfa = lerp(0.1, 0.9, zaman_dalmasi)
					var cizgi_rengi = Color(0.9, 0.2, 0.2, alfa) if dusman_var_mi else Color(0.2, 0.9, 0.3, alfa)
					
					var k_merkez = hex_merkezi_hesapla(komsu_koor.x, komsu_koor.y)
					var k_koseler = PackedVector2Array()
					for i in range(6):
						var aci = deg_to_rad(i * 60 + 30)
						k_koseler.append(k_merkez + Vector2(cos(aci), sin(aci)) * (HEX_RADIUS - HEX_BOSLUK))
					
					draw_polyline(k_koseler + PackedVector2Array([k_koseler[0]]), cizgi_rengi, 3.5)

	# 🟢 2. BİNALAR ÇİZİLİYOR
	for k in ana_oyun.binalar_verisi:
		var gorus_mesafe = gorus_haritasi.get(k, 3)
		if gorus_mesafe >= 3 and not bulutsuz_hexler.has(k): continue
		
		var parlaklik = 1.0 if gorus_mesafe <= 1 else (0.60 if gorus_mesafe == 2 else 0.30)
		var renk_filtresi = Color(parlaklik, parlaklik, parlaklik, 1.0)
		
		var b = ana_oyun.binalar_verisi[k]
		var m = hex_merkezi_hesapla(k.x, k.y)
		var bina_sahip = b["sahip"]
		var bina_renk_adi = ana_oyun.secilen_renkler.get(bina_sahip, "Beyaz")
		var r = ana_oyun.oyuncu_renkleri.get(bina_renk_adi, Color.WHITE) * renk_filtresi
		
		if b["tur"] == "sehir_merkezi":
			var b_med = ana_oyun.medeniyetler_verisi.get(bina_sahip, "")
			var b_resim = sehir_merkezi_resimleri.get(b_med, null)
			if b_resim != null:
				var g_genislik = b_resim.get_width()
				var g_yukseklik = b_resim.get_height()
				var c_yukseklik = 95.0
				var c_genislik = c_yukseklik * (float(g_genislik) / float(g_yukseklik))
				var b_kutusu = Rect2(m.x - (c_genislik / 2.0), (m.y - (c_yukseklik / 2.0)) - 10.0, c_genislik, c_yukseklik)
				draw_texture_rect_region(b_resim, b_kutusu, Rect2(0,0, g_genislik, g_yukseklik), renk_filtresi)
			else:
				draw_rect(Rect2(m - Vector2(15,15), Vector2(30,30)), r)
				draw_rect(Rect2(m - Vector2(15,15), Vector2(30,30)), Color.BLACK * renk_filtresi, false, 2.0)
				
		elif b["tur"] in ["oduncu_kampi", "tas_ocagi", "tarla"]:
			var b_resim = null
			var tur = b["tur"]
			var seviye = b.get("seviye", 1)
			
			if tur == "oduncu_kampi":
				b_resim = oduncu_resimleri.get(seviye, oduncu_resimleri[1])
			elif tur == "tarla":
				b_resim = tarla_resimleri.get(seviye, tarla_resimleri[1])
			elif tur == "tas_ocagi":
				b_resim = tasocagi_resimleri.get(seviye, tasocagi_resimleri[1])
			else:
				b_resim = bina_resimleri.get(tur, null)
				
			if b_resim != null:
				var g_genislik = b_resim.get_width()
				var g_yukseklik = b_resim.get_height()
				var c_yukseklik = 75.0 if tur in ["oduncu_kampi", "tarla", "tas_ocagi"] else 55.0
				var c_genislik = c_yukseklik * (float(g_genislik) / float(g_yukseklik))
				var b_kutusu = Rect2(m.x - (c_genislik / 2.0), m.y - (c_yukseklik / 2.0), c_genislik, c_yukseklik)
				draw_texture_rect_region(b_resim, b_kutusu, Rect2(0,0, g_genislik, g_yukseklik), renk_filtresi)
			else:
				if tur == "oduncu_kampi": draw_polygon(PackedVector2Array([m + Vector2(0,-15), m + Vector2(-15,15), m + Vector2(15,15)]), PackedColorArray([r]))
				elif tur == "tas_ocagi": draw_circle(m, 12.0, r)
				elif tur == "tarla": draw_rect(Rect2(m - Vector2(12,12), Vector2(24,24)), r, false, 2.0)

		elif b["tur"] == "oncu_kampi":
			var med = ana_oyun.medeniyetler_verisi.get(b["sahip"], "Osmanlı")
			var kamp_ikonu = piyon_resimleri.get(med)
			draw_circle(m, 27.0, Color(r.r, r.g, r.b, 0.35) * renk_filtresi)
			if kamp_ikonu:
				draw_texture_rect(kamp_ikonu, Rect2(m - Vector2(22, 22), Vector2(44, 44)), false, renk_filtresi)
			draw_string(ThemeDB.fallback_font, m + Vector2(-22, 36), "KAMP", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, renk_filtresi)

	# 🟢 3. ÖNCÜLER (PİYONLAR) ÇİZİLİYOR
	var piyon_gruplari = {}
	for i in range(ana_oyun.piyonlar.size()):
		var k = ana_oyun.piyonlar[i]["koordinat"]
		if not piyon_gruplari.has(k): piyon_gruplari[k] = []
		piyon_gruplari[k].append(i)

	for k in piyon_gruplari:
		var gorus_mesafe = gorus_haritasi.get(k, 3)
		if gorus_mesafe >= 3: continue
		
		var parlaklik = 1.0 if gorus_mesafe <= 1 else (0.60 if gorus_mesafe == 2 else 0.30)
		var renk_filtresi = Color(parlaklik, parlaklik, parlaklik, 1.0)
		var p_listesi = piyon_gruplari[k]
		var m = hex_merkezi_hesapla(k.x, k.y)
		var count = p_listesi.size()
		
		for j in range(count):
			var p_idx = p_listesi[j]
			var p = ana_oyun.piyonlar[p_idx]
			var p_pos = m
			
			if count == 2:
				if j == 0: p_pos += Vector2(-12, 0)
				if j == 1: p_pos += Vector2(12, 0)
			elif count == 3:
				if j == 0: p_pos += Vector2(0, -15)
				if j == 1: p_pos += Vector2(-15, 12)
				if j == 2: p_pos += Vector2(15, 12)
			elif count >= 4:
				if j == 0: p_pos += Vector2(-15, -15)
				if j == 1: p_pos += Vector2(15, -15)
				if j == 2: p_pos += Vector2(-15, 15)
				if j == 3: p_pos += Vector2(15, 15)

			var piyon_sahip = p["sahip"]
			var p_renk_adi = ana_oyun.secilen_renkler.get(piyon_sahip, "Beyaz")
			var p_renk = ana_oyun.oyuncu_renkleri.get(p_renk_adi, Color.WHITE) * renk_filtresi
			var p_med = ana_oyun.medeniyetler_verisi.get(piyon_sahip, "")
			var p_resim = piyon_resimleri.get(p_med, null)

			if p_resim != null:
				var g_genislik = p_resim.get_width()
				var g_yukseklik = p_resim.get_height()
				var c_yukseklik = 90.0
				var c_genislik = c_yukseklik * (float(g_genislik) / float(g_yukseklik))
				var p_kutusu = Rect2(p_pos.x - (c_genislik / 2.0), p_pos.y - c_yukseklik + 15.0, c_genislik, c_yukseklik)
				draw_texture_rect_region(p_resim, p_kutusu, Rect2(0,0, g_genislik, g_yukseklik), renk_filtresi)
			else:
				var dairesel_pos = p_pos
				draw_circle(dairesel_pos, 10.0, p_renk)
				draw_arc(dairesel_pos, 10.0, 0, TAU, 16, Color.BLACK * renk_filtresi, 2.0)

	# 🟢 4. EN ÜST: Seçili öncünün altın rengi ok işareti (Her şeyin en üstünde görünür)
	if ana_oyun.secili_piyon_index != -1 and ana_oyun.secili_piyon_index < ana_oyun.piyonlar.size() and not ana_oyun.kart_insa_modu_aktif:
		var secili_piyon = ana_oyun.piyonlar[ana_oyun.secili_piyon_index]
		var p_koor = secili_piyon["koordinat"]
		var isaret_merkezi = hex_merkezi_hesapla(p_koor.x, p_koor.y)
		
		var ayni_karedeki_piyon_sayisi = 0
		var benim_siram = -1
		for i in range(ana_oyun.piyonlar.size()):
			if ana_oyun.piyonlar[i]["koordinat"] == p_koor:
				if i == ana_oyun.secili_piyon_index: benim_siram = ayni_karedeki_piyon_sayisi
				ayni_karedeki_piyon_sayisi += 1
				
		if ayni_karedeki_piyon_sayisi == 2:
			if benim_siram == 0: isaret_merkezi += Vector2(-12, 0)
			if benim_siram == 1: isaret_merkezi += Vector2(12, 0)
		elif ayni_karedeki_piyon_sayisi == 3:
			if benim_siram == 0: isaret_merkezi += Vector2(0, -15)
			if benim_siram == 1: isaret_merkezi += Vector2(-15, 12)
			if benim_siram == 2: isaret_merkezi += Vector2(15, 12)
		elif ayni_karedeki_piyon_sayisi >= 4:
			if benim_siram == 0: isaret_merkezi += Vector2(-15, -15)
			if benim_siram == 1: isaret_merkezi += Vector2(15, -15)
			if benim_siram == 2: isaret_merkezi += Vector2(-15, 15)
			if benim_siram == 3: isaret_merkezi += Vector2(15, 15)
		
		var isaret_pos = isaret_merkezi + Vector2(0, -75.0)
		var z_dalmasi = sin(Time.get_ticks_msec() / 250.0) * 4.0
		isaret_pos.y += z_dalmasi
		
		var ok_noktalari = PackedVector2Array([
			isaret_pos + Vector2(-10, -15),
			isaret_pos + Vector2(10, -15),
			isaret_pos + Vector2(0, 0)
		])
		
		draw_polygon(ok_noktalari, PackedColorArray([Color.GOLD]))
		draw_polyline(ok_noktalari + PackedVector2Array([ok_noktalari[0]]), Color.DARK_GOLDENROD, 2.0)

func hex_merkezi_hesapla(x, y) -> Vector2:
	var offset_x = (HEX_RADIUS * sqrt(3) / 2.0) if y % 2 == 1 else 0.0
	return Vector2(x * HEX_RADIUS * sqrt(3) + offset_x + 120.0, y * HEX_RADIUS * 1.5 + 120.0)

func hex_komsu_mu(a: Vector2i, b: Vector2i) -> bool:
	var komsular = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(0, 1), Vector2i(-1, 1)] if a.y % 2 == 0 else [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(0, 1)]
	return (b - a) in komsular

func tiklanan_hexi_bul(fare_pos: Vector2) -> Vector2i:
	for x in range(HARITA_GENISLIK):
		for y in range(HARITA_YUKSEKLIK):
			var koor = Vector2i(x, y)
			if fare_pos.distance_to(hex_merkezi_hesapla(x, y)) < (HEX_RADIUS * 0.85):
				return koor
	return Vector2i(-1, -1)

func hex_mesafesi(a: Vector2i, b: Vector2i) -> int:
	var q1 = a.x - floor(a.y / 2.0)
	var r1 = a.y
	var s1 = -q1 - r1
	var q2 = b.x - floor(b.y / 2.0)
	var r2 = b.y
	var s2 = -q2 - r2
	return int(max(abs(q1 - q2), max(abs(r1 - r2), abs(s1 - s2))))

