extends Control
class_name AnaMenu

@onready var hbox_menu_ana = %HBoxMenuAna
@onready var hbox_menu_coklu = %HBoxMenuCoklu
@onready var profil_panel = %ProfilPanel
@onready var profil_duzenle_panel = %ProfilDuzenlePanel
@onready var profil_karartma = %ProfilKarartma
@onready var isim_giris_kutusu = %IsimGirisKutusu
@onready var isim_hata_label = %IsimHataLabel
@onready var kaydet_btn = %KaydetBtn
@onready var kur_btn = %KurBtn
@onready var baglan_btn = %BaglanBtn
@onready var ip_giris = %IPGiris
@onready var baglanti_durumu = %BaglantiDurumu

var oyun_menusu
var baglanti_sayaci := 0
var _ozel_mod := false
var _avatar := 1
var _baglaniyor := false
var oyuncu_adi_regex := RegEx.new()

func _ready():
	if PardexBridge.dedicated or "--hukum-server" in OS.get_cmdline_user_args(): return
	oyun_menusu = load("res://Scripts/OyunMenu.gd").new()
	add_child(oyun_menusu)
	SesYoneticisi.muzik_cal("menu")
	oyuncu_adi_regex.compile("^[A-Za-zÇĞİÖŞÜçğıöşü0-9 _-]+$")
	%CokOyunculuBtn.pressed.connect(_cok_oyunculu_menu_ac)
	%OzelSunucuBtn.pressed.connect(_ozel_sunucu_ac)
	%PardexBtn.pressed.connect(_pardex_ac)
	%TekOyuncuBtn.pressed.connect(_alistirma_ac)
	%AyarlarBtn.pressed.connect(oyun_menusu.ayarlari_ac)
	%YardimBtn.pressed.connect(oyun_menusu.yardimi_ac)
	%CikisBtn.pressed.connect(SceneTransition.quit_game)
	%ProfilDuzenleBtn.pressed.connect(_profil_duzenle_ac)
	%GeriBtn.pressed.connect(_ana_menuye_don)
	%KurBtn.pressed.connect(_on_kur_btn_pressed)
	%BaglanBtn.pressed.connect(_on_baglan_btn_pressed)
	%KaydetBtn.pressed.connect(_profil_kaydet)
	%IptalProfilBtn.pressed.connect(_profil_duzenle_kapat)
	%MasaKurBtn.pressed.connect(PardexLink.host_match)
	%KodlaKatilBtn.pressed.connect(func(): PardexLink.join_match(%KodGiris.text))
	%KodGiris.text_submitted.connect(func(_text): PardexLink.join_match(%KodGiris.text))
	%PardexGeriBtn.pressed.connect(_pardex_kapat)
	isim_giris_kutusu.text_changed.connect(_oyuncu_adi_degisti)
	isim_giris_kutusu.text_submitted.connect(func(_text):
		if not kaydet_btn.disabled: _profil_kaydet())
	ip_giris.text_submitted.connect(func(_text): _on_baglan_btn_pressed())
	%SunucuGiris.text_submitted.connect(func(_text): _on_baglan_btn_pressed())
	for i in range(1, 9):
		get_node("%Profil" + str(i)).pressed.connect(_avatar_sec.bind(i))
	multiplayer.connected_to_server.connect(_sunucuya_baglanildi)
	multiplayer.connection_failed.connect(_baglanti_basarisiz)
	Network.durum_degisti.connect(_network_durumu)
	PardexLink.status_changed.connect(_pardex_durumu)
	PardexLink.linked_changed.connect(func(_value): _baglanti_rozetini_guncelle())
	var surum = Label.new()
	surum.name = "SurumEtiketi"
	surum.text = "v" + Global.surum()
	surum.add_theme_font_size_override("font_size", 14)
	surum.modulate = Color(1, 1, 1, 0.55)
	surum.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	surum.offset_left = -120
	surum.offset_top = -34
	surum.offset_right = -18
	surum.offset_bottom = -10
	surum.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	surum.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surum)
	_donus_dugmesini_kur()
	_arayuzu_guncelle()
	%MenuDurum.text = Network.son_baglanti_mesaji
	Network.son_baglanti_mesaji = ""
	_baglanti_rozetini_guncelle()

func _input(event):
	if not event.is_action_pressed("ui_cancel"): return
	if profil_duzenle_panel.visible: _profil_duzenle_kapat()
	elif %PardexKatmani.visible: _pardex_kapat()
	elif hbox_menu_coklu.visible: _ana_menuye_don()
	else: return
	get_viewport().set_input_as_handled()

