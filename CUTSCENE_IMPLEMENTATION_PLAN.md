# Cutscene & Dialogue System Implementation Plan

**Project:** Game Off 2025 - Bat Platformer
**Created:** 2025-11-09
**Status:** In Progress

---

## Overview

This document outlines the implementation plan for the cutscene and dialogue system. The system will support:
- Retro-styled dialogue boxes with typewriter text effect
- Full-screen cutscene images with text overlay
- In-level scripted player animations for cutscenes
- Dialogue progression via Space/A button
- Skip cutscene functionality (hold button)
- Sound effects for dialogue
- Tutorial/tooltip system separate from story dialogue

---

## Phase 1: Core Dialogue Box UI Component ✓

### Tasks
- [x] Create `UI/DialogueBox/` directory structure
- [x] Create `dialogue_box.tscn` scene with Control node hierarchy
- [x] Design retro-styled dialogue box UI layout:
  - [x] Add Panel/NinePatchRect for box background
  - [x] Add RichTextLabel for dialogue text display
  - [x] Add Label for character name (optional)
  - [x] Style with appropriate fonts and colors
- [x] Create `dialogue_box.gd` script
- [x] Implement typewriter text effect:
  - [x] Add `display_text(text: String)` method
  - [x] Character-by-character reveal with Timer
  - [x] Configurable typing speed (characters per second)
  - [x] Option to instantly complete text on button press
- [x] Add input handling:
  - [x] Detect `ui_accept` or `jump` action
  - [x] Advance to next line or finish current typewriter
  - [x] Emit `dialogue_advanced` signal
- [x] Implement fade-in/fade-out animations using Tween
- [x] Add visual indicator for "press button to continue" (arrow, blink effect)
- [x] Test with placeholder dialogue:
  - [x] Single line of text
  - [x] Multiple lines in sequence
  - [x] Long text that wraps
  - [x] Instant text completion

**Testing Checklist:**
- [x] Dialogue box appears smoothly with fade-in
- [x] Typewriter effect displays at correct speed
- [x] Pressing A/Space instantly completes typewriter
- [x] Pressing A/Space again advances to next line
- [x] Visual indicator shows when ready to advance
- [x] Box fades out smoothly when dialogue ends

**Status:** ✅ COMPLETE - Test scene available at `UI/DialogueBox/dialogue_box_test.tscn`

---

## Phase 2: DialogueManager Autoload Singleton ✓

### Tasks
- [x] Create `Common/DialogueManager.gd` script
- [x] Define dialogue data structure:
  - [x] Create `DialogueLine` class/dictionary with fields:
    - `text: String` - The dialogue text
    - `character: String` - Speaker name (optional)
    - `pause_duration: float` - Pause after line (optional)
    - `callback: Callable` - Function to call after line (optional)
  - [x] Create `DialogueSequence` structure for grouped lines
- [x] Implement dialogue queue system:
  - [x] `start_dialogue(lines: Array[DialogueLine])` method
  - [x] Queue management (current line, next line, etc.)
  - [x] Auto-advance after typewriter completes (if pause_duration set)
  - [x] Manual advance on button press
- [x] Add DialogueBox instance management:
  - [x] Instantiate dialogue_box.tscn when needed
  - [x] Add to SceneTree as CanvasLayer overlay (layer 99)
  - [x] Remove when dialogue ends
- [x] Implement signals:
  - [x] `dialogue_started` - Emitted when dialogue begins
  - [x] `dialogue_finished` - Emitted when all lines complete
  - [x] `line_changed(line_index: int)` - Emitted on each new line
  - [x] `dialogue_skipped` - Emitted if player skips
- [x] Add utility methods:
  - [x] `is_active() -> bool`
  - [x] `skip_dialogue()` - Force end all dialogue
  - [x] `pause_dialogue()` / `resume_dialogue()`
  - [x] Helper methods: `create_line()`, `create_simple_lines()`, `start_simple_dialogue()`
- [x] Register as autoload:
  - [x] Add to `project.godot` under `[autoload]` section
  - [x] Test global access via `DialogueManager`
