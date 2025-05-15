# Copyright 2025-present Ferdinand Souchet (aka. Khusheete)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name InputDevice
extends RefCounted
## An [InputDevice] holds information about a physical device used for input.


## A type of a device.
enum DeviceType {
	## An unknown device is either non existant or not supported.
	UNKNOWN,
	KEYBOARD,
	GAME_CONTROLLER,
	MOUSE,
	MIDI_CONTROLLER,
}


## The type of this device.
var type := DeviceType.UNKNOWN
## The identifient of this device. This corresponds to [member InputEvent.device].
var id: int


## Returns the [InputDevice] of [param p_event].
static func create_from_event(p_event: InputEvent) -> InputDevice:
	var input_device := InputDevice.new()
	
	if p_event is InputEventKey:
		input_device.type = DeviceType.KEYBOARD
		input_device.id   = p_event.device
	elif p_event is InputEventJoypadButton or p_event is InputEventJoypadMotion:
		input_device.type = DeviceType.GAME_CONTROLLER
		input_device.id   = p_event.device
	elif p_event is InputEventMouse:
		input_device.type = DeviceType.MOUSE
		input_device.id   = p_event.device
	elif p_event is InputEventMIDI:
		input_device.type = DeviceType.MIDI_CONTROLLER
		input_device.id   = p_event.device
	
	return input_device


## Returns [code]true[/code] if this input device is valid. Meaning that the [member type] is
## not [enum DeviceType.UNKNOWN].
func is_valid() -> bool:
	return type != DeviceType.UNKNOWN


## Returns [code]true[/code] if this input device is the same as [param p_other].
func equals(p_other: InputDevice) -> bool:
	return type == p_other.type and id == p_other.id


func _to_string() -> String:
	match type:
		DeviceType.KEYBOARD:
			return "keyboard(%s)" % id
		DeviceType.GAME_CONTROLLER:
			return "game_controller(%s)" % id
		DeviceType.MOUSE:
			return "mouse(%s)" % id
		DeviceType.MIDI_CONTROLLER:
			return "midi_controller(%s)" % id
		_:
			return "unknown device"