func _cok_oyunculu_menu_ac():
	_baglanti_ac(false)

func _ozel_sunucu_ac():
	_baglanti_ac(true)

func _baglanti_ac(ozel: bool):
	PardexLink.use_private_mode()
	_ozel_mod = ozel
	hbox_menu_coklu.show()
	%BaglantiBaslik.text = tr("ÖZEL SUNUCU") if ozel else tr("YEREL AĞ")
	%BaglantiAciklama.text = tr("Sunucunun adresini gir. İlk katılan oyuncu odayı yönetir.") if ozel else tr("Aynı ağda bir kişi oda kursun. Diğer oyuncular sunucunun yerel IP adresiyle katılsın.")
	%LANAlanlari.visible = not ozel
	%OzelAlanlar.visible = ozel
	kur_btn.visible = not ozel
	baglanti_durumu.text = ""
	_baglanti_kilit(false)
	(%SunucuGiris if ozel else ip_giris).grab_focus()

func _ana_menuye_don():
	baglanti_sayaci += 1
	Network.baglantiyi_kapat()
	_baglanti_kilit(false)
	hbox_menu_coklu.hide()
	baglanti_durumu.text = ""
	%CokOyunculuBtn.grab_focus()

func _baglanti_kilit(locked: bool):
	_baglaniyor = locked
	kur_btn.disabled = locked
	baglan_btn.disabled = locked
	ip_giris.editable = not locked
	%SunucuGiris.editable = not locked
	%PortGiris.editable = not locked
	%BaglantiIlerleme.visible = locked
	%GeriBtn.text = tr("İPTAL") if locked else tr("GERİ")

func _on_kur_btn_pressed():
	if _baglaniyor: return
	_baglanti_kilit(true)
	if Network.host_game(int(%PortGiris.value)):
		_lobi_sahnesine_gec()
	else:
		_baglanti_kilit(false)
		baglanti_durumu.text = tr("Oda kurulamadı. Port kullanımda olabilir; farklı bir port deneyin.")

func _on_baglan_btn_pressed():
	if _baglaniyor: return
	if _ozel_mod:
		var url = %SunucuGiris.text.strip_edges()
		if not PardexBridge.valid_url(url):
			baglanti_durumu.text = tr("Geçersiz adres. ws:// veya wss:// ile başlayan bir sunucu adresi gir.")
			return
		_baglanti_kilit(true)
		if not Network.ozel_sunucuya_katil(url): _baglanti_basarisiz()
		return
	var ip = ip_giris.text.strip_edges()
	if ip.to_lower() == "localhost" or ip.is_empty(): ip = "127.0.0.1"
	if not ip.is_valid_ip_address():
		baglanti_durumu.text = tr("Geçersiz IP adresi. Örnek: 192.168.1.10")
		return
	_baglanti_kilit(true)
	baglanti_durumu.text = tr("Sunucuya bağlanılıyor…")
	if not Network.join_game(ip, int(%PortGiris.value)): _baglanti_basarisiz()

func _sunucuya_baglanildi():
	# Merkezi sunucuda ham bağlantı yeterli değildir: kabul RPC'si beklenir.
	# Maça dönüşte de lobiye değil, sunucunun dönüş onayına gidilir.
	if not Network.merkezi_mod and not Network.geri_donuyor: _lobi_sahnesine_gec()

func _baglanti_basarisiz():
	_baglanti_kilit(false)
	baglanti_durumu.text = tr("Bağlantı kurulamadı. Adresi, portu ve sunucuyu kontrol et.")

func _network_durumu(message: String, error: bool):
	if error: _baglanti_kilit(false)
	if error and is_instance_valid(_donus_btn):
		if Network.maca_donulebilir_mi(): _donus_btn.disabled = false
		else:
			for ad in ["MacaDonBtn", "DonusVazgecBtn"]:
				var b = hbox_menu_ana.get_node_or_null(ad)
				if b: b.queue_free()
	baglanti_durumu.text = message
	%MenuDurum.text = message if error else ""
	if %PardexKatmani.visible: _pardex_durumu(message, error)

func _lobi_sahnesine_gec():
	SceneTransition.go_to("res://LobiPaneli.tscn")

