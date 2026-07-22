class_name Weapon
extends Resource
@export var weapon_name := ""
@export var damage := 1.0
@export var cooldown := 0.2
var owner
var cooldown_timer := 0.0

func equip(player):
	owner = player

func process(delta):
	cooldown_timer = max(cooldown_timer - delta, 0)

func shoot(_direction: Vector2):
	pass
func trigger_pressed():
	pass
func trigger_released():
	pass
func special():
	pass
