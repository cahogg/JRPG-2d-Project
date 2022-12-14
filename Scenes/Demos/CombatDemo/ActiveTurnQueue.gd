# Queues and delegates turns for all battlers.
class_name ActiveTurnQueue
extends Node

var _party_members := []
var _opponents := []

# All battlers in the encounter are children of this node. We can get a list of all of them with
# get_children()
onready var battlers := get_children()


func _ready() -> void:
	for battler in battlers:
		# Listen to each battler's ready_to_act signal, binding a reference to the battler to the callback.
		battler.connect("ready_to_act", self, "_on_Battler_ready_to_act", [battler])
		if battler.is_party_member:
			_party_members.append(battler)
		else:
			_opponents.append(battler)

# Allows pausing the Active Time Battle during combat intro, a cutscene, or combat end.
var is_active := true setget set_is_active
# Multiplier for the global pace of battle, to slow down time while the player is making decisions.
# This is meant for accessibility and to control difficulty.
var time_scale := 1.0 setget set_time_scale


# Updates `is_active` on each battler.
func set_is_active(value: bool) -> void:
	is_active = value
	for battler in battlers:
		battler.is_active = is_active


# Updates `time_scale` on each battler.
func set_time_scale(value: float) -> void:
	time_scale = value
	for battler in battlers:
		battler.time_scale = time_scale

func _on_Battler_ready_to_act(battler: Battler) -> void:
	_play_turn(battler)

func _play_turn(battler: Battler) -> void:
	var action_data: ActionData
	var targets := []
	battler.stats.energy += 1
	
	# The code below makes a list of selectable targets using `Battler.is_selectable`
	var potential_targets := []
	var opponents := _opponents if battler.is_party_member else _party_members
	for opponent in opponents:
		if opponent.is_selectable:
			potential_targets.append(opponent)
	if battler.is_player_controlled():
		# We'll use the selection in the next lesson to move playable battlers
		# forward. This value will also make the Heads-Up Display (HUD) for this
		# battler move forward.
		battler.is_selected = true
		# This line slows down time while the player selects an action and
		# target. The function `set_time_scale()` recursively assigns that value
		# to all characters on the battlefield.
		set_time_scale(0.05)

		# Here is the meat of the player's turn. We use a while loop to wait for
		# the player to select a valid action and target(s).
		#
		# For now, we have two boilerplate asynchronous functions,
		# `_player_select_action_async()` and `_player_select_targets_async()`,
		# that respectively return an action to perform and an array of targets.
		# This seemingly complex setup will allow the player to cancel
		# operations in menus.
		var is_selection_complete := false
		# The loop keeps running until the player selected an action and target.
		while not is_selection_complete:
			# The player has to first select an action, then a target.
			# We store the selected action in the `action_data` variable defined
			# at the start of the function.
			action_data = yield(_player_select_action_async(battler), "completed")
			# If an action applies an effect to the battler only, we
			# automatically set it as the target.
			if action_data.is_targeting_self:
				targets = [battler]
			else:
				targets = yield(_player_select_targets_async(action_data, potential_targets), "completed")
			# If the player selected a correct action and target, we can break
			# out of the loop. I'm using a variable here to make the code
			# readable and clear. You could write a `while true` loop and use
			# the break keyword instead, but doing so makes the code less
			# explicit.
		is_selection_complete = action_data != null && targets != []
		# The player-controlled battler is ready to act. We reset the time scale
		# and deselect the battler.
		set_time_scale(1.0)
		battler.is_selected = false
	else:
		action_data = battler.actions[0]
		targets = [potential_targets[0]]

# We must use a placeholder `yield()` call to turn the methods into coroutines.
# Otherwise, we can't use `yield()` in the `_play_turn()` method.
func _player_select_action_async(battler: Battler) -> ActionData:
	yield(get_tree(), "idle_frame")
	return battler.actions[0]


func _player_select_targets_async(_action: ActionData, opponents: Array) -> Array:
	yield(get_tree(), "idle_frame")
	return [opponents[0]]
