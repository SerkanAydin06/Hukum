extends Control
class_name AnaMenu

# ==========================================
# 1. KAPSAYICI VE SAHNE DEĞİŞKENLERİ
# ==========================================
const LOBI_SAHNESI := "res://LobiPaneli.tscn"

@onready var ana_margin = $AnaMargin

# ==========================================
# 2. SOL MENÜ DEĞİŞKENLERİ
# ==========================================
@onready var hbox_menu_ana = %HBoxMenuAna
@onready var hbox_menu_coklu = %HBoxMenuCoklu
@onready var cok_oyunculu_btn = %CokOyunculuBtn
@onready var geri_btn = %GeriBtn
@onready var cikis_btn = %CikisBtn


# ==========================================
# 3. AĞ BAĞLANTI DEĞİŞKENLERİ
# ==========================================
@onready var kur_btn = %KurBtn
@onready var baglan_btn = %BaglanBtn
@onready var ip_giris = %IPGiris


# ==========================================
# 4. SAĞ PROFİL - NORMAL GÖRÜNÜM
# ==========================================
@onready var profil_panel = %ProfilPanel
@onready var profil_duzenle_btn = %ProfilDuzenleBtn
@onready var profil_oyuncu_ismi = %ProfilOyuncuIsmi
@onready var profil_resmi = %ProfilResmi


# ==========================================
# 5. SAĞ PROFİL - DÜZENLEME GÖRÜNÜMÜ
# ==========================================
@onready var profil_duzenle_panel = %ProfilDuzenlePanel
@onready var profil_geri_btn = %ProfilGeriBtn
@onready var iptal_btn = %IptalProfilBtn
@onready var kaydet_btn = %KaydetBtn
@onready var isim_giris_kutusu = %IsimGirisKutusu
@onready var duzenle_profil_resmi = %DuzenleProfilResmi
@onready var avatar_grid = %AvatarGrid
@onready var isim_hata_label: Label = %IsimHataLabel

const ISIM_MIN_UZUNLUK := 3
const ISIM_MAX_UZUNLUK := 16

const ISIM_RENK_NORMAL := Color("#B9A77A")
const ISIM_RENK_GECERLI := Color("#DDBB58")
const ISIM_RENK_HATA := Color("#DB7468")

var oyuncu_adi_regex := RegEx.new()

@onready var profil_karartma = %ProfilKarartma

const AVATAR_CERCEVE_NORMAL = preload(
	"res://Assets/UI/AvatarCerceveleri/Normal.png"
)

const AVATAR_CERCEVE_HOVER = preload(
	"res://Assets/UI/AvatarCerceveleri/Hover.png"
)

const AVATAR_CERCEVE_SELECTED = preload(
	"res://Assets/UI/AvatarCerceveleri/Selected.png"
)

const AVATAR_CERCEVE_DISABLED = preload(
	"res://Assets/UI/AvatarCerceveleri/Disabled.png"
)

var secili_avatar_butonu: TextureButton = null


# Geçici profil bilgileri
var gecici_avatar_texture = null
var gecici_profil_no := -1

