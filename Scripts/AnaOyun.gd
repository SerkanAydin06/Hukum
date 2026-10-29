extends Node2D
class_name AnaOyun

# --- ORTAK VERİ YAPILARI ---
var binalar_verisi = {}
var piyonlar = []
var oyuncular = [] 
var oyuncu_elleri = {}
var oyuncu_peer_idleri = []   # oyuncular[i] <-> oyuncu_peer_idleri[i]
var aktif_sira = 0
var benim_indexim = 0
var oyuncu_profil_no = {}
var oyuncu_renkleri = {
	"Beyaz": Color.WHITE, "Kirmizi": Color.RED, "Mavi": Color.BLUE,
	"Sari": Color.YELLOW, "Yesil": Color.GREEN, "Mor": Color.PURPLE, "CamGobegi": Color.CYAN
}

var sehir_merkezleri = {}
var puanlar = {}
var oyuncu_kaynaklari = {}
var kontrol_edilen_hexler = {}
var efendiler = {}
var odenen_vergiler = {} 
var medeniyetler_verisi = {} 

# 🟢 YENİ: Oyuncuların isimleriyle eşleşen renklerini tutacağımız sözlük
var secilen_renkler = {}

var bekleyen_onay = ""
var secilen_baslangic_biyomu = ""
var secili_kart_index = -1
var secili_piyon_index = -1
var aktif_oyuncu_aksiyon_hakki = 0
var ilk_tur_bitti = false
var insa_modu_aktif = false
var gecici_koordinat = Vector2i(-1, -1)
var tur_sayaci = 1
var kurulabilir_hexler = []
var kart_insa_modu_aktif = false

var oyun_bitti = false
var ayrilan_oyuncular = []   # oyundan kopan oyuncuların isimleri (sıraları atlanır)
var savas_puanlari = {}   # 🟢 YENİ: isim -> int (savaş kazanma/kaybetme sayacı)
const HEDEF_PUAN = 50

# --- ALT SİSTEM BAĞLANTILARI ---
@onready var deste = %DesteYonetici
@onready var savas = %SavasYonetici
@onready var harita = $Harita

@onready var arayuz = $ArayuzYonetici
@onready var tur_ekonomi = $TurEkonomiYonetici
@onready var aksiyon = $AksiyonYonetici

var oyun_menusu

func _ready():
	oyun_menusu = load("res://Scripts/OyunMenu.gd").new()
	add_child(oyun_menusu)
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_peer_ayrildi)
	deste.desteleri_hazirla()
	arayuz.ui_sinyallerini_bagla()
	arayuz.sag_paneli_guncelle(Vector2i(-1, -1))
	if Network.son_lobi_verisi.size() > 0:
		lobi_verisiyle_baslat(Network.son_lobi_verisi)
	else:
		var test_veri = {
			multiplayer.get_unique_id(): {
				"isim": Global.oyuncu_ismi, 
				"renk": "Beyaz", 
				"medeniyet": "Osmanlı", 
				"hazir": true,
				"profil_no": Global.profil_no 
			}
		}
		lobi_verisiyle_baslat(test_veri)

func lobi_verisiyle_baslat(gelen_lobi_verisi: Dictionary):
	oyuncular.clear()
	oyuncu_peer_idleri.clear()
	var peer_idleri = gelen_lobi_verisi.keys()
	peer_idleri.sort()
	
	for id in peer_idleri:
		var o_veri = gelen_lobi_verisi[id]
		
		# 🟢 DÜZELTME: Oyuncunun gerçek adını alıyoruz, renk adını değil!
		var gercek_isim = o_veri.get("isim", "Oyuncu " + str(id).left(4))
		# Aynı isimli oyuncular birbirinin verisini ezmesin (peer sırası her client'ta aynı)
		var temel_isim = gercek_isim
		var ek = 2
		while gercek_isim in oyuncular:
			gercek_isim = "%s (%d)" % [temel_isim, ek]
			ek += 1
		var secilen_renk = o_veri.get("renk", "Beyaz")
		
		oyuncular.append(gercek_isim)
		oyuncu_peer_idleri.append(id)
		oyuncu_elleri[gercek_isim] = []
		savas_puanlari[gercek_isim] = 0
		
		secilen_renkler[gercek_isim] = secilen_renk
		
		medeniyetler_verisi[gercek_isim] = o_veri.get("medeniyet", "")
		oyuncu_profil_no[gercek_isim] = o_veri.get("profil_no", 1)
		sehir_merkezleri[gercek_isim] = false
		puanlar[gercek_isim] = 0
		oyuncu_kaynaklari[gercek_isim] = {"odun": 18, "tas": 18, "yiyecek": 10, "altin": 3, "koylu": 0, "max_nufus": 3}
		odenen_vergiler[gercek_isim] = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}
		
	benim_indexim = peer_idleri.find(multiplayer.get_unique_id())
	if benim_indexim == -1:
		push_error("KRİTİK HATA: Bu client'ın peer ID'si (%d) lobi verisinde bulunamadı! Oyuncu listesi: %s" % [multiplayer.get_unique_id(), str(peer_idleri)])
		return
		
	arayuz.arayuzu_guncelle()
	
	# 🟢 YENİ EKLENEN KISIM: Oyun başlarken harita görüşünü ilk kez hesaplatıyoruz
	if harita and harita.has_method("gorus_haritasini_guncelle"):
		harita.gorus_haritasini_guncelle()
		harita.queue_redraw()
	# --------------------------------------------------------------------------
	
	if oyuncular.size() > 0:
		var ilk_oyuncu = oyuncular[0]
		var ilk_renk_kodu = oyuncu_renkleri[secilen_renkler[ilk_oyuncu]].to_html(false)
		
		# 🟢 DÜZELTME: "Kirmizi oyuncusunda" yazması yerine "[Gerçek İsim] oyuncusunda" yazar ve kendi rengine boyar
		var renkli_isim_metni = "[color=#%s][b]%s[/b][/color]" % [ilk_renk_kodu, ilk_oyuncu]
		arayuz.olay_yaz("[color=gold]⚔️ Oyun Başladı! Sıra %s oyuncusunda (%s).[/color]" % [renkli_isim_metni, medeniyetler_verisi[ilk_oyuncu]])

