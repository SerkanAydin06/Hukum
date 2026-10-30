extends Node
class_name YapayZeka

# Sunucuda çalışan rakip. Yalnızca herkese açık bilgiyi (keşfedilmiş arazi,
# binalar, piyonlar, kaynaklar) ve kendi elini kullanır; keşfedilmemiş araziyi,
# rakip ellerini veya deste sırasını görmez. Her hamleyi insan oyuncularla aynı
# doğrulanmış yoldan (AnaOyun._sunucu_adina) yapar.

const BIYOMLAR = ["cim", "cim", "cim", "orman", "dag"]   # çimen şehir yiyecek üretir
const GEREKEN_BIYOM = {"oduncu_kampi": "orman", "tas_ocagi": "dag"}

var ana
var hamle_araligi := 0.7     # insanın izleyebilmesi için iki hamle arası bekleme
var _bekleme := 0.0
var _tur_denemeleri := 0
var _son_tur := []

func _ready():
	ana = get_parent()

func _process(delta: float):
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server() or ana.oyun_bitti or ana.oyuncular.is_empty(): return
	_bekleme -= delta
	if _bekleme > 0.0: return
	if ana.savas.savas_aktif:
		if _savasta_hamle_yap(): _bekleme = hamle_araligi
		return
	if ana.savas.sonuc_gosteriliyor or ana.aktif_sira >= ana.oyuncular.size(): return
	var isim = ana.oyuncular[ana.aktif_sira]
	if not ana.bot_mu(isim) or isim in ana.ayrilan_oyuncular: return
	var tur = [ana.aktif_sira, ana.tur_sayaci]
	if tur != _son_tur:
		_son_tur = tur
		_tur_denemeleri = 0
	_tur_denemeleri += 1
	if _tur_denemeleri > 25 or not _hamle_yap(isim):
		_yap(isim, "tur_ekonomi", "sirayi_degistir_rpc", [])
	_bekleme = hamle_araligi

# --- ZORLUK ---
# Zorluk yalnızca karar kalitesini değiştirir; hiçbir seviye gizli bilgiye bakmaz
# veya ek kaynak almaz.
#   kolay: rastgele şehir arazisi, AP'yi sık sık yarıda bırakır, geliştirme ve
#          kart dönüştürme yapmaz, yalnız büyük orduyla saldırır.
#   orta : dengeli öncelikler.
#   zor  : yiyecek ekonomisini önce kurar, geliştirmelere (2 puan) öncelik verir,
#          daha çok kart çeker, liderin öncülerine saldırır.
func _zorluk(isim: String) -> String:
	return ana.yapay_zeka_zorluk.get(isim, "orta")

func _sehir_biyomu(isim: String) -> String:
	match _zorluk(isim):
		"kolay": return BIYOMLAR.pick_random()
		"zor": return "cim"
	return "cim" if randf() < 0.8 else BIYOMLAR.pick_random()

# --- TUR ---
func _hamle_yap(isim: String) -> bool:
	if not ana.sehir_merkezleri.get(isim, false):
		var hex = _sehir_hexi()
		return hex != Vector2i(-1, -1) and _yap(isim, "aksiyon", "bina_kur_rpc", [hex, isim, "sehir_merkezi", _sehir_biyomu(isim)])
	_ticaret_yap(isim)
	if not ana.ilk_tur_bitti or ana.aktif_oyuncu_aksiyon_hakki <= 0: return false
	if _zorluk(isim) == "kolay" and randf() < 0.3: return false
	for aday in _adaylar(isim):
		if _yap(isim, aday[0], aday[1], aday[2]): return true
	return false

