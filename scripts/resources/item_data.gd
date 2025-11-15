class_name ItemData
extends Resource

## Base template for all items in the game
## Create individual .tres files for each item (wood, stone, tools, etc.)

# Basic Info
@export_group("Basic Info")
@export var item_name: String = "Item"
@export var item_id: String = "item"  # Unique identifier
@export_multiline var description: String = ""
@export var icon: Texture2D

# Item Classification
@export_group("Classification")
@export var item_type: ItemType = ItemType.RESOURCE
@export var item_category: ItemCategory = ItemCategory.MATERIAL

enum ItemType {
	RESOURCE,    # Raw materials (wood, stone, ore)
	TOOL,        # Pickaxe, shovel, etc.
	WEAPON,      # Combat items
	CONSUMABLE,  # Food, potions
	EQUIPMENT    # Wearable items
}

enum ItemCategory {
	MATERIAL,    # Basic crafting materials
	FOOD,        # Edible items
	MINING,      # Mining-related tools/resources
	FARMING,     # Farming-related items
	COMBAT,      # Combat items
	MISC         # Other items
}

# Gathering Properties
@export_group("Gathering")
@export var can_be_gathered: bool = true
@export var gather_time: float = 2.0  # Seconds to hold F to gather
@export_multiline var gather_hint: String = "Hold F to gather"

# Inventory Properties
@export_group("Inventory")
@export var slots_taken: int = 1  # How many inventory slots this item occupies
@export var max_stack: int = 99  # Maximum stack size (1 = doesn't stack)
@export var quickslot_max_stack: int = 0  # Max stack in quickslots (0 = use max_stack value)
@export var weight: float = 1.0  # Affects climbing speed, carry capacity

# Item Stats (for tools/weapons)
@export_group("Stats", "stat_")
@export var stat_durability: int = 0  # 0 = doesn't break (resources)
@export var stat_mining_power: int = 0  # For tools
@export var stat_attack_damage: int = 0  # For weapons
@export var stat_nutrition: int = 0  # For food

# Durability Costs (how much durability each action uses)
@export_group("Durability Costs", "durability_cost_")
@export var durability_cost_attack: int = 5  # Cost when used for attacking
@export var durability_cost_dig: int = 1  # Cost when used for digging
@export var durability_cost_mine: int = 2  # Cost when mining hard materials
@export var durability_cost_gather: int = 1  # Cost when used to gather resources
@export var durability_cost_chop: int = 1  # Cost when chopping wood

# Attack Properties (for weapons/tools that can attack)
@export_group("Attack Properties", "attack_")
@export var attack_windup_time: float = 0.0  # Seconds to hold before attack executes
@export var attack_cooldown: float = 0.5  # Delay between attacks
@export var attack_range: float = 50.0  # Attack reach in pixels
@export var attack_animation: String = ""  # Animation name (e.g., "shovel_attack")

# Action Mode Properties (what happens when right-clicking with this item)
@export_group("Action Mode", "action_mode_")
@export var action_mode_movement_speed: float = 0.0  # Movement speed multiplier (0 = stop, 0.5 = half speed, 1.0 = normal, 1.5 = faster)
@export var action_mode_can_rotate: bool = true  # Can the player rotate/aim while in action mode?
@export var action_mode_animation: String = ""  # Special animation to play (e.g., "aiming", "blocking")
@export var action_mode_description: String = "Action mode"  # What to call this mode (e.g., "Aiming", "Blocking", "Charging")

# Tool Bonuses (passive benefits when equipped)
@export_group("Tool Bonuses", "tool_")
@export var tool_gathering_speed_bonus: float = 1.0  # Multiplier for gathering (1.5 = 50% faster)
@export var tool_mining_bonus: float = 1.0  # Future: mining speed bonus

# Advanced Properties
@export_group("Advanced")
@export var is_sellable: bool = true
@export var sell_value: int = 10
@export var rarity: Rarity = Rarity.COMMON

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# Methods for item behavior

func get_display_name() -> String:
	"""Get formatted display name"""
	return item_name

func get_total_weight(quantity: int) -> float:
	"""Calculate total weight for a stack"""
	return weight * quantity

func can_stack_with(other: ItemData) -> bool:
	"""Check if this item can stack with another"""
	if other == null:
		return false
	return other.item_id == item_id and max_stack > 1

func get_max_stack_for_quickslot() -> int:
	"""Get the maximum stack size allowed in quickslots"""
	# If quickslot_max_stack is 0 or not set, use the regular max_stack
	if quickslot_max_stack <= 0:
		return max_stack
	# Otherwise use the specified quickslot limit
	return quickslot_max_stack

func get_gather_time_display() -> String:
	"""Get human-readable gather time"""
	return "%.1f seconds" % gather_time

func is_tool() -> bool:
	"""Check if this is a tool"""
	return item_type == ItemType.TOOL

func is_resource() -> bool:
	"""Check if this is a resource"""
	return item_type == ItemType.RESOURCE

func is_consumable() -> bool:
	"""Check if this is consumable"""
	return item_type == ItemType.CONSUMABLE

func is_weapon() -> bool:
	"""Check if this is a weapon"""
	return item_type == ItemType.WEAPON

func can_attack() -> bool:
	"""Check if this item can be used for attacking"""
	return (item_type == ItemType.WEAPON or item_type == ItemType.TOOL) and stat_attack_damage > 0

func has_gathering_bonus() -> bool:
	"""Check if this item provides gathering speed bonus"""
	return tool_gathering_speed_bonus > 1.0
