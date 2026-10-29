extends SceneTree
func _initialize(): call_deferred("start")
func start():
	var driver = load("res://tests/central_network_driver.gd").new()
	driver.name = "SceneNetworkDriver"
	root.add_child(driver)
