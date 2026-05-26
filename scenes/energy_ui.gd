extends CanvasLayer

@export var loadout_menu_node: Control 
@onready var label: Label = $HBoxContainer/Label

func _ready():
	update_energy_ui()
	get_tree().node_added.connect(_on_node_added)
	
	for child in get_tree().get_nodes_in_group("collectibles"):
		_connect_collectible(child)


func _on_node_added(node: Node):
	if node.is_in_group("collectibles"):
		_connect_collectible(node)


func _connect_collectible(collectible: Node):
	if collectible.has_signal("collected"):
		if not collectible.collected.is_connected(_on_collectible_picked_up):
			collectible.collected.connect(_on_collectible_picked_up)


func _on_collectible_picked_up(id: String, value: int):
	if save_data.has_collected(id):
		update_energy_ui()
		return
	
	save_data.mark_collected(id)
	save_data.add_energy(value)
	
	update_energy_ui()


func update_energy_ui():
	label.text = str(save_data.get_max_energy())