func _adaylar(isim: String) -> Array:
	var liste = []
	var k = ana.oyuncu_kaynaklari[isim]
	var el = ana.oyuncu_elleri.get(isim, [])
	var zorluk = _zorluk(isim)
	var yedek = {"kolay": 1, "orta": 4, "zor": 3}[zorluk]           # keşif/toprak için bırakılan yiyecek
	var ordu = {"kolay": 4, "orta": 2, "zor": 2}[zorluk]            # saldırı için gereken savaş kartı
	var kart_hedefi = {"kolay": 3, "orta": 5, "zor": 6}[zorluk]     # elde tutulmak istenen inşa kartı
	# 1) Elindeki inşa, gelişim ve aksiyon kartları
	for i in range(el.size()):
		var kart = el[i]
		var mo = int(kart.get("odun_maliyet", 0))
		var mt = int(kart.get("tas_maliyet", 0))
		match kart.get("hedef"):
			"harita":
				if k["odun"] < mo or k["tas"] < mt: continue
				for hex in _bos_toprak(isim, GEREKEN_BIYOM.get(kart["tur"], "cim")):
					liste.append(["aksiyon", "kart_oyna_rpc", [isim, kart["tur"], hex, mo, mt, i]])
					break
			"kendi_binasi":
				if zorluk == "kolay" or k["odun"] < mo or k["tas"] < mt: continue
				for hex in ana.binalar_verisi:
					var b = ana.binalar_verisi[hex]
					if b["sahip"] == isim and b.get("seviye", 1) < 3 and (kart.get("bina_turu") == "joker" or b["tur"] == kart.get("bina_turu")):
						liste.append(["aksiyon", "bina_yukselt_rpc", [isim, hex, mo, mt, i]])
						break
			"direkt":
				liste.append(["aksiyon", "aksiyon_karti_kullan_rpc", [isim, kart["tur"], i]])
	if zorluk == "zor": liste.sort_custom(_zor_kart_onceligi.bind(isim))
	var savas_eli = _savas_karti_sayisi(isim)
	var insa_eli = el.size() - savas_eli
	# 2) Öncünün durduğu toprağı topraklarına kat (1 puan), yiyecek yedeği bırakarak
	if k["yiyecek"] >= max(3, yedek):
		for p in ana.piyonlar:
			var hex = p["koordinat"]
			var sahip = ana.kontrol_edilen_hexler.get(hex, "")
			if p["sahip"] == isim and sahip != isim and not ana.muttefik_mi(isim, sahip) and ana.hex_dosta_komsu_mu(hex, isim):
				liste.append(["aksiyon", "hakimiyet_kur_rpc", [isim, hex]])
	# 3) Elinde oynanacak kart yoksa önce kart çek
	if insa_eli < 2:
		liste.append(["aksiyon", "normal_kart_cek_rpc", [isim]])
	# 4) Yeterli orduyla komşu düşman öncüsüne veya toprağına saldır
	if savas_eli >= ordu:
		var hedefler = _saldiri_hedefleri(isim)
		if zorluk == "zor": hedefler.sort_custom(_lider_onceligi)
		for saldiri in hedefler:
			liste.append(["aksiyon", "savas_baslat_rpc", saldiri])
	# 5) Sınırdaki bilinmeyen araziyi keşfet
	if k["yiyecek"] >= yedek:
		for kesif in _kesif_hedefleri(isim):
			liste.append(["aksiyon", "kesif_ve_hareket_rpc", [kesif[0], kesif[1], isim]])
	# 6) Öncü yetiştir
	if k["yiyecek"] >= 7 and _oncu_sayisi(isim) < (5 if zorluk == "zor" else 4):
		for hex in ana.binalar_verisi:
			var b = ana.binalar_verisi[hex]
			if b["tur"] == "oncu_kampi" and b["sahip"] == isim:
				liste.append(["aksiyon", "oncu_uret_rpc", [isim, hex]])
				break
	# 7) Kart çek
	if insa_eli < kart_hedefi:
		liste.append(["aksiyon", "normal_kart_cek_rpc", [isim]])
	if k["altin"] >= 3 and savas_eli < 4:
		liste.append(["aksiyon", "savas_karti_cek_rpc", [isim]])
	# 8) Kullanılamayan kartı eksik kaynağa çevir
	if zorluk != "kolay":
		for feda in _feda_adaylari(isim):
			liste.append(["aksiyon", "karti_feda_et_rpc", feda])
	# 9) Keşfedecek yeri kalmayan öncüyü sınıra yürüt
	if k["yiyecek"] >= 2:
		for hareket in _yuruyus_hedefleri(isim):
			liste.append(["aksiyon", "piyon_hareket_rpc", hareket])
	return liste

func _ticaret_yap(isim: String):
	var pazar = false
	for b in ana.binalar_verisi.values():
		if b["sahip"] == isim and b["tur"] == "ticaret_merkezi": pazar = true
	if not pazar: return
	var maliyet = ana.tur_ekonomi.ticaret_maliyeti(isim)
	var fazla = 8 if _zorluk(isim) == "zor" else 15
	for tur in ["odun", "tas", "yiyecek"]:
		if ana.oyuncu_kaynaklari[isim][tur] >= maliyet + fazla:
			_yap(isim, "tur_ekonomi", "ticaret_yap_rpc", [isim, tur])

