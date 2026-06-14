class_name ServiceDefinition
extends Resource

@export_group("Service Identity")
@export var service_id: StringName = &""
@export var service_type: NPCProfile.ServiceType = NPCProfile.ServiceType.NONE
@export var display_name: String = ""

@export_group("UI")
@export var ui_scene: PackedScene

@export_group("Shop Data")
@export var shop_definition: ShopDefinition
