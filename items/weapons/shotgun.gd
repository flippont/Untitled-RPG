class_name Shotgun
extends Weapon

@export var pellets := 6
@export var spread := 12.0

var ammo := 5
var max_ammo := 5
var reload_time := 2.0
var reloading := false
var muzzle_offset = Vector2(30, 0)

func process(delta):
	super(delta)
	if reloading:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			ammo = max_ammo
			reloading = false

func trigger_pressed():
	if reloading:
		return
	if cooldown_timer > 0:
		return
	shoot((owner.get_global_mouse_position() - owner.global_position).normalized())

func shoot(direction):
	ammo -= 1
	cooldown_timer = 0.5
	for i in pellets:
		var projectile = preload("res://projectile/projectile.tscn").instantiate()
		var angle = deg_to_rad(randf_range(-spread, spread))
		projectile.global_position = owner.arm_pivot.global_position + muzzle_offset.rotated(direction.angle())
		projectile.velocity = direction.rotated(angle) * randf_range(700,1000)
		projectile.damage = 2
		owner.get_tree().current_scene.add_child(projectile)
	if ammo == 0:
		reloading = true
		cooldown_timer = reload_time
	owner.recoil(direction, 150.0)