# ==========================================
# BAŞLANGIÇ VE BAĞLANTILAR
# ==========================================
func _ready() -> void:
	# Başlangıç görünümleri
	hbox_menu_ana.visible = true
	hbox_menu_coklu.visible = false

	profil_panel.visible = true
	profil_duzenle_panel.visible = false
	
	oyuncu_adi_regex.compile(
	"^[A-Za-zÇĞİÖŞÜçğıöşü0-9 _-]+$"
)

	if isim_giris_kutusu:
		isim_giris_kutusu.max_length = ISIM_MAX_UZUNLUK
		isim_giris_kutusu.placeholder_text = "Oyuncu adını gir"

		isim_giris_kutusu.text_changed.connect(
			_oyuncu_adi_degisti
		)

		isim_giris_kutusu.text_submitted.connect(
			_oyuncu_adi_enter_ile_kaydet
		)
	
	if ana_margin:
		ana_margin.visible = true

	_arayuzu_guncelle()

	# Sol menü bağlantıları
	if cok_oyunculu_btn:
		cok_oyunculu_btn.pressed.connect(_cok_oyunculu_menu_ac)

	if geri_btn:
		geri_btn.pressed.connect(_ana_menuye_don)

	if cikis_btn:
		cikis_btn.pressed.connect(_oyundan_cik)

	if kur_btn:
		kur_btn.pressed.connect(_on_kur_btn_pressed)

	if baglan_btn:
		baglan_btn.pressed.connect(_on_baglan_btn_pressed)

	# Profil düzenleme bağlantıları
	if profil_duzenle_btn:
		profil_duzenle_btn.pressed.connect(_profil_duzenle_ac)

	if profil_geri_btn:
		profil_geri_btn.pressed.connect(_profil_duzenle_kapat)

	if iptal_btn:
		iptal_btn.pressed.connect(_profil_duzenle_kapat)

	if kaydet_btn:
		kaydet_btn.pressed.connect(_profil_kaydet)

	if avatar_grid:
		for buton in avatar_grid.get_children():
			if buton is TextureButton:
				buton.pressed.connect(
					_on_avatar_secildi.bind(buton)
				)

				buton.mouse_entered.connect(
					_avatar_hover_girdi.bind(buton)
				)

				buton.mouse_exited.connect(
					_avatar_hover_cikti.bind(buton)
				)

				_avatar_cercevesini_ayarla(
					buton,
					AVATAR_CERCEVE_NORMAL
				)

	# Multiplayer sinyalleri
	if not multiplayer.connected_to_server.is_connected(
		_sunucuya_baglanildi
	):
		multiplayer.connected_to_server.connect(
			_sunucuya_baglanildi
		)

	if not multiplayer.connection_failed.is_connected(
		_baglanti_basarisiz
	):
		multiplayer.connection_failed.connect(
			_baglanti_basarisiz
		)
	if profil_karartma:
		profil_karartma.visible = false
		
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	# Profil düzenleme ekranından çık
	if profil_duzenle_panel.visible:
		SesYoneticisi.geri_sesini_cal()
		_profil_duzenle_kapat()
		get_viewport().set_input_as_handled()
		return

	# Çok oyunculu menüden ana menüye dön
	if hbox_menu_coklu.visible:
		SesYoneticisi.geri_sesini_cal()
		_ana_menuye_don()
		get_viewport().set_input_as_handled()
		return

# ==========================================
# SOL MENÜ FONKSİYONLARI
# ==========================================
func _cok_oyunculu_menu_ac() -> void:
	hbox_menu_ana.visible = false
	hbox_menu_coklu.visible = true

	if kur_btn:
		kur_btn.grab_focus()


func _ana_menuye_don() -> void:
	if ip_giris:
		ip_giris.release_focus()

	hbox_menu_coklu.visible = false
	hbox_menu_ana.visible = true

	if cok_oyunculu_btn:
		cok_oyunculu_btn.grab_focus()


func _oyundan_cik() -> void:
	SceneTransition.quit_game()


# ==========================================
# AĞ VE LOBİ FONKSİYONLARI
# ==========================================
func _on_kur_btn_pressed() -> void:
	kur_btn.disabled = true
	baglan_btn.disabled = true

	if not Network.host_game():
		_baglanti_basarisiz()
		return

	_lobi_sahnesine_gec()

func _on_baglan_btn_pressed() -> void:
	var ip: String = ip_giris.text.strip_edges()

	if ip == "" or ip.to_lower() == "localhost":
		ip = "127.0.0.1"

	if not ip.is_valid_ip_address():
		print("❌ BAĞLANTI HATASI: Geçersiz IP adresi!")
		return

	kur_btn.disabled = true
	baglan_btn.disabled = true
	ip_giris.editable = false

	print("Bağlanılıyor... Sunucu aranıyor.")

	if not Network.join_game(ip):
		_baglanti_basarisiz()

