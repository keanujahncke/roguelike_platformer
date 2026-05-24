extends HBoxContainer

var player: CharacterBody2D
var slots_dict: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if "ability_name" in child and child.ability_name != "":
			slots_dict[child.ability_name] = child


func _process(_delta: float) -> void:
	if not player or not player.has_node("Abilities"):
		return
		
	for name in slots_dict.keys():
		var pascal_name = name.to_pascal_case() + "Ability"
		var node_path = "Abilities/" + pascal_name
		
		if player.has_node(node_path):
			var ability_node = player.get_node(node_path)
			
			if "unlocked" in ability_node:
				slots_dict[name].set_unlocked(ability_node.unlocked)
			
			if "cooldown_left" in ability_node and "cooldown_max" in ability_node:
				slots_dict[name].update_cooldown(ability_node.cooldown_left, ability_node.cooldown_max)
		else:
			print("UI Error: Could not find player node at path: ", node_path)
