extends Area2D

@export var item_id := ""
@onready var sprite = $Sprite2D
enum ItemType {
	WEAPON,
	CONSUMABLE,
	MATERIAL,
	KEY,
	ARMOR,
	QUEST
}
@export var type: ItemType
const TILE_SIZE = 32
const ATLAS = "res://assets/atlases/items.png"

func _ready():
	var item = Inventory.get_item(item_id)
	sprite.texture = preload(ATLAS)
	sprite.region_enabled = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_rect = Rect2(Vector2(item["pos"][0], item["pos"][1]) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))
	sprite.scale = Vector2(0.8, 0.8)
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if !body.has_method("pickup_item"):
		return
	body.inventory.add_item(item_id)
	queue_free()
