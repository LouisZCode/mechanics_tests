# Debug Commands

This file contains two ways to modify game stats while playing:
1. **F1 In-Game Console** (Recommended) - Simple commands you can type while playing
2. **F4 Godot Console** (Advanced) - Full GDScript access

---

## 🎮 F1 IN-GAME DEBUG CONSOLE (Recommended)

Press **F1** while playing to open the in-game debug console. Type commands directly and press Enter to execute.

### Quick Reference

Type `help` in console to see all commands. Here are the most useful:

**Stats:**
- `speed 300` - Set movement speed to 300
- `climb_speed 200` - Set climbing speed to 200
- `heal 50` - Restore 50 health
- `damage 25` - Take 25 damage
- `energy 100` - Restore 100 energy
- `reset` - Reset all stats to default

**Upgrades:**
- `upgrade movement_speed_1` - Apply movement speed upgrade
- `upgrade gathering_speed_1` - Apply gathering speed upgrade
- `upgrade inventory_upgrade_1` - Add 5 inventory slots
- `upgrade gathering_range_1` - Increase gathering range
- `upgrade weight_capacity_1` - Increase weight capacity

**Items & Equipment:**
- `give wood 10` - Add 10 wood to inventory (instant)
- `give shovel 1 true` - Add shovel to quickslot (for attacking/gathering)
- `additem stone 5` - Spawn 5 stone items around player
- `equip 0` - Equip quickslot 0 (makes it your active tool)

**Teleport:**
- `goto spawn` - Teleport to spawn point
- `goto wall` - Teleport to climbable wall
- `goto 1000 500` - Teleport to coordinates (x, y)
- `locations` - List all available teleport locations

**Utility:**
- `help` - Show all available commands
- `clear` - Clear console output
- `items` - List all available items (wood, stone, ore, shovel)
- `locations` - List all teleport locations

### Command Features

- **Up/Down Arrow Keys** - Navigate command history
- **Auto-pause** - Game pauses when console is open
- **Color-coded Output** - Green for success, red for errors, yellow for commands
- **Press F1 again** - Close console and resume game

---

### Detailed Command Reference

#### General Commands

**help**
- Shows all available commands with descriptions
- Example: `help`

**clear**
- Clears the console output log
- Example: `clear`

**locations**
- Lists all predefined teleport locations
- Shows: spawn, wall, ground and their coordinates
- Example: `locations`

**items**
- Lists all available items with names and weights
- Shows: wood (0.5kg), stone (1.5kg), ore (3.0kg)
- Example: `items`

---

#### Stat Modification Commands

**speed \<value\>**
- Sets player movement speed in pixels per second
- Default: 170
- Example: `speed 300` - Move super fast!
- Example: `speed 50` - Move in slow motion

**climb_speed \<value\>**
- Sets climbing speed in pixels per second
- Default: 100
- Example: `climb_speed 200` - Climb walls twice as fast
- Example: `climb_speed 50` - Slow climbing

**heal \<amount\>**
- Restores player health
- Max health: 100
- Example: `heal 50` - Restore 50 HP
- Example: `heal 100` - Restore to full health

**damage \<amount\>**
- Deal damage to player (for testing)
- Example: `damage 25` - Take 25 damage
- Example: `damage 99` - Almost kill player

**energy \<amount\>**
- Restores player energy
- Max energy: 100
- Example: `energy 50` - Restore 50 energy
- Example: `energy 100` - Restore to full energy

**reset**
- Resets ALL stats to base values
- Warning: Removes all upgrades for current session
- Example: `reset`

---

#### Upgrade Commands

**upgrade \<upgrade_id\>**
- Applies permanent upgrade (for current session)
- Available upgrade IDs:

**movement_speed_1**
- Effect: +30 movement speed (170 → 200)
- Example: `upgrade movement_speed_1`

**gathering_speed_1**
- Effect: +20% gathering speed (1.0x → 1.2x)
- Result: Items gather 20% faster
- Example: `upgrade gathering_speed_1`

**inventory_upgrade_1**
- Effect: +5 main inventory slots (10 → 15)
- Example: `upgrade inventory_upgrade_1`

**gathering_range_1**
- Effect: +50 pixels detection range (100px → 150px)
- Result: Detect items from further away
- Example: `upgrade gathering_range_1`

