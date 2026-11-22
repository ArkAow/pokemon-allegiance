class_name HexGrid
extends RefCounted

const SQRT3 := 1.7320508075688772

static func hex_width(size: float) -> float:
	return SQRT3 * size


static func cell_to_pixel(cell: Vector2i, size: float) -> Vector2:
	var x: float = size * SQRT3 * (float(cell.x) + 0.5 * float(cell.y & 1))
	var y: float = size * 1.5 * float(cell.y)
	return Vector2(x, y)


static func pixel_to_cell(p: Vector2, size: float) -> Vector2i:
	var q: float = (SQRT3 / 3.0 * p.x - 1.0 / 3.0 * p.y) / size
	var r: float = (2.0 / 3.0 * p.y) / size
	return axial_to_offset(_axial_round(Vector2(q, r)))


static func _axial_round(a: Vector2) -> Vector2i:
	var x: float = a.x
	var z: float = a.y
	var y: float = -x - z
	var rx: float = roundf(x)
	var ry: float = roundf(y)
	var rz: float = roundf(z)
	var dx: float = absf(rx - x)
	var dy: float = absf(ry - y)
	var dz: float = absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))


static func axial_to_offset(a: Vector2i) -> Vector2i:
	return Vector2i(a.x + ((a.y - (a.y & 1)) >> 1), a.y)


static func offset_to_axial(c: Vector2i) -> Vector2i:
	return Vector2i(c.x - ((c.y - (c.y & 1)) >> 1), c.y)


## Distance en nombre de cases entre deux cellules.
static func distance(a: Vector2i, b: Vector2i) -> int:
	var aa: Vector2i = offset_to_axial(a)
	var bb: Vector2i = offset_to_axial(b)
	var dq: int = aa.x - bb.x
	var dr: int = aa.y - bb.y
	return (absi(dq) + absi(dr) + absi(dq + dr)) >> 1


static func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a: Vector2i = offset_to_axial(cell)
	for d in [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]:
		out.append(axial_to_offset(a + d))
	return out


static func hex_points(center: Vector2, size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(6):
		var ang: float = deg_to_rad(60.0 * i - 30.0)
		pts.append(center + Vector2(cos(ang), sin(ang)) * size)
	return pts
