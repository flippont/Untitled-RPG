extends Node

var current_weapon : Weapon
@export var weapons: Array[Weapon]
var current_index := 0

func equip_weapon(weapon : Weapon):
	current_weapon = weapon
	current_weapon.equip(get_parent())
func equip_by_index(index: int):
	print(weapons)
	if index < 0 or index >= weapons.size():
		return
	current_index = index
	current_weapon = weapons[index]
	current_weapon.equip(get_parent())
	
func _process(delta):
	if current_weapon:
		current_weapon.process(delta)
func shoot_pressed():
	current_weapon.trigger_pressed()
func shoot_released():
	current_weapon.trigger_released()
func special():
	current_weapon.special()
func add_weapon(weapon: Weapon):
	weapons.append(weapon)
