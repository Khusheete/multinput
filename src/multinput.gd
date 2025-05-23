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

extends Node
## The [Multinput] singleton handles separating inputs made on different input devices (keyboard,
## mouse, game controller, and MIDI instrument) by players.
## 
## A player is registered using [method add_player] and can be assigned one or more input devices
## using [method player_add_device]. [Multinput] keeps track of input actions (defined in godot's
## [InputMap]) made by each player.
##
## [br][br]
## [b]Note:[/b] Since most OSes do not support differentiating keyboards and mice, godot dosen't
## either. Meaning that it is not possible to have two players both using a different keyboard.


## Emitted when a player's device has been connected or disconnected.
##
## [br][br]
## [b]Note: [/b] Currently, the only connection/disconnection event that is tracked is for game
## controllers.
signal player_device_connection_changed(
	p_player_id: StringName,
	p_device: InputDevice,
	p_connected: bool,
)


var _players: Dictionary[StringName, Player]


# =====================
# = Action Operations =
# =====================


## Retruns [code]true[/code] if [param p_event] matches the action [param p_action] from player
## [param p_player_id].
##
## [br][br]
## [b]See:[/b] [method InputEvent.is_action]
func input_is_player_action(
		p_event: InputEvent,
		p_player_id: StringName,
		p_action: StringName,
		p_exact_match: bool = false
	) -> bool:
	if not input_is_from_player(p_event, p_player_id):
		return false
	
	var player: Player = _players[p_player_id]
	
	# The player has an action override for p_action.
	if player.has_action(p_action):
		return player.action_has_event(p_action, p_event, p_exact_match)
	else:
		return p_event.is_action(p_action, p_exact_match)


