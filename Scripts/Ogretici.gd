extends CanvasLayer
class_name Ogretici

# İlk maç rehberi: oyuncu her adımı gerçek oyunda yapar; adım, oyun durumu
# hedefe ulaşınca kendiliğinden ilerler. Maç verisine dokunmaz.

const PENCERE_TEMASI = preload("res://UI/HukumTheme.tres")
const PENCERE_PANELI = preload("res://UI/HukumWindow.gd")

const ADIMLAR = [
	{"baslik": "Şehrini kur", "metin": "\"Başlangıç Arazini Seç\" bölümünden bir arazi seç: Çim yiyecek, Orman odun, Dağ taş üretir. Sonra haritada sisli bir hex'e tıklayıp ONAYLA'ya bas. Şehir 10 odun + 10 taş tutar."},
	{"baslik": "Turu bitir", "metin": "Sağ alttaki TURU BİTİR ile sırayı devret. Herkes şehrini kurduğunda her turda 3 aksiyon puanı (AP) alırsın; üretimin tur sonunda gelir."},
	{"baslik": "Kart çek", "metin": "Sol alttaki İNŞA DESTESİ'ne tıkla. 1 AP karşılığında bir inşa veya gelişim kartı çekersin. Elinde en fazla 7 inşa kartı olabilir."},
	{"baslik": "Keşfet", "metin": "Şehrindeki öncünü sol tıkla seç, ardından komşu sisli bir hex'e sağ tıkla. Keşif 1 AP ve 1 yiyecek harcar; arazinin türü ortaya çıkar."},
	{"baslik": "Toprak kazan", "metin": "Öncün seçiliyken durduğu hex'e sağ tıkla ve \"Bölgeyi Ele Geçir\" de: 1 AP + 3 yiyecek. Her toprak 1 puandır ve üzerine bina kurabilirsin."},
	{"baslik": "Bina kur", "metin": "Elindeki bir inşa kartına tıkla; uygun topraklar parlar. Oduncu Kampı ormana, Taş Ocağı dağa, diğerleri çimene kurulur. Kaynağın yetmezse kartı bir kaynağa çevirebilirsin."},
	{"baslik": "Üretimi topla", "metin": "Turu bitir. Şehrin ve binaların tur sonunda kaynak üretir; üst çubuktaki +/tur değerlerinden takip et. Gelişim kartları binaları 3. seviyeye kadar yükseltir."},
	{"baslik": "Savaşa hazırlan", "metin": "SAVAŞ sekmesinden 3 altınla bir savaş kartı çek. Öncün seçiliyken komşu bir düşmana sağ tıklayarak saldırırsın: iki taraf kartlarını KİLİTLE ile gizlice seçer, kartlar açılır ve herkes zarını atar. Eşitlikte savunan kazanır."},
	{"baslik": "Hazırsın", "metin": "Her toprak 1, şehir dışındaki her bina seviyesi 2, her vasal 5 puan; kazanılan savaş +2, kaybedilen −2. İlk 50 puana ulaşan kazanır. Kurallar her zaman MENÜ › Nasıl Oynanır? içinde."},
]

var ana
var adim := 0
var _baslangic := {}
var panel: PanelContainer
var baslik_label: Label
var metin_label: Label
var gec_btn: Button

func _ready():
	layer = 40
	ana = get_parent()
	panel = PENCERE_PANELI.new()
	panel.theme = PENCERE_TEMASI
	panel.name = "OgreticiPaneli"
	panel.custom_minimum_size = Vector2(640, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	panel.position = Vector2(470, 118)
	var kutu = VBoxContainer.new()
	kutu.add_theme_constant_override("separation", 8)
	kutu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(kutu)
	baslik_label = Label.new()
	baslik_label.add_theme_font_size_override("font_size", 22)
	baslik_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.5))
	kutu.add_child(baslik_label)
	metin_label = Label.new()
	metin_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	metin_label.custom_minimum_size.x = 600
	metin_label.add_theme_font_size_override("font_size", 17)
	kutu.add_child(metin_label)
	var satir = HBoxContainer.new()
	satir.alignment = BoxContainer.ALIGNMENT_END
	satir.add_theme_constant_override("separation", 10)
	kutu.add_child(satir)
	gec_btn = Button.new()
	gec_btn.name = "AdimiGecBtn"
	gec_btn.theme_type_variation = &"HukumCompact"
	gec_btn.pressed.connect(_ileri)
	satir.add_child(gec_btn)
	var kapat = Button.new()
	kapat.name = "OgreticiKapatBtn"
	kapat.text = "Öğreticiyi kapat"
	kapat.theme_type_variation = &"HukumCompact"
	kapat.pressed.connect(queue_free)
	satir.add_child(kapat)
	_goster()

func _process(_delta: float):
	if adim < ADIMLAR.size() - 1 and _adim_tamam(): _ileri()

func _ben() -> String:
	return ana.oyuncular[ana.benim_indexim] if not ana.oyuncular.is_empty() else ""

func _adim_tamam() -> bool:
	var ben = _ben()
	if ben == "": return false
	match adim:
		0: return ana.sehir_merkezleri.get(ben, false)
		1: return ana.ilk_tur_bitti and ana.aktif_sira == ana.benim_indexim
		2: return _el_sayisi(false) > _baslangic.get("insa", 0)
		3: return ana.harita.kesfedilen_hexler.size() > _baslangic.get("kesif", 0)
		4: return _sayi(ana.kontrol_edilen_hexler.values(), ben) > _baslangic.get("toprak", 0)
		5: return _bina_sayisi(ben) > _baslangic.get("bina", 0)
		6: return ana.tur_sayaci > _baslangic.get("tur", 0)
		7: return _el_sayisi(true) > _baslangic.get("savas", 0)
	return false

func _ileri():
	if adim >= ADIMLAR.size() - 1:
		queue_free()
		return
	adim += 1
	_goster()

func _goster():
	var ben = _ben()
	_baslangic = {"insa": _el_sayisi(false), "savas": _el_sayisi(true), "kesif": ana.harita.kesfedilen_hexler.size(),
		"toprak": _sayi(ana.kontrol_edilen_hexler.values(), ben), "bina": _bina_sayisi(ben), "tur": ana.tur_sayaci}
	baslik_label.text = "ÖĞRETİCİ · %d/%d · %s" % [adim + 1, ADIMLAR.size(), ADIMLAR[adim]["baslik"]]
	metin_label.text = ADIMLAR[adim]["metin"]
	gec_btn.text = "Bitir" if adim == ADIMLAR.size() - 1 else "Bu adımı geç"

func _el_sayisi(savas: bool) -> int:
	var sayi = 0
	for kart in ana.deste.el:
		if (kart.get("hedef") == "savas") == savas: sayi += 1
	return sayi

func _bina_sayisi(ben: String) -> int:
	var sayi = 0
	for b in ana.binalar_verisi.values():
		if b["sahip"] == ben: sayi += 1
	return sayi

func _sayi(dizi: Array, deger) -> int:
	return dizi.count(deger)
