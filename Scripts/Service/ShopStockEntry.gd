class_name ShopStockEntry
extends Resource

@export var item: ShopItemDefinition
@export var price_override: int = -1
@export var stock_amount: int = -1
@export var is_available: bool = true


func get_display_name() -> String:
	if item == null:
		return "Missing Item"

	return item.display_name


func get_price() -> int:
	if price_override >= 0:
		return price_override

	if item == null:
		return 0

	return item.base_price


func has_limited_stock() -> bool:
	return stock_amount >= 0


func is_in_stock() -> bool:
	if is_available == false:
		return false

	if has_limited_stock() == false:
		return true

	return stock_amount > 0
