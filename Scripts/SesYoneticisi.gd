extends Node

const HOVER_SESI := "res://Assets/Audio/UI/ui_hover.wav"
const CLICK_SESI := "res://Assets/Audio/UI/ui_click.wav"
const GERI_SESI := "res://Assets/Audio/UI/ui_back.wav"

var hover_oynatici: AudioStreamPlayer
var click_oynatici: AudioStreamPlayer
var geri_oynatici: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_ses_oynaticilarini_hazirla()

	if not get_tree().node_added.is_connected(_node_eklendi):
		get_tree().node_added.connect(_node_eklendi)

	await get_tree().process_frame

	_butonlari_tara(get_tree().current_scene)


# --- OYUN SESLERİ VE MÜZİK ---
const EFEKTLER = ["kart_cek", "insa", "kesif", "hakimiyet", "savas_baslat", "kilic", "zar",
	"savas_sonu", "sira_sende", "zafer", "yenilgi"]
const MUZIKLER = {"menu": "res://Assets/Audio/Muzik/menu_muzigi.ogg", "oyun": "res://Assets/Audio/Muzik/oyun_muzigi.ogg"}
# Hamle adı -> efekt (her eşte hamle uygulanınca çalar).
const HAMLE_SESLERI = {
	"bina_kur_rpc": "insa", "kart_oyna_rpc": "insa", "bina_yukselt_rpc": "insa", "oncu_uret_rpc": "insa",
	"kesif_ve_hareket_rpc": "kesif", "hakimiyet_kur_rpc": "hakimiyet", "savas_baslat_rpc": "savas_baslat",
	"karti_feda_et_rpc": "kart_cek", "ticaret_yap_rpc": "kart_cek",
}
var _efekt_akislari := {}
var _efekt_havuzu: Array[AudioStreamPlayer] = []
var _muzik_oynaticilari: Array[AudioStreamPlayer] = []
var _aktif_muzik := ""
var son_efekt := ""   # testler ve hata ayıklama için

func _oyun_seslerini_hazirla() -> void:
	Global._bus("Muzik")
	Global._bus("Efekt")
	Global.ayarlari_uygula()
	for ad in EFEKTLER:
		var yol = "res://Assets/Audio/Oyun/%s.wav" % ad
		if ResourceLoader.exists(yol): _efekt_akislari[ad] = load(yol)
	for i in range(6):
		var o = AudioStreamPlayer.new()
		o.bus = "Efekt"
		o.volume_db = -4.0
		add_child(o)
		_efekt_havuzu.append(o)
	for i in range(2):
		var m = AudioStreamPlayer.new()
		m.bus = "Muzik"
		m.volume_db = -60.0
		add_child(m)
		_muzik_oynaticilari.append(m)

func efekt_cal(ad: String) -> void:
	son_efekt = ad
	var akis = _efekt_akislari.get(ad)
	if akis == null or DisplayServer.get_name() == "headless": return
	for o in _efekt_havuzu:
		if not o.playing:
			o.stream = akis
			o.play()
			return
	_efekt_havuzu[0].stream = akis
	_efekt_havuzu[0].play()

func hamle_sesi(metod: String) -> void:
	if HAMLE_SESLERI.has(metod): efekt_cal(HAMLE_SESLERI[metod])

# İki oynatıcı arasında yumuşak geçişle döngü müziği.
func muzik_cal(ad: String) -> void:
	if ad == _aktif_muzik or _muzik_oynaticilari.is_empty(): return
	_aktif_muzik = ad
	if DisplayServer.get_name() == "headless" or not MUZIKLER.has(ad) or not ResourceLoader.exists(MUZIKLER[ad]): return
	var akis = load(MUZIKLER[ad]) as AudioStreamOggVorbis
	if akis == null: return
	akis.loop = true
	var eski = _muzik_oynaticilari[0]
	var yeni = _muzik_oynaticilari[1]
	_muzik_oynaticilari.reverse()
	yeni.stream = akis
	yeni.volume_db = -40.0
	yeni.play()
	var gecis = create_tween().set_parallel(true)
	gecis.tween_property(yeni, "volume_db", -8.0, 2.0)
	if eski.playing: gecis.tween_property(eski, "volume_db", -60.0, 2.0)
	gecis.chain().tween_callback(func(): if eski != _muzik_oynaticilari[1] or eski.volume_db <= -59.0: eski.stop())

func _ses_oynaticilarini_hazirla() -> void:
	_oyun_seslerini_hazirla()
	hover_oynatici = _oynatici_olustur(
		"HoverOynatici",
		HOVER_SESI,
		-13.0
	)

	click_oynatici = _oynatici_olustur(
		"ClickOynatici",
		CLICK_SESI,
		-9.0
	)

	geri_oynatici = _oynatici_olustur(
		"GeriOynatici",
		GERI_SESI,
		-10.0
	)


func _oynatici_olustur(
	oynatici_adi: String,
	ses_yolu: String,
	ses_seviyesi: float
) -> AudioStreamPlayer:
	var oynatici := AudioStreamPlayer.new()

	oynatici.name = oynatici_adi
	oynatici.volume_db = ses_seviyesi

	if AudioServer.get_bus_index("UI") != -1:
		oynatici.bus = "UI"
	else:
		oynatici.bus = "Master"

	if ResourceLoader.exists(ses_yolu):
		oynatici.stream = load(ses_yolu) as AudioStream
	else:
		push_warning(
			"UI ses dosyası bulunamadı: " + ses_yolu
		)

	add_child(oynatici)

	return oynatici


func _node_eklendi(node: Node) -> void:
	if node is BaseButton:
		_butonu_kaydet(node as BaseButton)


func _butonlari_tara(node: Node) -> void:
	if node == null:
		return

	if node is BaseButton:
		_butonu_kaydet(node as BaseButton)

	for child in node.get_children():
		_butonlari_tara(child)


func _butonu_kaydet(buton: BaseButton) -> void:
	if buton.has_meta("_ui_sesi_bagli"):
		return

	buton.set_meta("_ui_sesi_bagli", true)

	buton.mouse_entered.connect(
		_buton_hover.bind(buton)
	)

	buton.button_down.connect(
	_buton_basildi.bind(buton)
	)


func _buton_hover(buton: BaseButton) -> void:
	if not _buton_kullanilabilir(buton):
		return

	if _buton_sesi_kapali(buton):
		return

	_sesi_cal(hover_oynatici)


func _buton_basildi(buton: BaseButton) -> void:
	if not _buton_kullanilabilir(buton):
		return

	if _buton_sesi_kapali(buton):
		return

	if (
		buton.is_in_group("ui_geri_butonu")
		or buton.get_meta("ui_sesi", "") == "geri"
	):
		_sesi_cal(geri_oynatici)
	else:
		_sesi_cal(click_oynatici)


func _buton_kullanilabilir(
	buton: BaseButton
) -> bool:
	return (
		is_instance_valid(buton)
		and not buton.disabled
	)


func _buton_sesi_kapali(buton: BaseButton) -> bool:
	return buton.get_meta("ui_sesi", "") == "yok"


func _sesi_cal(oynatici: AudioStreamPlayer) -> void:
	if oynatici == null or oynatici.stream == null:
		return

	oynatici.stop()
	oynatici.play()

func geri_sesini_cal() -> void:
	_sesi_cal(geri_oynatici)