- [x] Test with sample dialogue sequences:
  - [x] 2-3 line simple conversation
  - [x] Dialogue with character names
  - [x] Dialogue with pauses/auto-advance
  - [x] Dialogue with callbacks

**Testing Checklist:**
- [x] DialogueManager accessible from any script
- [x] Multiple lines display in sequence correctly
- [x] Signals emit at appropriate times
- [x] Can start new dialogue after previous ends
- [x] Cannot start dialogue while one is active
- [x] skip_dialogue() immediately ends sequence

**Status:** ✅ COMPLETE - Test scene available at `Common/DialogueManagerTest.tscn`

---

## Phase 3: Full-Screen Cutscene Player ✓

### Tasks
- [x] Create `UI/CutscenePlayer/` directory
- [x] Create `cutscene_player.tscn` scene:
  - [x] CanvasLayer (layer 99 - just below pause menu)
  - [x] TextureRect for fullscreen cutscene image (expand mode)
  - [x] ColorRect for background/letterboxing
  - [x] Uses DialogueManager for dialogue overlay
  - [x] Control for skip indicator UI with progress bar
- [x] Create `cutscene_player.gd` script
- [x] Implement cutscene data structure:
  - [x] `CutsceneFrame` class with:
    - `image_path: String` - Path to cutscene image
    - `dialogue_lines: Array` - Text for this image
    - `duration: float` - Auto-advance time (optional)
- [x] Implement frame display logic:
  - [x] Load and display image in TextureRect
  - [x] Fade in/out images (0.5s transition)
  - [x] Display dialogue for current frame via DialogueManager
  - [x] Advance to next frame when dialogue completes
- [x] Add skip functionality:
  - [x] Detect hold on `ui_cancel` (ESC for 1.5 seconds)
  - [x] Show skip progress indicator (filling progress bar)
  - [x] Emit `cutscene_skipped` signal
  - [x] Clean up cutscene player properly
- [x] Implement cutscene sequencing:
  - [x] `play_cutscene(frames: Array)` method
  - [x] Auto-advance between frames
  - [x] Handle last frame completion
  - [x] Emit `cutscene_finished` signal
- [x] Test with existing cutscene images:
  - [x] Load multiple cutscene images
  - [x] Display with test dialogue
  - [x] Advance through sequence
  - [x] Test skip functionality
  - [x] Test full 3-frame sequence

**Testing Checklist:**
- [x] Cutscene images display fullscreen correctly
- [x] Dialogue appears over cutscene images
- [x] Can advance through multiple frames
- [x] Skip functionality works (hold ESC button)
- [x] Skip indicator provides clear feedback
- [x] Cutscene cleans up properly after completion

**Status:** ✅ COMPLETE - Test scene available at `UI/CutscenePlayer/cutscene_player_test.tscn`

---

## Phase 4: In-Level Cutscene Triggers & Player Control ✓

### Tasks
- [x] Create `Entities/CutsceneTrigger/` directory
- [x] Create `cutscene_trigger.tscn`:
  - [x] Area2D root node
  - [x] CollisionShape2D (RectangleShape2D)
  - [x] Visual indicator for editor (ColorRect, editor-only)
- [x] Create `cutscene_trigger.gd` script:
  - [x] Export variables:
    - `cutscene_id`, `trigger_once`, `auto_start`, `disable_player_control`
  - [x] Detect player entry via `body_entered` signal
  - [x] Emit `cutscene_triggered(cutscene_id)` signal
  - [x] Disable trigger after first use (if `trigger_once`)
- [x] Create `Common/CutsceneDirector.gd`:
  - [x] Autoload singleton for managing in-level cutscenes
  - [x] Register cutscene sequences by ID
  - [x] Handle cutscene playback with action system
  - [x] Coordinate with DialogueManager and CutscenePlayer
- [x] Implement player control disable system:
  - [x] Added `control_enabled` flag to UltimatePlatformerController
  - [x] `disable_control()` and `enable_control()` methods
  - [x] Early return in `_physics_process` when disabled
  - [x] Automatic control restoration after cutscene ends
