extends Label
@onready var mesh_manager: Node2D = $"../../MeshManager"
@onready var editor: Node2D = $"../.."
@onready var cursor: Node2D = $"../../Cursor"
@onready var camera: Node2D = $"../../Camera2D"

func _ready() -> void:
	pass

enum InputMode {
	NONE,
	MAP_NAME,
	MAP_SIZE,
	OPEN_MAP,
	FIND_TILE
}

var input_mode := InputMode.NONE
var input_text := ""
var input_label := ""
var new_map_name := ""
var new_map_creation := false
var open_existing_map := false
var find_tile := false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	self.text = "DEBUG_MODE\n"
	self.text += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
	var layer = "layer_one"
	if editor.selected_tile == "empty":
		var layers = mesh_manager.LAYERS.duplicate()
		layers.append("objects")
		layer = layers[editor.selected_layer]
	else:
		layer = str(mesh_manager.LAYERS[editor.selected_layer])
	if new_map_creation or open_existing_map or find_tile:
		self.text += input_label + " " + input_text + "\n"
	else:
		self.text += "Map Name: " + mesh_manager.current_map.name + "\n"
		self.text += "Map Size: " + str(mesh_manager.current_map.size) + "\n"        
		self.text += "Selected Layer: " + layer + "\n"
		self.text += "Texture Flipped: " + str(mesh_manager.flipped) + "\n"
		self.text += "Selected Texture: " + str(editor.selected_tile) + "\n"
		self.text += "Selected Tile: " + str(cursor.hover_tile) + "\n"
	pass

func _draw():
	var data = mesh_manager.tile_json[editor.selected_tile]
	var preview_size := 100
	var origin := Vector2(20, get_viewport_rect().size.y - preview_size - 20)
	# for the objects to render every tile.
	if data.has("group"):
		var max_offset := Vector2i.ZERO
		for piece in data.group:
			var offset := Vector2i(piece.offset[0], piece.offset[1])
			max_offset.x = max(max_offset.x, offset.x)
			max_offset.y = max(max_offset.y, offset.y)
		for piece in data.group:
			var tile = mesh_manager.tile_json[piece.tile]
			var src = Rect2(Vector2(tile.pos[0], tile.pos[1]) * mesh_manager.TILE_SIZE, mesh_manager.TILE_SIZE)
			var offset = Vector2(piece.offset[0] - max_offset.x, piece.offset[1] - max_offset.y) * preview_size
			draw_set_transform(origin + offset, 0, Vector2.ONE)
			draw_texture_rect_region(mesh_manager.atlas_texture, Rect2(Vector2.ZERO, Vector2(preview_size, preview_size)), src)
	else:
		var src = Rect2(Vector2(data.pos[0], data.pos[1]) * mesh_manager. TILE_SIZE,mesh_manager.TILE_SIZE)
		
		if mesh_manager.flipped:
			draw_set_transform(origin + Vector2(preview_size, 0), 0, Vector2(-1, 1))
		else:
			draw_set_transform(origin, 0, Vector2.ONE)
		draw_texture_rect_region(mesh_manager.atlas_texture, Rect2(Vector2.ZERO, Vector2(preview_size, preview_size)), src)

func handle_text_input(event: InputEventKey):
	if event.keycode == KEY_BACKSPACE:
		if input_text.length() > 0:
			input_text = input_text.substr(0, input_text.length() - 1)
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		submit_input()
		return
	elif event.unicode > 31:
		input_text += char(event.unicode)

func submit_input():
	match input_mode:
		InputMode.MAP_NAME:
			new_map_name = input_text
			input_text = ""
			input_label = "New Map Size:"
			input_mode = InputMode.MAP_SIZE
		InputMode.MAP_SIZE:
			var split = input_text.split(" ")
			if split.size() != 2:
				input_label = "Invalid size! Use: width height"
				input_text = ""
				return
			var width = int(split[0])
			var height = int(split[1])
			mesh_manager.create_new_map(new_map_name, width, height)
			input_mode = InputMode.NONE
			input_text = ""
			new_map_creation = false
		InputMode.OPEN_MAP:
			mesh_manager.load_map("res://assets/maps/" + input_text + ".txt")
			input_text = ""
			open_existing_map = false
		InputMode.FIND_TILE:
			if editor.tile_array.find(input_text) >= 0:
				editor.selected_tile = input_text
			input_text = ""
			editor.selected_layer = 0
			find_tile = false

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			new_map_creation = false
			open_existing_map = false
			find_tile = false
			return
		if event.ctrl_pressed and event.keycode == KEY_N:
			new_map_creation = true
			input_mode = InputMode.MAP_NAME
			input_label = "New Map Name:"
			return
		if event.ctrl_pressed and event.keycode == KEY_O:
			open_existing_map = true
			input_mode = InputMode.OPEN_MAP
			input_label = "Open Map:"
			return
		if event.ctrl_pressed and event.keycode == KEY_S:
			mesh_manager.save_map("res://assets/maps/" + str(mesh_manager.current_map.name) + ".txt")
			return
		if event.ctrl_pressed and event.keycode == KEY_F:
			input_label = "Find Tile:"
			find_tile = true
			input_mode = InputMode.FIND_TILE
			return
		if new_map_creation or open_existing_map or find_tile:
			handle_text_input(event)
		else:
			if event.keycode == KEY_ENTER:
				get_tree().change_scene_to_file("res://game/game.tscn")
