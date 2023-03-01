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
class_name MapCell
extends Node2D


# An individual cell on a map for the demo of Mingos' Restrictive Precise Angle
# Shadowcasting.


# The size in pixels of a map cell when drawn.
const pixel_size = Vector2(60, 90)


# The glyph to draw for a character occupying the cell.
var character = null
# The glyph to draw for the terrain of the cell.
var terrain = '#'
# True if the map cell is currently in the field of view.
var in_view = true


# Update the visual representation of the cell every frame.
func _process(_delta) -> void:
	# Change colors if the map cell is in the field of view.
	if in_view:
		$Glyph.add_theme_color_override("font_color", Color("ffffff"))
		$Background.color = Color("003f7f")
	else:
		$Glyph.add_theme_color_override("font_color", Color("5f5f5f"))
		$Background.color = Color("000000")

	# If a character is in the cell, override the terrain glyph
	# using the character's glyph.
	if character:
		$Glyph.text = character
		$Glyph.add_theme_color_override("font_color", Color("ffff00"))
	else:
		$Glyph.text = terrain
