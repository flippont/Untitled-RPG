extends Node2D
var map_path := "res://assets/maps/map_test.txt"
# Called when the node enters the scene tree for the first time.
@onready var mesh_manager: Node2D = $MeshManager
@onready var camera: Node2D = $Camera2D
@onready var cursor: Node2D = $Cursor

var tile_array := []
var selected_layer := 0
var selected_tile := ""

func _ready() -> void:
	mesh_manager.load_map(map_path)
	tile_array.clear()

	# convert tiles.json dict to array
	for tile_name in mesh_manager.tile_json.keys():
		var data = mesh_manager.tile_json[tile_name]
		if data.get("hidden", false):
			continue
		tile_array.append(tile_name)
	selected_tile = tile_array[0]
	pass

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("layer_up"):
		var maximum_layer = mesh_manager.LAYERS.size()
		if(selected_tile == "empty"):
			maximum_layer = mesh_manager.LAYERS.size() + 1
		if (selected_layer + 1) < maximum_layer:
			selected_layer += 1
		else:
			selected_layer = 0

	# swap layers
	if Input.is_action_just_pressed("layer_down"):
		if (selected_layer - 1) >= 0:
			selected_layer -= 1
		else:
			var final_layer = (mesh_manager.LAYERS.size() - 1)
			if(selected_tile == "empty"):
				final_layer = mesh_manager.LAYERS.size()
			selected_layer = final_layer

	# duplicate code but whatever
	if Input.is_action_just_pressed("switch_tile_left"):
		if selected_layer >= mesh_manager.LAYERS.size():
			selected_layer = mesh_manager.LAYERS.size() - 1
		if (tile_array.find(selected_tile) - 1) >= 0:
			selected_tile = tile_array[tile_array.find(selected_tile) - 1]
	if Input.is_action_just_pressed("switch_tile_right"):	
		if selected_layer >= mesh_manager.LAYERS.size():
			selected_layer = mesh_manager.LAYERS.size() - 1
		if (tile_array.find(selected_tile) + 1) < tile_array.size():
			selected_tile = tile_array[tile_array.find(selected_tile) + 1]
	if Input.is_action_just_pressed("flip_key") && !Input.is_action_pressed("control"):
		mesh_manager.flipped = !mesh_manager.flipped
	if Input.is_action_just_pressed("q_key"):
		selected_tile = "empty"
	
	mesh_manager.update_chunk_visibility(camera)
	queue_redraw()
	pass

func _draw():
	# map size rectangle. there for an indicator
	var colour = Color(0.12, 0.12, 0.12, 0.765)
	draw_rect(Rect2(Vector2(0, 0), Vector2i(mesh_manager.current_map.size) * Vector2i(mesh_manager.TILE_SIZE)), colour, true)