## Retruns [code]true[/code] if [param p_event] is being pressed and matches the action
## [param p_action] from player [param p_player_id].
##
## [br][br]
## [b]See:[/b] [method InputEvent.is_action_pressed]
func input_is_player_action_pressed(
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
	
	return input_is_player_action(p_event, p_player_id, p_action, p_exact_match)


## Retruns [code]true[/code] if [param p_event] is released (ie. not pressed) and matches the action
## [param p_action] from player [param p_player_id].
##
## [br][br]
## [b]See:[/b] [method InputEvent.is_action_released]
func input_is_player_action_released(
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
	
	return input_is_player_action(p_event, p_player_id, p_action, p_exact_match)


## Retruns true if the action [param p_action] is currently pressed for player [param p_player_id].
##
## [br][br]
## [b]See:[/b] [method Input.is_action_pressed]
func is_player_action_pressed(
		p_player_id: StringName,
		p_action: StringName,
		p_exact_match: bool = false
	) -> bool:
	if not player_exists(p_player_id):
		return false
	
	return _players[p_player_id].action_is_pressed(p_action, p_exact_match)


## Retruns true if the action [param p_action] for player [param p_player_id] has been pressed in
## the current frame or physics tick.
##
## [br][br]
## [b]See:[/b] [method Input.is_action_just_pressed]
func is_player_action_just_pressed(
		p_player_id: StringName,
		p_action: StringName,
		p_exact_match: bool = false
	) -> bool:
	if not player_exists(p_player_id):
		return false
	
	var player: Player = _players[p_player_id]
	
	if p_exact_match and not player.action_is_exact(p_action):
		return false
	
	if Engine.is_in_physics_frame():
		return player.action_get_pressed_physics_frame(p_action) == Engine.get_physics_frames()
	else:
		return player.action_get_pressed_process_frame(p_action) == Engine.get_process_frames()


## Retruns true if the action [param p_action] for player [param p_player_id] has been released in
## the current frame or physics tick.
##
## [br][br]
## [b]See:[/b] [method Input.is_action_just_released]
func is_player_action_just_released(
		p_player_id: StringName,
		p_action: StringName,
		p_exact_match: bool = false
	) -> bool:
	if not player_exists(p_player_id):
		return false
	
	var player: Player = _players[p_player_id]
	
	if p_exact_match and not player.action_is_exact(p_action):
		return false
	
	if Engine.is_in_physics_frame():
		return player.action_get_released_physics_frame(p_action) == Engine.get_physics_frames()
	else:
		return player.action_get_released_process_frame(p_action) == Engine.get_process_frames()


## [b]See:[/b] [method Input.get_action_strength]
func get_player_action_strength(
		p_player_id: StringName,
		p_action: StringName,
		p_exact_match: bool = false
	) -> float:
	if not player_exists(p_player_id):
		return 0.0
	return _players[p_player_id].action_get_strength(p_action, p_exact_match)


## [b]See:[/b] [method Input.get_action_raw_strength]
func get_player_action_raw_strength(
		p_player_id: StringName,
		p_action: StringName,
		p_exact_match: bool = false
	) -> float:
	if not player_exists(p_player_id):
		return 0.0
	return _players[p_player_id].action_get_raw_strength(p_action, p_exact_match)


## [b]See:[/b] [method Input.get_axis]
func get_player_axis(
		p_player_id: StringName,
		p_negative_action: StringName,
		p_positive_action: StringName,
	) -> float:
	return (
		get_player_action_strength(p_player_id, p_positive_action)
		- get_player_action_strength(p_player_id, p_negative_action)
	)


## [b]See:[/b] [method Input.get_axis] and [method Input.get_raw_strength]
func get_player_raw_axis(
		p_player_id: StringName,
		p_negative_action: StringName,
		p_positive_action: StringName,
	) -> float:
	return (
		get_player_action_raw_strength(p_player_id, p_positive_action)
		- get_player_action_raw_strength(p_player_id, p_negative_action)
	)


## Gets a vector for player [param p_player_id] defined by the four actions given defining values
## for the x and y axes.
##
## [b]See:[/b] [method Input.get_vector]
func get_player_vector(
		p_player_id: StringName,
		p_negative_x_action: StringName,
		p_positive_x_action: StringName,
		p_negative_y_action: StringName,
		p_positive_y_action: StringName,
		p_deadzone: float = -1.0,
	) -> Vector2:
	if not player_exists(p_player_id):
		return Vector2.ZERO
	
	var player: Player = _players[p_player_id]
	
	var vector := Vector2(
		player.action_get_raw_strength(p_positive_x_action, false)
		- player.action_get_raw_strength(p_negative_x_action, false),
		player.action_get_raw_strength(p_positive_y_action, false)
		- player.action_get_raw_strength(p_negative_y_action, false)
	)
	
	if p_deadzone < 0.0:
		var positive_x_deadzone: float = (
			player.action_get_deadzone(p_positive_x_action)
			if player.has_action(p_positive_x_action) else
			Input.get_action_raw_strength(p_positive_x_action)
		)
		
		var positive_y_deadzone: float = (
			player.action_get_deadzone(p_positive_y_action)
			if player.has_action(p_positive_y_action) else
			Input.get_action_raw_strength(p_positive_y_action)
		)
		
		var negative_x_deadzone: float = (
			player.action_get_deadzone(p_negative_x_action)
			if player.has_action(p_negative_x_action) else
			Input.get_action_raw_strength(p_negative_x_action)
		)
		
		var negative_y_deadzone: float = (
			player.action_get_deadzone(p_negative_y_action)
			if player.has_action(p_negative_y_action) else
			Input.get_action_raw_strength(p_negative_y_action)
		)
		
		p_deadzone = (
			positive_x_deadzone
			+ positive_y_deadzone
			+ negative_x_deadzone
			+ negative_y_deadzone
		) * 0.25
	
	var length: float = vector.length()
	
	if length < p_deadzone:
		return Vector2.ZERO
	elif length > 1.0:
		return vector / length
	else:
		return vector * (inverse_lerp(p_deadzone, 1.0, length) / length)


# ====================
# = Input Operations =
# ====================


## Returns [code]true[/code] if [param p_event] is from a device assigned to any player.
func input_has_player(p_event: InputEvent) -> bool:
	return not input_get_player(p_event).is_empty()


## Returns [code]true[/code] if [param p_event] is from a device assigned to [param p_player_id].
func input_is_from_player(p_event: InputEvent, p_player_id: StringName) -> bool:
	return input_get_player(p_event) == p_player_id


## Returns the player that has [param p_event]'s device assigned. If [param p_event]'s device is not
## assigned to any player, returns an empty [StringName].
func input_get_player(p_event: InputEvent) -> StringName:
	return device_get_player(InputDevice.create_from_event(p_event))


# ==========================
# = InputDevice Operations =
# ==========================


## Returns the player that has [param p_device] assigned. If [p_device] is not assigned to any
## player, returns an empty [StringName].
func device_get_player(p_device: InputDevice) -> StringName:
	for player: StringName in _players:
		if _players[player].has_device(p_device):
			return player
	return &""


## Returns [code]true[/code] if [param p_device] is assigned to any player.
func is_device_assigned(p_device: InputDevice) -> bool:
	return not device_get_player(p_device).is_empty()


## Unassign [param p_device] from the player it is assigned to.
func unassign_device(p_device: InputDevice) -> void:
	var player_id: StringName = device_get_player(p_device)
	if player_id.is_empty():
		return
	
	_players[player_id].remove_device(p_device)


# =====================
# = Player Operations =
# =====================


## Adds a player named [param p_player_id]. Errors if [param p_player_id] already exists.
func add_player(p_player_id: StringName) -> void:
	if p_player_id.is_empty():
		push_error("Cannot add empty player")
		return
	if player_exists(p_player_id):
		push_error("Input player `%s` has already been added")
		return
	_players[p_player_id] = Player.new()


## Removes the player named [param p_player_id].
##
## [br][br]
## [b]See:[/b] [method add_player]
func remove_player(p_player_id: StringName) -> void:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	var player: Player = _players[p_player_id]
	player.free()
	_players.erase(p_player_id)


## Returns [code]true[/code] if the player [param p_player_id] exists.
func player_exists(p_player_id: StringName) -> bool:
	return p_player_id in _players


## Returns [code]true[/code] if the player [param p_player_id] has any device assigned.
func player_has_assigned_device(p_player_id: StringName) -> bool:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return true
	return _players[p_player_id].get_device_count() != 0


## Assigns the device [param p_device] to the player [param p_player_id]. An [InputDevice] cannot be
## assigned to multiple players.
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
	
	_players[p_player_id].add_device(p_device)


## Returns the list of devices assigned to [param p_player_id].
func player_get_devices(p_player_id: StringName) -> Array[InputDevice]:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return []
	return _players[p_player_id].get_devices()


## Unassigns all devices assigned to [param p_player_id].
func player_clear_devices(p_player_id: StringName) -> void:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	_players[p_player_id].clear_devices()


## Returns the list of all existing players.
func get_players() -> Array[StringName]:
	return _players.keys()


# ====================================
# = Player action override functions =
# ====================================


## Adds the action [param p_action] to the player [param p_player_id]'s input map. This overrides
## actions defined in Godot's [InputMap]. This system allows for input remapping per player.
## 
## [br][br]
## [b]See:[/b] [method player_action_add_event], [method player_action_remove_event]
func player_add_action(p_player_id: StringName, p_action: StringName) -> void:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	
	var player: Player = _players[p_player_id]
	if player.has_action(p_action):
		push_error("Input player `%s` already has action `%s`" % [p_player_id, p_action])
		return
	
	player.add_action(p_action)


## Removes the action [param p_action] from the player [param p_player_id]'s input map.
##
## [br][br]
## [b]See:[b/] [method player_add_action]
func player_remove_action(p_player_id: StringName, p_action: StringName) -> void:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	
	var player: Player = _players[p_player_id]
	if not player.has_action(p_action):
		push_error("Input player `%s` does not have action `%s`" % [p_player_id, p_action])
		return
	
	player.remove_action(p_action)


## Returns [code]true[/code] if the action [param p_action] is in the player [param p_player_id]'s
## input map.
func player_has_action(p_player_id: StringName, p_action: StringName) -> void:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	return _players[p_player_id].has_action(p_action)


## Returns the list of actions in the player [param p_player_id]'s input map.
func player_get_actions(p_player_id: StringName) -> Array[StringName]:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return []
	return _players[p_player_id].get_actions()


## Registers [param p_event] to [param p_action] in [param p_player_id]'s input map. The action
## [param p_action] needs to be defined in [param p_player_id]'s input map.
## 
## [br][br]
## [b]See:[/b] [method player_add_action]
func player_action_add_event(
		p_player_id: StringName,
		p_action: StringName,
		p_event: InputEvent,
	) -> void:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	
	var player: Player = _players[p_player_id]
	if not player.has_action(p_action):
		push_error("Input player `%s` does not have action `%s`" % [p_player_id, p_action])
		return
	
	if not player.action_has_event(p_action, p_event, true):
		player.action_add_event(p_action, p_event)


## Removes [param p_event] from [param p_action] in [param p_player_id]'s input map.
func player_action_remove_event(
		p_player_id: StringName,
		p_action: StringName,
		p_event: InputEvent,
	) -> void:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	
	var player: Player = _players[p_player_id]
	if not player.has_action(p_action):
		push_error("Input player `%s` does not have action `%s`" % [p_player_id, p_action])
		return
	
	player.action_remove_event(p_action, p_event)


## Returns the list of events registered for the action [param p_action] in [param p_player_id]'s
## input map.
func player_action_get_events(p_player_id: StringName, p_action: StringName) -> Array[InputEvent]:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return []
	
	var player: Player = _players[p_player_id]
	if not player.has_action(p_action):
		push_error("Input player `%s` does not have action `%s`" % [p_player_id, p_action])
		return []
	
	return player.action_get_events(p_action)


## Clears all events registered for [param p_action] in [param p_player_id]'s input map.
func player_action_clear_events(p_player_id: StringName, p_action: StringName) -> void:
	if not player_exists(p_player_id):
		push_error("Input player `%s` does not exist" % p_player_id)
		return
	
	var player: Player = _players[p_player_id]
	if not player.has_action(p_action):
		push_error("Input player `%s` does not have action `%s`" % [p_player_id, p_action])
		return
	
	player.action_clear_events(p_action)


# ==================
# = Input Handling =
# ==================


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(p_event: InputEvent) -> void:
	var player_name: StringName = input_get_player(p_event)
	if player_name.is_empty():
		return
	
	_players[player_name]._process_input_event(p_event)


func _on_joy_connection_changed(p_device: int, p_connected: bool) -> void:
	var device := InputDevice.new()
	device.type = InputDevice.DeviceType.GAME_CONTROLLER
	device.id = p_device
	
	var player_name: StringName = device_get_player(device)
	if player_name.is_empty():
		return
	
	player_device_connection_changed.emit(
		player_name,
		device,
		p_connected,
	)


# ===========
# = Classes =
# ===========


class ActionState extends Object:
	var pressed_process_frame: int
	var pressed_physics_frame: int
	var released_process_frame: int
	var released_physics_frame: int
	
	var pressed: bool
	var exact: bool
	var raw_strength: float
	var strength: float


class Action extends Object:
	var deadzone: float = 0.2
	var events: Array[InputEvent]


class Player extends Object:
	var devices: Array[InputDevice]
	var local_input_map: Dictionary[StringName, Action]
	var action_states: Dictionary[StringName, ActionState]
	
	
	func add_device(p_device: InputDevice) -> void:
		devices.push_back(p_device)
	
	
	func remove_device(p_device: InputDevice) -> void:
		var index: int = _find_device(p_device)
		if index != -1:
			devices.remove_at(index)
	
	
	func has_device(p_device: InputDevice) -> bool:
		return _find_device(p_device) != -1
	
	
	func clear_devices() -> void:
		devices.clear()
	
	
	func get_devices() -> Array[InputDevice]:
		return devices
	
	
	func _find_device(p_device: InputDevice) -> int:
		return devices.find_custom(func(p_inner_device: InputDevice) -> bool:
			return p_device.equals(p_inner_device)
		)
	
	
	func get_device_count() -> int:
		return devices.size()
	
	
	func remove_action(p_action: StringName) -> void:
		var action: Action = local_input_map[p_action]
		action.free()
		local_input_map.erase(p_action)
		action_states.erase(p_action)
	
	
	func add_action(p_action: StringName) -> void:
		local_input_map[p_action] = Action.new()
	
	
	func get_actions() -> Array[StringName]:
		return local_input_map.keys()
	
	
	func action_add_event(p_action: StringName, p_event: InputEvent) -> void:
		local_input_map[p_action].events.push_back(p_event)
	
	
	func action_has_event(p_action: StringName, p_event: InputEvent, p_exact_match: bool) -> bool:
		return _action_find_event(p_action, p_event, p_exact_match) != -1
	
	
	func action_get_events(p_action: StringName) -> Array[InputEvent]:
		var result: Array[InputEvent]
		result.assign(local_input_map[p_action].events)
		return result
	
	
	func action_remove_event(p_action: StringName, p_event: InputEvent) -> void:
		var index: int = _action_find_event(p_action, p_event, true)
		if index != -1:
			local_input_map[p_action].events.remove_at(index)
	
	
	func action_clear_events(p_action: StringName) -> void:
		local_input_map[p_action].events.clear()
	
	
	func action_set_deadzone(p_action: StringName, p_deadzone: float) -> void:
		local_input_map[p_action].deadzone = clampf(p_deadzone, 0.0, 1.0)
	
	
	func action_get_deadzone(p_action: StringName) -> float:
		return local_input_map[p_action].deadzone
	
	
	func _action_find_event(p_action: StringName, p_event: InputEvent, p_exact_match: bool) -> int:
		return local_input_map[p_action].events.find_custom(func(p_inner_event: InputEvent) -> bool:
			return Multinput._input_event_match(p_event, p_inner_event, p_exact_match)
		)
	
	
	func has_action(p_action: StringName) -> bool:
		return p_action in local_input_map
	
	
	func action_is_pressed(p_action: StringName, p_exact: bool) -> bool:
		var action_state: ActionState = action_states.get(p_action, null)
		if not action_state:
			return false
		return action_state.pressed and (action_state.exact if p_exact else true)
	
	
	func action_is_exact(p_action: StringName) -> bool:
		var action_state: ActionState = action_states.get(p_action, null)
		if not action_state:
			return false
		return action_state.exact
	
	
	func action_get_raw_strength(p_action: StringName, p_exact_match: bool) -> float:
		var action_state: ActionState = action_states.get(p_action, null)
		if not action_state:
			return 0.0
		if not action_state.pressed:
			return 0.0
		if p_exact_match and not action_state.exact:
			return 0.0
		return action_state.raw_strength
	
	
	func action_get_strength(p_action: StringName, p_exact_match: bool) -> float:
		var action_state: ActionState = action_states.get(p_action, null)
		if not action_state:
			return 0.0
		if not action_state.pressed:
			return 0.0
		if p_exact_match and not action_state.exact:
			return 0.0
		return action_state.strength
	
	
	func action_get_pressed_process_frame(p_action: StringName) -> int:
		var action_state: ActionState = action_states.get(p_action, null)
		if not action_state:
			return -1
		return action_state.pressed_process_frame
	
	
	func action_get_pressed_physics_frame(p_action: StringName) -> int:
		var action_state: ActionState = action_states.get(p_action, null)
		if not action_state:
			return -1
		return action_state.pressed_physics_frame
	
	
	func action_get_released_process_frame(p_action: StringName) -> int:
		var action_state: ActionState = action_states.get(p_action, null)
		if not action_state:
			return -1
		return action_state.released_process_frame
	
	
	func action_get_released_physics_frame(p_action: StringName) -> int:
		var action_state: ActionState = action_states.get(p_action, null)
		if not action_state:
			return -1
		return action_state.released_physics_frame
	
	
	func _process_input_event(p_event: InputEvent) -> void:
		var event_raw_strength: float = Multinput._input_get_raw_strength(p_event)
		
		# Check if this event is from an overridden action
		for action: StringName in local_input_map.keys():
			var action_match: int = _action_match_event(action, p_event)
			if action_match:
				if p_event.is_pressed():
					_action_set_pressed(
						action,
						event_raw_strength,
						Multinput._input_get_strength(p_event, action_get_deadzone(action)),
						action_match == 2
					)
				elif p_event.is_released():
					_action_set_released(action, action_match == 2)
		
		# Check if this event is from an action in the global input map
		for action: StringName in InputMap.get_actions():
			if has_action(action):
				continue
			var strength: float = p_event.action_get_strength(action, false)
			
			if p_event.action_is_pressed(action, false, true):
				_action_set_pressed(action, event_raw_strength, strength, true)
			elif p_event.action_is_pressed(action, false, false):
				_action_set_pressed(action, event_raw_strength, strength, false)
			elif p_event.is_action_released(action, true):
				_action_set_released(action, true)
			elif p_event.is_action_released(action, false):
				_action_set_released(action, false)
	
	
	func _action_set_pressed(
			p_action: StringName,
			p_raw_strength: float,
			p_strength: float,
			p_exact: bool,
		) -> void:
		var action_state: ActionState = action_states.get(p_action)
		if not action_state:
			action_state = ActionState.new()
			action_states[p_action] = action_state
		
		action_state.pressed = true
		action_state.pressed_process_frame = Engine.get_process_frames()
		action_state.pressed_physics_frame = Engine.get_physics_frames()
		action_state.exact = p_exact
		action_state.raw_strength = p_raw_strength
		action_state.strength = p_strength
	
	
	func _action_set_released(p_action: StringName, p_exact: bool) -> void:
		var action_state: ActionState = action_states.get(p_action)
		if not action_state:
			action_state = ActionState.new()
			action_states[p_action] = action_state
		
		action_state.pressed = false
		action_state.released_process_frame = Engine.get_process_frames()
		action_state.released_physics_frame = Engine.get_physics_frames()
		action_state.exact = p_exact
	
	
	## Returns:
	## - 0 if the event is not in this action
	## - 1 if the event is in this action but is not an exact match
	## - 2 if the event is in this action but is not an exact match
	func _action_match_event(p_action: StringName, p_event: InputEvent) -> int:
		var event_match: int = 0
		for inner_event: InputEvent in local_input_map[p_action]:
			if Multinput._input_event_match(p_event, inner_event, true):
				return 2
			elif Multinput._input_event_match(p_event, inner_event, false):
				event_match = 1
		return event_match


# ====================
# = Helper Functions =
# ====================


func _input_event_match(p_event_a: InputEvent, p_event_b: InputEvent, p_exact_match: bool) -> bool:
	if p_exact_match and p_event_a is InputEventWithModifiers and p_event_b is InputEventWithModifiers:
		var exact_match: bool = (
			p_event_a.alt_pressed == p_event_b.alt_pressed
			and p_event_a.ctrl_pressed == p_event_b.ctrl_pressed
			and p_event_a.meta_pressed == p_event_b.meta_pressed
			and p_event_a.shift_pressed == p_event_b.shift_pressed
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


func _input_get_raw_strength(p_event: InputEvent) -> float:
	if (
			p_event is InputEventJoypadButton
			or p_event is InputEventMIDI
			or p_event is InputEventKey
			or p_event is InputEventMouseButton
		):
		return 1.0
	if p_event is InputEventJoypadMotion:
		return abs(p_event.axis_value)
	return 0.0


func _input_get_strength(p_event: InputEvent, p_deadzone: float) -> float:
	if (
			p_event is InputEventJoypadButton
			or p_event is InputEventMIDI
			or p_event is InputEventKey
			or p_event is InputEventMouseButton
		):
		return 1.0
	
	if p_event is InputEventJoypadMotion:
		if p_deadzone == 1.0:
			return 1.0
		return clampf(
			inverse_lerp(p_deadzone, 1.0, abs(p_event.axis_value)),
			0.0, 1.0
		)
	return 0.0
