extends Node2D
## Static, seeded canvas artwork. Redraw only on configuration, never per frame.
var board := Rect2(0,0,1920,1200)

func configure(bounds: Rect2) -> void:
 board = bounds
 queue_redraw()

func _draw() -> void:
 paint(self,board)

static func paint(canvas: CanvasItem, bounds: Rect2, with_road: bool = true) -> void:
 canvas.draw_rect(bounds,Color("#536344"))
 var rng = RandomNumberGenerator.new()
 rng.seed = 41729
 var palette = [Color("#59694a"),Color("#4d6042"),Color("#606d4a"),Color("#566745"),Color("#4e6247")]
 var clip = PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
 # Broad, low-contrast patches rather than noisy per-cell triangles.
 var count = maxi(12,int(bounds.get_area()/28000.0))
 for i in range(count):
  var center = bounds.position+Vector2(rng.randf()*bounds.size.x,rng.randf()*bounds.size.y)
  var radius = Vector2(rng.randf_range(90,230),rng.randf_range(65,155))
  var patch = PackedVector2Array()
  for j in range(10):
   var angle = TAU*float(j)/10.0
   var uneven = rng.randf_range(0.72,1.18)
   patch.append(center+Vector2(cos(angle),sin(angle))*radius*uneven)
  for polygon in Geometry2D.intersect_polygons(patch,clip):
   canvas.draw_colored_polygon(polygon,palette[i%palette.size()])
 if with_road: _road(canvas,bounds,rng)

static func _ribbon(canvas: CanvasItem, points: PackedVector2Array, widths: Array, color: Color) -> void:
 var left = PackedVector2Array()
 var right = PackedVector2Array()
 for i in range(points.size()):
  var tangent = (points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]).normalized()
  var normal = Vector2(-tangent.y,tangent.x)
  left.append(points[i]+normal*float(widths[i]))
  right.append(points[i]-normal*float(widths[i]))
 right.reverse()
 left.append_array(right)
 canvas.draw_colored_polygon(left,color)

static func _road(canvas: CanvasItem, bounds: Rect2, rng: RandomNumberGenerator) -> void:
 # Preserve the original route and leave navigation entirely unchanged.
 var start = bounds.position+Vector2(bounds.size.x*80.0/1920.0,bounds.size.y*960.0/1200.0)
 var finish = bounds.position+Vector2(bounds.size.x*1700.0/1920.0,bounds.size.y*225.0/1200.0)
 var normal = Vector2(-(finish-start).normalized().y,(finish-start).normalized().x)
 var points = PackedVector2Array()
 var shoulders = []
 var surface = []
 for i in range(19):
  var t = float(i)/18.0
  var wobble = sin(t*PI)*rng.randf_range(-7,7)
  points.append(start.lerp(finish,t)+normal*wobble)
  shoulders.append(rng.randf_range(39,47))
  surface.append(rng.randf_range(27,31))
 _ribbon(canvas,points,shoulders,Color("#6c6b4d"))
 _ribbon(canvas,points,surface,Color("#9a8762"))
 # Two broad worn wheel paths with a darker, less-travelled center strip.
 for side in [-1.0,1.0]:
  var track = PackedVector2Array()
  for point in points: track.append(point+normal*side*15.0)
  canvas.draw_polyline(track,Color("#b09b73"),9.0,true)
 for i in range(1,points.size()-1):
  var p = points[i]
  canvas.draw_line(p-normal*21, p-normal*9+Vector2(5,2),Color("#837552"),1.5,true)
