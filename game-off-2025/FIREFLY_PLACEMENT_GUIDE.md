# Firefly Placement Guide

## Quick Start

Each level needs exactly **3 fireflies** with IDs: 0, 1, and 2.

## How to Add Fireflies to Levels

### In Godot Editor:

1. Open a level scene (e.g., `Levels/level-1.tscn`)
2. Add firefly instances:
   - Right-click in the Scene tree → "Instantiate Child Scene"
   - Select `res://Entities/Bugs/firefly.tscn`
   - Or drag the firefly.tscn file into the scene
3. Configure each firefly:
   - Select the firefly instance
   - In Inspector, set `Firefly Id` to 0, 1, or 2
   - Position it in your level
4. Save the scene
5. Repeat for all 5 levels

### Firefly Properties:

- **firefly_id**: Must be 0, 1, or 2 (unique per level)
- **hover_amplitude**: How much it bobs (default: 2.0)
- **hover_speed**: How fast it bobs (default: 1.5)
- **glow_energy**: Brightness of glow (default: 1.5)

## Placement Tips:

- **Easy (1 per level)**: Place near main path, visible but slightly out of the way
- **Medium (1 per level)**: Require small detour or platforming challenge
- **Hard (1 per level)**: Hidden areas, secret passages, or challenging jumps

## What Happens:

1. Fireflies glow and hover in place
2. Player touches firefly → it's collected with animation
3. Collection saved to player's save file
4. Already-collected fireflies won't appear on replay
5. Level select shows firefly count (0/3, 1/3, 2/3, 3/3)
6. Greyed-out icons become bright yellow when collected

## System Overview:

- **SaveManager**: Stores which fireflies were collected
- **FireflyCollectionManager**: Tracks collection per level
- **LevelButton UI**: Shows collection status on level select
- **Firefly entity**: Glowing collectible with hover animation

## Current Status:

- ✅ Firefly entity created with glowing effect
- ✅ Save system tracks collection
- ✅ Level select UI shows firefly status
- ⏳ Need to manually place 3 fireflies in each of the 5 levels

## Levels to Update:

- [ ] `Levels/level-1.tscn` - Add 3 fireflies (IDs: 0, 1, 2)
- [ ] `Levels/level-2.tscn` - Add 3 fireflies (IDs: 0, 1, 2)
- [ ] `Levels/level-3.tscn` - Add 3 fireflies (IDs: 0, 1, 2)
- [ ] `Levels/level-4.tscn` - Add 3 fireflies (IDs: 0, 1, 2)
- [ ] `Levels/level-5.tscn` - Add 3 fireflies (IDs: 0, 1, 2)

---

**Total fireflies in game: 15 (5 levels × 3 fireflies)**
