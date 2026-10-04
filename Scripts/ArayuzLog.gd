extends Node
class_name ArayuzLog

var arayuz: Node

func baslat(_arayuz):
	arayuz = _arayuz

func olay_yaz(metin: String):
	if not arayuz.olay_logu: return
	
	var yeni_satir = RichTextLabel.new()
	yeni_satir.bbcode_enabled = true
	yeni_satir.fit_content = true
	yeni_satir.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	yeni_satir.custom_minimum_size = Vector2(10, 0)
	yeni_satir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yeni_satir.text = metin
	
	arayuz.olay_logu.add_child(yeni_satir)
	
	await arayuz.get_tree().process_frame
	var kaydirma_kutusu = arayuz.olay_logu.get_parent() 
	if kaydirma_kutusu is ScrollContainer:
		var dikey_bar = kaydirma_kutusu.get_v_scroll_bar()
		var scroll_tween = create_tween()
		scroll_tween.tween_property(kaydirma_kutusu, "scroll_vertical", int(dikey_bar.max_value), 0.1)
	
	# Log sayısı 50'yi geçerse en eski logu siler (istersen bu limiti artırabilirsin)
	if arayuz.olay_logu.get_child_count() > 50: 
		arayuz.olay_logu.get_child(0).queue_free()
	
	# Panel opaklığı her zaman tam görünür (1.0) kalır ve asla kaybolmaz
	var sol_panel = arayuz.olay_logu.get_parent().get_parent()
	sol_panel.modulate.a = 1.0