func _pardex_ac():
	PardexLink.use_official_mode()
	%PardexKatmani.show()
	var available = PardexLink.is_available()
	%MasaKurBtn.disabled = not available
	%KodlaKatilBtn.disabled = not available
	%KodGiris.editable = available
	%PardexAciklama.text = tr("Masa kurup çıkan beş karakterli kodu arkadaşlarınla paylaş. Aynı masada 2–6 kişi oynayabilirsiniz.") if available else tr("Çevrimiçi masa kurmak veya koda katılmak için HÜKÜM'ü PARDEX kütüphanesinden aç. PARDEX hesabınla bağlantı otomatik kurulur.")
	_pardex_durumu(PardexLink.son_durum if available else tr("PARDEX oturumu bulunamadı."), not available)
	(%MasaKurBtn if available else %PardexGeriBtn).grab_focus()

func _pardex_durumu(message: String, error: bool):
	%PardexDurum.text = message
	%PardexDurum.add_theme_color_override("font_color", Color("ed9b88") if error else Color("9dccae"))
	%PardexIlerleme.visible = PardexLink._busy or (Network.merkezi_mod and Network.oturum_asamasi == "connecting")

func _pardex_kapat():
	PardexLink.leave_match()
	if Network.oturum_asamasi == "connecting": Network.baglantiyi_kapat()
	%PardexKatmani.hide()
	%PardexBtn.grab_focus()

func _baglanti_rozetini_guncelle():
	%BaglantiRozeti.text = tr("PARDEX'E BAĞLI") if PardexLink.linked else tr("YEREL PROFİL")
	%BaglantiRozeti.add_theme_color_override("font_color", Color("9dccae") if PardexLink.linked else Color("bba980"))

func _arayuzu_guncelle():
	%ProfilOyuncuIsmi.text = Global.oyuncu_ismi
	%ProfilResmi.texture = Global.oyuncu_avatar

func _profil_duzenle_ac():
	%MenuDurum.text = ""
	isim_giris_kutusu.text = Global.oyuncu_ismi
	_avatar_sec(Global.profil_no)
	_oyuncu_adi_degisti(isim_giris_kutusu.text)
	profil_duzenle_panel.show()
	isim_giris_kutusu.grab_focus()

func _profil_duzenle_kapat():
	profil_duzenle_panel.hide()
	%ProfilDuzenleBtn.grab_focus()

func _avatar_sec(number: int):
	_avatar = number
	%DuzenleProfilResmi.texture = load("res://Assets/Resimler/Profil%d.png" % number)
	for i in range(1, 9):
		get_node("%Profil" + str(i)).get_node("Secim").visible = i == number

func _oyuncu_adi_hatasini_bul(value: String) -> String:
	var clean = value.strip_edges()
	if clean.length() < 3: return tr("Oyuncu adı en az 3 karakter olmalı.")
	if clean.length() > 16: return tr("Oyuncu adı en fazla 16 karakter olabilir.")
	if clean.contains("  "): return tr("Arka arkaya iki boşluk kullanılamaz.")
	if oyuncu_adi_regex.search(clean) == null: return tr("Yalnız harf, rakam, boşluk, _ ve - kullan.")
	return ""

func _oyuncu_adi_degisti(value: String):
	var error = _oyuncu_adi_hatasini_bul(value)
	kaydet_btn.disabled = not error.is_empty()
	isim_hata_label.text = tr("Oyuncu adı uygun") if error.is_empty() else error
	isim_hata_label.add_theme_color_override("font_color", Color("9dccae") if error.is_empty() else Color("ed9b88"))

func _profil_kaydet():
	if not _oyuncu_adi_hatasini_bul(isim_giris_kutusu.text).is_empty(): return
	Global.oyuncu_ismi = isim_giris_kutusu.text.strip_edges()
	Global.profil_no_ata(_avatar)
	Global.profili_kaydet()
	_arayuzu_guncelle()
	_profil_duzenle_kapat()

