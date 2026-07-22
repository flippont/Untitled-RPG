extends Node2D
@onready var mesh_manager: Node2D = $"../MeshManager"
@onready var editor: Node2D = $".."
@onready var camera: Camera2D = $"../Camera2D"

var hover_tile := Vector2i(-1, -1)
var painting := false
var keyboard_control := false
var move_timer := 0.0
const MOVE_DELAY := 0.15

func _ready() -> void:
	self.z_as_relative = false
	self.z_index = 1000

func _process(delta: float) -> void:
	move_timer -= delta
	if move_timer <= 0.0:
		var dir := Vector2i.ZERO
		if Input.is_action_pressed("arrow_right"):
			dir.x += 1
		if Input.is_action_pressed("arrow_left"):
			dir.x -= 1
		if Input.is_action_pressed("arrow_down"):
			dir.y += 1
		if Input.is_action_pressed("arrow_up"):
			dir.y -= 1
		if dir != Vector2i.ZERO:
			keyboard_control = true
			hover_tile += dir
			move_timer = MOVE_DELAY

		# Switch back to mouse control if the mouse moves
	var mouse_velocity = Input.get_last_mouse_velocity()
	if mouse_velocity.length() > 0.0:
		keyboard_control = false

	if !keyboard_control || Input.is_action_just_released("shift_pressed"):
		var mouse = to_local(get_global_mouse_position())
		hover_tile = Vector2i(floor(mouse.x / mesh_manager.TILE_SIZE.x), floor(mouse.y / mesh_manager.TILE_SIZE.y))
	
	if camera.shifting:
		hover_tile = Vector2i(-1,-1)
	
	if Input.is_action_pressed("space_pressed"):
		paint_at_cursor()
	queue_redraw()

func _draw():
	if camera.shifting:
		return
	var colour = Color(0.988, 0.133, 0.133, 0.5)
	if hover_tile.x < 0 or hover_tile.y < 0 or hover_tile.x >= mesh_manager.current_map.size.x or hover_tile.y >= mesh_manager.current_map.size.y:
		colour = Color(0.133, 0.133, 0.133, 1.0)
	var pos = Vector2(hover_tile) * mesh_manager.TILE_SIZE 
	draw_rect(Rect2(pos, mesh_manager.TILE_SIZE), colour, true)

func paint_at_cursor():
	if hover_tile.x < 0 or hover_tile.y < 0:
		return
	if hover_tile.x >= mesh_manager.current_map.size.x:
		return
	if hover_tile.y >= mesh_manager.current_map.size.y:
		return
	var data = mesh_manager.tile_json[editor.selected_tile]
	if data.get("object", false):
		mesh_manager.spawn_object(editor.selected_tile, Vector2i(hover_tile.x, hover_tile.y))
	elif editor.selected_tile == "empty" and editor.selected_layer >= mesh_manager.LAYERS.size():
		mesh_manager.remove_object(Vector2i(hover_tile.x, hover_tile.y))
	else:
		mesh_manager.update_tile(hover_tile.x, hover_tile.y, editor.selected_tile, editor.selected_layer, mesh_manager.flipped)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			painting = event.pressed
			if painting:
				paint_at_cursor()
	elif event is InputEventMouseMotion and painting:
		paint_at_cursor()
