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


class_name MRPAS
extends RefCounted


# An implementation of Mingos' Restrictive Precise Angle Shadowcasting.
#
# Intended for use in traditional roguelikes for determining which map cells
# are visible from the player position on the map.
#
# For a description of the algorithm, see
#	http://www.roguebasin.com/index.php?title=Restrictive_Precise_Angle_Shadowcasting
#
# Expected usage is as follows:
#
#	var mrpas = MRPAS.new(map_size)
#	mrpas.set_transparent(occluder_position, false)
#
#	mrpas.clear_field_of_view()
#	mrpas.compute_field_of_view(view_position, max_view_distance)
#
#	if mrpas.is_in_view(map_cell_position):
#		...


# When computing visibility for a quadrant, indicate which axis is major.
enum _MajorAxis { X_AXIS, Y_AXIS }


# The size of the map in cells.
var _size: Vector2
# A bool for each cell indicating whether it allows vision.
var _transparent_cells: Array = []
# A bool for each cell indicating that it is currently in view.
var _fov_cells: Array = []


# Initialize the algorithm for a map of a particular size.
func _init(size: Vector2) -> void:
	_size = Vector2(size.x as int, size.y as int)

	# Build array-of-arrays for both transparency and field of view,
	# so that we can track each cell.
	for _y in range(_size.y):
		var transparent_row = []
		var fov_row = []

		for _x in range(_size.x):
			transparent_row.push_back(true)
			fov_row.push_back(true)

		_transparent_cells.push_back(transparent_row)
		_fov_cells.push_back(fov_row)


# Returns true if a cell is marked as transparent.
func is_transparent(position: Vector2) -> bool:
	if _in_bounds(position):
		return _transparent_cells[position.y][position.x]
	return false


# Set the transparency of a cell in the map.
func set_transparent(position: Vector2, transparent: bool) -> void:
	if _in_bounds(position):
		_transparent_cells[position.y][position.x] = transparent


# Returns true if a cell is currently in view.
func is_in_view(position: Vector2) -> bool:
	if _in_bounds(position):
		return _fov_cells[position.y][position.x]
	return false


# Mark a map cell as in / not in the current view.
func set_in_view(position: Vector2, in_view: bool) -> void:
	if _in_bounds(position):
		_fov_cells[position.y][position.x] = in_view


# Mark all cells in the map as not in the current view.
func clear_field_of_view() -> void:
	for y in range(_size.y):
		for x in range(_size.x):
			_fov_cells[y][x] = false


# Compute the viewable cells from a particular view position by doing
# each of the eight octants of the view.
func compute_field_of_view(view_position: Vector2, max_distance: int) -> void:
	_compute_octant(_MajorAxis.Y_AXIS, -1, -1, view_position, max_distance)
	_compute_octant(_MajorAxis.Y_AXIS, -1, 1, view_position, max_distance)

	_compute_octant(_MajorAxis.Y_AXIS, 1, -1, view_position, max_distance)
	_compute_octant(_MajorAxis.Y_AXIS, 1, 1, view_position, max_distance)

	_compute_octant(_MajorAxis.X_AXIS, -1, -1, view_position, max_distance)
	_compute_octant(_MajorAxis.X_AXIS, -1, 1, view_position, max_distance)

	_compute_octant(_MajorAxis.X_AXIS, 1, -1, view_position, max_distance)
	_compute_octant(_MajorAxis.X_AXIS, 1, 1, view_position, max_distance)


