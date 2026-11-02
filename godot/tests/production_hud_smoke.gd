extends SceneTree
## Production sidebar and staging usability checks for desktop and Android-sized viewports.
var failures: Array[String]=[]
var world

func expect(value: bool, label: String) -> void:
 if value: print("PASS: "+label)
 else:
  failures.append(label)
  push_error("FAIL: "+label)

func _initialize() -> void:
 call_deferred("run_checks")

func verify_layout(dim: Vector2, expanded: bool) -> void:
 var layout=world._hud_layout_for_size(dim,expanded)
 var top: Rect2=layout["top"]
 var dock: Rect2=layout["dock"]
 var toolbar: Rect2=layout["toolbar"]
 expect(dock.position.x>=0 and dock.end.x<=dim.x+0.01,"Drawer horizontally fits %s" % [str(dim)])
 expect(dock.position.y>=0 and dock.end.y<=dim.y+0.01,"Drawer vertically fits %s" % [str(dim)])
 expect(top.position.x>=0 and top.end.x<=dim.x+0.01,"Status fits %s" % [str(dim)])
 expect(toolbar.position.x>=0 and toolbar.end.x<=dim.x+0.01,"Command bar fits %s" % [str(dim)])
 expect(not toolbar.intersects(dock) or not bool(layout["compact"]),"Compact command bar does not overlap drawer %s" % [str(dim)])
 expect(dock.size.y>=48.0,"Drawer always retains accessible toggle")

func run_checks() -> void:
 world=load("res://scenes/skirmish.tscn").instantiate()
 root.add_child(world)
 await process_frame
 world.paused=true
 expect(world.hud_dock!=null and world.hud_scroll!=null,"Production dock and scrolling controls exist")
 expect(world.producer_summary!=null,"Compact active production summary exists")
 expect(world.producer_list!=null,"Tappable producer list exists")
 expect(world.stage_chips.size()==4,"Personal, Alpha, Bravo and Charlie quick choices exist")
 expect(is_instance_valid(world.orders_sheet) and not world.orders_sheet.visible,"Spawn and rally controls stay closed until a producer is selected")
 expect(world.hud_toolbar_scroll!=null,"Command bar supports horizontal scrolling")
 verify_layout(Vector2(1280,720),true)
 verify_layout(Vector2(1920,1080),true)
 verify_layout(Vector2(844,390),true)
 verify_layout(Vector2(390,844),true)
 verify_layout(Vector2(390,844),false)
 verify_layout(Vector2(320,568),true)
 world.sidebar_open=false
 world._apply_hud_layout(Vector2(390,844))
 expect(world.compact_hud,"Portrait uses compact interface")
 expect(not world.hud_scroll.visible,"Collapsed mobile sheet leaves battlefield visible")
 expect(world.sidebar_toggle.visible and not world.sidebar_toggle.disabled,"Collapsed sheet still has an operable toggle")
 world.sidebar_open=true
 world._apply_hud_layout(Vector2(390,844))
 expect(world.hud_scroll.visible,"Mobile drawer expands to full controls")
 expect(not world.rally_stage_selector.visible,"Small screen uses stage chips instead of duplicate dropdown")
 expect(not world.activate_producer_button.visible,"Mobile producer cards replace redundant activate button")
 for chip in world.stage_chips:
  expect(chip.custom_minimum_size.y>=44.0,"Touch stage choice meets minimum target size")
 world._apply_hud_layout(Vector2(1280,720))
 expect(not world.compact_hud and world.rally_stage_selector.visible,"Desktop has full sidebar and dropdown")
 expect(world._deploy_mcv(0),"MCV deploys for test setup")
 expect(world._place_structure("barracks",0,Vector2(440,435)),"First Barracks is placed")
 var b1=world._active_producer(0,"infantry")
 expect(world._place_structure("barracks",0,Vector2(720,675)),"Second Barracks is placed")
 var b2=world._active_producer(0,"infantry")
 expect(world._place_structure("factory",0,Vector2(770,900)),"War Factory is placed")
 var factory=world._active_producer(0,"vehicle")
 world._update_hud()
 expect(world.producer_buttons.size()==3,"All existing producers appear as separate cards")
 expect(world.producer_buttons.has(b1.get_instance_id()),"First Barracks card is present")
 expect(world.producer_buttons.has(b2.get_instance_id()),"Second Barracks card is present")
 expect(world.producer_buttons.has(factory.get_instance_id()),"Factory card is present")
 var current_card: Button=world.producer_buttons[b2.get_instance_id()]
 expect(current_card.button_pressed and current_card.text.contains("ACTIVE"),"Newest Barracks has a visible active indicator")
 expect(world.producer_summary.text.contains("INF #2"),"Compact status identifies active Barracks ordinal")
 world._on_producer_card_pressed(b1)
 expect(world.orders_sheet.visible,"Selecting a producer opens rally setup beneath the build icons")
 expect(world._active_producer(0,"infantry")==b1,"Tapping an older Barracks activates its spawn exit")
 expect(world.selected_building==b1,"Producer card also selects its building")
 expect(world.producer_buttons[b1.get_instance_id()].button_pressed,"Card highlights newly activated producer")
 expect(world.producer_summary.text.contains("INF #1"),"Summary tracks manual producer switching")
 expect(world.set_staging_area(0,"ALPHA",Vector2(800,1040)),"Alpha staging area assigned")
 expect(world.assign_producer_stage(0,b1,"ALPHA"),"First Barracks assigned to Alpha")
 expect(world.set_producer_attack_move(0,b1,true),"First Barracks set to attack-move")
 world._update_hud()
 var stage_card: Button=world.producer_buttons[b1.get_instance_id()]
 expect(stage_card.text.contains("ALPHA") and stage_card.text.contains("ATTACK-MOVE"),"Factory card clearly shows stage and movement mode")
 expect(world.producer_summary.text.contains("ALPHA ATK"),"Compact summary shows stage and attack mode")
 expect(world.stage_chips[1].button_pressed,"Quick Alpha chip shows current choice")
 expect(world.stage_detail.text.contains("ALPHA") and world.stage_detail.text.contains("ATTACK-MOVE"),"Selected production details show route intent")
 world._on_stage_selected(2)
 expect(b1.rally_stage_id=="BRAVO","Quick Bravo chip changes selected building destination")
 expect(world.stage_chips[2].button_pressed,"Stage selection highlight changes to Bravo")
 world._toggle_rally_attack_move()
 expect(not b1.rally_attack_move,"Toggle switches selected producer back to Move")
 expect(world.rally_mode_button.text.contains("MOVE"),"Movement mode is visible in sidebar")
 world._on_producer_card_pressed(factory)
 expect(world._active_producer(0,"vehicle")==factory,"Factory card activates vehicle lane without changing infantry lane")
 expect(world._active_producer(0,"infantry")==b1,"Infantry lane remains on earlier Barracks")
 expect(world.producer_summary.text.contains("VEH #1"),"Vehicle producer identity is visible")
 expect(world.sell_structure(0,b2),"Unused Barracks can be sold")
 world._update_hud()
 expect(world.producer_buttons.size()==2,"Sold producer card is removed without stale references")
 world.reset_battle()
 expect(world.producer_buttons.is_empty(),"Match reset clears all producer cards")
 world.queue_free()
 if failures.is_empty():
  print("PRODUCTION_HUD_SMOKE_PASS")
  quit(0)
 else:
  print("PRODUCTION_HUD_SMOKE_FAIL "+str(failures.size()))
  quit(1)