func _sunucuya_baglanildi() -> void:
	print("✅ Bağlantı başarılı! Lobiye geçiliyor.")

	_lobi_sahnesine_gec()

func _baglanti_basarisiz() -> void:
	print("❌ HATA: Sunucu bulunamadı veya bağlantı kurulamadı!")

	Network.baglantiyi_kapat()

	# Bağlantı başarısız olursa kontrolleri yeniden aç
	kur_btn.disabled = false
	baglan_btn.disabled = false
	ip_giris.editable = true

func _lobi_sahnesine_gec() -> void:
	if not ResourceLoader.exists(LOBI_SAHNESI):
		print(
			"❌ Lobi sahnesi bulunamadı: ",
			LOBI_SAHNESI
		)

		kur_btn.disabled = false
		baglan_btn.disabled = false
		ip_giris.editable = true
		return

	SceneTransition.go_to(LOBI_SAHNESI)

# ==========================================
# SAĞ PROFİL FONKSİYONLARI
# ==========================================
func _arayuzu_guncelle() -> void:
	if profil_oyuncu_ismi:
		profil_oyuncu_ismi.text = Global.oyuncu_ismi

	if Global.oyuncu_avatar != null and profil_resmi:
		profil_resmi.texture = Global.oyuncu_avatar

		# Lobiyle senkronize olması için
		Global.secilen_profil_teksturu = Global.oyuncu_avatar

func _profil_duzenle_ac() -> void:
	if isim_giris_kutusu and profil_oyuncu_ismi:
		isim_giris_kutusu.text = profil_oyuncu_ismi.text
		_oyuncu_adi_degisti(isim_giris_kutusu.text)

	if profil_resmi and duzenle_profil_resmi:
		duzenle_profil_resmi.texture = profil_resmi.texture
		gecici_avatar_texture = profil_resmi.texture

	profil_panel.visible = false

	if profil_karartma:
		profil_karartma.visible = true

	profil_duzenle_panel.visible = true

	_avatar_secimini_goster(Global.profil_no)

	isim_giris_kutusu.grab_focus()
	isim_giris_kutusu.caret_column = isim_giris_kutusu.text.length()
	
func _on_avatar_secildi(
	secilen_buton: TextureButton
) -> void:
	var avatar_resmi = secilen_buton.get_node_or_null(
		"AvatarResmi"
	) as TextureRect

	if avatar_resmi == null:
		push_error(
			secilen_buton.name
			+ " içinde AvatarResmi bulunamadı!"
		)
		return

	# Önceki seçimin çerçevesini normale döndür
	if secili_avatar_butonu != null:
		_avatar_cercevesini_ayarla(
			secili_avatar_butonu,
			AVATAR_CERCEVE_NORMAL
		)

	# Yeni avatarı seç
	secili_avatar_butonu = secilen_buton

	_avatar_cercevesini_ayarla(
		secilen_buton,
		AVATAR_CERCEVE_SELECTED
	)

	gecici_avatar_texture = avatar_resmi.texture

	gecici_profil_no = int(
		String(secilen_buton.name).trim_prefix("Profil")
	)

	if duzenle_profil_resmi:
		duzenle_profil_resmi.texture = avatar_resmi.texture

func _profil_duzenle_kapat() -> void:
	if isim_giris_kutusu:
		isim_giris_kutusu.release_focus()

	gecici_avatar_texture = null
	gecici_profil_no = -1

	profil_duzenle_panel.visible = false

	if profil_karartma:
		profil_karartma.visible = false

	profil_panel.visible = true

	if profil_duzenle_btn:
		profil_duzenle_btn.grab_focus()

