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
	if not Network.merkezi_mod: Network.oturum_asamasi = "game"
	oyun_menusu = load("res://Scripts/OyunMenu.gd").new()
	add_child(oyun_menusu)
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_peer_ayrildi)
		multiplayer.peer_connected.connect(_maca_baglanan_peer)
	deste.desteleri_hazirla()
	arayuz.ui_sinyallerini_bagla()
	arayuz.sag_paneli_guncelle(Vector2i(-1, -1))
	if Network.donus_bekliyor:
		# Maça dönen istemci: durumu sunucudan bekler, kendi başına maç kurmaz.
		durum_iste_rpc.rpc_id(1)
		return
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
		_alistirma_rakiplerini_ekle(test_veri, Network.alistirma_rakip_sayisi)
		lobi_verisiyle_baslat(test_veri)
	if not yapay_zeka_oyunculari.is_empty() and multiplayer.is_server():
		var yz = YapayZeka.new()
		yz.name = "YapayZeka"
		add_child(yz)
	if Network.merkezi_mod: Network.sahne_hazir_rpc.rpc_id(1)
	elif not multiplayer.is_server(): Network.oyun_sahnesi_hazir_rpc.rpc_id(1)
	if multiplayer.is_server(): _donus_anahtarlarini_dagit()

# --- YAPAY ZEKÂ RAKİPLER ---
# Rakipler gerçek bağlantısı olmayan koltuklardır (negatif kimlik); hamlelerini
# sunucudaki YapayZeka düğümü, insanlarla aynı doğrulanmış yoldan yapar.
var yapay_zeka_oyunculari := []
const RAKIP_ADLARI = {"Osmanlı": "Orhan Gazi", "Venedik": "Dandolo", "Bizans": "Theodora", "Moğol": "Kubilay", "Viking": "Ragnhild", "Mısır": "Hatşepsut"}
const RAKIP_RENKLERI = ["Kirmizi", "Mavi", "Yesil", "Sari", "Mor", "CamGobegi"]

func bot_mu(isim: String) -> bool:
	return isim in yapay_zeka_oyunculari

func _alistirma_rakiplerini_ekle(veri: Dictionary, sayi: int):
	var insan = veri.values()[0]
	var medeniyetler = RAKIP_ADLARI.keys().filter(func(m): return m != insan["medeniyet"])
	medeniyetler.shuffle()
	for i in range(clampi(sayi, 0, 5)):
		var med = medeniyetler[i]
		veri[-(i + 1)] = {"isim": RAKIP_ADLARI[med], "renk": RAKIP_RENKLERI[i], "medeniyet": med,
			"hazir": true, "profil_no": (i % 8) + 1, "bot": true}

func lobi_verisiyle_baslat(gelen_lobi_verisi: Dictionary):
	oyuncular.clear()
	oyuncu_peer_idleri.clear()
	yapay_zeka_oyunculari.clear()
	var peer_idleri = gelen_lobi_verisi.keys()
	# İnsanlar peer kimliğine göre önce, rakipler sonra oynar (her eşte aynı sıra).
	peer_idleri.sort_custom(func(a, b):
		var bot_a = gelen_lobi_verisi[a].get("bot", false)
		var bot_b = gelen_lobi_verisi[b].get("bot", false)
		if bot_a != bot_b: return bot_b
		return a < b if not bot_a else a > b)
	
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
		if o_veri.get("bot", false): yapay_zeka_oyunculari.append(gercek_isim)
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
	if benim_indexim == -1 and Network.dedicated_mode: benim_indexim = 0
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

# --- MAÇA GERİ DÖNÜŞ (sunucu) ---
var _donus_anahtarlari := {}      # isim -> gizli anahtar
var _donus_rezervleri := {}       # yeni peer -> isim (durum görüntüsü bekleyen)
var _donus_kuyrugu := []          # durum isteyen, savaşın bitmesini bekleyen peerler

