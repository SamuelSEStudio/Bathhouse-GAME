class_name PlaceholderShopUI
extends CanvasLayer

signal close_requested

const SHOP_ITEM_ROW_SCENE: PackedScene = preload(
	"res://Scenes/Menus_UI/shop_item_row.tscn"
)

@onready var title_label: Label = $"Container/Panel/MargnContainer/VboxContainer/Title Label"
@onready var shop_id_label: Label = $"Container/Panel/MargnContainer/VboxContainer/Shop Id Label"
@onready var item_list_container: VBoxContainer = $Container/Panel/MargnContainer/VboxContainer/ItemListContainer
@onready var buy_button: Button = $Container/Panel/MargnContainer/VboxContainer/BuyButton
@onready var sell_button: Button = $Container/Panel/MargnContainer/VboxContainer/SellButton
@onready var exit_button: Button = $Container/Panel/MargnContainer/VboxContainer/ExitButton

var current_service_definition: ServiceDefinition = null
var current_shop_definition: ShopDefinition = null
var current_shop_id: StringName = &""
var selected_entry: ShopStockEntry = null


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	exit_button.pressed.connect(_on_leave_pressed)

	_refresh_ui()
	exit_button.grab_focus()


func setup(shop_id: StringName) -> void:
	current_shop_id = shop_id

	if is_node_ready():
		_refresh_ui()


func setup_service(service_definition: ServiceDefinition) -> void:
	current_service_definition = service_definition

	if current_service_definition != null:
		current_shop_id = current_service_definition.service_id
		current_shop_definition = current_service_definition.shop_definition

	if is_node_ready():
		_refresh_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _refresh_ui() -> void:
	_refresh_labels()
	_rebuild_item_rows()
	_refresh_buy_button()


func _refresh_labels() -> void:
	if current_service_definition != null and current_service_definition.display_name != "":
		title_label.text = current_service_definition.display_name
	else:
		title_label.text = "SHOP"

	if current_shop_definition != null:
		if current_shop_definition.description != "":
			shop_id_label.text = current_shop_definition.description
		else:
			shop_id_label.text = "Shop ID: %s" % String(current_shop_definition.shop_id)
	elif current_shop_id != &"":
		shop_id_label.text = "Shop ID: %s" % String(current_shop_id)
	else:
		shop_id_label.text = "Placeholder service"


func _rebuild_item_rows() -> void:
	for child: Node in item_list_container.get_children():
		child.queue_free()

	selected_entry = null

	if current_shop_definition == null:
		return

	var available_stock: Array[ShopStockEntry] = current_shop_definition.get_available_stock()

	for entry: ShopStockEntry in available_stock:
		var row_instance: Node = SHOP_ITEM_ROW_SCENE.instantiate()
		var row: ShopItemRow = row_instance as ShopItemRow

		if row == null:
			push_warning("Shop item row scene root must use ShopItemRow.")
			row_instance.queue_free()
			continue

		item_list_container.add_child(row)
		row.setup(entry)
		row.item_selected.connect(_on_item_row_selected)

	if item_list_container.get_child_count() > 0:
		var first_row: ShopItemRow = item_list_container.get_child(0) as ShopItemRow
		if first_row != null:
			first_row.grab_row_focus()

func _refresh_buy_button() -> void:
	if selected_entry == null:
		buy_button.text = "Buy"
		buy_button.disabled = true
		return

	buy_button.disabled = false
	buy_button.text = "Buy %s" % selected_entry.get_display_name()


func _on_item_row_selected(entry: ShopStockEntry) -> void:
	selected_entry = entry
	_refresh_buy_button()

	print("Selected shop item: %s" % selected_entry.get_display_name())


func _on_buy_pressed() -> void:
	if selected_entry == null:
		print("No item selected.")
		return

	print(
		"PLACEHOLDER BUY: %s for %s"
		% [
			selected_entry.get_display_name(),
			str(selected_entry.get_price())
		]
	)


func _on_sell_pressed() -> void:
	print("PLACEHOLDER SELL selected for shop: %s" % String(current_shop_id))


func _on_leave_pressed() -> void:
	close_requested.emit()
