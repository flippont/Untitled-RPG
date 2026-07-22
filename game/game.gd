extends Node2D
@onready var mesh_manager: Node2D = $"MeshManager"
@onready var camera: Node2D = $"Entities/CharacterBody2D/Camera2D"
const item_pickup = preload("res://items/item.tscn")

func spawn_item(id: String, pos: Vector2):
	var pickup = item_pickup.instantiate()
	pickup.item_id = id
	pickup.global_position = pos
	add_child(pickup)

func _ready() -> void:
	mesh_manager.load_map("res://assets/maps/test_map.txt")
	spawn_item("apple", Vector2(100,100))
	spawn_item("shotgun", Vector2(300,200))
	spawn_item("rocket_launcher", Vector2(500,150))
	pass


func _process(_delta) -> void:
	mesh_manager.update_chunk_visibility(camera)
	pass
