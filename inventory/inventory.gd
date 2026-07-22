extends Node

var listed_items := {}
var holding_items := []
signal inventory_changed

func _ready():
	var file = FileAccess.open("res://assets/json/items.json", FileAccess.READ)
	listed_items = JSON.parse_string(file.get_as_text())
	
func get_item(id: String):
	return listed_items[id]

func add_item(item_id: String):
	holding_items.append(item_id)
	inventory_changed.emit()
