extends Node2D
@export var atlas_texture: Texture;
@export var object_root: Node
@export var collision_root: Node
signal map_loaded
const TILE_SIZE = Vector2(32,32)
const CHUNK_SIZE = 15
const LAYERS = ["below", "floor", "collision", "above"]
var screen_size: Vector2 = DisplayServer.screen_get_size()

var chunk_meshes = {}
var multimesh_chunks := {}
var collision_chunks := {}
var tile_path := "res://assets/json/tiles.json"
var tile_json := {}
var current_map := {}
var flipped := false
var objects_list := {}
var object_chunks := {}

# do I need to even create a failsafe for this? if the file didn't work the whole thing goes kaput anyways...
func _ready():
	var json = JSON.new()
	var file = FileAccess.open(tile_path, FileAccess.READ)
	if file:
		json.parse(file.get_as_text())
		tile_json = json.data
		file.close()
	else: 
		push_error("NO TILE FILE FOUND")
		return
	pass

func update_tile_visual(layer:int, x:int, y:int):
	var chunk = Vector2i(int(float(x) / CHUNK_SIZE), int(float(y) / CHUNK_SIZE))
	var multi_mesh = multimesh_chunks[layer][chunk].multimesh
	var start_x = chunk.x * CHUNK_SIZE
	var start_y = chunk.y * CHUNK_SIZE
	var width = mini(CHUNK_SIZE, current_map.size.x - start_x)
	var local_x = x - start_x
	var local_y = y - start_y
	var instance = local_y * width + local_x
	var tile_name = current_map.data[LAYERS[layer]][y][x]
	var flip = tile_name.ends_with("_h")
	if flip:
		tile_name = tile_name.trim_suffix("_h")
	multi_mesh.set_instance_custom_data(instance, Color(tile_json[tile_name].pos[0], tile_json[tile_name].pos[1], flip, 0))
	multi_mesh.set_instance_color(instance, Color.WHITE)

func update_tile(x:int, y:int, tile, layer, flip):
	current_map.data[LAYERS[layer]][y][x] = tile + ("_h" if flip else "")
	update_tile_visual(layer, x, y)

func load_map_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Couldn't open map")
		return {}
	var map := {
		"data": {},
		"name": "",
		"size": Vector2(0, 0),
		"objects": {}
	}
	for i in LAYERS.size():
		map.data[LAYERS[i]] = []
	var file_index = 0;
	while !file.eof_reached():
		var line = file.get_line().strip_edges()
		# the file format is defined here. 
		# line 1: name, line2: size, line3 onwards: data
		if line == "":
			continue
		if file_index == 0: 
			map.name = str(line)
		elif file_index == 1:
			var size = line.split(" ")
			map.size = Vector2(int(size[0]), int(size[1]))
		else:
			var split_line = line.split(" ")
			var data_line = (file_index - 2)
			var data_index = int(floor(data_line / map.size.x))
			for i in LAYERS.size():
				if data_index >= (map.data[LAYERS[i]].size()):
					map.data[LAYERS[i]].append([])
				map.data[LAYERS[i]][data_index].append(split_line[i])
			var x_pos = int(data_line) % int(map.size.x)
			var position_vector = Vector2(x_pos, data_index)
			if split_line.size() > LAYERS.size():
				map.objects[position_vector] = split_line[LAYERS.size()]
		file_index += 1
	return map

func create_new_map(map_name: String, width: int, height: int, default_tile := "empty") -> void:
	# Remove any old chunks
	for layer in multimesh_chunks.values():
		for chunk in layer.values():
			chunk.queue_free()
	multimesh_chunks.clear()
	
	# Remove old objects
	for object in objects_list.values():
		object.queue_free()
	objects_list.clear()
	for chunk in object_chunks.values():
		chunk.queue_free()
	object_chunks.clear()
	
	
	# Create new map dictionary
	current_map = {
		"name": map_name,
		"size": Vector2i(width, height),
		"data": {},
		"objects": {}
	}
	for layer in LAYERS:
		current_map.data[layer] = []
		for y in range(height):
			current_map.data[layer].append([])
			for x in range(width):
				current_map.data[layer][y].append(default_tile)
	for layer in range(LAYERS.size()):
		create_layer_chunks(layer)
	for layer in range(LAYERS.size()):
		build_layer(layer)
	build_collisions()

