# Firefly System - Testing Guide

## Implementation Complete! ✅

**IMPORTANT: Fireflies only count if you complete the level without dying!**
- Collect firefly → it disappears temporarily
- Die/restart → firefly respawns (not permanently saved yet)
- Complete level → fireflies saved permanently

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

### Step 3: Test Death/Respawn Behavior

1. Collect a firefly (it disappears)
2. Die or restart the level
3. Verify:
   - ✅ Firefly respawns! (wasn't permanently saved yet)
   - ✅ You can collect it again
4. Collect the firefly again
5. Complete the level without dying
6. Verify:
   - ✅ Firefly is now permanently saved

### Step 3b: Test Persistence Across Deaths

1. Return to level select
2. Check the level button:
   - ✅ Shows "1/3 fireflies" (only counts completed runs)
   - ✅ First icon is bright yellow, others are greyed out
3. Restart the level
4. Verify:
   - ✅ Already-permanently-collected firefly doesn't appear
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
1. **On Level Start:**
   - Fireflies check if PERMANENTLY collected (saved in previous successful runs)
   - If permanently collected → don't spawn
   - If not permanently collected → spawn normally
   - Temporary collection is cleared

2. **When Player Collects Firefly:**
   - Check if already collected THIS RUN (temporary)
   - If not collected this run:
     - Mark as collected temporarily (NOT saved to disk yet)
     - Add to `current_run_collected` array
     - Emit `firefly_collected` signal
     - Play collection animation
     - Remove from scene

3. **On Death/Restart:**
   - Temporary collection cleared
   - All fireflies respawn (except permanently collected ones)
   - Player must collect them again

4. **On Level Completion:**
   - All temporarily collected fireflies → saved permanently
   - Committed to SaveManager (written to disk)
   - Next time level loads, those fireflies won't spawn

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

✅ Fireflies only save permanently on level completion
✅ Fireflies respawn if you die before completing the level
✅ Challenge: Must collect AND survive to keep them
✅ No duplicate collection in same run
✅ Smooth collection animation
✅ Visual feedback on level select (shows permanent collection only)
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
