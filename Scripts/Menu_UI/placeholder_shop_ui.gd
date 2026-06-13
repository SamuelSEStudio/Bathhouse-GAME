class_name PlaceholderShopUI
extends CanvasLayer

signal close_requested

@onready var title_label: Label = $"Container/Panel/MargnContainer/VboxContainer/Title Label"
@onready var shop_id_label: Label = $"Container/Panel/MargnContainer/VboxContainer/Shop Id Label"
@onready var buy_button: Button = $Container/Panel/MargnContainer/VboxContainer/BuyButton
@onready var sell_button: Button = $Container/Panel/MargnContainer/VboxContainer/SellButton
@onready var exit_button: Button = $Container/Panel/MargnContainer/VboxContainer/ExitButton


var current_shop_id: StringName = &""


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	exit_button.pressed.connect(_on_leave_pressed)

	_refresh_labels()
	exit_button.grab_focus()


func setup(shop_id: StringName) -> void:
	current_shop_id = shop_id

	if is_node_ready():
		_refresh_labels()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _refresh_labels() -> void:
	title_label.text = "SHOP"

	if current_shop_id == &"":
		shop_id_label.text = "Placeholder service"
	else:
		shop_id_label.text = "Shop ID: %s" % String(current_shop_id)


func _on_buy_pressed() -> void:
	print("PLACEHOLDER BUY selected for shop: %s" % String(current_shop_id))


func _on_sell_pressed() -> void:
	print("PLACEHOLDER SELL selected for shop: %s" % String(current_shop_id))


func _on_leave_pressed() -> void:
	close_requested.emit()