# Compute all visibile cells for one octant of the viewpoint.
func _compute_octant(
		axis: int,
		major_sign: int,
		minor_sign: int,
		view_position: Vector2,
		max_distance: int) -> void:

	# Track occluders previously encountered in this octant.
	var occluders = []
	var new_occluders = []

	# Iterate along the major axis.
	for major in range(max_distance + 1):
		var any_transparent = false

		var position = view_position + _octant_to_offset(
			axis, major_sign * major, 0)
		if not _in_bounds(position):
			break

		var position_delta = _octant_to_offset(axis, 0, minor_sign)

		# Clamp the iteration range to the map bounds, which allows us to skip
		# bounds check in the inner loop.
		var clamped_minor = _clamp_to_map_bounds(position, position_delta, major + 1)

		var angle_half_step = 0.5 / (major + 1) as float

		# Iterate along the minor axis, but not beyond the major axis distance.
		for minor in range(clamped_minor):
			# It is important to recompute angle each iteration, because the
			# alternative approach of accumulating angle_half_step introduces
			# noticible artifacts due to accumulation of floating point
			# precision error.
			var angle = minor as float / (major + 1) as float

			var transparent = _is_transparent_no_bounds(position)

			# Check if occluders found on previous lines block this cell.
			if not _is_occluded(occluders, angle, angle_half_step, transparent):
				_set_in_view_no_bounds(position, true)
				if transparent:
					any_transparent = true
				else:
					# The occluder represents a range of angle values, rather
					# than a coordinate.
					var occluder = Vector2(angle, angle + 2.0 * angle_half_step)
					new_occluders.push_back(occluder)

			position += position_delta

		# If no tranparent cells were seen on this line, we can stop.
		if not any_transparent:
			break

		# Add any occluders we encountered on this line for checking
		# future lines.
		occluders = occluders + new_occluders
		new_occluders.clear()


# Clamp the range of iteration to the bounds of the map.  This returns a
# new maximum number of iterations, such that the iteration is entirely
# within the boundary of the map.
func _clamp_to_map_bounds(
	position: Vector2,
	position_delta: Vector2,
	iterations: int) -> int:

	if position.x + position_delta.x * iterations < 0:
		iterations = int(-position.x / position_delta.x) + 1
	if position.x + position_delta.x * iterations > _size.x:
		iterations = int((_size.x - position.x) / position_delta.x)

	if position.y + position_delta.y * iterations < 0:
		iterations = int(-position.y / position_delta.y) + 1
	if position.y + position_delta.y * iterations > _size.y:
		iterations = int((_size.y - position.y) / position_delta.y)

	return iterations


# Returns true if a cell within the quadrant should not be considered within
# the view.
#
# For cells which are themselves transparent, require visibility to the mid
# point as well as either of the sides of the cell.
#
# For cells which are not transparent, require only visiblity to one of the
# three tested points.
func _is_occluded(
		occluders: Array,
		angle: float,
		angle_half_step: float,
		transparent: bool) -> bool:

	var begin = _is_angle_occluded(occluders, angle)
	var mid = _is_angle_occluded(occluders, angle + angle_half_step)
	var end = _is_angle_occluded(occluders, angle + 2.0 * angle_half_step)

	if not transparent and (not begin or not mid or not end):
		return false

	if transparent and not mid and (not begin or not end):
		return false

	return true


# Given a list of occluded angle ranges and an angle test test, return
# true if the angle tested is occluded by at least one of the occluders.
func _is_angle_occluded(occluders: Array, angle: float) -> bool:
	for occluder in occluders:
		if angle >= occluder.x and angle <= occluder.y:
			return true

	return false


# Given a major axis, and offsets along the major and minor axes, return
# an equivalent (x, y) coordinate.
func _octant_to_offset(axis: int, major: int, minor: int) -> Vector2:
	if axis == _MajorAxis.Y_AXIS:
		return Vector2(minor, major)
	else:
		return Vector2(major, minor)


# Test whether a particular position is within the map bounds.
func _in_bounds(position: Vector2) -> bool:
	var x_in_bounds = position.x >= 0 and position.x < _size.x
	var y_in_bounds = position.y >= 0 and position.y < _size.y
	return x_in_bounds and y_in_bounds


# is_transparent, but without a bounds check for use in the inner loop of
# visibility computation.
func _is_transparent_no_bounds(position: Vector2) -> bool:
	return _transparent_cells[position.y][position.x]


# set_in_view, but with no bounds check.  For use in the inner loop of
# visibility computation.
func _set_in_view_no_bounds(position: Vector2, in_view: bool) -> void:
	_fov_cells[position.y][position.x] = in_view