func _donus_anahtarlarini_dagit():
	if multiplayer.multiplayer_peer == null: return
	var kripto = Crypto.new()
	for i in range(oyuncular.size()):
		var peer = oyuncu_peer_idleri[i]
		if peer == multiplayer.get_unique_id() or peer < 0: continue
		var anahtar = kripto.generate_random_bytes(24).hex_encode()
		_donus_anahtarlari[oyuncular[i]] = anahtar
		Network.donus_anahtari_rpc.rpc_id(peer, anahtar, oyuncular[i])

# Geçerli anahtar, oyundan kopmuş bir oyuncuya aitse koltuğu ayırır; eski peer'ı döndürür.
func donus_rezerve_et(peer: int, anahtar: String) -> int:
	if oyun_bitti or anahtar.length() < 16: return -1
	for isim in _donus_anahtarlari:
		if _donus_anahtarlari[isim] != anahtar: continue
		if isim not in ayrilan_oyuncular or isim in _donus_rezervleri.values(): return -1
		_donus_rezervleri[peer] = isim
		return oyuncu_peer_idleri[oyuncular.find(isim)]
	return -1

const DONUS_KABUL_SURESI := 15.0

# Maç sırasında bağlanan peer bir oyuncu değildir; süre içinde dönüş anahtarıyla
# koltuğa oturmazsa bağlantısı kesilir (merkezi sunucuda Network aynı işi yapar).
func _maca_baglanan_peer(id: int):
	if Network.merkezi_mod: return
	get_tree().create_timer(DONUS_KABUL_SURESI).timeout.connect(func():
		if not is_inside_tree() or multiplayer.multiplayer_peer == null: return
		if id in oyuncu_peer_idleri or _donus_rezervleri.has(id): return
		if id in multiplayer.get_peers(): multiplayer.multiplayer_peer.disconnect_peer(id))

@rpc("any_peer", "call_remote", "reliable")
func durum_iste_rpc():
	if not multiplayer.is_server(): return
	var peer = multiplayer.get_remote_sender_id()
	if _donus_rezervleri.has(peer) and peer not in _donus_kuyrugu: _donus_kuyrugu.append(peer)
	_donus_kuyrugunu_isle()

# Savaş sürerken dönüş bekletilir; dönen oyuncu temiz bir tur durumuna katılır.
func _donus_kuyrugunu_isle():
	if _donus_kuyrugu.is_empty() or savas.savas_aktif or savas.sonuc_gosteriliyor: return
	for peer in _donus_kuyrugu.duplicate():
		_donus_kuyrugu.erase(peer)
		var isim = _donus_rezervleri.get(peer, "")
		_donus_rezervleri.erase(peer)
		if isim == "" or isim not in ayrilan_oyuncular or not peer in multiplayer.get_peers(): continue
		oyuncu_geri_dondu_rpc.rpc(isim, peer)
		donus_goruntusu_rpc.rpc_id(peer, _donus_goruntusu(isim))
		if sure_asamasi_adi != "": sure_baslat_rpc.rpc_id(peer, sure_asamasi_adi, maxf(_sure_kalan, 0.0))

@rpc("authority", "call_local", "reliable")
func oyuncu_geri_dondu_rpc(isim: String, peer: int):
	var idx = oyuncular.find(isim)
	if idx == -1: return
	oyuncu_peer_idleri[idx] = peer
	ayrilan_oyuncular.erase(isim)
	arayuz.olay_yaz("[color=light_green]↩ %s maça geri döndü.[/color]" % arayuz.renkli_isim(isim))
	arayuz.arayuzu_guncelle()