- [x] Create action-based cutscene system:
  - [x] Action types: DIALOGUE, WAIT, PLAYER_WALK, SPAWN_OBJECT, FULLSCREEN_CUTSCENE, CUSTOM_FUNCTION
  - [x] Sequential action execution
  - [x] Helper methods for creating actions
  - [x] Support for custom callbacks
- [x] Documentation and examples:
  - [x] Complete README with examples
  - [x] Test script demonstrating usage

**Testing Checklist:**
- [x] Cutscene trigger activates when player enters
- [x] Trigger only fires once (if configured)
- [x] Player control disables during cutscene
- [x] Scripted player walk animations work
- [x] Player walks to target position correctly
- [x] Control re-enables after cutscene ends
- [x] Multiple triggers can exist in same level
- [x] Can chain dialogue and animations together

**Status:** ✅ COMPLETE - See `Common/CUTSCENE_DIRECTOR_README.md` for documentation and examples

---

## Phase 5: Audio & Polish

### Tasks
- [ ] Source or create audio assets:
  - [ ] Text blip sound effect (short, repeating per character)
  - [ ] Dialogue box open sound
  - [ ] Dialogue box close sound
  - [ ] Optional: Different blips for different characters
- [ ] Add audio to DialogueBox:
  - [ ] AudioStreamPlayer node in dialogue_box.tscn
  - [ ] Play blip sound on each character during typewriter
  - [ ] Play open/close sounds on box appear/disappear
  - [ ] Add option to mute text blips (if annoying)
- [ ] Integrate with BackgroundMusic autoload:
  - [ ] Add method to lower music volume during dialogue
  - [ ] Restore volume after dialogue ends
  - [ ] Optional: Pause music during cutscenes
- [ ] Add visual polish to dialogue box:
  - [ ] Import or create retro pixel art border
  - [ ] Add subtle box bounce/shake on appear
  - [ ] Polish continue indicator (blinking arrow)
  - [ ] Test readability with background contrast
- [ ] Camera control during cutscenes (if needed):
  - [ ] Disable camera follow during scripted sequences
  - [ ] Smooth camera pan to focus on cutscene action
  - [ ] Restore camera follow after cutscene
- [ ] Test full audio experience:
  - [ ] Play through sample dialogue with audio
  - [ ] Verify timing feels natural
  - [ ] Check volume balance with music/SFX
  - [ ] Test in actual level environment

**Testing Checklist:**
- [ ] Text blip sound plays at appropriate speed
- [ ] Blip sound is not annoying or too loud
- [ ] Box open/close sounds provide good feedback
- [ ] Music volume adjusts smoothly during dialogue
- [ ] Dialogue box is visually distinct and readable
- [ ] Continue indicator is clear and noticeable
- [ ] Audio doesn't overlap or clip

---

## Phase 6: Tutorial/Tooltip System

### Tasks
- [ ] Create `Common/TooltipManager.gd` autoload
- [ ] Create `UI/Tooltip/tooltip.tscn`:
  - [ ] Smaller, distinct style from dialogue boxes
  - [ ] Button prompt display (icon + text: "Press E")
  - [ ] Can position at player or screen position
  - [ ] Auto-dismiss after duration or on action performed
- [ ] Create `tooltip.gd` script:
  - [ ] `show_tooltip(text: String, position: Vector2)` method
  - [ ] Optional button icon display
  - [ ] Fade in/out animations
  - [ ] Auto-dismiss timer
- [ ] Implement first-time trigger system:
  - [ ] Track shown tooltips in SaveManager
  - [ ] Check if tooltip was already shown
  - [ ] Add `show_once(tooltip_id: String, text: String)` method
- [ ] Create tooltip trigger zones:
  - [ ] Similar to CutsceneTrigger but for tooltips
  - [ ] Can be placed anywhere in levels
  - [ ] Disappear after showing once
- [ ] Implement context-sensitive tutorial:
  - [ ] Hook into FireflyCollectionManager for first butterfly
  - [ ] Hook into EcholocationManager for first echolocation use
  - [ ] Show tooltips at appropriate teaching moments
- [ ] Test tutorial flow:
  - [ ] First butterfly collection shows echolocation tip
  - [ ] Tooltip displays clearly and doesn't obstruct gameplay
  - [ ] Tooltip dismisses on button press or after timer
  - [ ] Tooltip doesn't show again on replay

