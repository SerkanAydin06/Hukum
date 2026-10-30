extends CanvasLayer

const PENCERE_TEMASI = preload("res://UI/HukumTheme.tres")
const PENCERE_PANELI = preload("res://UI/HukumWindow.gd")

var perde: ColorRect
var panel: PanelContainer
var satirlar: VBoxContainer
var oyun: Node
var sonuc_acik := false

func _ready():
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	oyun = get_parent() if get_parent() is AnaOyun else null
	if oyun:
		# The scene owns HUD layout; the settings action follows its panel at any size.
		var menu = oyun.get_node("%OyunMenuBtn")
		menu.pressed.connect(menuyu_ac)
	perde = ColorRect.new()
	perde.color = Color(0, 0, 0, 0.76)
	perde.theme = PENCERE_TEMASI
	add_child(perde)
	perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var merkez = CenterContainer.new()
	perde.add_child(merkez)
	merkez.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PENCERE_PANELI.new()
	panel.custom_minimum_size = Vector2(760, 0)
	merkez.add_child(panel)
	satirlar = VBoxContainer.new()
	satirlar.add_theme_constant_override("separation", 14)
	panel.add_child(satirlar)
	perde.hide()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if sonuc_acik: return
		if perde.visible: perde.hide()
		else: menuyu_ac()
		get_viewport().set_input_as_handled()

func _temizle(baslik: String):
	for child in satirlar.get_children():
		satirlar.remove_child(child)
		child.queue_free()
	var label = Label.new()
	label.text = baslik
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color("e8ca85"))
	satirlar.add_child(label)
	perde.show()

func _metin(metin: String):
	var label = Label.new()
	label.text = metin
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 680
	label.add_theme_font_size_override("font_size", 20)
	satirlar.add_child(label)

func _buton(metin: String, islem: Callable):
	var button = Button.new()
	button.text = metin
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 20)
	satirlar.add_child(button)
	button.pressed.connect(islem)
	return button

func menuyu_ac():
	if sonuc_acik: return
	_temizle(tr("HÜKÜM"))
	if oyun: _metin(tr("Çevrimiçi maç bu menü açıkken devam eder."))
	_buton(tr("Devam et"), perde.hide).grab_focus()
	_buton(tr("Nasıl oynanır?"), yardimi_ac)
	_buton("Ayarlar", ayarlari_ac)
	if oyun and oyun.tek_oyunculu_mu():
		var kaydet = _buton(tr("Maçı kaydet"), func():
			_temizle(tr("MAÇ KAYDI"))
			_metin(tr("Maç kaydedildi. Ana menüden Tek Oyunculu › Kayıtlı maça devam et ile sürdürebilirsin.") if oyun.maci_kaydet() else tr("Şu an kaydedilemiyor: savaş sürerken veya şehir kurulmadan kayıt alınmaz."))
			_buton(tr("Geri"), menuyu_ac))
		kaydet.disabled = not oyun.kaydedilebilir_mi()
	if oyun: _buton(tr("Maçtan ayrıl"), ayrilma_onayi).theme_type_variation = &"HukumDanger"
	else: _buton(tr("Oyundan çık"), SceneTransition.quit_game).theme_type_variation = &"HukumDanger"

func yardimi_ac():
	_temizle(tr("NASIL OYNANIR?"))
	_metin(tr("AMAÇ: 50 puana ulaş. Her toprak 1, şehir dışındaki her bina seviyesi 2, her doğrudan vasal 5 puan verir. Savaş kazanmak +2, kaybetmek −2 puandır."))
	_metin(tr("KURULUM: Bir biyom seç, keşfedilmemiş bir hex'e sol tıkla ve onayla. Şehir 10 odun + 10 taş tutar; bir öncü verir. Herkes şehrini kurduktan sonra tur başına 3 AP kazanılır."))
	_metin(tr("KEŞİF: Öncüyü sol tıkla seç. Komşu hex'e sağ tıkla hareket et (1 AP + 1 yiyecek). Öncünün üstüne sağ tıkla, kendi toprağına komşu bölgeyi sahiplen (1 AP + 3 yiyecek)."))
	_metin(tr("KARTLAR: İnşa kartı çekmek 1 AP; savaş kartı 1 AP + 3 altın. İki elin ayrı ayrı sınırı 7 karttır. Kartı seçerek kullan, dönüştür veya at. Üretim tur sonunda gelir. Ticaret Merkezi kaynakları altına çevirir."))
	_metin(tr("SAVAŞ: Düşmana sağ tıkla; iki taraf kartlarını kilitler ve zar atar. Eşitlikte savunan kazanır. Kuşatma kartları yalnız bina saldırısındadır. Hükmet şehir sahibini vasal yapar; vasal üretiminin yarısını vergi verir."))
	_metin(tr("KONTROLLER: WASD / oklar ve sağ tuşla sürükleme: kamera. Fare tekerleği: yakınlaştırma. Sağ tık: inşayı iptal. Esc: menü. Oda bağlantısı: sunucunun IP adresi, UDP 7777."))
	_buton(tr("Geri"), menuyu_ac)

