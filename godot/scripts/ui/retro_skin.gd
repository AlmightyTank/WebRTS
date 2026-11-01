extends RefCounted
## Original industrial RTS HUD skin. No third-party artwork or fonts.
const INK = Color("#10171f")
const STEEL = Color("#303b49")
const RIM = Color("#778698")
const BLUE = Color("#6ac7f0")
const GOLD = Color("#f5c55c")
const TEXT = Color("#e3e9ef")
const MUTED = Color("#91a2b1")

static func plate(kind: String="panel") -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=Color("#101720") if kind=="panel" else (Color("#1b2633") if kind=="screen" else Color("#26313f"))
 s.border_color=Color("#758595") if kind=="panel" else Color("#526476")
 s.set_border_width_all(2)
 s.corner_radius_top_left=7
 s.corner_radius_top_right=7
 s.corner_radius_bottom_left=7
 s.corner_radius_bottom_right=7
 s.shadow_color=Color(0.0,0.0,0.0,0.45)
 s.shadow_size=4
 s.content_margin_left=8.0
 s.content_margin_right=8.0
 s.content_margin_top=7.0
 s.content_margin_bottom=7.0
 return s

static func tile(kind: String="normal") -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=Color("#18232e") if kind=="normal" else (Color("#343018") if kind=="gold" else (Color("#193542") if kind=="active" else Color("#0d141b")))
 s.border_color=Color("#536a7e") if kind=="normal" else (Color("#ffdc70") if kind=="gold" else (Color("#6ec9ec") if kind=="active" else Color("#35434f")))
 s.set_border_width_all(2)
 s.corner_radius_top_left=4
 s.corner_radius_top_right=4
 s.corner_radius_bottom_left=4
 s.corner_radius_bottom_right=4
 s.content_margin_left=4.0
 s.content_margin_right=4.0
 s.content_margin_top=4.0
 s.content_margin_bottom=4.0
 return s

static func button(b: BaseButton, gold: bool=false, compact: bool=false) -> void:
 b.add_theme_stylebox_override("normal",tile("gold" if gold else "normal"))
 b.add_theme_stylebox_override("hover",tile("active"))
 b.add_theme_stylebox_override("pressed",tile("gold"))
 b.add_theme_stylebox_override("focus",tile("active"))
 b.add_theme_stylebox_override("disabled",tile("disabled"))
 b.add_theme_color_override("font_color",TEXT)
 b.add_theme_color_override("font_hover_color",Color.WHITE)
 b.add_theme_color_override("font_pressed_color",GOLD)
 b.add_theme_color_override("font_disabled_color",Color("#6d7984"))
 b.add_theme_font_size_override("font_size",12 if compact else 14)
 b.focus_mode=Control.FOCUS_NONE

static func label(l: Label, small: bool=false, accent: bool=false) -> void:
 l.add_theme_color_override("font_color",GOLD if accent else (MUTED if small else TEXT))
 l.add_theme_font_size_override("font_size",12 if small else 15)

static func panel(p: PanelContainer, kind: String="panel") -> void:
 p.add_theme_stylebox_override("panel",plate(kind))