# Dönen oyuncunun görebileceği durum: kendi eli açık, rakip elleri ve deste sırası gizli.
func _donus_goruntusu(isim: String) -> Dictionary:
	var eller = {}
	var gorulmemis_insa = deste.normal_deste.duplicate(true)
	var gorulmemis_savas = deste.savas_destesi.duplicate(true)
	for o in oyuncular:
		eller[o] = []
		for kart in oyuncu_elleri.get(o, []):
			var savas_karti = kart.get("hedef") == "savas"
			if o == isim:
				eller[o].append(kart.duplicate(true))
			else:
				eller[o].append(deste.gizli_kart(savas_karti))
				(gorulmemis_savas if savas_karti else gorulmemis_insa).append(kart.duplicate(true))
	return {
		"oyuncular": oyuncular.duplicate(), "peerler": oyuncu_peer_idleri.duplicate(),
		"benim": oyuncular.find(isim), "eller": eller,
		"renkler": secilen_renkler.duplicate(true), "medeniyetler": medeniyetler_verisi.duplicate(true),
		"profiller": oyuncu_profil_no.duplicate(true), "sehirler": sehir_merkezleri.duplicate(true),
		"kaynaklar": oyuncu_kaynaklari.duplicate(true), "vergiler": odenen_vergiler.duplicate(true),
		"kontrol": kontrol_edilen_hexler.duplicate(true), "efendiler": efendiler.duplicate(true),
		"binalar": binalar_verisi.duplicate(true), "piyonlar": piyonlar.duplicate(true),
		"savas_puanlari": savas_puanlari.duplicate(true), "ayrilanlar": ayrilan_oyuncular.duplicate(),
		"aktif_sira": aktif_sira, "ap": aktif_oyuncu_aksiyon_hakki, "ilk_tur_bitti": ilk_tur_bitti,
		"tur_sayaci": tur_sayaci, "kesfedilen": harita.kesfedilen_hexler.duplicate(true),
		"normal_kalan": deste.normal_kalan, "savas_kalan": deste.savas_kalan,
		"atilan_insa": deste.atilan_insa_kartlari.duplicate(true), "atilan_savas": deste.atilan_savas_kartlari.duplicate(true),
		"gorulmemis_insa": gorulmemis_insa, "gorulmemis_savas": gorulmemis_savas,
	}

var donus_tamamlandi := false

@rpc("authority", "call_remote", "reliable")
func donus_goruntusu_rpc(g: Dictionary):
	if not Network.donus_bekliyor or typeof(g.get("oyuncular")) != TYPE_ARRAY: return
	Network.donus_bekliyor = false
	oyuncular = g["oyuncular"].duplicate()
	oyuncu_peer_idleri = g["peerler"].duplicate()
	benim_indexim = int(g["benim"])
	oyuncu_elleri = g["eller"].duplicate(true)
	secilen_renkler = g["renkler"].duplicate(true)
	medeniyetler_verisi = g["medeniyetler"].duplicate(true)
	oyuncu_profil_no = g["profiller"].duplicate(true)
	sehir_merkezleri = g["sehirler"].duplicate(true)
	oyuncu_kaynaklari = g["kaynaklar"].duplicate(true)
	odenen_vergiler = g["vergiler"].duplicate(true)
	kontrol_edilen_hexler = g["kontrol"].duplicate(true)
	efendiler = g["efendiler"].duplicate(true)
	binalar_verisi = g["binalar"].duplicate(true)
	piyonlar = g["piyonlar"].duplicate(true)
	savas_puanlari = g["savas_puanlari"].duplicate(true)
	ayrilan_oyuncular = g["ayrilanlar"].duplicate()
	aktif_sira = int(g["aktif_sira"])
	aktif_oyuncu_aksiyon_hakki = int(g["ap"])
	ilk_tur_bitti = bool(g["ilk_tur_bitti"])
	tur_sayaci = int(g["tur_sayaci"])
	harita.kesfedilen_hexler = g["kesfedilen"].duplicate(true)
	deste.normal_kalan = int(g["normal_kalan"])
	deste.savas_kalan = int(g["savas_kalan"])
	deste.atilan_insa_kartlari = g["atilan_insa"].duplicate(true)
	deste.atilan_savas_kartlari = g["atilan_savas"].duplicate(true)
	deste.normal_deste = g["gorulmemis_insa"].duplicate(true)
	deste.savas_destesi = g["gorulmemis_savas"].duplicate(true)
	deste.el = oyuncu_elleri.get(oyuncular[benim_indexim], []).duplicate(true)
	puanlari_guncelle()
	donus_tamamlandi = true
	Network.oyun_sahnesi_hazir_rpc.rpc_id(1)
	harita.gorus_haritasini_guncelle()
	arayuz.arayuzu_guncelle()
	deste.eldeki_kartlari_ciz()
	harita.queue_redraw()
	arayuz.olay_yaz("[color=light_green]↩ Maça geri döndün. Sıra %s oyuncusunda.[/color]" % arayuz.renkli_isim(oyuncular[aktif_sira]))

