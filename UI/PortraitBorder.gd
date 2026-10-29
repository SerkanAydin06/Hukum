@tool
extends TextureRect

const NORMAL = preload("res://Assets/UI/AvatarCerceveleri/Normal.png")
const HOVER = preload("res://Assets/UI/AvatarCerceveleri/Hover.png")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture = NORMAL
	if get_parent() is TextureButton:
		get_parent().mouse_entered.connect(func(): texture = HOVER)
		get_parent().mouse_exited.connect(func(): texture = NORMAL)
