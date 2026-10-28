extends Node

var oyuncu_ismi: String = ""
var oyuncu_avatar: Texture2D = null  
var secilen_profil_teksturu: Texture2D = null

var profil_no: int = 1

var tum_oyuncu_profilleri = {}

var ses_seviyesi := 0.75
var tam_ekran := true

func _ready():
	rastgele_isim_ata()
	rastgele_profil_ata()
	var kayit = ConfigFile.new()
	if kayit.load("user://profil.cfg") == OK:
		oyuncu_ismi = str(kayit.get_value("profil", "isim", oyuncu_ismi)).left(16)
		profil_no_ata(clampi(int(kayit.get_value("profil", "avatar", 1)), 1, 8))
		ses_seviyesi = clampf(float(kayit.get_value("ayarlar", "ses", 0.75)), 0.0, 1.0)
		tam_ekran = bool(kayit.get_value("ayarlar", "tam_ekran", true))
	ayarlari_uygula()

func profili_kaydet():
	var kayit = ConfigFile.new()
	kayit.set_value("profil", "isim", oyuncu_ismi)
	kayit.set_value("profil", "avatar", profil_no)
	kayit.set_value("ayarlar", "ses", ses_seviyesi)
	kayit.set_value("ayarlar", "tam_ekran", tam_ekran)
	var hata = kayit.save("user://profil.cfg")
	if hata != OK: push_warning("Profil kaydedilemedi: %s" % hata)

func ayarlari_uygula():
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(ses_seviyesi, 0.0001)))
	AudioServer.set_bus_mute(0, ses_seviyesi == 0.0)
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
	for simge in {"🌲": " odun", "🪨": " taş", "🌾": " yiyecek", "🪙": " altın"}:
		metin = metin.replace(simge, {"🌲": " odun", "🪨": " taş", "🌾": " yiyecek", "🪙": " altın"}[simge])
	var sonuc = ""
	for karakter in metin:
		var kod = karakter.unicode_at(0)
		if kod == 0xfe0f or kod == 0x200d: continue
		if kod >= 0x1f000 or (kod >= 0x2600 and kod <= 0x27bf): continue
		sonuc += karakter
	return sonuc.strip_edges()