func ayarlari_ac():
	_temizle(tr("AYARLAR"))
	_metin(tr("Ana ses seviyesi"))
	var ses = HSlider.new()
	ses.min_value = 0
	ses.max_value = 100
	ses.value = Global.ses_seviyesi * 100.0
	ses.custom_minimum_size.y = 40
	satirlar.add_child(ses)
	ses.value_changed.connect(func(deger):
		Global.ses_seviyesi = deger / 100.0
		Global.ayarlari_uygula()
		Global.profili_kaydet())
	for ayar in [["Müzik", "muzik_seviyesi"], ["Efektler", "efekt_seviyesi"]]:
		_metin(tr(ayar[0]))
		var kaydirici = HSlider.new()
		kaydirici.name = ayar[1]
		kaydirici.min_value = 0
		kaydirici.max_value = 100
		kaydirici.value = Global.get(ayar[1]) * 100.0
		kaydirici.custom_minimum_size.y = 40
		satirlar.add_child(kaydirici)
		kaydirici.value_changed.connect(func(deger):
			Global.set(ayar[1], deger / 100.0)
			Global.ayarlari_uygula()
			Global.profili_kaydet())
	_metin(tr("Dil · Language"))
	var dil = OptionButton.new()
	dil.name = "DilSecimi"
	dil.custom_minimum_size.y = 44
	var diller = Global.DILLER.keys()
	for kod in diller: dil.add_item(Global.DILLER[kod])
	dil.select(diller.find(TranslationServer.get_locale().left(2)) if diller.has(TranslationServer.get_locale().left(2)) else 0)
	satirlar.add_child(dil)
	dil.item_selected.connect(func(i):
		Global.dil = diller[i]
		Global.dili_uygula()
		Global.profili_kaydet()
		ayarlari_ac())
	var ekran = CheckButton.new()
	ekran.text = tr("Tam ekran")
	ekran.button_pressed = Global.tam_ekran
	satirlar.add_child(ekran)
	ekran.toggled.connect(func(deger):
		Global.tam_ekran = deger
		Global.ayarlari_uygula()
		Global.profili_kaydet())
	_buton(tr("Geri"), menuyu_ac)

func ayrilma_onayi():
	_temizle(tr("MAÇTAN AYRIL"))
	if oyun and oyun.tek_oyunculu_mu():
		_metin(tr("Maç her turunun başında kendiliğinden kaydedilir. Ana menüden Tek Oyunculu › Kayıtlı maça devam et ile sürdürebilirsin."))
	else:
		_metin(tr("Sunucuysanız tüm oyuncuların bağlantısı kapanır. Bu maç kaydedilmez.\nKendi isteğinle ayrılırsan bu maça geri dönemezsin."))
	_buton(tr("Maça dön"), perde.hide)
	_buton(tr("Ayrıl ve ana menüye dön"), ana_menuye_don).theme_type_variation = &"HukumDanger"

func ana_menuye_don():
	get_tree().paused = false
	Network.donus_kaydini_sil()
	Network.baglantiyi_kapat()
	SceneTransition.go_to("res://AnaMenu.tscn")

func sonucu_goster(kazanan: String, puan: int):
	sonuc_acik = true
	_temizle(tr("ZAFER") if oyun.oyuncular[oyun.benim_indexim] == kazanan else tr("MAÇ TAMAMLANDI"))
	_metin(tr("%s, %d puanla hüküm sürdü.\nToplam tur: %d") % [kazanan, puan, oyun.tur_sayaci])
	var siralama = oyun.oyuncular.duplicate()
	siralama.sort_custom(func(a, b): return oyun.puan_hesapla(a) > oyun.puan_hesapla(b))
	for isim in siralama:
		_metin("%s  ·  %s  ·  %d puan" % [isim, oyun.medeniyetler_verisi.get(isim, ""), oyun.puan_hesapla(isim)])
	_buton(tr("Ana menüye dön"), ana_menuye_don).grab_focus()