# --- OYUNCU KOPMASI ---
# Sunucu, kopan oyuncuyu herkese bildirir; sırası ondaysa oyun kilitlenmesin diye tur geçilir
func _peer_ayrildi(id: int):
	var idx = oyuncu_peer_idleri.find(id)
	if idx != -1: oyuncu_ayrildi_rpc.rpc(oyuncular[idx])

@rpc("authority", "call_local", "reliable")
func oyuncu_ayrildi_rpc(isim: String):
	if isim in ayrilan_oyuncular: return
	ayrilan_oyuncular.append(isim)
	arayuz.olay_yaz("[color=gray]🚪 %s oyundan ayrıldı.[/color]" % arayuz.renkli_isim(isim))
	if savas.savas_aktif and isim in savas.savas_taraflari():
		savas.savasi_iptal_et()
	if oyuncular[aktif_sira] == isim and ayrilan_oyuncular.size() < oyuncular.size():
		tur_ekonomi.turu_bitir()

# --- RPC GÜVENLİĞİ ---
# RPC'yi gönderen peer'ın oyuncu ismi ("" = tanınmayan peer)
func rpc_gonderen_ismi() -> String:
	var gonderen = multiplayer.get_remote_sender_id()
	if gonderen == 0: gonderen = multiplayer.get_unique_id()
	var idx = oyuncu_peer_idleri.find(gonderen)
	return oyuncular[idx] if idx != -1 else ""

# Gönderen, sırası gelen oyuncu mu? (isim verilirse o isimle de eşleşmeli)
func rpc_sirada_mi(isim: String = "") -> bool:
	if oyun_bitti or savas.savas_aktif or savas.sonuc_gosteriliyor: return false
	if aktif_sira >= oyuncular.size(): return false
	var gonderen = rpc_gonderen_ismi()
	var gecerli = gonderen != "" and gonderen == oyuncular[aktif_sira] and (isim == "" or isim == gonderen)
	if not gecerli: push_warning("Geçersiz RPC reddedildi (gönderen: %s, sıra: %s)" % [gonderen, oyuncular[aktif_sira]])
	return gecerli

# Gönderen sunucu mu?
func rpc_sunucudan_mi() -> bool:
	var gonderen = multiplayer.get_remote_sender_id()
	return gonderen == 0 or gonderen == 1

func hex_gecerli_mi(koor: Vector2i) -> bool:
	return koor.x >= 0 and koor.x < harita.HARITA_GENISLIK and koor.y >= 0 and koor.y < harita.HARITA_YUKSEKLIK

# Ortak Yardımcı Fonksiyonlar
# Vasal zincirinin en üstündeki hükümdar; bozuk kayıtlar sonsuz döngü oluşturmaz.
func koruyucu_efendi(isim: String) -> String:
	var gorulen = []
	var mevcut = isim
	while efendiler.get(mevcut, "") != "":
		if mevcut in gorulen: return isim
		gorulen.append(mevcut)
		mevcut = efendiler[mevcut]
	return mevcut

func muttefik_mi(isim1: String, isim2: String) -> bool:
	if isim1 == "" or isim2 == "": return false
	return koruyucu_efendi(isim1) == koruyucu_efendi(isim2)

func vasallik_gecerli_mi(vasal: String, efendi: String) -> bool:
	if vasal not in oyuncular or efendi not in oyuncular or vasal == efendi: return false
	var gorulen = []
	var mevcut = efendi
	while mevcut != "":
		if mevcut == vasal or mevcut in gorulen: return false
		gorulen.append(mevcut)
		mevcut = efendiler.get(mevcut, "")
	return true

func hex_dosta_komsu_mu(hedef_koor: Vector2i, sahip_isim: String) -> bool:
	for k in kontrol_edilen_hexler:
		if kontrol_edilen_hexler[k] == sahip_isim:
			if harita.hex_komsu_mu(k, hedef_koor): return true
	return false


# Score is game state; headless hosts and UI share this calculation.
func puan_hesapla(isim: String) -> int:
	var toplam = 0
	for sahip in kontrol_edilen_hexler.values():
		if sahip == isim: toplam += 1
	for bina in binalar_verisi.values():
		if bina["sahip"] == isim and bina["tur"] != "sehir_merkezi":
			toplam += bina.get("seviye", 1) * 2
	for efendi in efendiler.values():
		if efendi == isim: toplam += 5
	return toplam + savas_puanlari.get(isim, 0) * 2

func puanlari_guncelle():
	for isim in oyuncular: puanlar[isim] = puan_hesapla(isim)

func zaferi_kontrol_et():
	puanlari_guncelle()
	if not multiplayer.is_server() or oyun_bitti: return
	for isim in oyuncular:
		if isim not in ayrilan_oyuncular and puanlar[isim] >= HEDEF_PUAN:
			aksiyon.oyunu_bitir_rpc.rpc(isim, puanlar[isim])
			return
