extends Node

var players: Dictionary[StringName, Player]


func is_player_action(
		p_event: InputEvent,
		p_player_id: StringName,
		p_action: StringName,
		p_exact_match: bool = false
	) -> bool:
	if not input_is_from_player(p_event, p_player_id):
		return false
	
	var player: Player = players[p_player_id]
	
	# The player has an action override for p_action.
	if player.has_action(p_action):
		return player.action_has_event(p_action, p_event, p_exact_match)
	else:
		return p_event.is_action(p_action, p_exact_match)


func is_player_action_pressed(
		p_event: InputEvent,
		p_player_id: StringName,
		p_action: StringName,
		p_allow_echo: bool = false,
		p_exact_match: bool = false
	) -> bool:
	if not p_allow_echo and p_event is InputEventKey and p_event.is_echo():
		return false
	
	if not p_event.is_pressed():
		return false
	
	return is_player_action(p_event, p_player_id, p_action, p_exact_match)


func is_player_action_released(
		p_event: InputEvent,
		p_player_id: StringName,
		p_action: StringName,
		p_allow_echo: bool = false,
		p_exact_match: bool = false
	) -> bool:
	if not p_allow_echo and p_event is InputEventKey and p_event.is_echo():
		return false
	
	if not p_event.is_released():
		return false
	
	return is_player_action(p_event, p_player_id, p_action, p_exact_match)


func input_has_player(p_event: InputEvent) -> bool:
	return not input_get_player(p_event).is_empty()


func input_is_from_player(p_event: InputEvent, p_player_id: StringName) -> bool:
	return input_get_player(p_event) == p_player_id


func input_get_player(p_event: InputEvent) -> StringName:
	return device_get_player(InputDevice.create_from_event(p_event))


func device_get_player(p_device: InputDevice) -> StringName:
	for player: StringName in players:
		if players[player].has_device(p_device):
			return player
	return &""


func input_can_assign_to_player(p_input_event: InputEvent) -> bool:
	return InputDevice.create_from_event(p_input_event).is_valid()


func add_player(p_player_id: StringName) -> void:
	if p_player_id.is_empty():
		push_error("Cannot add empty player")
		return
	if player_exists(p_player_id):
		push_error("Input player `%s` has already been added")
		return
	players[p_player_id] = Player.new()


func remove_player(p_player_id: StringName) -> void:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	players.erase(p_player_id)


func player_exists(p_player_id: StringName) -> bool:
	return p_player_id in players


func is_device_assigned(p_device: InputDevice) -> bool:
	return not device_get_player(p_device).is_empty()


func player_has_assigned_device(p_player_id: StringName) -> bool:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return true
	return players[p_player_id].get_device_count() != 0


func player_add_device(p_player_id: StringName, p_device: InputDevice) -> void:
	if not p_device.is_valid():
		push_error("Cannot add invalid device to player")
		return
	
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	
	var input_device_player: StringName = device_get_player(p_device)
	if not input_device_player.is_empty():
		push_error("Input device %s is already assigned to player `%s`" % [
			p_device, input_device_player
		])
		return
	
	players[p_player_id].add_device(p_device)


func player_get_devices(p_player_id: StringName) -> Array[InputDevice]:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return []
	return players[p_player_id].devices


func unassign_device(p_device: InputDevice) -> void:
	var player_id: StringName = device_get_player(p_device)
	if player_id.is_empty():
		return
	
	players[player_id].remove_device(p_device)


func _input_event_eq(p_event_a: InputEvent, p_event_b: InputEvent, p_exact_match: bool) -> bool:
	if p_exact_match and p_event_a is InputEventWithModifiers and p_event_b is InputEventWithModifiers:
		var exact_match: bool = (
			p_event_a.alt_pressed == p_event_b.alt_pressed
			and p_event_a.ctrl_pressed == p_event_b.ctrl_pressed
			and p_event_a.meta_pressed == p_event_b.meta_pressed
			and p_event_a.shift_pressed == p_event_b.shift_pressed
			and p_event_a.command_or_control_autoremap == p_event_b.command_or_control_autoremap
		)
		if not exact_match:
			return false
	
	if p_event_a is InputEventJoypadButton and p_event_b is InputEventJoypadButton:
		return p_event_a.button_index == p_event_b.button_index
	if p_event_a is InputEventJoypadMotion and p_event_b is InputEventJoypadMotion:
		return (
			p_event_a.axis == p_event_b.axis
			and p_event_a.axis_value * p_event_b.axis_value >= 0.0
		)
	if p_event_a is InputEventMIDI and p_event_b is InputEventMIDI:
		return (
			p_event_a.channel == p_event_b.channel
			and p_event_a.controller_number == p_event_b.controller_number
			and p_event_a.instrument == p_event_b.instrument
			and (
				(
					(p_event_a.message == MIDI_MESSAGE_NOTE_ON or p_event_a.message == MIDI_MESSAGE_NOTE_OFF)
					and (p_event_b.message == MIDI_MESSAGE_NOTE_ON or p_event_b.message == MIDI_MESSAGE_NOTE_OFF)
				)
				or (
					p_event_a.message == MIDI_MESSAGE_CONTROL_CHANGE
					and p_event_b.message == MIDI_MESSAGE_CONTROL_CHANGE
				)
			)
			and p_event_a.pitch == p_event_b.pitch
		)
	if p_event_a is InputEventKey and p_event_b is InputEventKey:
		return p_event_a.physical_keycode == p_event_b.physical_keycode
	if p_event_a is InputEventMouseButton and p_event_b is InputEventMouseButton:
		return p_event_a.button_index == p_event_b.button_index
	
	return false


class Player extends Object:
	var devices: Array[InputDevice]
	var input_map: Dictionary[StringName, Array]
	
	
	func add_device(p_device: InputDevice) -> void:
		devices.push_back(p_device)
	
	
	func remove_device(p_device: InputDevice) -> void:
		var index: int = _find_device(p_device)
		if index != -1:
			devices.remove_at(index)
	
	
	func has_device(p_device: InputDevice) -> bool:
		return _find_device(p_device) != -1
	
	
	func _find_device(p_device: InputDevice) -> int:
		return devices.find_custom(func(p_inner_device: InputDevice) -> bool:
			return p_device.equals(p_inner_device)
		)
	
	
	func get_device_count() -> int:
		return devices.size()
	
	
	func get_action_events(p_action: StringName) -> Array[InputEvent]:
		var result: Array[InputEvent]
		result.assign(input_map[p_action])
		return result
	
	
	func remove_action(p_action: StringName) -> void:
		input_map.erase(p_action)
	
	
	func add_action(p_action: StringName) -> void:
		input_map[p_action] = []
	
	
	func action_add_event(p_action: StringName, p_event: InputEvent) -> void:
		input_map[p_action].push_back(p_event)
	
	
	func action_has_event(p_action: StringName, p_event: InputEvent, p_exact_match: bool) -> bool:
		return _action_find_event(p_action, p_event, p_exact_match) != -1
	
	
	func action_remove_event(p_action: StringName, p_event: InputEvent) -> void:
		var index: int = _action_find_event(p_action, p_event, true)
		if index != -1:
			input_map[p_action].remove_at(index)
	
	
	func _action_find_event(p_action: StringName, p_event: InputEvent, p_exact_match: bool) -> int:
		return input_map[p_action].find_custom(func(p_inner_event: InputEvent) -> bool:
			return Multinput._input_event_eq(p_event, p_inner_event, p_exact_match)
		)
	
	
	func has_action(p_action: StringName) -> bool:
		return p_action in input_map
