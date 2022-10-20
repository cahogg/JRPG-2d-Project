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

# A list of all properties that can receive bonuses.
const UPGRADABLE_STATS = [
	"max_health", "max_energy", "attack", "defense", "speed", "hit_chance", "evasion"
]

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

# The property below stores a list of modifiers for each property listed in
# `UPGRADABLE_STATS`.
# The value of a modifier can be any floating-point value, positive or negative.
var _modifiers := {}

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

# Initializes keys in the modifiers dict, ensuring they all exist.
func _init() -> void:
	for stat in UPGRADABLE_STATS:
		_modifiers[stat] = {
			# Each stat now have two dictionaries, `value` and `rate`, to later make it easy 
			# to calculate final stats.
			value = {},
			rate = {}
		}

# Adds a value-based modifier. The value gets added to the stat `stat_name` after applying
# rate-based modifiers.
func add_value_modifier(stat_name: String, value: float) -> void:
	# I miss some features from languages like Python here, that would allow for a more explicit 
	# syntax.
	_add_modifier(stat_name, value, 0.0)


# Adds a rate-based modifier. A value of `0.2` represents an increase in 20% of the stat `stat_name`.
func add_rate_modifier(stat_name: String, rate: float) -> void:
	_add_modifier(stat_name, 0.0, rate)


# Adds either a value-based or a rate-based modifier. Notice I'm using a third argument with a 
# default value of `0.0`.
func _add_modifier(stat_name: String, value: float, rate := 0.0) -> int:
	assert(stat_name in UPGRADABLE_STATS, "Trying to add a modifier to a nonexistent stat.")
	var id := -1

	# If the argument `value` is not `0.0`, we register a value-based modifier.
	if not is_equal_approx(value, 0.0):
		# Generates a new unique id for the "value" key.
		id = _generate_unique_id(stat_name, true)
		_modifiers[stat_name]["value"][id] = value
	# If the argument `value` is not `0.0`, we register a rate-based modifier.
	if not is_equal_approx(rate, 0.0):
		# Generates a new unique id for the "rate" key.
		id = _generate_unique_id(stat_name, false)
		_modifiers[stat_name]["rate"][id] = rate

	_recalculate_and_update(stat_name)
	return id


func _recalculate_and_update(stat: String) -> void:
	var value: float = get("base_" + stat)

	# We first get and sum all rate-based multipliers.
	var modifiers_multiplier: Array = _modifiers[stat]["rate"].values()
	var multiplier := 1.0
	for modifier in modifiers_multiplier:
		multiplier += modifier
	# Then, we multiply the base stat's value, if necessary.
	if not is_equal_approx(multiplier, 1.0):
		value *= multiplier

	# And we add all value-based modifiers.
	var modifiers_value: Array = _modifiers[stat]["value"].values()
	for modifier in modifiers_value:
		value += modifier

	value = round(max(value, 0.0))
	set(stat, value)


func _generate_unique_id(stat_name: String, is_value_modifier: bool) -> int:
	# We now use a boolean to pick the right key and generate a corresponding id.
	var type := "value" if is_value_modifier else "rate"
	var keys: Array = _modifiers[stat_name][type].keys()
	if keys.empty():
		return 0
	else:
		return keys.back() + 1
