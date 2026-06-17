class_name ServiceManagerService
extends Node

signal service_open_requested(service_type: int, service_id: StringName, source_npc: Node)
signal shop_open_requested(shop_id: StringName, source_npc: Node)
signal service_closed(service_type: int, service_id: StringName)

var service_registry: ServiceRegistry = preload(
	"res://Resources/Services/ServiceRegistry.tres"
)

var current_service_id: StringName = &""
var current_service_type: int = NPCProfile.ServiceType.NONE
var current_source_npc: Node = null
var current_service_definition: ServiceDefinition = null
var current_shop_definition: ShopDefinition = null

var _open_shop_ui: PlaceholderShopUI = null
var _locked_player: Player = null
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED


func open_active_npc_service() -> void:
	var game_manager: Node = get_tree().root.get_node_or_null("GameManager")

	if game_manager == null:
		push_warning("ServiceManager could not find the GameManager autoload.")
		return

	if game_manager.has_method("get_active_dialogue_npc") == false:
		push_warning("GameManager has no get_active_dialogue_npc method.")
		return

	var active_npc: NPCBase = game_manager.call("get_active_dialogue_npc") as NPCBase

	if active_npc == null:
		push_warning("ServiceManager could not open a service: there is no active dialogue NPC.")
		return

	open_service_for_profile(active_npc.npc_profile, active_npc)


func open_service_for_profile(profile: NPCProfile, source_npc: Node = null) -> void:
	if profile == null:
		push_warning("ServiceManager could not open service: profile was null.")
		return

	if profile.service_type == NPCProfile.ServiceType.NONE:
		push_warning("%s has no service type." % profile.display_name)
		return

	if profile.service_id == &"":
		push_warning("%s has no service_id." % profile.display_name)
		return

	if source_npc is NPCBase:
		var npc: NPCBase = source_npc as NPCBase

		if npc.is_service_available_from_schedule() == false:
			push_warning("%s service is not available in the current schedule package." % npc.name)
			return
		
	var definition: ServiceDefinition = _get_service_definition(profile.service_id)

	if definition == null:
		return

	if definition.service_type != profile.service_type:
		push_warning(
			"Service type mismatch for '%s'. Profile type: %s, definition type: %s"
			% [
				String(profile.service_id),
				str(profile.service_type),
				str(definition.service_type)
			]
		)

	if current_service_id != &"":
		close_current_service()

	current_service_definition = definition
	current_shop_definition = definition.shop_definition
	current_service_type = definition.service_type
	current_service_id = definition.service_id
	current_source_npc = source_npc

	service_open_requested.emit(
		current_service_type,
		current_service_id,
		current_source_npc
	)

	match definition.service_type:
		NPCProfile.ServiceType.SHOP:
			_open_shop(definition, source_npc)

		NPCProfile.ServiceType.BATHHOUSE_COUNTER:
			_open_service_ui(definition)

		NPCProfile.ServiceType.TRAINING:
			_open_service_ui(definition)

		NPCProfile.ServiceType.INFORMATION:
			_open_service_ui(definition)

		_:
			_open_service_ui(definition)


func close_current_service() -> void:
	var closing_service_type: int = current_service_type
	var closing_service_id: StringName = current_service_id

	if _open_shop_ui != null and is_instance_valid(_open_shop_ui):
		_open_shop_ui.queue_free()

	_open_shop_ui = null

	_unlock_player_input()

	current_service_id = &""
	current_service_type = NPCProfile.ServiceType.NONE
	current_source_npc = null
	current_service_definition = null
	current_shop_definition = null

	service_closed.emit(closing_service_type, closing_service_id)


func _get_service_definition(service_id: StringName) -> ServiceDefinition:
	if service_registry == null:
		push_warning("ServiceManager has no ServiceRegistry assigned.")
		return null

	var definition: ServiceDefinition = service_registry.get_service(service_id)

	if definition == null:
		push_warning("No ServiceDefinition found for service_id: %s" % String(service_id))
		return null

	return definition


func _open_shop(definition: ServiceDefinition, source_npc: Node = null) -> void:
	print("SHOP OPENED: %s" % String(definition.service_id))

	shop_open_requested.emit(definition.service_id, source_npc)
	_open_service_ui(definition)


func _open_service_ui(definition: ServiceDefinition) -> void:
	if definition.ui_scene == null:
		push_warning("ServiceDefinition has no UI scene: %s" % String(definition.service_id))
		return

	var ui_instance: Node = definition.ui_scene.instantiate()

	if ui_instance == null:
		push_warning("Could not instantiate UI scene for service: %s" % String(definition.service_id))
		return

	var shop_ui: PlaceholderShopUI = ui_instance as PlaceholderShopUI

	if shop_ui == null:
		push_warning("Service UI scene root must currently use PlaceholderShopUI.")
		ui_instance.queue_free()
		return

	_open_shop_ui = shop_ui
	get_tree().root.add_child(_open_shop_ui)

	_open_shop_ui.close_requested.connect(close_current_service)
	_open_shop_ui.setup_service(definition)

	_lock_player_input()


func _lock_player_input() -> void:
	if _locked_player != null and is_instance_valid(_locked_player):
		return

	_locked_player = get_tree().get_first_node_in_group("player") as Player

	if _locked_player != null:
		_locked_player.lock_input()

	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unlock_player_input() -> void:
	if _locked_player != null and is_instance_valid(_locked_player):
		_locked_player.unlock_input()

	_locked_player = null
	Input.mouse_mode = _previous_mouse_mode