func _alistirma_ac():
	oyun_menusu._temizle(tr("TEK OYUNCULU"))
	oyun_menusu._metin(tr("Yapay zekâ hükümdarlara karşı oyna ya da rakipsiz haritada şehir kurmayı, keşfi, üretimi ve kartları öğren. İlk 50 puana ulaşan kazanır. Tek oyunculuda süre sınırı yoktur."))
	var ozet = MacKaydi.ozet()
	if ozet != "":
		oyun_menusu._buton(tr("Kayıtlı maça devam et · ") + ozet, _kayitli_maci_ac).theme_type_variation = &"HukumPrimary"
	oyun_menusu._buton(tr("Öğreticiyle başla"), _ogretici_baslat).theme_type_variation = &"HukumPrimary" if ozet == "" else &""
	var zorluk_satiri = HBoxContainer.new()
	zorluk_satiri.add_theme_constant_override("separation", 12)
	var zorluk_yazi = Label.new()
	zorluk_yazi.text = tr("Rakip zorluğu")
	zorluk_yazi.add_theme_font_size_override("font_size", 20)
	zorluk_satiri.add_child(zorluk_yazi)
	var zorluk = OptionButton.new()
	zorluk.name = "ZorlukSecimi"
	zorluk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zorluk.custom_minimum_size.y = 44
	for ad in ["Kolay", "Orta", "Zor"]: zorluk.add_item(tr(ad))
	zorluk.select(["kolay", "orta", "zor"].find(Network.alistirma_zorlugu))
	zorluk.item_selected.connect(func(i): Network.alistirma_zorlugu = ["kolay", "orta", "zor"][i])
	zorluk_satiri.add_child(zorluk)
	oyun_menusu.satirlar.add_child(zorluk_satiri)
	oyun_menusu._buton(tr("1 rakiple oyna"), _alistirma_baslat.bind(1))
	oyun_menusu._buton(tr("3 rakiple oyna"), _alistirma_baslat.bind(3))
	oyun_menusu._buton(tr("5 rakiple oyna"), _alistirma_baslat.bind(5))
	oyun_menusu._buton(tr("Rakipsiz alıştırma"), _alistirma_baslat.bind(0))
	oyun_menusu._buton(tr("Geri"), oyun_menusu.perde.hide)

func _kayitli_maci_ac():
	var kayit = MacKaydi.yukle()
	if kayit.is_empty():
		%MenuDurum.text = tr("Kayıt okunamadı.")
		return
	_alistirma_baslat(0)
	Network.kayit_yukle = kayit

# Rakipsiz haritada adım adım ilk maç rehberi.
func _ogretici_baslat():
	_alistirma_baslat(0)
	Network.ogretici_modu = true

func _alistirma_baslat(rakip_sayisi: int = 0):
	PardexLink.use_private_mode()
	Network.baglantiyi_kapat()
	Network.alistirma_rakip_sayisi = rakip_sayisi
	Network.alistirma_zorluklari = []
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Network.oyun_tohumu = randi()
	SceneTransition.go_to("res://AnaOyun.tscn")

# --- MAÇA DÖN ---
# Bağlantısı beklenmedik şekilde kopan oyuncu, sunucu açıksa koltuğuna döner.
var _donus_btn: Button

func _donus_dugmesini_kur():
	if not Network.maca_donulebilir_mi(): return
	_donus_btn = Button.new()
	_donus_btn.name = "MacaDonBtn"
	_donus_btn.text = tr("MAÇA DÖN · %s") % str(Network.donus_kaydi.get("isim", "")).to_upper()
	_donus_btn.theme_type_variation = &"HukumPrimary"
	_donus_btn.custom_minimum_size = Vector2(0, 74)
	_donus_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_donus_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var baslik_fontu = %PardexBtn.get_theme_font("font")
	if baslik_fontu: _donus_btn.add_theme_font_override("font", baslik_fontu)
	_donus_btn.add_theme_font_size_override("font_size", 20)
	hbox_menu_ana.add_child(_donus_btn)
	hbox_menu_ana.move_child(_donus_btn, %PardexBtn.get_index())
	_donus_btn.pressed.connect(_maca_don)
	var vazgec = Button.new()
	vazgec.name = "DonusVazgecBtn"
	vazgec.text = tr("Bu maçtan vazgeç")
	vazgec.theme_type_variation = &"HukumCompact"
	vazgec.custom_minimum_size = Vector2(0, 36)
	vazgec.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hbox_menu_ana.add_child(vazgec)
	hbox_menu_ana.move_child(vazgec, _donus_btn.get_index() + 1)
	vazgec.pressed.connect(func():
		Network.donus_kaydini_sil()
		_donus_btn.queue_free()
		vazgec.queue_free())

func _maca_don():
	if not Network.maca_geri_don():
		%MenuDurum.text = tr("Sunucuya bağlanılamadı. Adres geçersiz ya da ağ kapalı.")
		return
	_donus_btn.disabled = true
	%MenuDurum.text = tr("Maça dönülüyor…")