**weight_capacity_1**
- Effect: +5kg to all weight thresholds
- Result: Carry more before speed penalties
- Example: `upgrade weight_capacity_1`

---

#### Item & Equipment Commands

**give \<item\> [amount] [true]**
- Adds items directly to inventory or quickslot (no pickup animation)
- Items bypass gathering time
- Available items: wood, stone, ore, shovel
- Amount is optional (default: 1)
- Add `true` as 3rd parameter to add to quickslot instead of main inventory

Examples:
- `give wood 10` - Add 10 wood to main inventory
- `give stone 5` - Add 5 stone to main inventory
- `give shovel 1 true` - Add shovel to quickslot (for equipping)
- `give ore` - Add 1 ore to main inventory

**additem \<item\> [amount]**
- Spawns physical items in the game world
- Items spawn in a circle around the player
- Must walk over them to pick up
- Available items: wood, stone, ore, shovel
- Amount is optional (default: 1)

Examples:
- `additem wood 10` - Spawn 10 wood items around player
- `additem stone 5` - Spawn 5 stone items in a circle
- `additem shovel` - Spawn 1 shovel at player position

**equip \<slot_index\>**
- Equips an item from the specified quickslot
- Slot indices: 0, 1, 2 (corresponding to quickslots 1, 2, 3)
- Equipped item appears in quickslot UI with golden highlight
- Equipped tools provide passive bonuses (e.g., shovel = 50% faster gathering)
- Equipped weapons can be used for attacks

Examples:
- `equip 0` - Equip item in first quickslot
- `equip 1` - Equip item in second quickslot
- `equip 2` - Equip item in third quickslot

**Difference between give and additem:**
- `give` = Instant inventory/quickslot addition (no world item)
- `additem` = Physical items spawn that you can see and pick up

**Complete attack/equipment workflow:**
1. `give shovel 1 true` - Add shovel to quickslot
2. `equip 0` - Equip the shovel
3. Right-click to enter action mode
4. Hold left-click to wind up attack (2 seconds for shovel)
5. Release to execute attack

---

#### Teleport Commands

**goto \<location\>**
- Teleports player to predefined location
- Available locations:
  - `spawn` - Main spawn point (640, 400)
  - `wall` - Near climbable wall (850, 400)
  - `ground` - On the ground (640, 450)

Examples:
- `goto spawn` - Teleport to spawn
- `goto wall` - Teleport to climbing wall
- `goto ground` - Teleport to ground level

**goto \<x\> \<y\>**
- Teleports player to exact coordinates
- X = horizontal position, Y = vertical position
- Useful for testing specific areas

Examples:
- `goto 1000 500` - Teleport to (1000, 500)
- `goto 0 0` - Teleport to origin
- `goto 640 400` - Teleport to center

---

---

### Testing Attack & Equipment System

**How to Test:**
1. Give yourself a shovel in quickslot: `give shovel 1 true`
2. Equip it: `equip 0`
3. Right-click to enter action mode (weapon ready)
4. Hold left-click for 2 seconds (windup)
5. Release to swing attack

**How to Test Gathering Bonus:**
1. Spawn wood items: `additem wood 5`
2. WITHOUT shovel: Gather one (takes 1.5s)
3. WITH shovel equipped: Gather one (takes 1.0s = 50% faster!)

---

### Example Workflow

**Test Attack System:**
```
give shovel 1 true
equip 0
# Now right-click to ready weapon, hold left-click to wind up, release to attack
```

**Quick Item Testing:**
```
give wood 20
give stone 15
give ore 10
```

**Test Movement Upgrades:**
```
speed 300
upgrade movement_speed_1
goto wall
climb_speed 250
```

**Spawn Items for Gathering Test:**
```
goto spawn
additem wood 10
additem stone 5
upgrade gathering_speed_1
upgrade gathering_range_1
```

**Reset and Start Over:**
```
reset
goto spawn
clear
```

---

## 🔧 F4 GODOT CONSOLE (Advanced)

## Upgrade Commands

### Movement Speed Upgrade
```gdscript
PlayerGlobals.apply_upgrade("movement_speed_1")
```
**Effect:** Increases base movement speed by 30 pixels/second (170 → 200)
**UI Update:** Bottom-left shows "Movement: 200 (Run: x2.5)"

