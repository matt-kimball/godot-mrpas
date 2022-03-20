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


tool
extends Node2D


# A demo for Mingos' Restrictive Precise Angle Shadowcasting used for
# visibility checks in a traditional roguelike.


# The current position of the player in map cell coordinates.
var _player_position: Vector2 = Vector2(0, 2)
# The shadowcasting algorithm used for visibility checks.
var _mrpas: MRPAS


# Place the player's symbol on the map and check initial visibility.
func _ready() -> void:
	$Map.get_cell(_player_position).character = '@'
	_populate_mrpas()
	_compute_field_of_view()


# Handle keypress events to move the player using arrow keys, WASD or 
# vi movement keys.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var scancode = event.scancode

		if scancode == KEY_LEFT or scancode == KEY_H or scancode == KEY_A:
			_move_player(Vector2(-1, 0))
		if scancode == KEY_RIGHT or scancode == KEY_L or scancode == KEY_D:
			_move_player(Vector2(1, 0))
		if scancode == KEY_UP or scancode == KEY_K or scancode == KEY_W:
			_move_player(Vector2(0, -1))
		if scancode == KEY_DOWN or scancode == KEY_J or scancode == KEY_S:
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

	# Recompute visibility for the new position.
	_compute_field_of_view()


# Populate the shadowcasting algorithm with transparent / occluded cells
# using the position of walls on the map.
func _populate_mrpas() -> void:
	_mrpas = MRPAS.new($Map.size)

	for y in range($Map.size.y):
		for x in range($Map.size.x):
			var position = Vector2(x, y)
			var cell = $Map.get_cell(position)

			# Specifically check for walls and assume all other cells are
			# transparent.
			_mrpas.set_transparent(position, cell.terrain != '#')


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
			var position = Vector2(x, y)

			# Mark the cell as visible if the shadowcasting has found it
			# to be in view.
			$Map.get_cell(position).in_view = _mrpas.is_in_view(position)
