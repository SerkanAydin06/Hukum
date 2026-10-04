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


func _ses_oynaticilarini_hazirla() -> void:
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
