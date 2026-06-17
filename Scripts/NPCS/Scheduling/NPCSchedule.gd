class_name NPCSchedule
extends Resource

@export_group("Schedule Identity")
@export var schedule_id: StringName = &""
@export var display_name: String = ""
@export_multiline var designer_note: String = ""

@export_group("Packages")
@export var packages: Array[NPCSchedulePackage] = []

@export_group("Fallback")
@export var fallback_package: NPCSchedulePackage


func get_package_for_time_block(world_state: WorldState, time_block: int) -> NPCSchedulePackage:
	var best_package: NPCSchedulePackage = null

	for package: NPCSchedulePackage in packages:
		if package == null:
			continue

		if package.matches(world_state, time_block) == false:
			continue

		if best_package == null:
			best_package = package
			continue

		if package.priority > best_package.priority:
			best_package = package

	if best_package != null:
		return best_package

	return fallback_package


func get_package_for_current_world_state(world_state: WorldState) -> NPCSchedulePackage:
	if world_state == null:
		return fallback_package

	return get_package_for_time_block(world_state, world_state.current_time_block)


func has_package_for_context(context_id: StringName) -> bool:
	for package: NPCSchedulePackage in packages:
		if package == null:
			continue

		if package.has_context(context_id):
			return true

	return false


func get_all_location_ids() -> Array[StringName]:
	var result: Array[StringName] = []

	for package: NPCSchedulePackage in packages:
		if package == null:
			continue

		if package.location_id == &"":
			continue

		if result.has(package.location_id) == false:
			result.append(package.location_id)

	return result


func get_debug_label() -> String:
	if display_name != "":
		return display_name

	if schedule_id != &"":
		return String(schedule_id)

	return "Unnamed NPC Schedule"