# --- SAVAŞ ---
func _savasta_hamle_yap() -> bool:
	if ana.savas.sonuc_gosteriliyor: return false
	var taraflar = ana.savas.savas_taraflari()
	if ana.savas.son_kartlar_dict.is_empty():
		for i in range(2):
			var isim = taraflar[i]
			if ana.bot_mu(isim) and not ana.savas.secilen_savas_kartlari.has(isim):
				var kartlar = []
				var idxler = []
				var el = ana.oyuncu_elleri.get(isim, [])
				for j in range(el.size()):
					var kart = el[j]
					if kart.get("hedef") != "savas": continue
					if kart.get("tur") in ["kocbasi", "mancinik"] and (i != 0 or ana.savas.savas_hedef_turu != "bina"): continue
					if kartlar.size() >= 7: break
					kartlar.append(kart.duplicate(true))
					idxler.append(j)
				ana._sunucu_adina(isim, "aksiyon", "savas_hamlesi_yap_rpc", [isim, kartlar, idxler])
				return true
		return false
	for i in range(2):
		var deger = ana.savas.zar_saldiran_deger if i == 0 else ana.savas.zar_savunan_deger
		if ana.bot_mu(taraflar[i]) and deger == -1:
			ana._sunucu_adina(taraflar[i], "savas", "zar_at_istegi_rpc", [i == 0])
			return true
	return false

# --- YARDIMCILAR ---
# Hamleyi doğrulanmış yoldan dener; oyun durumu değiştiyse başarılı sayar.
func _yap(isim: String, yonetici: String, metod: String, args: Array) -> bool:
	var once = _imza(isim)
	ana._sunucu_adina(isim, yonetici, metod, args)
	return _imza(isim) != once

func _imza(isim: String) -> Array:
	return [ana.aktif_sira, ana.aktif_oyuncu_aksiyon_hakki, ana.oyuncu_kaynaklari.get(isim, {}).duplicate(),
		ana.oyuncu_elleri.get(isim, []).size(), ana.binalar_verisi.size(), ana.kontrol_edilen_hexler.size(),
		ana.piyonlar.size(), ana.savas.savas_aktif, ana.sehir_merkezleri.get(isim, false)]

func _komsular(hex: Vector2i) -> Array:
	var liste = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var k = hex + Vector2i(dx, dy)
			if k != hex and ana.hex_gecerli_mi(k) and ana.harita.hex_komsu_mu(hex, k): liste.append(k)
	return liste

func _bos_toprak(isim: String, biyom: String) -> Array:
	var liste = []
	for hex in ana.kontrol_edilen_hexler:
		if ana.kontrol_edilen_hexler[hex] == isim and not ana.binalar_verisi.has(hex) and ana.harita.kesfedilen_hexler.get(hex, "") == biyom:
			liste.append(hex)
	return liste

func _sehir_hexi() -> Vector2i:
	# Diğer şehirlerden uzak, boş ve keşfedilmemiş bir hex.
	var en_iyi = Vector2i(-1, -1)
	var en_iyi_puan = -1
	for x in range(1, ana.harita.HARITA_GENISLIK - 1):
		for y in range(1, ana.harita.HARITA_YUKSEKLIK - 1):
			var hex = Vector2i(x, y)
			if ana.harita.kesfedilen_hexler.has(hex) or ana.kontrol_edilen_hexler.has(hex) or ana.binalar_verisi.has(hex): continue
			var mesafe = 99
			for diger in ana.binalar_verisi:
				mesafe = min(mesafe, ana.harita.hex_mesafesi(hex, diger))
			for p in ana.piyonlar:
				mesafe = min(mesafe, ana.harita.hex_mesafesi(hex, p["koordinat"]))
			var puan = mesafe * 10 + randi() % 10
			if puan > en_iyi_puan:
				en_iyi_puan = puan
				en_iyi = hex
	return en_iyi

func _kesif_hedefleri(isim: String) -> Array:
	var liste = []
	for i in range(ana.piyonlar.size()):
		var p = ana.piyonlar[i]
		if p["sahip"] != isim: continue
		for hex in _komsular(p["koordinat"]):
			if ana.harita.kesfedilen_hexler.has(hex): continue
			# Topraklarına komşu keşifler önce: sonraki hamlede hakimiyet kurulabilir.
			if ana.hex_dosta_komsu_mu(hex, isim): liste.push_front([i, hex])
			else: liste.append([i, hex])
	return liste

func _yuruyus_hedefleri(isim: String) -> Array:
	var liste = []
	for i in range(ana.piyonlar.size()):
		var p = ana.piyonlar[i]
		if p["sahip"] != isim: continue
		var bos_komsu = false
		for hex in _komsular(p["koordinat"]):
			if not ana.harita.kesfedilen_hexler.has(hex): bos_komsu = true
		if bos_komsu: continue
		for hex in _komsular(p["koordinat"]):
			if ana.kontrol_edilen_hexler.get(hex, isim) != isim: continue
			if not ana.harita.kesfedilen_hexler.has(hex): continue
			for komsu in _komsular(hex):
				if not ana.harita.kesfedilen_hexler.has(komsu):
					liste.append([i, hex])
					break
	liste.shuffle()
	return liste

