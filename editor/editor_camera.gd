extends Camera2D
const camera_pan = 10
@onready var mesh_manager: Node2D = $"../MeshManager"

var shifting := false
func _ready() -> void:
	mesh_manager.map_loaded.connect(center_camera)
func _physics_process(_delta: float) -> void:
	# haha lol shifting
	if Input.is_action_just_pressed("shift_pressed"):
		shifting = true
	if Input.is_action_just_released("shift_pressed"):
		shifting = false
	if !shifting:
		return
	
	# there was definitely a better way to do this bruh
	if Input.is_action_pressed("arrow_right"):
		global_position += Vector2.RIGHT * camera_pan
	if Input.is_action_pressed("arrow_left"):
		global_position += Vector2.LEFT * camera_pan
	if Input.is_action_pressed("arrow_up"):
		global_position += Vector2.UP * camera_pan
	if Input.is_action_pressed("arrow_down"):
		global_position += Vector2.DOWN * camera_pan

func center_camera():
	# I don't even know if this is right. TODO: check later
	var map_size_pixels = get_viewport_rect().size - mesh_manager.current_map.size * mesh_manager.TILE_SIZE
	self.position = -map_size_pixels * 0.5
