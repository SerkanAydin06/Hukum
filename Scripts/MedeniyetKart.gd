extends Control

signal medeniyet_secildi(medeniyet:String)

@export_enum("Osmanlı","Mısır","Venedik","Bizans","Moğol","Viking")
var medeniyet := "Osmanlı"
var secili := false

@onready var flama:TextureButton = $Flama
@onready var lock:Label = $Lock

var dosyalar = {
	"Osmanlı":"osmanli",
	"Mısır":"misir",
	"Venedik":"venedik",
	"Bizans":"bizans",
	"Moğol":"mogol",
	"Viking":"viking"
}

func _ready():
	var dosya = dosyalar[medeniyet]
	flama.texture_normal = load("res://Assets/Flamalar/%s_flama.png" % dosya)
	lock.visible = false
	flama.pressed.connect(_tiklandi)
	flama.mouse_entered.connect(_hover)
	flama.mouse_exited.connect(_normal)

func _tiklandi():
	if flama.disabled:
		return
	medeniyet_secildi.emit(medeniyet)

func _hover():
	if flama.disabled or secili:
		return

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.05, 1.05), 0.12)
	tw.tween_property(self, "position:y", -6.0, 0.12)

func _normal():
	if secili:
		return

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12)
	tw.tween_property(self, "position:y", 0.0, 0.12)

func secili_yap():

	secili = true

	var tw = create_tween()
	tw.set_parallel(true)

	tw.tween_property(self, "scale", Vector2(1.08,1.08), 0.15)
	tw.tween_property(self, "position:y", -8, 0.15)

func secimi_kaldir():

	secili = false

	var tw = create_tween()
	tw.set_parallel(true)

	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
	tw.tween_property(self, "position:y", 0, 0.15)

func kilitle():

	lock.visible = true
	flama.disabled = true

	modulate = Color(0.45,0.45,0.45)

func kilidi_ac():

	lock.visible = false
	flama.disabled = false

	modulate = Color.WHITE
