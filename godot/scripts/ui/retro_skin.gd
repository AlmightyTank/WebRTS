extends RefCounted
## Compact field-console skin based on the responsive SVG command HUD reference.
const INK = Color("#14191c")
const STEEL = Color("#2c3538")
const RIM = Color("#8d7340")
const BLUE = Color("#5f7c8a")
const GOLD = Color("#e3c56a")
const TEXT = Color("#dce9e9")
const MUTED = Color("#9fbaa8")
const MAP = Color("#455a44")
const CARD = Color("#526469")
const DARK_CARD = Color("#26363e")

static func plate(kind: String="panel") -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=STEEL if kind=="panel" else (INK if kind=="screen" else Color("#364348"))
 s.border_color=RIM if kind=="panel" else Color("#53666b")
 s.set_border_width_all(1)
 s.corner_radius_top_left=3
 s.corner_radius_top_right=3
 s.corner_radius_bottom_left=3
 s.corner_radius_bottom_right=3
 s.content_margin_left=6.0
 s.content_margin_right=6.0
 s.content_margin_top=4.0
 s.content_margin_bottom=4.0
 return s

static func tile(kind: String="normal") -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=CARD if kind=="normal" else (BLUE if kind=="gold" or kind=="active" else DARK_CARD)
 s.border_color=RIM if kind=="normal" else (Color("#a9c8cf") if kind=="gold" or kind=="active" else Color("#45545a"))
 s.set_border_width_all(1)
 s.corner_radius_top_left=2
 s.corner_radius_top_right=2
 s.corner_radius_bottom_left=2
 s.corner_radius_bottom_right=2
 s.content_margin_left=3.0
 s.content_margin_right=3.0
 s.content_margin_top=3.0
 s.content_margin_bottom=3.0
 return s

static func button(b: BaseButton, gold: bool=false, compact: bool=false) -> void:
 b.add_theme_stylebox_override("normal",tile("gold" if gold else "normal"))
 b.add_theme_stylebox_override("hover",tile("active"))
 b.add_theme_stylebox_override("pressed",tile("gold"))
 b.add_theme_stylebox_override("focus",tile("active"))
 b.add_theme_stylebox_override("disabled",tile("disabled"))
 b.add_theme_color_override("font_color",TEXT)
 b.add_theme_color_override("font_hover_color",Color.WHITE)
 b.add_theme_color_override("font_pressed_color",TEXT)
 b.add_theme_color_override("font_disabled_color",Color("#718187"))
 b.add_theme_font_size_override("font_size",9 if compact else 10)
 b.focus_mode=Control.FOCUS_ALL

static func label(l: Label, small: bool=false, accent: bool=false) -> void:
 l.add_theme_color_override("font_color",GOLD if accent else (MUTED if small else TEXT))
 l.add_theme_font_size_override("font_size",8 if small else 10)

static func panel(p: PanelContainer, kind: String="panel") -> void:
 p.add_theme_stylebox_override("panel",plate(kind))
