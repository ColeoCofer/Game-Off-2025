# Firefly System - Testing Guide

## Implementation Complete! ✅

The firefly collectible system has been fully implemented with the following features:

### What Was Implemented:

#### 1. **Firefly Entity** (`Entities/Bugs/firefly.tscn` & `firefly.gd`)
- Glowing effect using PointLight2D
- Smooth hovering animation
- Unique ID system (0, 1, 2) for tracking per level
- Collection detection with player collision
- Fade-out animation on collection
- Persistence check (already-collected fireflies don't spawn)

#### 2. **Save System** (`Common/SaveManager.gd`)
Extended with:
- `fireflies_collected` dictionary in save data
- `save_firefly()` - Save collected firefly
- `is_firefly_collected()` - Check if collected
- `get_collected_fireflies()` - Get array of collected IDs
- `get_firefly_count()` - Get count for a level
- `get_total_fireflies_collected()` - Total across all levels

#### 3. **Collection Manager** (`Common/FireflyCollectionManager.gd`)
New autoload singleton:
- Handles firefly collection logic
- Signals: `firefly_collected`, `all_fireflies_collected_in_level`
- Tracks 3 fireflies per level
- Integration with SaveManager
- Completion percentage tracking
- 100% completion detection

#### 4. **Level Select UI** (`UI/LevelButton.tscn` & `LevelButton.gd`)
Enhanced with:
- 3 firefly icon indicators (TextureRect nodes)
- Firefly count label ("X/3 fireflies")
- Visual feedback: bright yellow for collected, greyed-out for uncollected
- Automatic update from save data

---

## How to Test:

### Step 1: Place Fireflies in a Test Level

1. Open Godot and load `Levels/level-1.tscn`
2. Instance the firefly scene 3 times:
   - Right-click Scene tree → "Instantiate Child Scene"
   - Select `res://Entities/Bugs/firefly.tscn`
3. For each firefly:
   - Set `Firefly Id` in Inspector (0, 1, or 2)
   - Position it somewhere visible in the level
4. Save the scene

### Step 2: Test Collection

1. Run the game
2. Navigate to level select and select level 1
3. Play the level and collect a firefly
4. Verify:
   - ✅ Firefly glows and hovers
   - ✅ Collection animation plays (fade out, scale up, float up)
   - ✅ Console shows: "Firefly X collected in level-1! (Y/3)"

### Step 3: Test Persistence

1. Pause and return to level select
2. Check the level button:
   - ✅ Shows "1/3 fireflies" (or however many you collected)
   - ✅ First icon is bright yellow, others are greyed out
3. Restart the level
4. Verify:
   - ✅ Already-collected firefly doesn't appear
   - ✅ Uncollected fireflies are still there

### Step 4: Test Save/Load

1. Collect more fireflies
2. Exit the game completely
3. Restart the game
4. Check level select:
   - ✅ Firefly counts persist across sessions
   - ✅ Icons show correct collection status

### Step 5: Test Full Completion

1. Collect all 3 fireflies in level 1
2. Verify:
   - ✅ Console shows "All fireflies collected in level-1! (3/3)"
   - ✅ Level select shows "3/3 fireflies"
   - ✅ All 3 icons are bright yellow

---

## Debug Console Commands:

You can check the FireflyCollectionManager in the Godot console:

```gdscript
# Check if firefly collected
print(FireflyCollectionManager.is_firefly_collected("level-1", 0))

# Get collected count
print(FireflyCollectionManager.get_firefly_count("level-1"))

# Get total across all levels
print(FireflyCollectionManager.get_total_fireflies_collected())

# Check completion percentage
print(FireflyCollectionManager.get_completion_percentage())

# Check 100% completion
print(FireflyCollectionManager.is_game_100_percent_complete())
```

---

## Expected Behavior:

### Collection Flow:
1. Player enters firefly collision area
2. Firefly checks if already collected (via SaveManager)
3. If not collected:
   - Marks as collected
   - Saves to persistent storage
   - Emits `firefly_collected` signal
   - Plays collection animation
   - Removes itself from scene

### Save Data Structure:
```json
{
  "game_data": {
    "fireflies_collected": {
      "level-1": [0, 1, 2],
      "level-2": [0],
      "level-3": []
    }
  }
}
```

### Level Select Display:
- **0/3 collected**: All icons greyed out
- **1/3 collected**: First icon bright, others greyed
- **2/3 collected**: First two bright, last greyed
- **3/3 collected**: All icons bright yellow

---

## Known Features:

✅ Fireflies persist across game sessions
✅ No duplicate collection (can't collect twice)
✅ Smooth collection animation
✅ Visual feedback on level select
✅ Works with existing save system
✅ Optional collectible (doesn't block progression)

---

## Next Steps:

1. **Place fireflies in all 5 levels** (see `FIREFLY_PLACEMENT_GUIDE.md`)
2. **Test each level** to ensure IDs are unique (0, 1, 2)
3. **Design hiding spots** - easy, medium, and hard locations
4. **Optional**: Add sound effect when collecting fireflies
5. **Optional**: Add particle effects on collection
6. **Optional**: Add reward for collecting all 15 fireflies

---

## File Changes Summary:

### New Files:
- `Entities/Bugs/firefly.gd` - Firefly entity script
- `Entities/Bugs/firefly.tscn` - Firefly scene
- `Common/FireflyCollectionManager.gd` - Collection manager
- `FIREFLY_PLACEMENT_GUIDE.md` - Placement instructions
- `FIREFLY_TESTING_GUIDE.md` - This file

### Modified Files:
- `Common/SaveManager.gd` - Added firefly tracking
- `UI/LevelButton.gd` - Added firefly display logic
- `UI/LevelButton.tscn` - Added firefly UI elements
- `project.godot` - Registered FireflyCollectionManager autoload

---

## Troubleshooting:

### Firefly doesn't disappear when collected:
- Check console for errors
- Verify FireflyCollectionManager is registered in autoloads
- Ensure firefly_id is set (0, 1, or 2)

### Firefly always appears even when collected:
- Check that `_check_if_collected()` is being called in `_ready()`
- Verify SaveManager is saving correctly
- Check save file at `user://save_data.json`

### Icons don't update on level select:
- Verify LevelButton is calling `_update_firefly_display()`
- Check that FireflyCollectionManager is accessible
- Ensure level_name matches between level and save data

### Multiple fireflies have the same ID:
- Each firefly in a level must have a unique ID (0, 1, or 2)
- Check Inspector for each firefly instance
- IDs can repeat across different levels, but not within the same level

---

**System is ready to test! 🎮✨**
