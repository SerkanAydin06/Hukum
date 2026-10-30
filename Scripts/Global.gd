extends Node

var oyuncu_ismi: String = ""
var oyuncu_avatar: Texture2D = null  
var secilen_profil_teksturu: Texture2D = null

var profil_no: int = 1

var tum_oyuncu_profilleri = {}

var ses_seviyesi := 0.75
var muzik_seviyesi := 0.5
var efekt_seviyesi := 0.8
var tam_ekran := true

func _ready():
	rastgele_isim_ata()
	rastgele_profil_ata()
	var kayit = ConfigFile.new()
	if kayit.load("user://profil.cfg") == OK:
		oyuncu_ismi = str(kayit.get_value("profil", "isim", oyuncu_ismi)).left(16)
		profil_no_ata(clampi(int(kayit.get_value("profil", "avatar", 1)), 1, 8))
		ses_seviyesi = clampf(float(kayit.get_value("ayarlar", "ses", 0.75)), 0.0, 1.0)
		muzik_seviyesi = clampf(float(kayit.get_value("ayarlar", "muzik", 0.5)), 0.0, 1.0)
		efekt_seviyesi = clampf(float(kayit.get_value("ayarlar", "efekt", 0.8)), 0.0, 1.0)
		tam_ekran = bool(kayit.get_value("ayarlar", "tam_ekran", true))
		dil = str(kayit.get_value("ayarlar", "dil", ""))
		if dil not in DILLER: dil = ""
	dili_uygula()
	ayarlari_uygula()
	# Proje adı "Hukum" kalır (kullanıcı verisi klasörü değişmesin); pencere başlığı tam ad.
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_title("HÜKÜM")

func profili_kaydet():
	var kayit = ConfigFile.new()
	kayit.set_value("profil", "isim", oyuncu_ismi)
	kayit.set_value("profil", "avatar", profil_no)
	kayit.set_value("ayarlar", "ses", ses_seviyesi)
	kayit.set_value("ayarlar", "muzik", muzik_seviyesi)
	kayit.set_value("ayarlar", "efekt", efekt_seviyesi)
	kayit.set_value("ayarlar", "tam_ekran", tam_ekran)
	kayit.set_value("ayarlar", "dil", dil)
	var hata = kayit.save("user://profil.cfg")
	if hata != OK: push_warning("Profil kaydedilemedi: %s" % hata)

func ayarlari_uygula():
	_bus_ayarla(0, ses_seviyesi)
	_bus_ayarla(_bus("Muzik"), muzik_seviyesi)
	_bus_ayarla(_bus("Efekt"), efekt_seviyesi)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if tam_ekran else DisplayServer.WINDOW_MODE_WINDOWED)

func rastgele_isim_ata():
	var random_num = randi_range(1000, 9999)
	oyuncu_ismi = "Oyuncu" + str(random_num)

func rastgele_profil_ata():
	profil_no_ata(randi_range(1, 8))

# 🟢 YENİ: Artık HERKES (rastgele atama da, manuel seçim de) bu fonksiyondan geçecek
func profil_no_ata(yeni_no: int):
	profil_no = yeni_no
	var yol = "res://Assets/Resimler/Profil%d.png" % profil_no
	if ResourceLoader.exists(yol):
		oyuncu_avatar = load(yol)
		secilen_profil_teksturu = oyuncu_avatar

func profilimi_guncelle(isim: String, texture: Texture2D):
	oyuncu_ismi = isim
	secilen_profil_teksturu = texture
	oyuncu_avatar = texture


# Decorative emoji are absent from the bundled fonts; preserve resource meaning in text.
func okunur_metin(metin: String) -> String:
	var kelimeler = {"🌲": "odun", "🪨": "taş", "🌾": "yiyecek", "🪙": "altın"}
	for simge in kelimeler:
		metin = metin.replace(simge, " " + tr(kelimeler[simge]))
	var sonuc = ""
	for karakter in metin:
		var kod = karakter.unicode_at(0)
		if kod == 0xfe0f or kod == 0x200d: continue
		if kod >= 0x1f000 or (kod >= 0x2600 and kod <= 0x27bf): continue
		sonuc += karakter
	return sonuc.strip_edges()

# Müzik ve efekt seviyeleri ana sesten bağımsız ayarlanır; bus'lar ilk kullanımda oluşur.
func _bus(ad: String) -> int:
	var idx = AudioServer.get_bus_index(ad)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, ad)
		AudioServer.set_bus_send(idx, "Master")
	return idx

func _bus_ayarla(idx: int, seviye: float):
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(seviye, 0.0001)))
	AudioServer.set_bus_mute(idx, seviye == 0.0)

# Oyun verisindeki kimliklerin (tur adları) oyuncuya görünen, çevrilmiş adları.
const BINA_ADLARI = {"sehir_merkezi": "Şehir Merkezi", "tarla": "Tarla", "oduncu_kampi": "Oduncu Kampı",
	"tas_ocagi": "Taş Ocağı", "ticaret_merkezi": "Ticaret Merkezi", "oncu_kampi": "Öncü Kampı", "ev": "Ev", "kisla": "Kışla"}
const KAYNAK_ADLARI = {"odun": "Odun", "tas": "Taş", "yiyecek": "Yiyecek", "altin": "Altın"}

func bina_adi(tur: String) -> String:
	return tr(BINA_ADLARI.get(tur, tur.replace("_", " ").capitalize()))

func kaynak_adi(tur: String) -> String:
	return tr(KAYNAK_ADLARI.get(tur, tur))

# --- DİL ---
const DILLER = {"tr": "Türkçe", "en": "English"}
var dil := ""

func dili_uygula():
	if dil == "": dil = "tr" if OS.get_locale_language() == "tr" else "en"
	TranslationServer.set_locale(dil)

func surum() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "1.0.0"))
