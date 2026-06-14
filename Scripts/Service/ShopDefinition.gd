class_name ShopDefinition
extends Resource
# This is currently a UI scene, but later this may become a menu,
# vending machine interaction, shelf browsing scene, or custom service presentation.
@export var ui_scene: PackedScene
@export_group("Shop Identity")
@export var shop_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Inventory Placeholder")
@export var stock: Array[ShopStockEntry] = []


func get_available_stock() -> Array[ShopStockEntry]:
	var result: Array[ShopStockEntry] = []

	for entry: ShopStockEntry in stock:
		if entry == null:
			continue

		if entry.is_in_stock():
			result.append(entry)

	return result


func is_empty() -> bool:
	return get_available_stock().is_empty()
