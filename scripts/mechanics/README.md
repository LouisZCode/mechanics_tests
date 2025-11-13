# Player Mechanics - Component Pattern

This folder contains modular player mechanics using the **Component Pattern** for Godot 4.5.

## Architecture Overview

The player is organized into a **coordinator + components** structure:

- **player.gd** - Coordinator script that manages mechanics, animations, and input routing
- **Mechanics/** - Self-contained components for different player abilities

## Current Mechanics

### Core Mechanics (Always Active)
- **MovementMechanic** - Handles horizontal movement, running, and direction tracking
- **GravityMechanic** - Applies gravity physics to the player

## Creating a New Mechanic

### Step 1: Create the Script

Copy `mechanic_template.gd` and rename it (e.g., `digging_mechanic.gd`):

```gdscript
class_name DiggingMechanic
extends Node

signal dig_started
signal dig_completed(position)

@export var dig_speed = 1.0
@export var dig_range = 50.0

var is_digging = false
var player: CharacterBody2D

func _ready():
    player = get_parent() as CharacterBody2D
    if not player:
        push_error("DiggingMechanic must be child of CharacterBody2D")

func can_activate() -> bool:
    """Check if player can start digging"""
    return not is_digging and is_on_diggable_ground()

func execute(delta: float):
    """Main digging logic"""
    if is_digging:
        # Digging behavior here
        pass

func is_active() -> bool:
    """Check if currently digging"""
    return is_digging

func activate():
    """Start digging"""
    if can_activate():
        is_digging = true
        dig_started.emit()

func deactivate():
    """Stop digging"""
    is_digging = false
    dig_completed.emit(player.global_position)

func is_on_diggable_ground() -> bool:
    # Add detection logic
    return false
```

### Step 2: Add to Player Scene

In Godot Editor:
1. Open `scenes/player.tscn`
2. Right-click on `Player` node → Add Child Node → Node
3. Name it: `DiggingMechanic`
4. In Inspector, attach script: `res://scripts/mechanics/digging_mechanic.gd`
5. Configure export variables in Inspector

### Step 3: Reference in player.gd

Add to player.gd coordinator:

```gdscript
# Add at top with other mechanic references
@onready var digging: DiggingMechanic = $DiggingMechanic

func _physics_process(delta):
    # ... existing code ...

    # Add mechanic input handling
    if Input.is_action_just_pressed("dig"):
        digging.activate()

    # Execute if active
    if digging.is_active():
        digging.execute(delta)

    # ... rest of code ...
```

## Component Communication

### Using Signals
Components emit signals to communicate with the coordinator:

```gdscript
# In mechanic
signal mechanic_started
signal mechanic_ended

# In player.gd
digging.mechanic_started.connect(_on_digging_started)

func _on_digging_started():
    # Respond to digging start
    pass
```

### Returning State Data
Components return state dictionaries for animations:

```gdscript
# In mechanic
func execute(delta: float) -> Dictionary:
    return {
        "is_active": true,
        "progress": 0.5
    }

# In player.gd
var dig_state = digging.execute(delta)
if dig_state.is_active:
    anim.play("digging")
```

## Benefits of This Pattern

✅ **Modular** - Each mechanic is self-contained and reusable
✅ **Testable** - Can test mechanics independently
✅ **Flexible** - Easy to enable/disable mechanics
✅ **Inspector-Friendly** - Export variables configurable in Godot Editor
✅ **Maintainable** - Clear separation of concerns

## File Structure

```
scripts/
├── player.gd (coordinator)
└── mechanics/
    ├── README.md (this file)
    ├── mechanic_template.gd (copy to create new mechanics)
    ├── movement_mechanic.gd
    ├── gravity_mechanic.gd
    ├── digging_mechanic.gd (future)
    ├── climbing_mechanic.gd (future)
    └── attack_mechanic.gd (future)
```

## Best Practices

1. **Single Responsibility** - Each mechanic handles one thing
2. **Blind Components** - Mechanics don't know about other mechanics
3. **Coordinator Control** - player.gd decides which mechanics are active
4. **Export Variables** - Make values tweakable in Inspector
5. **Use Signals** - For communication between components and coordinator
6. **Type Hints** - Use `-> bool`, `-> Dictionary` for clarity
