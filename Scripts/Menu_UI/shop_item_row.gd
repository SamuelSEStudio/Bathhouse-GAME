class_name ShopItemRow
extends PanelContainer

signal item_selected(entry: ShopStockEntry)

@onready var button: Button = $Button
@onready var icon_texture_rect: TextureRect = $Button/HBoxContainer/IconTextureRect
@onready var name_label: Label = $Button/HBoxContainer/NameLabel
@onready var price_label: Label = $Button/HBoxContainer/PriceLabel

var stock_entry: ShopStockEntry = null


func _ready() -> void:
	button.pressed.connect(_on_pressed)


func setup(entry: ShopStockEntry) -> void:
	stock_entry = entry

	if is_node_ready() == false:
		return

	_apply_entry_to_ui()


func grab_row_focus() -> void:
	if button != null:
		button.grab_focus()


func _apply_entry_to_ui() -> void:
	if stock_entry == null:
		name_label.text = "Missing Item"
		price_label.text = "-"
		icon_texture_rect.texture = null
		return

	name_label.text = stock_entry.get_display_name()
	price_label.text = "%s" % stock_entry.get_price()

	if stock_entry.item != null and stock_entry.item.icon != null:
		icon_texture_rect.texture = stock_entry.item.icon
		print("Shop row icon loaded for: %s" % stock_entry.get_display_name())
	else:
		icon_texture_rect.texture = null
		print("Shop row has no icon for: %s" % stock_entry.get_display_name())


func _on_pressed() -> void:
	if stock_entry == null:
		return

	item_selected.emit(stock_entry)