func _profil_kaydet() -> void:
	var yeni_isim: String = isim_giris_kutusu.text.strip_edges()
	var hata_mesaji := _oyuncu_adi_hatasini_bul(yeni_isim)

	if not hata_mesaji.is_empty():
		_oyuncu_adi_degisti(isim_giris_kutusu.text)
		isim_giris_kutusu.grab_focus()
		return

	Global.oyuncu_ismi = yeni_isim

	if gecici_profil_no != -1:
		Global.profil_no_ata(gecici_profil_no)

	_arayuzu_guncelle()
	isim_giris_kutusu.release_focus()
	
	gecici_avatar_texture = null
	gecici_profil_no = -1

	profil_duzenle_panel.visible = false
	profil_panel.visible = true

	if profil_karartma:
		profil_karartma.visible = false
		
func _avatar_cercevesini_ayarla(
	buton: TextureButton,
	texture: Texture2D
) -> void:
	var cerceve = buton.get_node_or_null("Cerceve") as TextureRect

	if cerceve:
		cerceve.texture = texture


func _avatar_hover_girdi(
	buton: TextureButton
) -> void:
	if buton.disabled:
		_avatar_cercevesini_ayarla(
			buton,
			AVATAR_CERCEVE_DISABLED
		)
		return

	if buton == secili_avatar_butonu:
		_avatar_cercevesini_ayarla(
			buton,
			AVATAR_CERCEVE_SELECTED
		)
	else:
		_avatar_cercevesini_ayarla(
			buton,
			AVATAR_CERCEVE_HOVER
		)


func _avatar_hover_cikti(
	buton: TextureButton
) -> void:
	if buton.disabled:
		_avatar_cercevesini_ayarla(
			buton,
			AVATAR_CERCEVE_DISABLED
		)
		return

	if buton == secili_avatar_butonu:
		_avatar_cercevesini_ayarla(
			buton,
			AVATAR_CERCEVE_SELECTED
		)
	else:
		_avatar_cercevesini_ayarla(
			buton,
			AVATAR_CERCEVE_NORMAL
		)


func _avatar_secimini_goster(
	profil_no: int
) -> void:
	secili_avatar_butonu = null

	for buton in avatar_grid.get_children():
		if not buton is TextureButton:
			continue

		var buton_no := int(
			String(buton.name).trim_prefix("Profil")
		)

		if buton_no == profil_no:
			secili_avatar_butonu = buton

			_avatar_cercevesini_ayarla(
				buton,
				AVATAR_CERCEVE_SELECTED
			)
		else:
			_avatar_cercevesini_ayarla(
				buton,
				AVATAR_CERCEVE_NORMAL
			)

func _oyuncu_adi_hatasini_bul(
	girilen_isim: String
) -> String:
	var temiz_isim := girilen_isim.strip_edges()

	if temiz_isim.is_empty():
		return "Oyuncu adı boş bırakılamaz."

	if temiz_isim.length() < ISIM_MIN_UZUNLUK:
		return "Oyuncu adı en az 3 karakter olmalı."

	if temiz_isim.length() > ISIM_MAX_UZUNLUK:
		return "Oyuncu adı en fazla 16 karakter olabilir."

	if temiz_isim.contains("  "):
		return "Arka arkaya iki boşluk kullanılamaz."

	if oyuncu_adi_regex.search(temiz_isim) == null:
		return "Bu karakter oyuncu adında kullanılamaz."

	return ""


func _oyuncu_adi_degisti(
	yeni_metin: String
) -> void:
	var hata_mesaji := _oyuncu_adi_hatasini_bul(yeni_metin)
	var isim_gecerli := hata_mesaji.is_empty()

	kaydet_btn.disabled = not isim_gecerli

	if isim_gecerli:
		isim_hata_label.text = "Oyuncu adı uygun"
		isim_hata_label.add_theme_color_override(
			"font_color",
			ISIM_RENK_GECERLI
		)
	else:
		isim_hata_label.text = hata_mesaji
		isim_hata_label.add_theme_color_override(
			"font_color",
			ISIM_RENK_HATA
		)

func _oyuncu_adi_enter_ile_kaydet(
	_yeni_metin: String
) -> void:
	if not kaydet_btn.disabled:
		_profil_kaydet()