func _saldiri_hedefleri(isim: String) -> Array:
	var liste = []
	for i in range(ana.piyonlar.size()):
		var p = ana.piyonlar[i]
		if p["sahip"] != isim: continue
		for hex in _komsular(p["koordinat"]):
			if ana.binalar_verisi.has(hex): continue
			var savunan_idx = -1
			for j in range(ana.piyonlar.size()):
				var q = ana.piyonlar[j]
				if q["koordinat"] == hex and q["sahip"] != isim and not ana.muttefik_mi(isim, q["sahip"]):
					savunan_idx = j
			var sahip = ana.kontrol_edilen_hexler.get(hex, "")
			var dusman_toprak = sahip != "" and sahip != isim and not ana.muttefik_mi(isim, sahip)
			if savunan_idx != -1 or dusman_toprak:
				liste.append([i, savunan_idx, hex.x, hex.y, "normal"])
	return liste

# Elde tutulan ama şu an oynanamayan kartlar, en çok ihtiyaç duyulan kaynağa çevrilir.
func _feda_adaylari(isim: String) -> Array:
	var k = ana.oyuncu_kaynaklari[isim]
	var ihtiyac = ""
	if k["yiyecek"] < 4: ihtiyac = "yiyecek"
	elif k["odun"] < 6: ihtiyac = "odun"
	elif k["tas"] < 2: ihtiyac = "tas"
	if ihtiyac == "": return []
	var liste = []
	var el = ana.oyuncu_elleri.get(isim, [])
	for i in range(el.size()):
		var kart = el[i]
		var izinli = ["odun"]
		if kart.get("hedef") == "savas": continue
		elif kart.get("tur") == "ticaret_merkezi": izinli = ["odun", "tas", "yiyecek"]
		elif kart.get("tur") in ["tarla", "gelismis_sulama"]: izinli = ["yiyecek"]
		elif kart.get("tur") in ["tas_ocagi", "derin_damarlar"]: izinli = ["tas"]
		if ihtiyac in izinli and not _kart_oynanabilir(isim, kart):
			liste.append([isim, ihtiyac, i])
	return liste

func _kart_oynanabilir(isim: String, kart: Dictionary) -> bool:
	match kart.get("hedef"):
		"harita": return not _bos_toprak(isim, GEREKEN_BIYOM.get(kart["tur"], "cim")).is_empty()
		"kendi_binasi":
			for b in ana.binalar_verisi.values():
				if b["sahip"] == isim and b.get("seviye", 1) < 3 and (kart.get("bina_turu") == "joker" or b["tur"] == kart.get("bina_turu")): return true
			return false
	return true

# Zor: geliştirme (2 puan) önce; yiyecek üretimi zayıfsa tarla öne alınır.
func _zor_kart_onceligi(a: Array, b: Array, isim: String) -> bool:
	return _kart_puani(a, isim) > _kart_puani(b, isim)

func _kart_puani(aday: Array, isim: String) -> int:
	if aday[1] == "bina_yukselt_rpc": return 3
	if aday[1] == "kart_oyna_rpc":
		if aday[2][1] == "tarla" and ana.tur_ekonomi.bina_uretimi(isim)["yiyecek"] < 2: return 4
		return 2
	return 1

# Zor: puanı en yüksek rakibin öncüsüne/toprağına saldırmayı yeğler.
func _lider_onceligi(a: Array, b: Array) -> bool:
	return _hedef_puani(a) > _hedef_puani(b)

func _hedef_puani(saldiri: Array) -> int:
	var hex = Vector2i(saldiri[2], saldiri[3])
	var sahip = ana.kontrol_edilen_hexler.get(hex, "")
	if saldiri[1] >= 0 and saldiri[1] < ana.piyonlar.size(): sahip = ana.piyonlar[saldiri[1]]["sahip"]
	return ana.puanlar.get(sahip, 0)

func _savas_karti_sayisi(isim: String) -> int:
	var sayi = 0
	for kart in ana.oyuncu_elleri.get(isim, []):
		if kart.get("hedef") == "savas": sayi += 1
	return sayi

func _oncu_sayisi(isim: String) -> int:
	var sayi = 0
	for p in ana.piyonlar:
		if p["sahip"] == isim: sayi += 1
	return sayi
