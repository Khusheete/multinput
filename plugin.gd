@tool
extends EditorPlugin


const InputDevice: Script = preload("src/input_device.gd")


func _enter_tree() -> void:
	add_custom_type("InputDevice", "RefCounted", InputDevice, null)
	add_autoload_singleton("Multinput", "src/multinput.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("Multinput")
	remove_custom_type("InputDevice")
