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


# A map for the demo of Mingos' Restrictive Precise Angle Shadowcasting.


# The size of the map in map cells.
# (If cells are displayed as 60 pixels x 90 pixels, then this size is correct
# for 1080p resolution.)
const size = Vector2(32, 12)
# A map layout to generate cells from.
const map_string = """
################################
######.........#................
...............#................
...............#......#.#.#.#.#.
...............#................
......##############............
..##################............
#...............................
#...............................
............#.......#...........
............#...................
####........#...................
"""


# Map cell nodes arranged as an array of arrays.
var _cells = []


# Generate and populate cells from the map_string layout.
func _ready() -> void:
	_generate_cells()

	var map_lines = map_string.split("\n")
	for y in range(1, map_lines.size()):
		var line = map_lines[y]
		for x in range(line.length()):
			var cell = get_cell(Vector2(x, y - 1))
			cell.terrain = line[x]


# Return the map cell node for a particular map cell coordinate.
# Returns null if the requested cell is outside the bounds of the map.
func get_cell(position: Vector2) -> MapCell:
	if position.x < 0 or position.x >= size.x:
		return null
	if position.y < 0 or position.y >= size.y:
		return null

	return _cells[position.y as int][position.x as int]


# Generate all cells by instancing the map cell scene.
func _generate_cells() -> void:
	for y in range(size.y):
		var row = []

		for x in range(size.x):
			var position = Vector2(
				MapCell.pixel_size.x * x, MapCell.pixel_size.y * y)

			var cell = preload("res://map_cell.tscn").instance()
			cell.transform = Transform2D.translated(position)
			add_child(cell)

			row.push_back(cell)

		_cells.push_back(row)
