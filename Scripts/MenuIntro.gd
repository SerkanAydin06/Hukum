extends Node

@export var logo: Control
@export var ana_menu_grubu: Control
@export var profil_paneli: Control

@export_category("Animasyon")
@export var intro_suresi := 0.38
@export var baslangic_olcegi := 0.96

var intro_tween: Tween


func _ready() -> void:
	# Container yerleşimlerinin tamamlanmasını bekle
	await get_tree().process_frame

	_introyu_baslat()


func _introyu_baslat() -> void:
	if intro_tween and intro_tween.is_valid():
		intro_tween.kill()

	var kontroller: Array[Control] = []

	if is_instance_valid(logo):
		kontroller.append(logo)

	if is_instance_valid(ana_menu_grubu):
		kontroller.append(ana_menu_grubu)

	if is_instance_valid(profil_paneli):
		kontroller.append(profil_paneli)

	if kontroller.is_empty():
		push_warning(
			"MenuIntro: Animasyon node'ları atanmamış!"
		)
		return

	var hedef_olcekler: Dictionary = {}

	for kontrol in kontroller:
		# Ölçek merkezden gerçekleşsin
		kontrol.pivot_offset = kontrol.size / 2.0

		# Mevcut gerçek ölçeği sakla
		hedef_olcekler[kontrol] = kontrol.scale

		# Başlangıç görünümü
		kontrol.modulate.a = 0.0
		kontrol.scale = kontrol.scale * baslangic_olcegi

	# Bütün animasyonlar aynı anda çalışır
	intro_tween = create_tween()
	intro_tween.set_parallel(true)
	intro_tween.set_trans(Tween.TRANS_CUBIC)
	intro_tween.set_ease(Tween.EASE_OUT)

	for kontrol in kontroller:
		intro_tween.tween_property(
			kontrol,
			"modulate:a",
			1.0,
			intro_suresi
		)

		intro_tween.tween_property(
			kontrol,
			"scale",
			hedef_olcekler[kontrol],
			intro_suresi
		)
