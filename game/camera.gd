extends Camera2D

@export var map: Node # Your map renderer script

func _ready():
	make_current()
	map.map_loaded.connect(update_limits)

func update_limits():
	var map_size = map.current_map.size * map.TILE_SIZE

	limit_left = 0
	limit_top = 0
	limit_right = int(map_size.x)
	limit_bottom = int(map_size.y)