# --- OYUNCU KOPMASI ---
# Sunucu, kopan oyuncuyu herkese bildirir; sırası ondaysa oyun kilitlenmesin diye tur geçilir
func _peer_ayrildi(id: int):
	_donus_rezervleri.erase(id)
	_donus_kuyrugu.erase(id)
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

# --- SUNUCU SIRALI HAMLELER ---
# Oyuncular hamlelerini doğrudan birbirine göndermez. İstek sunucuya gider;
# sunucu bütün bilgiyle (eller, deste, harita) hamleyi önce kendinde çalıştırır.
# Kabul ederse aynı hamleyi, açılması gereken bilgilerle (oynanan kart, keşfedilen
# biyom) birlikte herkese aynı sırayla uygulatır. Böylece rakip elleri gizli kalır
# ve hiçbir eş durumu sunucudan önce değiştiremez.
const SIRALI_HAMLELER = {
	"aksiyon": ["kesif_ve_hareket_rpc", "bina_kur_rpc", "bina_yukselt_rpc", "piyon_hareket_rpc",
		"kart_oyna_rpc", "hakimiyet_kur_rpc", "karti_feda_et_rpc", "savas_karti_atildi_rpc",
		"oncu_uret_rpc", "aksiyon_karti_kullan_rpc", "savas_baslat_rpc"],
	"tur_ekonomi": ["ticaret_yap_rpc", "sirayi_degistir_rpc"],
}
# Yalnızca sunucuda çalışan, sonucunu kendi yayınlayan istekler.
const SUNUCU_ISTEKLERI = {
	"aksiyon": ["normal_kart_cek_rpc", "savas_karti_cek_rpc", "savas_hamlesi_yap_rpc"],
	"savas": ["zar_at_istegi_rpc"],
}
const ISTEK_ARGUMAN_SINIRI = 8

var _relay_gonderen := 0     # işlenen hamlenin sahibi peer (0 = hamle işlenmiyor)
var islem_ek := {}           # sunucunun hamleyle birlikte açıkladığı bilgiler
var islem_kabul := false     # hamle işleyicisi bütün kontrolleri geçti mi

# Arayüzün kullandığı tek giriş: hamleyi sunucuya gönderir.
func istek(yonetici: String, metod: String, args: Array = []):
	if multiplayer.is_server():
		_istegi_isle(multiplayer.get_unique_id(), yonetici, metod, args)
	else:
		istek_rpc.rpc_id(1, yonetici, metod, args)

@rpc("any_peer", "call_remote", "reliable")
func istek_rpc(yonetici: String, metod: String, args: Array):
	if not multiplayer.is_server(): return
	_istegi_isle(multiplayer.get_remote_sender_id(), yonetici, metod, args)

func _istek_hedefi(yonetici: String, metod: String, args: Array) -> Node:
	var sirali = SIRALI_HAMLELER.get(yonetici, []).has(metod)
	if not sirali and not SUNUCU_ISTEKLERI.get(yonetici, []).has(metod): return null
	var hedef = get(yonetici)
	if not hedef is Node or not hedef.has_method(metod): return null
	if args.size() > min(ISTEK_ARGUMAN_SINIRI, hedef.get_method_argument_count(metod)): return null
	return hedef