---

### Gathering Speed Upgrade
```gdscript
PlayerGlobals.apply_upgrade("gathering_speed_1")
```
**Effect:** Increases gathering speed by 20% (1.0x → 1.2x multiplier)
**UI Update:** Bottom-left shows "Gather: Range 100px | Speed x1.20"
**Example:** Wood gathering time: 1.5s → 1.25s

---

### Inventory Capacity Upgrade
```gdscript
PlayerGlobals.apply_upgrade("inventory_upgrade_1")
```
**Effect:** Adds 5 main inventory slots (10 → 15)
**UI Update:**
- Top-left shows "Inventory: 0/15"
- Bottom-left shows "Capacity: 15/3"

---

### Gathering Range Upgrade
```gdscript
PlayerGlobals.apply_upgrade("gathering_range_1")
```
**Effect:** Increases detection range by 50 pixels (100px → 150px)
**UI Update:** Bottom-left shows "Gather: Range 150px | Speed x1.00"
**Gameplay:** Can detect and gather items from further away

---

### Weight Capacity Upgrade
```gdscript
PlayerGlobals.apply_upgrade("weight_capacity_1")
```
**Effect:** Increases all weight thresholds by 5kg
- Threshold 1: 7kg → 12kg (no penalty)
- Threshold 2: 10kg → 15kg (90% speed)
- Threshold 3: 15kg → 20kg (75% speed)
- Threshold 4: 20kg → 25kg (50% speed)

**UI Update:** Bottom-left shows "Capacity: 10/3 | Weight: 12/15/20/25 kg"

---

## Stat Query Commands

### Check Current Movement Speed
```gdscript
print(PlayerGlobals.get_movement_speed())
```

### Check Current Climb Speed
```gdscript
print(PlayerGlobals.get_climb_speed())
```

### Check Inventory Capacity
```gdscript
print("Main: ", PlayerGlobals.get_max_main_slots(), " Quick: ", PlayerGlobals.get_max_quick_slots())
```

### Check Gathering Stats
```gdscript
print("Range: ", PlayerGlobals.get_gather_range(), " Speed: ", PlayerGlobals.get_gather_speed_multiplier())
```

### Check Weight Thresholds
```gdscript
print(PlayerGlobals.get_weight_thresholds())
```

---

## Direct Stat Modification Commands

### Set Movement Speed Directly
```gdscript
PlayerGlobals.current_movement_speed = 300.0
```
**Note:** This bypasses the upgrade system and directly sets the speed

### Apply Temporary Speed Buff
```gdscript
PlayerGlobals.apply_temporary_speed_buff(1.5, 10.0)
```
**Effect:** 50% speed boost for 10 seconds

### Set Climb Speed Directly
```gdscript
PlayerGlobals.current_climb_speed = 200.0
```

### Reset All Stats to Base
```gdscript
PlayerGlobals.reset_to_base_stats()
```
**Warning:** This resets ALL upgrades and stats to default values

---

## Health & Energy Commands (Future)

### Damage Player
```gdscript
PlayerGlobals.damage(25.0)
```

### Heal Player
```gdscript
PlayerGlobals.heal(50.0)
```

### Restore Energy
```gdscript
PlayerGlobals.restore_energy(100.0)
```

### Consume Energy
```gdscript
PlayerGlobals.consume_energy(20.0)
```

---

## Item Testing Commands

### Add Items to Inventory
```gdscript
# Access player's inventory mechanic
var player = get_tree().get_first_node_in_group("player")
var inventory = player.get_node("InventoryMechanic")

# Add 5 wood
var wood = load("res://resources/items/wood.tres")
inventory.add_item(wood, 5)

# Add 3 stone
var stone = load("res://resources/items/stone.tres")
inventory.add_item(stone, 3)

# Add 2 ore
var ore = load("res://resources/items/ore.tres")
inventory.add_item(ore, 2)
```

### Clear Inventory
```gdscript
var player = get_tree().get_first_node_in_group("player")
var inventory = player.get_node("InventoryMechanic")
inventory.clear_inventory()
```

---

## Notes

- All upgrade commands are **permanent** for the current game session
- Stats reset when you restart the game (save system not implemented yet)
- Some upgrades can be applied multiple times for cumulative effects
- UI updates happen automatically via signals when stats change
