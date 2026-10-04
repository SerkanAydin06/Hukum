extends Node

var oyuncu_ismi: String = ""
var oyuncu_avatar: Texture2D = null  
var secilen_profil_teksturu: Texture2D = null

var profil_no: int = 1

var tum_oyuncu_profilleri = {}

func _ready():
	rastgele_isim_ata()
	rastgele_profil_ata()

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