func _istegi_isle(peer: int, yonetici: String, metod: String, args: Array):
	if oyuncu_peer_idleri.find(peer) == -1: return
	var hedef = _istek_hedefi(yonetici, metod, args)
	if hedef == null: return
	_hamleyi_calistir(peer, hedef, metod, args, {})
	if islem_kabul and SIRALI_HAMLELER.get(yonetici, []).has(metod):
		hamle_uygula_rpc.rpc(peer, yonetici, metod, args, islem_ek.duplicate(true))
	islem_ek = {}

@rpc("authority", "call_remote", "reliable")
func hamle_uygula_rpc(peer: int, yonetici: String, metod: String, args: Array, ek: Dictionary):
	if not SIRALI_HAMLELER.get(yonetici, []).has(metod): return
	var hedef = _istek_hedefi(yonetici, metod, args)
	if hedef == null: return
	_hamleyi_calistir(peer, hedef, metod, args, ek)
	if not islem_kabul:
		push_warning("Sunucunun onayladığı hamle bu eşte uygulanamadı: %s" % metod)
	islem_ek = {}

func _hamleyi_calistir(peer: int, hedef: Node, metod: String, args: Array, ek: Dictionary):
	_relay_gonderen = peer
	islem_ek = ek
	islem_kabul = false
	hedef.callv(metod, args)
	_relay_gonderen = 0

# --- SÜRE SINIRLARI (yalnızca sunucu) ---
# Bağlı kalıp hamle yapmayan bir oyuncu maçı kilitleyemesin diye süre dolunca
# sunucu, o oyuncunun yerine aynı doğrulanmış hamle yolunu kullanır.
var tur_suresi := 120.0          # kurulum dahil her tur
var savas_secim_suresi := 45.0   # savaş kartlarını kilitleme
var zar_suresi := 20.0           # zar atma
const UYARI_SURESI := 15.0
var _sure_anahtari := []
var _sure_kalan := 0.0
var _uyari_verildi := false

# İstemcilerin gösterdiği geri sayım (sunucunun yayınladığı aşamaya göre).
var sure_asamasi_adi := ""
var _sure_bitis_ms := 0
var _son_gosterilen_saniye := -1

func _process(delta: float):
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		sure_sinirlarini_isle(delta)
		_donus_kuyrugunu_isle()
	var saniye = kalan_sure_saniye()
	if saniye != _son_gosterilen_saniye:
		_son_gosterilen_saniye = saniye
		if arayuz and arayuz.has_method("sure_goster"): arayuz.sure_goster()

# -1: gösterilecek sayaç yok.
func kalan_sure_saniye() -> int:
	if sure_asamasi_adi == "": return -1
	return max(0, int(ceil((_sure_bitis_ms - Time.get_ticks_msec()) / 1000.0)))

@rpc("authority", "call_local", "reliable")
func sure_baslat_rpc(asama: String, saniye: float):
	sure_asamasi_adi = asama
	_sure_bitis_ms = Time.get_ticks_msec() + int(saniye * 1000.0)
	_son_gosterilen_saniye = kalan_sure_saniye()
	if arayuz and arayuz.has_method("sure_goster"): arayuz.sure_goster()

# Yerel ağda istemciler sahnelerini yükleyince sunucuya bildirir; süre ve
# sayaç yayını bütün oyuncular hazır olana kadar başlamaz.
func _oyuncular_hazir_mi() -> bool:
	if Network.merkezi_mod: return true   # merkezi sunucu zaten bütün sahneleri bekler
	for i in range(oyuncu_peer_idleri.size()):
		var peer = oyuncu_peer_idleri[i]
		if peer == multiplayer.get_unique_id() or peer < 0 or oyuncular[i] in ayrilan_oyuncular: continue
		if not Network.oyun_hazir_peerleri.has(peer): return false
	return true

