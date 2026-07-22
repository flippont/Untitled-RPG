extends Area2D

@export var speed := 800.0
@export var damage := 1.0
@export var lifetime := 2.0

var velocity := Vector2.ZERO
var collided := false

@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D
@onready var particles := $GPUParticles2D

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if collided:
		return
	global_position += velocity * delta
	if velocity.length_squared() > 0:
		rotation = velocity.angle()
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if collided:
		return
	collided = true
	if body.has_method("damage"):
		body.damage(damage)
	sprite.visible = false
	collision.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	queue_free()
