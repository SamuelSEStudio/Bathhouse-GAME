class_name ShopItemDefinition
extends Resource

enum ItemCategory {
	GENERAL,
	FOOD,
	DRINK,
	BATHHOUSE,
	KEY_ITEM,
	QUEST,
	OTHER
}

@export_group("Item Identity")
@export var item_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Shop Display")
@export var category: ItemCategory = ItemCategory.GENERAL
@export var icon: Texture2D

@export_group("Economy Placeholder")
@export var base_price: int = 0
@export var can_buy: bool = true
@export var can_sell: bool = false
