extends CharacterBody2D

@export var speed = 400
@onready var player_sprite: Node2D = $PlayerSprite
@onready var legs: Sprite2D = $"PlayerSprite/Legs"
@onready var torso: Sprite2D = $"PlayerSprite/Torso"
@onready var head: Sprite2D = $"PlayerSprite/Head"
@onready var frontarm: Sprite2D = $"PlayerSprite/FrontArm"
@onready var backarm: Sprite2D = $"PlayerSprite/BackArm"
@onready var gun: Sprite2D = $"PlayerSprite/Gun"
@onready var arm_pivot = $ArmPivot
@onready var animation_player = $AnimationPlayer
@onready var weapon_manager = $WeaponManager
@export var recoil_damping := 200.0
var recoil_velocity := Vector2.ZERO
@onready var inventory = Inventory

func pickup_item(item_id: String):
	inventory.add_item(item_id)

func _ready() -> void:
	var machine_gun = Shotgun.new()
	$WeaponManager.equip_weapon(machine_gun)

func calculate_pivot_pos(node, target_position):
	if target_position.x < self.global_position.x:
		node.rotation = lerp_angle(node.rotation, -(arm_pivot.global_position - target_position).angle(), (0.5))
	else:
		node.rotation = lerp_angle(node.rotation, (target_position - arm_pivot.global_position).angle(), (0.5))

func flip_sprites(value: bool):
	if value:
		player_sprite.scale.x = 1
	else:
		player_sprite.scale.x = -1

func get_mouse_input():
	var mouse_position = get_global_mouse_position()
	flip_sprites(mouse_position.x > self.global_position.x)
	calculate_pivot_pos(frontarm, mouse_position)
	calculate_pivot_pos(gun, mouse_position)
	calculate_pivot_pos(backarm, mouse_position)

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	if input_direction != Vector2(0,0):
		animation_player.play("walk")
	else:
		animation_player.play("idle")
	var x_input =  Input.get_action_strength("right") - Input.get_action_strength("left")
	var moving_forward = (x_input > 0 and player_sprite.scale.x == 1) or (x_input < 0 and player_sprite.scale.x == -1)
	flip_sprites(moving_forward)

func recoil(direction: Vector2, strength: float):
	recoil_velocity -= direction * strength

func _process(_delta):
	if Input.is_action_pressed("fire"):
		weapon_manager.shoot_pressed()
	if Input.is_action_just_released("fire"):
		weapon_manager.shoot_released()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode >= Key.KEY_0 and event.keycode <= Key.KEY_9:
			var number = event.keycode - Key.KEY_0
			weapon_manager.equip_by_index(number)

func _physics_process(delta):
	get_input()
	get_mouse_input()
	velocity += recoil_velocity
	move_and_slide()
	recoil_velocity = recoil_velocity.move_toward(Vector2.ZERO, recoil_damping * delta)