**Testing Checklist:**
- [ ] Tooltip appears after first butterfly collection
- [ ] Tooltip clearly prompts "Press E" for echolocation
- [ ] Tooltip is visually distinct from dialogue
- [ ] Tooltip doesn't show again after first time
- [ ] Can manually trigger tooltips from code
- [ ] Multiple tooltips can be shown in sequence (but not simultaneously)

---

## Phase 7: Opening Cutscene Implementation ✓

### Tasks
- [x] Create opening cutscene orchestration script
- [x] Set up level-1 integration:
  - [x] Auto-start on level load (1 second delay)
  - [x] Player finding and group detection
  - [x] Complete action sequence registered
- [x] Create opening scripted sequence:
  - [x] Fade handled by SceneManager
  - [x] Auto-disable player control via CutsceneDirector
  - [x] Scripted walk sequence:
    - [x] Sona walks slowly (40px/s) 80 pixels
    - [x] Stops automatically
  - [x] Dialogue: "I should turn around..."
  - [x] Pause (1 second)
  - [x] Walk forward 50 more pixels
- [x] Implement photo shard system:
  - [x] Created `Entities/PhotoShard/photo_shard.tscn`
  - [x] Placeholder visual (yellowish rectangle)
  - [x] Spawn dynamically during cutscene
  - [x] Fade-in animation implemented
- [x] Photo shard pickup sequence:
  - [x] Dialogue: "Huh...?"
  - [x] Sona walks to photo shard (50px/s)
  - [x] Pickup animation (float up + fade)
  - [x] Photo shard removed from scene
- [x] Full-screen cutscene sequence:
  - [x] Uses CutscenePlayer system
  - [x] Frame 1: `looking-at-first-scrappng.png`
    - "This photo...it looks familiar..."
    - "I think it's of me and my mom...right before..."
  - [x] Frame 2: `sona-close-up-sad.png`
    - "It kills me to be so alone..."
    - (Bat attack sounds placeholder for Phase 5)
  - [x] Frame 3: `sona-full-photo-above.png`
    - "There could be others out there..."
    - "But I lost my only family before I learned to fly..."
  - [x] Frame 4: `sona-title.png`
    - "Maybe there's another way..."
- [x] Transition to title screen:
  - [x] SceneManager.load_scene("res://UI/MainMenu.tscn")
  - [x] BackgroundMusic.play() call (configure in Phase 5)
- [x] Documentation:
  - [x] Complete README with integration instructions
  - [x] Customization guide
  - [x] Troubleshooting section

**Testing Checklist:**
- [x] Opening cutscene auto-plays when level-1 loads
- [x] Sona walks smoothly with scripted animation
- [x] All dialogue displays in correct order
- [x] Photo shard appears and pickup works correctly
- [x] Full-screen cutscenes display proper images
- [ ] Bat attack sounds play at correct moment (Phase 5)
- [x] Fade to black works smoothly
- [x] Transitions to title screen correctly
- [ ] Adventurous music starts on title screen (Phase 5)
- [x] Can skip entire sequence by holding ESC button
- [ ] First butterfly tutorial tooltip shows after sequence (Phase 6)

**Status:** ✅ COMPLETE - See `Levels/OPENING_CUTSCENE_README.md` for integration instructions

**Integration:** Add `opening_cutscene.gd` script to level-1 to activate

---

## Phase 8: Ending Cutscene Implementation

### Tasks
- [ ] Set up final level ending area:
  - [ ] Identify end position in final level
  - [ ] Add CutsceneTrigger at level completion point
  - [ ] Create tall cave wall visual
- [ ] Implement approach sequence:
  - [ ] Player reaches trigger area
  - [ ] Control disabled
  - [ ] Sona slowly walks toward wall
  - [ ] Stops at wall
  - [ ] Dialogue: "I can't make it up there after all..."
- [ ] Photo shard discovery:
  - [ ] Photo shard sprite barely visible in ground
  - [ ] Camera pan/focus on shard (optional)
  - [ ] Dialogue: "What's this?"
  - [ ] Play pickup animation (shard appears above head briefly)
  - [ ] Dialogue: "Oh--that's the last one..."
