extends "res://ui/game/menu_panel.gd"

func build_content() -> void:
	var feed := Button.new()
	feed.text = "CARE_FEED"
	feed.pressed.connect(func(): get_node("/root/Menus").open_menu(&"food", true))
	body.add_child(feed)
	first_focus = feed
