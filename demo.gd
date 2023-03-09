# Copyright 2022 Matt Kimball
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


@tool
extends Node2D


# A demo for Mingos' Restrictive Precise Angle Shadowcasting used for
# visibility checks in a traditional roguelike.


# The current position of the player in map cell coordinates.
var _player_position: Vector2 = Vector2(0, 2)
# The shadowcasting algorithm used for visibility checks.
var _mrpas: MRPAS
var _worst_fov_time


# Place the player's symbol on the map and check initial visibility.
func _ready() -> void:
	$Map.get_cell(_player_position).character = '@'
	_populate_mrpas()
	_compute_field_of_view()


# Handle keypress events to move the player using arrow keys, WASD or 
# vi movement keys.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode = event.keycode

		if keycode == KEY_LEFT or keycode == KEY_H or keycode == KEY_A:
			_move_player(Vector2(-1, 0))
		if keycode == KEY_RIGHT or keycode == KEY_L or keycode == KEY_D:
			_move_player(Vector2(1, 0))
		if keycode == KEY_UP or keycode == KEY_K or keycode == KEY_W:
			_move_player(Vector2(0, -1))
		if keycode == KEY_DOWN or keycode == KEY_J or keycode == KEY_S:
			_move_player(Vector2(0, 1))


# Move the player one space in a cardinal direction.
func _move_player(direction: Vector2) -> void:
	var destination = _player_position + direction
	var destination_cell = $Map.get_cell(destination)

	# Don't allow movement outside the map.
	if not destination_cell:
		return

	# Don't allo movement into walls.
	if destination_cell.terrain == '#':
		return

	# Remove the player symbol from the previous cell and add it to the new one.
	var current_cell = $Map.get_cell(_player_position)
	current_cell.character = null
	_player_position = destination
	destination_cell.character = '@'

	var start_time = Time.get_ticks_usec()
	# Recompute visibility for the new position.
	_compute_field_of_view()
	var end_time = Time.get_ticks_usec()

	if OS.is_debug_build():
		var fov_time = (end_time - start_time) / 1000.0
		if _worst_fov_time == null or fov_time > _worst_fov_time:
			_worst_fov_time = fov_time

		$PerformaceLabel.text = "compute fov: %0.3f ms / worst: %0.3f ms" % \
			[fov_time, _worst_fov_time]


# Populate the shadowcasting algorithm with transparent / occluded cells
# using the position of walls on the map.
func _populate_mrpas() -> void:
	_mrpas = MRPAS.new($Map.size)

	for y in range($Map.size.y):
		for x in range($Map.size.x):
			var map_position = Vector2(x, y)
			var cell = $Map.get_cell(map_position)

			# Specifically check for walls and assume all other cells are
			# transparent.
			_mrpas.set_transparent(map_position, cell.terrain != '#')


# Recompute which map cells are visible.
func _compute_field_of_view() -> void:
	# Mark all map cells as not in view.
	_mrpas.clear_field_of_view()

	# Use shadowcasting to find the cells which are visible from the
	# new payer position.
	_mrpas.compute_field_of_view(
		_player_position, max($Map.size.x, $Map.size.y) as int)

	for y in range($Map.size.y):
		for x in range($Map.size.x):
			var map_position = Vector2(x, y)

			# Mark the cell as visible if the shadowcasting has found it
			# to be in view.
			$Map.get_cell(map_position).in_view = _mrpas.is_in_view(map_position)