- [ ] Final cutscene sequence:
  - [ ] Transition to CutscenePlayer
  - [ ] Show appropriate image
  - [ ] Dialogue: "Mom..."
  - [ ] Dialogue: "I made it all this way and still cannot reach the top..."
  - [ ] Dialogue: "I let you down..."
  - [ ] Dialogue: "I knew I couldn't do it without you here..."
  - [ ] Dialogue: "..."
  - [ ] Dialogue: "Wait a minute...there's writing on the other side..."
  - [ ] Show `letter.png` (text on back of photo)
  - [ ] (Additional dialogue as user completes writing)
- [ ] Configure ending transitions:
  - [ ] Fade to credits or end screen (as appropriate)
  - [ ] Music fade out or credits music
  - [ ] Option to return to main menu
- [ ] Test complete ending sequence:
  - [ ] Trigger activates at level end correctly
  - [ ] Wall approach plays smoothly
  - [ ] Photo shard discovery feels impactful
  - [ ] All dialogue flows correctly
  - [ ] Letter image displays clearly
  - [ ] Ending feels emotionally satisfying
  - [ ] Can skip if desired

**Testing Checklist:**
- [ ] Ending triggers at final level completion
- [ ] Sona approaches wall with scripted movement
- [ ] Photo shard discovery animation works
- [ ] All ending dialogue displays correctly
- [ ] Letter image is readable and impactful
- [ ] Music transitions appropriately
- [ ] Ending can be skipped by holding button
- [ ] Game provides clear next action (credits, menu, etc.)

---

## Additional Tasks & Polish

### Optional Enhancements
- [ ] Add dialogue history/log (accessible from pause menu)
- [ ] Implement character portraits in dialogue box
- [ ] Add dialogue speed setting in options menu
- [ ] Create more elaborate skip confirmation (prevent accidental skips)
- [ ] Add subtle camera shake during emotional moments
- [ ] Implement save points that remember cutscene progress
- [ ] Add replay cutscene option from main menu

### Bug Fixes & Refinements
- [ ] Ensure player hunger doesn't drain during cutscenes
- [ ] Pause Timer during cutscenes (TimerManager integration)
- [ ] Test cutscenes with different screen resolutions
- [ ] Verify dialogue text doesn't overflow box
- [ ] Handle edge case: What if player pauses during cutscene?
- [ ] Ensure all cutscene assets are properly imported
- [ ] Optimize cutscene image loading (preload vs load)

---

## Notes & Decisions

**Design Decisions:**
- In-level cutscenes use scripted animation sequences (not automated controller)
- Photo shards are one-time cutscene triggers (not persistent collectibles)
- Cutscenes embedded in levels via trigger areas (not separate scenes)
- Tutorial tooltips use separate system from story dialogue

**Key Features:**
- Typewriter text effect for dialogue
- Hold-to-skip cutscene functionality
- Sound effects: text blips, box open/close
- Tutorial/tooltip system for gameplay hints

**File Paths Reference:**
- Cutscene images: `/Users/colecofer/Dev/Godot/Game-Off-2025/game-off-2025/Assets/Art/cut-scenes/`
- Player: `/Users/colecofer/Dev/Godot/Game-Off-2025/game-off-2025/Entities/Player/`
- Levels: `/Users/colecofer/Dev/Godot/Game-Off-2025/game-off-2025/Levels/`

---

## Progress Tracking

**Legend:**
- [ ] Not Started
- [x] Complete
- [~] In Progress
- [!] Blocked/Issues

**Overall Progress:** 5/8 Phases Complete (62.5%)

**Phase Status:**
- [x] Phase 1: Core Dialogue Box UI Component
- [x] Phase 2: DialogueManager Autoload Singleton
- [x] Phase 3: Full-Screen Cutscene Player
- [x] Phase 4: In-Level Cutscene Triggers & Player Control
- [ ] Phase 5: Audio & Polish
- [ ] Phase 6: Tutorial/Tooltip System
- [x] Phase 7: Opening Cutscene Implementation
- [ ] Phase 8: Ending Cutscene Implementation

**Last Updated:** 2025-11-11
