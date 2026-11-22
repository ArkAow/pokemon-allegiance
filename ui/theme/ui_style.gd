class_name UiStyle
extends RefCounted

const COL_BG := Color("0b1426")
const COL_PANEL := Color("1b2a4a")
const COL_PANEL_DARK := Color("121f38")
const COL_BORDER := Color("f4f4f0")
const COL_ACCENT := Color("d93a46")
const COL_GOLD := Color("ffd54a")
const COL_TEXT := Color("f4f4f0")
const COL_TEXT_DIM := Color("9fb0cc")
const COL_GOOD := Color("7be08a")
const COL_EVO := Color("ff9bf0")
const FONT_SIZE := 16
const RADIUS := 10
const BORDER_W := 3

const FONT_PATH := "res://ui/theme/font.ttf"
const FONT_PATH_OTF := "res://ui/theme/font.otf"
const CUSTOM_THEME_PATH := "res://ui/theme/custom_theme.tres"

static var _theme: Theme = null


static func get_theme() -> Theme:
	if _theme == null:
		if ResourceLoader.exists(CUSTOM_THEME_PATH):
			_theme = load(CUSTOM_THEME_PATH)
		else:
			_theme = make_theme()
	return _theme


static func box(fill: Color, border: Color = COL_BORDER, border_w: int = BORDER_W, radius: int = RADIUS, margin: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 4
	return sb


static func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = FONT_SIZE
	if ResourceLoader.exists(FONT_PATH):
		th.default_font = load(FONT_PATH)
	elif ResourceLoader.exists(FONT_PATH_OTF):
		th.default_font = load(FONT_PATH_OTF)
	th.set_color("font_color", "Label", COL_TEXT)
	th.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.6))
	th.set_constant("outline_size", "Label", 2)
	th.set_color("default_color", "RichTextLabel", COL_TEXT)
	th.set_stylebox("panel", "PanelContainer", box(COL_PANEL))
	th.set_stylebox("panel", "Panel", box(COL_PANEL))
	for kind in ["Button", "OptionButton"]:
		th.set_stylebox("normal", kind, box(COL_PANEL_DARK, COL_TEXT_DIM, 2, 8, 8))
		th.set_stylebox("hover", kind, box(Color("27406e"), COL_GOLD, 2, 8, 8))
		th.set_stylebox("pressed", kind, box(Color("0d172a"), COL_GOLD, 2, 8, 8))
		th.set_stylebox("disabled", kind, box(Color("1a2236"), Color("3a4560"), 2, 8, 8))
		th.set_stylebox("focus", kind, StyleBoxEmpty.new())
		th.set_color("font_color", kind, COL_TEXT)
		th.set_color("font_hover_color", kind, COL_GOLD)
		th.set_color("font_disabled_color", kind, Color("66708a"))
	th.set_stylebox("panel", "PopupMenu", box(COL_PANEL_DARK, COL_BORDER, 2, 6, 6))
	th.set_stylebox("hover", "PopupMenu", box(Color("27406e"), COL_GOLD, 1, 4, 4))
	th.set_color("font_color", "PopupMenu", COL_TEXT)
	th.set_color("font_hover_color", "PopupMenu", COL_GOLD)
	th.set_stylebox("background", "ProgressBar", box(Color("0a1120"), Color("3a4560"), 1, 5, 0))
	th.set_stylebox("fill", "ProgressBar", box(COL_GOOD, COL_GOOD, 0, 5, 0))
	return th


static func header(text: String, size: int = 20) -> PanelContainer:
	var p: PanelContainer = header_bar()
	p.add_child(label(text, size, COL_TEXT))
	return p


static func header_bar() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(COL_ACCENT, COL_BORDER, 2, 8, 6))
	return p


static func panel(dark: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(COL_PANEL_DARK if dark else COL_PANEL))
	return p


static func label(text: String, size: int = FONT_SIZE, color: Color = COL_TEXT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size = Vector2(120, 0)
	return l


static func type_pill(type_id: String, small: bool = false) -> PanelContainer:
	var info: Dictionary = GlobalData.get_type_info(type_id)
	var p := PanelContainer.new()
	var sb := box(Color(str(info.get("color", "#888888"))).darkened(0.1), Color(1, 1, 1, 0.8), 1, 12, 2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.shadow_size = 0
	p.add_theme_stylebox_override("panel", sb)
	var l := label(str(info.get("name", type_id)), 11 if small else 13, Color.WHITE)
	l.add_theme_constant_override("outline_size", 3)
	p.add_child(l)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


static func type_pills(types: Array, small: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for t in types:
		row.add_child(type_pill(str(t), small))
	return row


static func hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color("4cd964")
	if ratio > 0.2:
		return Color("ffcc33")
	return Color("ff4a3d")


static func bar(value: float, max_value: float, color: Color, height: float = 10.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = maxf(1.0, max_value)
	b.value = value
	b.show_percentage = false
	b.custom_minimum_size = Vector2(60, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_stylebox_override("fill", box(color, color.lightened(0.3), 1, 5, 0))
	return b


static func stat_row(stat_name: String, value: int, max_value: float, color: Color, extra: String = "") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var n := label(stat_name, 14, COL_TEXT_DIM)
	n.custom_minimum_size = Vector2(78, 0)
	row.add_child(n)
	row.add_child(bar(float(value), max_value, color, 10.0))
	var v := label(str(value) + extra, 14, COL_TEXT)
	v.custom_minimum_size = Vector2(64, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	return row
