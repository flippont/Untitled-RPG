class_name MachineGun
extends Weapon

@export var fire_rate := 15.0

var heat := 0.0
var max_heat := 2000.0
var overheated := false
var muzzle_offset = Vector2(30, 0)

func process(delta):
	super(delta)
	if overheated:
		heat -= delta * 40
		if heat <= 0:
			heat = 0
			overheated = false
	else:
		heat = max(heat - delta * 15, 0)

func trigger_pressed():
	if overheated:
		return
	if cooldown_timer > 0:
		return
	shoot((owner.get_global_mouse_position() - owner.global_position).normalized())

func shoot(direction):
	var projectile = preload("res://projectile/projectile.tscn").instantiate()
	projectile.global_position = owner.arm_pivot.global_position + muzzle_offset.rotated(direction.angle())
	projectile.damage = damage
	projectile.speed = 900
	projectile.velocity = direction.rotated(randf_range(-0.02,0.02))*projectile.speed
	owner.get_tree().current_scene.add_child(projectile)
	heat += 5
	if heat >= max_heat:
		overheated = true
	owner.recoil(direction, 10.0)