func load_map(path):
	# Remove any old chunks
	for layer in multimesh_chunks.values():
		for chunk in layer.values():
			chunk.queue_free()
	multimesh_chunks.clear()
	
	# Remove old objects
	for object in objects_list.values():
		object.queue_free()
	objects_list.clear()
	for chunk in object_chunks.values():
		chunk.queue_free()
	object_chunks.clear()

	current_map = load_map_file(path)
	print(current_map.name)
	for layer in range(LAYERS.size()):
		create_layer_chunks(layer)
	for layer in range(LAYERS.size()):
		build_layer(layer)
	for object in current_map.objects:
		if current_map.objects[object] != "none":
			spawn_object(current_map.objects[object], object)
	emit_signal("map_loaded")
	build_collisions()

# in the grand scheme of things it probably is more readable to have a line break every row of tiles
func save_map(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Couldn't save map.")
		return
	# Name
	file.store_line(current_map.name)
	# Size
	file.store_line("%d %d" % [current_map.size.x, current_map.size.y])
	# Tile data
	for y in range(current_map.size.y):
		for x in range(current_map.size.x):
			var line = ""
			for layer in LAYERS:
				line += str(current_map.data[layer][y][x]) + " "
			var pos := Vector2i(x, y)
			if current_map.objects.has(pos):
				line += current_map.objects[pos]
			else: 
				line += "none"
			file.store_line(line.strip_edges())
	file.close()
	
# create the general multimesh for the game
func create_chunk_mesh(_layer:int, _chunk:Vector2i) -> MultiMeshInstance2D:
	var instance := MultiMeshInstance2D.new()
	var shader := load("res://assets/shaders/tilemap.gdshader")
	var mesh_material := ShaderMaterial.new()
	mesh_material.shader = shader
	mesh_material.set_shader_parameter("tile_size", TILE_SIZE)
	mesh_material.set_shader_parameter("atlas_size", atlas_texture.get_size())
	instance.material = mesh_material
	instance.texture = atlas_texture
	var multi_mesh := MultiMesh.new()
	multi_mesh.use_custom_data = true
	multi_mesh.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2(TILE_SIZE.x, -TILE_SIZE.y)
	multi_mesh.mesh = quad
	instance.multimesh = multi_mesh
	add_child(instance)
	return instance

func create_layer_chunks(layer:int):
	multimesh_chunks[layer] = {}
	var chunks_x = ceili(current_map.size.x / float(CHUNK_SIZE))
	var chunks_y = ceili(current_map.size.y / float(CHUNK_SIZE))
	for cy in range(chunks_y):
		for cx in range(chunks_x):
			var chunk = create_chunk_mesh(layer, Vector2i(cx, cy))
			multimesh_chunks[layer][Vector2i(cx, cy)] = chunk
			
func build_layer(layer:int):
	for chunk in multimesh_chunks[layer].keys():
		var multi_mesh = multimesh_chunks[layer][chunk].multimesh
		var start_x = chunk.x * CHUNK_SIZE
		var start_y = chunk.y * CHUNK_SIZE
		var end_x = mini(start_x + CHUNK_SIZE, current_map.size.x)
		var end_y = mini(start_y + CHUNK_SIZE, current_map.size.y)
		var width = end_x - start_x
		var height = end_y - start_y
		multi_mesh.instance_count = width * height
		var instance = 0
		for y in range(start_y, end_y):
			for x in range(start_x, end_x):
				var tile_name = current_map.data[LAYERS[layer]][y][x]
				var flip = tile_name.ends_with("_h")
				if flip:
					tile_name = tile_name.trim_suffix("_h")
				var pos = Vector2(x * TILE_SIZE.x + TILE_SIZE.x * 0.5, y * TILE_SIZE.y + TILE_SIZE.y * 0.5)
				multi_mesh.set_instance_transform_2d(instance, Transform2D(0, pos))
				multi_mesh.set_instance_custom_data(instance, Color(tile_json[tile_name].pos[0], tile_json[tile_name].pos[1], flip, 0))
				multi_mesh.set_instance_color(instance, Color.WHITE)
				instance += 1

func get_camera_rect(camera: Camera2D) -> Rect2:
	var half_size = get_viewport().get_visible_rect().size * camera.zoom
	return Rect2(camera.global_position - half_size * 0.5, half_size)
	
func update_chunk_visibility(camera: Camera2D):
	var view_rect = get_camera_rect(camera)
	for layer in multimesh_chunks.values():
		for chunk_pos in layer.keys():
			var chunk_rect = Rect2(Vector2(chunk_pos * CHUNK_SIZE) * TILE_SIZE, Vector2(CHUNK_SIZE, CHUNK_SIZE) * TILE_SIZE)
			var item_visible = view_rect.intersects(chunk_rect)
			layer[chunk_pos].visible = item_visible
			if object_chunks.has(chunk_pos):
				object_chunks[chunk_pos].visible = item_visible

func build_collisions():
	# Remove old chunks
	for chunk in collision_chunks.values():
		chunk.queue_free()
	collision_chunks.clear()
	var map = current_map.data["collision"]
	var chunks_x = ceili(current_map.size.x / float(CHUNK_SIZE))
	var chunks_y = ceili(current_map.size.y / float(CHUNK_SIZE))
	for cy in range(chunks_y):
		for cx in range(chunks_x):
			var body := StaticBody2D.new()
			collision_root.add_child(body)
			collision_chunks[Vector2i(cx, cy)] = body
			var start_x = cx * CHUNK_SIZE
			var start_y = cy * CHUNK_SIZE
			var end_x = mini(start_x + CHUNK_SIZE, current_map.size.x)
			var end_y = mini(start_y + CHUNK_SIZE, current_map.size.y)
			for y in range(start_y, end_y):
				var x = start_x
				while x < end_x:
					var tile = map[y][x]
					if tile == "empty":
						x += 1
						continue
					# Find horizontal run length
					var run_start = x
					while x < end_x:
						tile = map[y][x]
						if tile == "empty":
							break
						x += 1
					var run_length = x - run_start
					var shape := CollisionShape2D.new()
					var rect := RectangleShape2D.new()
					rect.size = Vector2(run_length * TILE_SIZE.x, TILE_SIZE.y)
					shape.shape = rect
					shape.position = Vector2(run_start * TILE_SIZE.x + rect.size.x * 0.5, y * TILE_SIZE.y + TILE_SIZE.y * 0.5)
					body.add_child(shape)

func spawn_object_visual(tile_name: String, tile_pos: Vector2i):
	var object := ObjectRenderer.new()
	object.name = "%s_%d_%d" % [tile_name, tile_pos.x, tile_pos.y]
	var chunk = Vector2i(int(float(tile_pos.x) / CHUNK_SIZE), int(float(tile_pos.y) / CHUNK_SIZE))
	var local = tile_pos - chunk * CHUNK_SIZE
	object.position = Vector2(local) * TILE_SIZE + TILE_SIZE / 2
	object.atlas = atlas_texture
	object.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	object.tile_json = tile_json
	object.tile_name = tile_name
	return object
	
func spawn_object(tile_name: String, tile_pos: Vector2i):
	if objects_list.has(tile_pos):
		var object = objects_list[tile_pos]
		object.tile_name = tile_name
		object.queue_redraw()
	else:
		var object = spawn_object_visual(tile_name, tile_pos)
		current_map.objects[tile_pos] = tile_name
		objects_list[tile_pos] = object
		var chunk = Vector2i(int(float(tile_pos.x) / CHUNK_SIZE), int(float(tile_pos.y) / CHUNK_SIZE))
		get_object_chunk(chunk).add_child(object)
	current_map.objects[tile_pos] = tile_name

func remove_object(tile_pos: Vector2i):
	if objects_list.has(tile_pos):
		objects_list[tile_pos].queue_free()
		objects_list.erase(tile_pos)
		current_map.objects.erase(tile_pos)

func get_object_chunk(chunk_pos: Vector2i) -> Node2D:
	if object_chunks.has(chunk_pos):
		return object_chunks[chunk_pos]
	var chunk := Node2D.new()
	chunk.position = Vector2(chunk_pos * CHUNK_SIZE) * TILE_SIZE
	chunk.y_sort_enabled = true
	object_root.add_child(chunk)
	object_chunks[chunk_pos] = chunk
	print(objects_list)
	return chunk

class ObjectRenderer:
	extends Node2D
	var atlas: Texture2D
	var tile_json: Dictionary
	var tile_name: String
	func _ready():
		queue_redraw()
	func _draw():
		var data = tile_json[tile_name]
		for part in data.group:
			var tile_data = tile_json[part.tile]
			var src = Rect2(Vector2(tile_data.pos[0], tile_data.pos[1]) * TILE_SIZE, TILE_SIZE)
			var distance = Rect2(Vector2(part.offset[0], part.offset[1]) * TILE_SIZE - TILE_SIZE / 2, TILE_SIZE)
			draw_texture_rect_region(atlas, distance, src)