func _sure_asamasi() -> Array:
	if oyun_bitti or oyuncular.size() < 2 or aktif_sira >= oyuncular.size(): return []
	if oyuncular.size() - yapay_zeka_oyunculari.size() < 2: return []   # tek insan oyuncu: süre yok
	if not _oyuncular_hazir_mi(): return []
	if Network.merkezi_mod and Network.oturum_asamasi != "game": return []
	if savas.sonuc_gosteriliyor: return []
	if savas.savas_aktif:
		if savas.son_kartlar_dict.is_empty(): return ["savas_secim", savas_secim_suresi]
		return ["zar", zar_suresi]
	return ["tur", tur_suresi]

func sure_sinirlarini_isle(delta: float):
	var asama = _sure_asamasi()
	if asama.is_empty():
		if not _sure_anahtari.is_empty() or sure_asamasi_adi != "":
			_sure_anahtari = []
			_sure_yayinla("", 0.0)
		return
	var anahtar = [asama[0], aktif_sira, tur_sayaci, savas.savas_bina_koordinat]
	if anahtar != _sure_anahtari:
		_sure_anahtari = anahtar
		_sure_kalan = asama[1]
		_uyari_verildi = false
		_sure_yayinla(asama[0], asama[1])
	_sure_kalan -= delta
	if not _uyari_verildi and _sure_kalan <= UYARI_SURESI and asama[1] > UYARI_SURESI:
		_uyari_verildi = true
		sure_uyarisi_rpc.rpc(asama[0], int(ceil(_sure_kalan)))
	if _sure_kalan > 0.0: return
	_sure_anahtari = []
	_sure_yayinla("", 0.0)
	match asama[0]:
		"tur": _turu_zaman_asimiyla_bitir()
		"savas_secim":
			for isim in savas.savas_taraflari():
				if savas.savas_aktif and not savas.secilen_savas_kartlari.has(isim):
					_sunucu_adina(isim, "aksiyon", "savas_hamlesi_yap_rpc", [isim, [], []])
		"zar":
			var taraflar = savas.savas_taraflari()
			if savas.savas_aktif and savas.zar_saldiran_deger == -1:
				_sunucu_adina(taraflar[0], "savas", "zar_at_istegi_rpc", [true])
			if savas.savas_aktif and savas.zar_savunan_deger == -1:
				_sunucu_adina(taraflar[1], "savas", "zar_at_istegi_rpc", [false])

func _sure_yayinla(asama: String, saniye: float):
	if multiplayer.multiplayer_peer == null: return
	sure_baslat_rpc.rpc(asama, saniye)

func _turu_zaman_asimiyla_bitir():
	var isim = oyuncular[aktif_sira]
	sure_doldu_rpc.rpc(isim)
	# Şehrini kurmamış oyuncu için boş, keşfedilmemiş bir hex'e çimenlik şehir kurulur.
	if not sehir_merkezleri.get(isim, false):
		var hex = _bos_sehir_hexi()
		if hex != Vector2i(-1, -1):
			_sunucu_adina(isim, "aksiyon", "bina_kur_rpc", [hex, isim, "sehir_merkezi", "cim"])
	_sunucu_adina(isim, "tur_ekonomi", "sirayi_degistir_rpc", [])
	if aktif_sira < oyuncular.size() and oyuncular[aktif_sira] == isim:
		# Şehir kurulamadıysa bile sıra kilitlenmez.
		tur_gecir_rpc.rpc(isim)

func _bos_sehir_hexi() -> Vector2i:
	var adaylar = []
	for x in range(harita.HARITA_GENISLIK):
		for y in range(harita.HARITA_YUKSEKLIK):
			var k = Vector2i(x, y)
			if harita.kesfedilen_hexler.has(k) or kontrol_edilen_hexler.has(k) or binalar_verisi.has(k): continue
			var dolu = false
			for p in piyonlar:
				if p["koordinat"] == k: dolu = true
			if not dolu: adaylar.append(k)
	if adaylar.is_empty(): return Vector2i(-1, -1)
	return adaylar[randi() % adaylar.size()]

