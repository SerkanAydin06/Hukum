extends Node

# Presentation only. Never writes player identity, rules, cards or match state.
const BASE = preload("res://UI/HukumTheme.tres")
const TEMPLATES = preload("res://UI/CivilizationTemplates.gd")
const ORNAMENT = preload("res://UI/CivilizationOrnament.gd")
const CIVS = {
	"Osmanlı": {"id": "osmanli", "accent": "b54b57"},
	"Venedik": {"id": "venedik", "accent": "418dce"},
	"Bizans": {"id": "bizans", "accent": "a372c8"},
	"Mısır": {"id": "misir", "accent": "35bcb1"},
	"Moğol": {"id": "mogol", "accent": "b88b52"},
	"Viking": {"id": "viking", "accent": "559d9e"},
}
const CRESTS = {
	"osmanli": preload("res://UI/Civilizations/osmanli_crest.png"),
	"venedik": preload("res://UI/Civilizations/venedik_crest.png"),
	"bizans": preload("res://UI/Civilizations/bizans_crest.png"),
	"misir": preload("res://UI/Civilizations/misir_crest.png"),
	"mogol": preload("res://UI/Civilizations/mogol_crest.png"),
	"viking": preload("res://UI/Civilizations/viking_crest.png"),
}
static var _skins: Dictionary = {}
var civilization := ""
var _styled_root: Node

func _ready():
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	# Newly dealt card scenes carry the base theme explicitly. Keep their
	# command buttons in the local player's skin without touching card artwork.
	if is_instance_valid(_styled_root) and node is Control and node.theme == BASE and _styled_root.is_ancestor_of(node):
		node.set_meta("hukum_original_theme", BASE)
		node.theme = skin_for(civilization).theme

static func _svg_texture(source: String) -> Texture2D:
	var image = Image.new()
	if image.load_svg_from_string(source) != OK: return null
	return ImageTexture.create_from_image(image)

static func skin_for(civ: String) -> Dictionary:
	if not CIVS.has(civ): return {}
	if _skins.has(civ): return _skins[civ]
	var spec = CIVS[civ]
	var accent = Color(spec.accent)
	var skin: Theme = BASE.duplicate()
	var textures := {}
	for family in ["standard", "primary"]:
		for state in ["normal", "hover", "selected", "hover_pressed", "disabled"]:
			var source = str(TEMPLATES.BUTTONS[family + "_" + state])
			if state != "disabled":
				var down = state in ["selected", "hover_pressed"]
				var tint = accent.lerp(Color("b69b62"), 0.28) if family == "primary" else accent
				var top = tint.lerp(Color.BLACK, 0.48 if "hover" in state else 0.60)
				var colors = [top.lightened(0.08), tint.lerp(Color.BLACK, 0.76), tint.lerp(Color.BLACK, 0.90), Color("050604")]
				if down: colors.reverse()
				var gradient = '<linearGradient id="face" x1="0%" y1="0%" x2="0%" y2="100%">'
				for i in range(4):
					gradient += '<stop offset="%s" stop-color="#%s"/>' % [["0%", "24%", "64%", "100%"][i], colors[i].to_html(false)]
				gradient += '</linearGradient>'
				var start = source.find('<linearGradient id="face"')
				var end = source.find('</linearGradient>', start) + '</linearGradient>'.length()
				source = source.substr(0, start) + gradient + source.substr(end)
			textures[family + "_" + state] = _svg_texture(source)
	for type in ["Button", "HukumPrimary", "HukumCompact"]:
		var family = "primary" if type == "HukumPrimary" else "standard"
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var style: StyleBoxTexture = BASE.get_stylebox(state, type).duplicate()
			style.texture = textures[family + "_" + ("selected" if state == "pressed" else state)]
			skin.set_stylebox(state, type, style)
	var window = str(TEMPLATES.WINDOW)
	window = window.replace('</svg>', '<path d="M11 25 V103 M117 25 V103 M25 11 H103 M25 117 H103" fill="none" stroke="#%s" stroke-width="1.4" opacity=".85"/></svg>' % accent.to_html(false))
	var window_texture = _svg_texture(window)
	for type in ["PanelContainer", "Panel", "HukumPanel", "HukumSlot"]:
		var style: StyleBoxTexture = BASE.get_stylebox("panel", type).duplicate()
		style.texture = window_texture
		skin.set_stylebox("panel", type, style)
	var emblem = CRESTS[spec.id]
	var result = {"theme": skin, "window": window_texture, "emblem": emblem, "accent": accent, "id": spec.id}
	_skins[civ] = result
	return result

func apply_to(target: Node, civ: String):
	if civilization == civ and _styled_root == target: return
	var data = skin_for(civ)
	if data.is_empty(): return
	civilization = civ
	_styled_root = target
	var pending = [target]
	while not pending.is_empty():
		var node = pending.pop_back()
		pending.append_array(node.get_children())
		if not node is Control: continue
		if node.theme != null:
			if not node.has_meta("hukum_original_theme"): node.set_meta("hukum_original_theme", node.theme)
			var original: Theme = node.get_meta("hukum_original_theme")
			if original == BASE:
				node.theme = data.theme
			else:
				var merged: Theme = original.duplicate()
				for type in ["Button", "HukumPrimary", "HukumCompact", "PanelContainer", "Panel", "HukumPanel", "HukumSlot"]:
					for key in data.theme.get_stylebox_list(type): merged.set_stylebox(key, type, data.theme.get_stylebox(key, type))
				node.theme = merged
		var framed = node is NinePatchRect and node.texture != null and (node.texture.resource_path.ends_with("window.svg") or node.has_meta("hukum_civ_window"))
		if framed:
			node.set_meta("hukum_civ_window", true)
			node.texture = data.window
		if framed or (node is PanelContainer and node.theme_type_variation not in [&"HukumPortrait", &"HukumSlot"]):
			var decoration = node.get_node_or_null("CivilizationOrnament")
			if decoration == null:
				decoration = ORNAMENT.new()
				decoration.name = "CivilizationOrnament"
				decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
				decoration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				node.add_child(decoration)
				node.move_child(decoration, 0)
			decoration.emblem = data.emblem
			decoration.queue_redraw()
	var end_turn = target.get_node_or_null("%TurButonu")
	if end_turn is Button:
		end_turn.icon = data.emblem
		end_turn.expand_icon = true
		end_turn.add_theme_constant_override("icon_max_width", 72)
		end_turn.add_theme_constant_override("h_separation", 12)
		end_turn.tooltip_text = civ + tr(" · Turu bitir")
