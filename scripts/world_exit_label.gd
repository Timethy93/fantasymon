class_name WorldExitLabel
extends Label3D

@export var text_key: String
@export var movement_action: String

@onready var settings: FantasyMonSettings = get_node("/root/GameSettings")


func _ready() -> void:
	settings.changed.connect(_refresh)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


func _refresh() -> void:
	text = tr(text_key).format({"key": settings.key_label(movement_action)})
