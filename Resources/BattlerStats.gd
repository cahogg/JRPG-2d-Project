# Stores and manages the battler's base stats like health, energy, and base
# damage.
extends Resource
class_name BattlerStats

# Emitted when a character has no `health` left.
signal health_depleted
# Emitted every time the value of `health` changes.
# We will use it to animate the life bar.
signal health_changed(old_value, new_value)
# Same as above, but for the `energy`.
signal energy_changed(old_value, new_value)


# The battler's maximum health.
export var max_health := 100.0
export var max_energy := 6

export var base_attack := 10.0 setget set_base_attack
export var base_defense := 10.0 setget set_base_defense
export var base_speed := 70.0 setget set_base_speed
export var base_hit_chance := 100.0 setget set_base_hit_chance
export var base_evasion := 0.0 setget set_base_evasion


# The values below are meant to be read-only.
var attack := base_attack
var defense := base_defense
var speed := base_speed
var hit_chance := base_hit_chance
var evasion := base_evasion

# Note that due to how Resources work, in Godot 3.2, health will not have a
# value of `max_health`. This is why we have the function `reinitialize()`
# below. Each battler should call it when the encounter starts.
# This happens because a resource's initialization happens when you create it 
# in the editor to serialize it, not when you load it in the game.
var health := max_health setget set_health
var energy := 0 setget set_energy

var _attack := base_attack setget , get_attack
# ...

func get_attack() -> float:
	return attack

func reinitialize() -> void:
	set_health(max_health)


func set_health(value: float) -> void:
	var health_previous := health
	# We use `clamp()` to ensure the value is always in the [0.0, max_health]
	# interval.
	health = clamp(value, 0.0, max_health)
	emit_signal("health_changed", health_previous, health)
	# As we are working with decimal values, using the `==` operator for
	# comparisons isn't safe. Instead, we need to call `is_equal_approx()`.
	if is_equal_approx(health, 0.0):
		emit_signal("health_depleted")


func set_energy(value: int) -> void:
	var energy_previous := energy
	# Energy works with whole numbers in this demo but the `clamp()` function
	# returns a floating-point value. You can let the compiler cast the value to
	# an integer, which will trigger a warning. I prefer to always do it
	# explicitly to remind myself that I'm working with integers here.
	energy = int(clamp(value, 0.0, max_energy))
	emit_signal("energy_changed", energy_previous, energy)
	
func set_base_attack(value: float) -> void:
	base_attack = value
	_recalculate_and_update("attack")


func set_base_defense(value: float) -> void:
	base_defense = value
	_recalculate_and_update("defense")


func set_base_speed(value: float) -> void:
	base_speed = value
	_recalculate_and_update("speed")


func set_base_hit_chance(value: float) -> void:
	base_hit_chance = value
	_recalculate_and_update("hit_chance")


func set_base_evasion(value: float) -> void:
	base_evasion = value
	_recalculate_and_update("evasion")
