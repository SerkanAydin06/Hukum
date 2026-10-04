extends PanelContainer

signal renk_secildi(renk:String)

@onready var hukumdar = %HukumdarResmi
@onready var oyuncu_ismi = %OyuncuIsmi
@onready var medeniyet = %SeciliMedeniyetBaslik
@onready var hazir_ikon = %HazirIkon
@onready var renk_kutusu = %RenkKutusu

var secili_renk = ""

var renkler = {
	"Kirmizi":Color.RED,
	"Mavi":Color.BLUE,
	"Yesil":Color.GREEN,
	"Sari":Color.YELLOW,
	"Mor":Color(0.75,0.3,1),
	"CamGobegi":Color.CYAN
}

func _ready():
	for b in renk_kutusu.get_children():
		b.pressed.connect(func():
			renk_butonuna_basildi(b)
		)

func renk_butonuna_basildi(btn):
	if btn.disabled:
		return
	secili_renk = btn.name
	renk_secildi.emit(btn.name)
	renkleri_guncelle()

func renkleri_guncelle():
	for b in renk_kutusu.get_children():
		b.scale = Vector2.ONE
		b.modulate = Color.WHITE

func kullanilan_renkleri_guncelle(liste:Array):
	for b in renk_kutusu.get_children():
		b.disabled = false
		b.modulate = Color.WHITE
		if b.name in liste and b.name != secili_renk:
			b.disabled = true
			b.modulate = Color(0.35,0.35,0.35)

func oyuncu_verisini_guncelle(veri:Dictionary):
	oyuncu_ismi.text = veri["isim"]
	medeniyet.text = veri["medeniyet"]
	
	var ismin_rengi = renkler.get(veri["renk"], Color.WHITE)
	oyuncu_ismi.add_theme_color_override("font_color", ismin_rengi)
	medeniyet.add_theme_color_override("font_color", ismin_rengi)
	
	secili_renk = veri["renk"]
	renkleri_guncelle()
	
	var yol = "res://Assets/Hukumdarlar/%s_hukumdar.png" % veri["medeniyet"]
	if ResourceLoader.exists(yol):
		hukumdar.texture = load(yol)
	else:
		hukumdar.texture = null
		
	# 🟢 DEĞİŞEN KISIM: Hazır durumu resmi
	hazir_ikon.modulate = Color.WHITE # Eski yeşil/kırmızı renk kalıntılarını sıfırlıyoruz
	if veri["hazir"]:
		hazir_ikon.texture = load("res://Assets/Resimler/hazir.png")
	else:
		hazir_ikon.texture = load("res://Assets/Resimler/hazirdegil.png")

func bos_slot():
	oyuncu_ismi.text = "Açık"
	oyuncu_ismi.add_theme_color_override("font_color", Color.WHITE)
	medeniyet.text = "-"
	medeniyet.add_theme_color_override("font_color", Color.WHITE)
	hukumdar.texture = null
	
	# 🟢 DEĞİŞEN KISIM: Boş slot durumu
	hazir_ikon.texture = load("res://hazirdegil.png")
	hazir_ikon.modulate = Color(1, 1, 1, 0.4) # Boş slotta ikon biraz saydam ve soluk dursun
