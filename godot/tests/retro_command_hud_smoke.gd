extends SceneTree
## Retro-command UI tests: Godot scene, radar, production tiles, status and touch layout.
var failures: Array[String] = []
var world

func expect(ok: bool,label: String) -> void:
 if ok: print("PASS: "+label)
 else:
  failures.append(label)
  push_error("FAIL: "+label)

func _initialize() -> void:
 call_deferred("run_checks")

func run_checks() -> void:
 world=load("res://scenes/skirmish.tscn").instantiate()
 root.add_child(world)
 await process_frame
 world.paused=true
 expect(world.radar_view!=null and is_instance_valid(world.radar_view),"Procedural minimap created in production drawer")
 expect(world.radar_view.get_script().resource_path.ends_with("retro_radar.gd"),"Radar is a real map widget, not a background image")
 expect(world.retro_economy_label!=null,"Dedicated credits and power HUD exists")
 expect(world.retro_powerbar!=null,"Visual power meter exists")
 expect(world.build_container is GridContainer,"Production rack uses a tile grid")
 expect(world.build_container.columns==2,"Production rack has two RA2-inspired icon columns")
 expect(world.production_tile_icons.size()==world.action_buttons.size(),"Each build entry has its own original procedural icon")
 expect(world.action_palette_buttons.size()==11,"Eleven real tactical buttons including Scout, Rally and Staging")
 expect(world.queue_preview_labels.size()==4,"Production status has four visible slots")
 expect(world.tab_buttons.size()==5,"Sidebar tabs are buildings, defense, infantry, vehicles, and general upgrades")
 expect(str(world.tab_buttons[4].text)=="UPG","General upgrades have their own tab")
 expect(world.repair_button.get_parent().get_index()>world.radar_view.get_index(),"Repair and sell sit under the minimap")
 expect(world.repair_button.get_parent().get_index()<world.tab_buttons[0].get_parent().get_index(),"Repair and sell sit above the build tabs")
 expect(world.repair_button.get_parent()==world.sell_button.get_parent(),"Repair and sell share the row under the map")
 expect(is_instance_valid(world.orders_sheet) and not world.orders_sheet.visible,"Rally setup stays out of the build column until a producer is selected")
 expect(is_instance_valid(world.upgrades_panel) and not world.upgrades_panel.visible,"Upgrades page waits for its tab")
 expect(world.hud_dock.get_theme_stylebox("panel") is StyleBoxFlat,"Sidebar receives beveled steel style")
 expect(world.hud_toolbar.get_theme_stylebox("panel") is StyleBoxFlat,"Command bar receives beveled steel style")
 expect(world.radar_view.map_point(Vector2(0,0)).is_equal_approx(Vector2.ZERO),"Radar maps battlefield origin")
 expect(world.radar_view.map_point(Vector2(960,600)).x>=0.0,"Radar projection operates for on-map points")
 world._update_hud()
 expect(world.retro_economy_label.text.contains("IRON"),"Economy readout displays reference IRON currency label")
 expect(world.retro_economy_label.text.contains("POWER"),"Economy readout displays power")
 expect(world._deploy_mcv(0),"Initial MCV deploys")
 world._place_structure("power",0,Vector2(420,460))
 world._place_structure("barracks",0,Vector2(560,610))
 world._set_tab(2)
 world._update_hud()
 expect(world.action_buttons["a_ranger"].visible,"Infantry tab exposes Ranger tile")
 expect(not world.action_buttons["power"].visible,"Infantry tab hides building tile")
 expect(world.action_buttons["a_ranger"].text.contains("RANGER"),"Production tile labels remain readable")
 expect(world.action_buttons["a_ranger"].text.contains("$"),"Tile displays its cost")
 expect(world.queue_production(0,"infantry","a_ranger"),"Real infantry queue starts from icon rack")
 world._tick_production(0,1.0)
 world._update_hud()
 expect(world.queue_preview_caption.text.contains("INFANTRY"),"Queue preview tracks active production lane")
 expect(world.queue_preview_labels[0].text.contains("%"),"Active queue slot shows percentage completion")
 world._on_toolbar("STAGING")
 expect(world.sidebar_open and world.current_tab==2,"Staging button reveals relevant production controls")
 var factory=world._place_structure("factory",0,Vector2(760,730))
 expect(factory,"War Factory can be added without changing UI state")
 world._update_hud()
 expect(world.producer_buttons.size()==2,"Factory cards coexist with new production rack")
 var layouts=[Vector2(1920,1080),Vector2(1280,720),Vector2(844,390),Vector2(390,844),Vector2(320,568)]
 for d in layouts:
  var expanded=world._hud_layout_for_size(d,true)
  var dock: Rect2=expanded["dock"]
  var toolbar: Rect2=expanded["toolbar"]
  expect(dock.position.x>=0.0 and dock.end.x<=d.x+0.1,"Dock fits test width "+str(int(d.x)))
  expect(toolbar.end.y<=d.y+0.1,"Bottom bar fits test height "+str(int(d.y)))
 world.sidebar_open=false
 world._apply_hud_layout(Vector2(390,844))
 expect(not world.hud_scroll.visible,"Narrow portrait can collapse production sheet")
 world.sidebar_open=true
 world._apply_hud_layout(Vector2(390,844))
 expect(world.hud_scroll.visible,"Production tiles and staging controls reopen on phone")
 expect(world.radar_view.custom_minimum_size.y<=100,"Mobile radar shrinks to preserve visible production space")
 world._apply_hud_layout(Vector2(1280,720))
 world._set_tab(0)
 world._update_hud()
 expect(world.action_buttons["power"].visible,"Switching back exposes building production")
 world._set_tab(4)
 world._update_hud()
 expect(world.upgrades_panel.visible and not world.build_container.visible,"Upgrades tab replaces the cameo grid")
 expect(not world.queue_panel.visible,"Queue strip steps aside on the upgrades page")
 expect(not world.action_buttons["power"].visible,"Upgrades tab hides structure cameos")
 world._set_tab(0)
 world._update_hud()
 expect(world.build_container.visible and world.action_buttons["power"].visible,"Buildings tab returns to the cameo grid")
 world.queue_free()
 if failures.is_empty():
  print("RETRO_COMMAND_HUD_SMOKE_PASS")
  quit(0)
 else:
  print("RETRO_COMMAND_HUD_SMOKE_FAIL "+str(failures.size()))
  quit(1)
