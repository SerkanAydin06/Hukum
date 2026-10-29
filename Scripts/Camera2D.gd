extends Camera2D

# Klavye ile kaydırma hızı
var klavye_hizi = 500.0 

# Fare sürükleme durumu
var surukleniyor = false

func _process(delta):
	var ana = get_parent()
	if ana is AnaOyun and (ana.oyun_bitti or (ana.oyun_menusu and ana.oyun_menusu.perde.visible)): return
	var hareket_yonu = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		hareket_yonu.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		hareket_yonu.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		hareket_yonu.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		hareket_yonu.y -= 1
		
	if hareket_yonu != Vector2.ZERO:
		position += hareket_yonu.normalized() * klavye_hizi * delta

func _unhandled_input(event):
	var ana = get_parent()
	if ana is AnaOyun and (ana.oyun_bitti or (ana.oyun_menusu and ana.oyun_menusu.perde.visible)):
		surukleniyor = false
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if zoom.x < 5.0:
				zoom += Vector2(0.05, 0.05)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if zoom.x > 1.0:
				zoom -= Vector2(0.05, 0.05)

		if event.button_index == MOUSE_BUTTON_RIGHT:
			surukleniyor = event.pressed

	if event is InputEventMouseMotion and surukleniyor:
		position -= event.relative / zoom.x
