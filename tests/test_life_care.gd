extends SceneTree

const Clock = preload("res://scripts/life/world_clock.gd")

class RejectingMonster:
	extends MonsterInstance
	var attempts := 0
	var on_receive: Callable

	func _init(source: MonsterDefinition) -> void:
		super(source)

	func receive_food(_gain: float, _at_seconds: float) -> bool:
		attempts += 1
		if on_receive.is_valid():
			on_receive.call()
		return false

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func run() -> void:
	var clock := Clock.new()
	root.add_child(clock)
	clock.set_physics_process(false)
	clock.debug_set_seconds(0)
	check(clock.advance_hours(24) and clock.day() == 2 and clock.hour() == 0, "24-hour day")
	clock.debug_set_seconds(0)
	for step in 60:
		clock.advance_seconds(clock.game_seconds_per_real_second)
	check(clock.hour() == 1, "One real minute equals one game hour")
	var other := Clock.new()
	root.add_child(other)
	other.set_physics_process(false)
	other.debug_set_seconds(0)
	other.advance_hours(1)
	check(other.total_seconds == clock.total_seconds, "Jump equals incremental time")
	check(not clock.advance_seconds(-1) and not clock.advance_seconds(INF), "Reject backward/nonfinite simulation")
	var before := clock.total_seconds
	paused = true
	clock._physics_process(60)
	check(clock.total_seconds == before, "Paused simulation does not advance")
	paused = false
	root.get_node("SceneManager").transition_in_progress = true
	clock._physics_process(60)
	check(clock.total_seconds == before, "Scene transition does not advance")
	root.get_node("SceneManager").transition_in_progress = false
	clock.free()
	other.free()
	await extra_tests()
	print("Life & Care: %s checks, %s failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func extra_tests() -> void:
	var registry := MonsterRegistry.new()
	var drako := MonsterInstance.create(registry.get_monster(&"drako"))
	var slimo := MonsterInstance.create(registry.get_monster(&"slimo"))
	drako.advance_care(0, 3600)
	slimo.advance_care(0, 3600)
	check(drako.satiety == 92 and slimo.satiety == 95, "Species-specific hourly decay")
	check(drako.definition.food_requirement != slimo.definition.food_requirement, "Species-specific food requirement")
	var stepped := MonsterInstance.create(drako.definition)
	for step in 24:
		stepped.advance_care(step * 3600, (step + 1) * 3600)
	var jumped := MonsterInstance.create(drako.definition)
	jumped.advance_care(0, 24 * 3600)
	check(stepped.satiety == jumped.satiety and jumped.care_events().size() == 1, "Jump and steps share starvation rules")
	var event: RefCounted = jumped.care_events()[0]
	check(event.cause == &"STARVATION" and event.world_seconds == 45000 and event.instance_id == jumped.instance_id, "Exact starvation crossing and owner")
	jumped.advance_care(24 * 3600, 48 * 3600)
	check(jumped.care_events().size() == 1, "No repeated starvation")
	jumped.receive_food(10, 48 * 3600)
	jumped.advance_care(48 * 3600, 50 * 3600)
	check(jumped.care_events().size() == 2, "Feeding re-arms new starvation phase")
	drako.debug_set_satiety(0)
	check(drako.care_events().is_empty() and slimo.satiety == 95, "Direct debug setting has no care event; independent instances")
	drako.debug_set_satiety(90)
	check(drako.receive_food(11, 100) and drako.satiety == 100 and drako.refusing_food, "Overfeeding succeeds, clamps and refuses")
	check(not drako.receive_food(11, 101) and drako.care_events().size() == 1, "Refused food creates no extra event")
	drako.advance_care(0, 9000)
	check(drako.satiety == 80 and drako.refusing_food, "Still refuses at exactly 80")
	drako.advance_care(9000, 9001)
	check(not drako.refusing_food, "Refusal ends below 80")
	drako.debug_set_satiety(90)
	drako.receive_food(10, 200)
	check(not drako.refusing_food and drako.care_events().size() == 1, "Exactly 100 is not overfeeding")
	await item_tests()

func item_tests() -> void:
	var catalog := load("res://data/items/catalog.tres")
	var Inventory = load("res://scripts/items/inventory.gd")
	var Feeding = load("res://scripts/items/feeding_service.gd")
	var inv = Inventory.new(2)
	var apple: Resource = catalog.get_item(&"apple")
	check(catalog.validation_errors().is_empty() and catalog.items.size() == 3, "Data-driven item catalog validates")
	check(inv.add(apple, 25) and inv.stacks().size() == 2, "Overflow creates second stack")
	check(not inv.add(apple, 16) and inv.quantity(&"apple") == 25, "Capacity failure is atomic")
	check(inv.add(apple, 15) and inv.quantity(&"apple") == 40, "Existing stack space fills")
	check(not inv.set_capacity(1) and inv.capacity == 2, "Cannot shrink below occupied slots")
	check(inv.remove(&"apple", 21) and inv.stacks().size() == 1, "Removing empties a slot")
	check(not inv.remove(&"apple", 20) and inv.quantity(&"apple") == 19, "Failed removal changes nothing")
	var snapshot: Array = inv.stacks()
	snapshot[0].quantity = 0
	check(inv.quantity(&"apple") == 19, "Inventory snapshot cannot mutate stacks")
	var registry := MonsterRegistry.new()
	var first := MonsterInstance.create(registry.get_monster(&"drako"))
	var second := MonsterInstance.create(registry.get_monster(&"slimo"))
	var feeding = Feeding.new()
	first.satiety = 0
	second.satiety = 0
	check(feeding.feed(first, inv, apple, 50) == &"FEED_OK" and first.satiety == 10, "Food requirement scales Drako gain")
	check(feeding.feed(second, inv, apple, 50) == &"FEED_OK" and second.satiety == 20, "Same food scales Slimo gain")
	first.satiety = 95
	check(feeding.feed(first, inv, apple, 51) == &"FEED_OK" and first.refusing_food, "Inventory feeding overfeeds successfully")
	var count: int = inv.quantity(&"apple")
	check(feeding.feed(first, inv, apple, 52) == &"FEED_REFUSED" and inv.quantity(&"apple") == count and first.care_events().size() == 1, "Refused feed consumes nothing and repeats no event")
	check(feeding.feed(second, Inventory.new(0), apple, 52) == &"FEED_NO_ITEM", "Empty inventory rejected")
	var tiny = Inventory.new(0)
	check(not tiny.add(apple, 1), "Zero capacity")
	var duplicate: Resource = catalog.duplicate(true)
	duplicate.items.append(apple)
	check(not duplicate.validation_errors().is_empty(), "Duplicate item ID rejected")
	var observed := {"result": &""}
	var reenter := func(): observed.result = feeding.feed(second, inv, apple, 100)
	second.changed.connect(reenter)
	count = inv.quantity(&"apple")
	check(feeding.feed(second, inv, apple, 100) == &"FEED_OK" and observed.result == &"FEED_BUSY" and inv.quantity(&"apple") == count - 1, "Signal re-entry cannot double-consume food")
	second.changed.disconnect(reenter)
	var invalid_item: Resource = apple.duplicate(true)
	invalid_item.item_id = &"test_food"
	invalid_item.effects[0].kind = &"unimplemented"
	inv = Inventory.new(2)
	inv.add(invalid_item, 1)
	check(feeding.feed(second, inv, invalid_item, 100) == &"FEED_UNSUPPORTED" and inv.quantity(&"test_food") == 1, "Unsupported effect consumes nothing")
	var event_count := jumped_event_test()
	check(event_count == 1, "Clearing history does not duplicate ongoing starvation")
	feeding_transaction_tests()
	await menu_tests()

func feeding_transaction_tests() -> void:
	var catalog := load("res://data/items/catalog.tres")
	var Inventory = load("res://scripts/items/inventory.gd")
	var Feeding = load("res://scripts/items/feeding_service.gd")
	var apple: Resource = catalog.get_item(&"apple")
	var definition := MonsterRegistry.new().get_monster(&"drako")
	var rejected := RejectingMonster.new(definition)
	var service = Feeding.new()
	var inv = Inventory.new(2)
	inv.add(apple, 25)
	var before: Array = inv.stacks()
	var notifications := {"count": 0}
	inv.changed.connect(func(): notifications.count += 1)
	check(service.feed(rejected, inv, apple, 100) == &"FEED_REFUSED" and rejected.attempts == 1, "Consumer rejection is reported instead of success")
	check(inv.stacks() == before and notifications.count == 0, "Rejected consumption restores exact multi-stack inventory without notification")
	check(rejected.satiety == 100 and rejected.care_events().is_empty(), "Rejected feeding leaves monster and care history unchanged")
	# Reserve the last item, then attempt to occupy its slot during rejection.
	inv = Inventory.new(1)
	inv.add(apple, 1)
	var mutations := {"add": true, "remove": true, "capacity": true}
	rejected.on_receive = func():
		mutations.add = inv.add(catalog.get_item(&"mushroom"), 1)
		mutations.remove = inv.remove(&"apple", 1)
		mutations.capacity = inv.set_capacity(0)
	check(service.feed(rejected, inv, apple, 100) == &"FEED_REFUSED" and inv.quantity(&"apple") == 1 and inv.stacks().size() == 1, "Last-item rollback cannot lose its slot")
	check(not mutations.add and not mutations.remove and not mutations.capacity and inv.capacity == 1, "Pending consumer cannot invalidate rollback through inventory mutations")
	check(not inv.consume_if(&"apple", 1, func(): return null) and inv.quantity(&"apple") == 1, "Unexpected consumer result also rolls back consumption")
	var monster := MonsterInstance.create(definition)
	monster.satiety = 0
	check(service.feed(monster, inv, apple, 100) == &"FEED_OK" and inv.quantity(&"apple") == 0 and monster.satiety == 10, "Locks release after rejection; later success consumes exactly one")
	var attempts := rejected.attempts
	check(service.feed(rejected, inv, apple, 100) == &"FEED_NO_ITEM" and rejected.attempts == attempts, "Missing item never calls consumer")
	var tiny_food: Resource = apple.duplicate(true)
	tiny_food.effects[0].value = 1.0e-300
	var huge_requirement := definition.duplicate() as MonsterDefinition
	huge_requirement.food_requirement = 1.0e300
	monster = MonsterInstance.create(huge_requirement)
	inv.add(tiny_food, 1)
	check(service.feed(monster, inv, tiny_food, 100) == &"FEED_UNSUPPORTED" and inv.quantity(tiny_food.item_id) == 1, "Underflow to zero never consumes food")
	# Different service objects must not consume the same pending transaction.
	inv = Inventory.new(1)
	inv.add(apple, 3)
	monster = MonsterInstance.create(definition)
	monster.satiety = 0
	var other = Feeding.new()
	var nested := {"result": &""}
	var nested_feed := func(): nested.result = other.feed(monster, inv, apple, 100)
	monster.changed.connect(nested_feed)
	check(service.feed(monster, inv, apple, 100) == &"FEED_OK" and nested.result != &"FEED_OK" and inv.quantity(&"apple") == 2 and monster.satiety == 10, "Another service cannot consume during pending monster signals")
	monster.changed.disconnect(nested_feed)

func jumped_event_test() -> int:
	var monster := MonsterInstance.create(MonsterRegistry.new().get_monster(&"drako"))
	monster.advance_care(0, 86400)
	monster.debug_clear_care_events()
	monster.advance_care(86400, 172800)
	monster.receive_food(1, 172800)
	monster.advance_care(172800, 180000)
	return monster.care_events().size()

func menu_tests() -> void:
	change_scene_to_file("res://forest_clearing.tscn")
	await scene_changed
	for frame in 35:
		await physics_frame
	var menus := root.get_node("Menus")
	check(menus.open_menu(&"inventory") and paused, "Inventory opens and pauses")
	var clock := root.get_node("WorldTime")
	var before: float = clock.total_seconds
	for frame in 5:
		await physics_frame
	check(clock.total_seconds == before, "Menu stops world time")
	check(menus.open_menu(&"care") and paused and not root.get_node("GameMenus").inventory_menu.visible, "Switching menus keeps pause and hides previous")
	check(menus.open_menu(&"food", true), "Care opens food filter")
	menus.back()
	check(menus.active_menu == &"care" and paused, "Back to care stays paused")
	root.get_node("SettingsMenu").open_menu()
	check(menus.active_menu == &"settings" and paused, "Settings shares coordinator")
	menus.close_menu(&"inventory")
	check(paused and menus.active_menu == &"settings", "Inactive menu cannot unpause settings")
	root.get_node("SettingsMenu").close_menu()
	check(not paused, "Closing active settings resumes")
	root.get_node("SceneManager").transition_in_progress = true
	check(not menus.open_menu(&"inventory"), "No menu during transition")
	root.get_node("SceneManager").transition_in_progress = false
	var monster: MonsterInstance = root.get_node("CompanionManager").active_monster
	monster.satiety = 0
	menus.open_menu(&"inventory")
	var inventory_menu = root.get_node("GameMenus").inventory_menu
	inventory_menu.selected_id = &"apple"
	var old_count: int = root.get_node("PlayerInventory").inventory.quantity(&"apple")
	inventory_menu.use_selected()
	check(monster.satiety == 10 and root.get_node("PlayerInventory").inventory.quantity(&"apple") == old_count - 1, "UI calls same feeding service")
	menus.close_menu()
	await hud_tests()

func hud_tests() -> void:
	var hud := root.get_node("GameHud")
	var monster: MonsterInstance = root.get_node("CompanionManager").active_monster
	monster.current_hp = 7
	monster.current_mp = 3
	monster.satiety = 42
	check(hud.monster_hud.fields[&"hp"].bar.value == 7 and hud.monster_hud.fields[&"mp"].bar.value == 3 and hud.monster_hud.fields[&"satiety"].bar.value == 42, "HUD reacts to model signals")
	var settings := root.get_node("GameSettings")
	var before: bool = settings.hud_visible[&"satiety"]
	settings.hud_visible[&"satiety"] = false
	settings.changed.emit()
	check(not hud.monster_hud.fields[&"satiety"].row.visible, "HUD field visibility")
	settings.hud_visible[&"satiety"] = before
	settings.changed.emit()
	var old_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("de")
	await process_frame
	check(hud.monster_hud.fields[&"satiety"].label.text.begins_with("Sättigung") and hud.time_hud.label.text.begins_with("Tag"), "Live HUD translation")
	TranslationServer.set_locale(old_locale)
	var Settings = load("res://scripts/game_settings.gd")
	var path := "res://.godot/life_test_settings.cfg"
	var test_settings = Settings.new()
	test_settings.save_path = path
	root.add_child(test_settings)
	test_settings.set_hud_visible(&"hp", false)
	test_settings.free()
	var reloaded = Settings.new()
	reloaded.save_path = path
	root.add_child(reloaded)
	check(not reloaded.hud_visible[&"hp"] and reloaded.hud_visible[&"mp"], "HUD preferences persist independently")
	reloaded.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	settings._apply_all()
	await integration_tests()

func integration_tests() -> void:
	var menus := root.get_node("Menus")
	check(menus.has_menu(&"debug") == OS.is_debug_build(), "Developer menu registered only in debug")
	if menus.has_menu(&"debug"):
		menus.open_menu(&"debug")
		var view = menus._menus[&"debug"].view
		var monster: MonsterInstance = root.get_node("CompanionManager").active_monster
		monster.debug_clear_care_events()
		view.numbers.satiety.value = 0
		view.apply_monster()
		check(monster.satiety == 0 and monster.care_events().is_empty(), "Debug edit does not simulate starvation")
		monster.satiety = 8
		root.get_node("WorldTime").advance_hours(2)
		view.refresh()
		check(monster.care_events().size() == 1 and not view.history.text.is_empty(), "Debug time jump simulates and displays starvation")
		menus.close_menu()
	var monster: MonsterInstance = root.get_node("CompanionManager").active_monster
	var identity := monster.instance_id
	monster.satiety = 55
	var inventory = root.get_node("PlayerInventory").inventory
	var count: int = inventory.quantity(&"apple")
	root.get_node("SceneManager").travel_to("res://forest_path.tscn", &"FromForestClearing")
	var clock := root.get_node("WorldTime")
	var before: float = clock.total_seconds
	for frame in 90:
		await physics_frame
		if not root.get_node("SceneManager").transition_in_progress:
			break
	check(current_scene.scene_file_path == "res://forest_path.tscn" and root.get_node("CompanionManager").active_monster.instance_id == identity, "Monster data survives segment transition")
	check(clock.total_seconds == before and monster.satiety == 55 and inventory.quantity(&"apple") == count, "No transition time/decay; inventory persists")
	for frame in 5:
		await physics_frame
	check(clock.total_seconds > before and monster.satiety < 55, "Simulation resumes after transition")
	await keyboard_tests()
	await layout_tests()

func layout_tests() -> void:
	var previous_size := root.content_scale_size
	root.content_scale_size = Vector2i(640, 360)
	for frame in 4:
		await process_frame
	var settings := root.get_node("SettingsMenu")
	settings.open_menu()
	settings.tabs.current_tab = 3
	for frame in 4:
		await process_frame
	var rect: Rect2 = settings.panel.get_global_rect()
	print("SMALL_SETTINGS_RECT ", rect, " root=", settings.root.size, " min=", settings.panel.get_combined_minimum_size())
	check(rect.position.y >= 0 and rect.end.y <= 360 and rect.position.x >= 0 and rect.end.x <= 640, "Settings fits a 640x360 canvas")
	var last_toggle: Control = settings._hud_checks[&"time"]
	last_toggle.grab_focus()
	for frame in 4:
		await process_frame
	var scroll_rect: Rect2 = last_toggle.get_parent().get_parent().get_global_rect()
	check(scroll_rect.encloses(last_toggle.get_global_rect()), "Keyboard focus scrolls last HUD preference into view")
	settings.close_menu()
	root.get_node("Menus").open_menu(&"status")
	for frame in 4:
		await process_frame
	rect = root.get_node("GameMenus").status_menu.panel.get_global_rect()
	check(rect.position.y >= 0 and rect.end.y <= 360, "Status and close button fit small canvas")
	root.get_node("Menus").open_menu(&"inventory")
	var inventory_view = root.get_node("GameMenus").inventory_menu
	for frame in 4:
		await process_frame
	inventory_view.use_button.grab_focus()
	for frame in 4:
		await process_frame
	scroll_rect = inventory_view.body.get_parent().get_global_rect()
	print("SMALL_USE_RECT ", inventory_view.use_button.get_global_rect(), " scroll=", scroll_rect)
	check(scroll_rect.encloses(inventory_view.use_button.get_global_rect()), "Keyboard focus scrolls food-use action into view")
	root.get_node("Menus").close_menu()
	root.content_scale_size = previous_size
	var clock := Clock.new()
	root.add_child(clock)
	clock.set_physics_process(false)
	for rate in [30, 60, 120]:
		clock.debug_set_seconds(0)
		for frame in rate * 60:
			clock._physics_process(1.0 / rate)
		check(absf(clock.total_seconds - 3600.0) < 0.00001, "World time independent of physics rate: %s" % rate)
	clock.region_time_factor = 2
	clock.debug_set_seconds(0)
	clock._physics_process(1.0)
	check(clock.total_seconds == 120, "Configured region factor scales normal simulation")
	clock.free()

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	await process_frame

func keyboard_tests() -> void:
	var menus := root.get_node("Menus")
	await key(KEY_F1)
	check(menus.active_menu == &"inventory" and paused, "F1 opens inventory")
	await key(KEY_F2)
	check(menus.active_menu == &"care" and paused, "F2 switches without unpause")
	await key(KEY_ESCAPE)
	check(menus.active_menu.is_empty() and not paused, "ESC closes in-game menu")
	await key(KEY_ESCAPE)
	var settings := root.get_node("SettingsMenu")
	settings._begin_capture("move_forward")
	await key(KEY_F1)
	check(menus.active_menu == &"settings" and settings.is_capturing(), "Reserved menu key cannot escape movement capture")
	await key(KEY_ESCAPE)
	check(paused and not settings.is_capturing(), "ESC cancels capture before menu close")
	await key(KEY_ESCAPE)
	check(not paused, "Second ESC closes settings")