# Sunucu, süre dolan oyuncunun yerine hamleyi aynı yoldan işler ve yayınlar.
func _sunucu_adina(isim: String, yonetici: String, metod: String, args: Array):
	var peer = oyuncu_peer_id(isim)
	if peer == 0: return
	_istegi_isle(peer, yonetici, metod, args)

@rpc("authority", "call_local", "reliable")
func sure_uyarisi_rpc(asama: String, saniye: int):
	var ne = "Tur" if asama == "tur" else "Kart seçimi" if asama == "savas_secim" else "Zar"
	arayuz.olay_yaz("[color=orange]⏳ %s için %d saniye kaldı.[/color]" % [ne, saniye])

@rpc("authority", "call_local", "reliable")
func sure_doldu_rpc(isim: String):
	arayuz.olay_yaz("[color=orange]⌛ %s için süre doldu; sıra otomatik geçiyor.[/color]" % arayuz.renkli_isim(isim))

# Son çare: sıra hâlâ süresi dolan oyuncudaysa herkeste aynı şekilde geçirilir.
@rpc("authority", "call_local", "reliable")
func tur_gecir_rpc(isim: String):
	if aktif_sira >= oyuncular.size() or oyuncular[aktif_sira] != isim: return
	tur_ekonomi.turu_bitir()

# Sunucu, belirli bir oyuncunun eşine özel veri göndermek için kullanır.
func oyuncu_peer_id(isim: String) -> int:
	var idx = oyuncular.find(isim)
	return oyuncu_peer_idleri[idx] if idx != -1 and idx < oyuncu_peer_idleri.size() else 0

# --- RPC GÜVENLİĞİ ---
# Hamlenin sahibi oyuncunun ismi ("" = tanınmayan veya doğrudan gönderilmiş çağrı).
# Ağdan doğrudan gelen çağrılar kabul edilmez; hamleler yalnızca sunucu sırasıyla işlenir.
# Sunucunun kendi yerel çağrısı (tek oyunculu alıştırma, testler) geçerlidir.
func rpc_gonderen_ismi() -> String:
	var gonderen = _relay_gonderen
	if gonderen == 0:
		if multiplayer.get_remote_sender_id() != 0 or not multiplayer.is_server(): return ""
		gonderen = multiplayer.get_unique_id()
	var idx = oyuncu_peer_idleri.find(gonderen)
	return oyuncular[idx] if idx != -1 else ""

# Gönderen, sırası gelen oyuncu mu? (isim verilirse o isimle de eşleşmeli)
func rpc_sirada_mi(isim: String = "") -> bool:
	if Network.merkezi_mod and Network.oturum_asamasi != "game": return false
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

var _zafer_bekliyor := false

func _zaferi_yayinla(isim: String, puan: int):
	_zafer_bekliyor = false
	if not oyun_bitti: aksiyon.oyunu_bitir_rpc.rpc(isim, puan)

func puanlari_guncelle():
	for isim in oyuncular: puanlar[isim] = puan_hesapla(isim)

func zaferi_kontrol_et():
	puanlari_guncelle()
	if not multiplayer.is_server() or oyun_bitti: return
	for isim in oyuncular:
		if isim not in ayrilan_oyuncular and puanlar[isim] >= HEDEF_PUAN:
			# Hamle işlenirken zafer, hamlenin kendisinden sonra yayınlanmalı.
			if _relay_gonderen != 0:
				if not _zafer_bekliyor:
					_zafer_bekliyor = true
					call_deferred("_zaferi_yayinla", isim, puanlar[isim])
			else:
				aksiyon.oyunu_bitir_rpc.rpc(isim, puanlar[isim])
			return
