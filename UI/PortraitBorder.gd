@tool
extends TextureRect

const NORMAL = preload("res://Assets/UI/AvatarCerceveleri/Normal.png")
const PORTRAIT_MASK = preload("res://UI/PortraitMask.gdshader")
const HOVER = preload("res://Assets/UI/AvatarCerceveleri/Hover.png")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture = NORMAL
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait = get_parent()
	var portrait_material = ShaderMaterial.new()
	portrait_material.shader = PORTRAIT_MASK
	portrait.material = portrait_material
	if portrait is TextureRect:
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_SCALE
	elif portrait is TextureButton:
		portrait.stretch_mode = TextureButton.STRETCH_SCALE
	portrait.resized.connect(_update_mask_bounds)
	_update_mask_bounds()
	if get_parent() is TextureButton:
		get_parent().mouse_entered.connect(func(): texture = HOVER)
		get_parent().mouse_exited.connect(func(): texture = NORMAL)

func _update_mask_bounds():
	var portrait = get_parent() as Control
	var side = maxf(1.0, minf(portrait.size.x, portrait.size.y))
	portrait.material.set_shader_parameter("box_ratio", portrait.size / side)
