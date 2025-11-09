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

## Phase 1: Core Dialogue Box UI Component

### Tasks
- [ ] Create `UI/DialogueBox/` directory structure
- [ ] Create `dialogue_box.tscn` scene with Control node hierarchy
- [ ] Design retro-styled dialogue box UI layout:
  - [ ] Add Panel/NinePatchRect for box background
  - [ ] Add RichTextLabel for dialogue text display
  - [ ] Add Label for character name (optional)
  - [ ] Style with appropriate fonts and colors
- [ ] Create `dialogue_box.gd` script
- [ ] Implement typewriter text effect:
  - [ ] Add `display_text(text: String)` method
  - [ ] Character-by-character reveal with Timer
  - [ ] Configurable typing speed (characters per second)
  - [ ] Option to instantly complete text on button press
- [ ] Add input handling:
  - [ ] Detect `ui_accept` or `jump` action
  - [ ] Advance to next line or finish current typewriter
  - [ ] Emit `dialogue_advanced` signal
- [ ] Implement fade-in/fade-out animations using Tween
- [ ] Add visual indicator for "press button to continue" (arrow, blink effect)
- [ ] Test with placeholder dialogue:
  - [ ] Single line of text
  - [ ] Multiple lines in sequence
  - [ ] Long text that wraps
  - [ ] Instant text completion

**Testing Checklist:**
- [ ] Dialogue box appears smoothly with fade-in
- [ ] Typewriter effect displays at correct speed
- [ ] Pressing A/Space instantly completes typewriter
- [ ] Pressing A/Space again advances to next line
- [ ] Visual indicator shows when ready to advance
- [ ] Box fades out smoothly when dialogue ends

---

## Phase 2: DialogueManager Autoload Singleton

### Tasks
- [ ] Create `Common/DialogueManager.gd` script
- [ ] Define dialogue data structure:
  - [ ] Create `DialogueLine` class/dictionary with fields:
    - `text: String` - The dialogue text
    - `character: String` - Speaker name (optional)
    - `pause_duration: float` - Pause after line (optional)
    - `callback: String` - Function to call after line (optional)
  - [ ] Create `DialogueSequence` structure for grouped lines
- [ ] Implement dialogue queue system:
  - [ ] `start_dialogue(lines: Array[DialogueLine])` method
  - [ ] Queue management (current line, next line, etc.)
  - [ ] Auto-advance after typewriter completes (if pause_duration set)
  - [ ] Manual advance on button press
- [ ] Add DialogueBox instance management:
  - [ ] Instantiate dialogue_box.tscn when needed
  - [ ] Add to SceneTree as CanvasLayer overlay (high z-index)
  - [ ] Remove when dialogue ends
- [ ] Implement signals:
  - [ ] `dialogue_started` - Emitted when dialogue begins
  - [ ] `dialogue_finished` - Emitted when all lines complete
  - [ ] `line_changed(line_index: int)` - Emitted on each new line
  - [ ] `dialogue_skipped` - Emitted if player skips
- [ ] Add utility methods:
  - [ ] `is_dialogue_active() -> bool`
  - [ ] `skip_dialogue()` - Force end all dialogue
  - [ ] `pause_dialogue()` / `resume_dialogue()`
- [ ] Register as autoload:
  - [ ] Add to `project.godot` under `[autoload]` section
  - [ ] Test global access via `DialogueManager`
- [ ] Test with sample dialogue sequences:
  - [ ] 2-3 line simple conversation
  - [ ] Dialogue with pauses between lines
  - [ ] Rapid dialogue advancement
  - [ ] Interrupting dialogue mid-sequence

**Testing Checklist:**
- [ ] DialogueManager accessible from any script
- [ ] Multiple lines display in sequence correctly
- [ ] Signals emit at appropriate times
- [ ] Can start new dialogue after previous ends
- [ ] Cannot start dialogue while one is active
- [ ] skip_dialogue() immediately ends sequence

---

## Phase 3: Full-Screen Cutscene Player

### Tasks
- [ ] Create `UI/CutscenePlayer/` directory
- [ ] Create `cutscene_player.tscn` scene:
  - [ ] CanvasLayer (layer 99 - just below pause menu)
  - [ ] TextureRect for fullscreen cutscene image (expand mode)
  - [ ] ColorRect for background/letterboxing
  - [ ] Instance of DialogueBox as child
  - [ ] Control for skip indicator UI
- [ ] Create `cutscene_player.gd` script
- [ ] Implement cutscene data structure:
  - [ ] `CutsceneFrame` class with:
    - `image_path: String` - Path to cutscene image
    - `dialogue_lines: Array[DialogueLine]` - Text for this image
    - `duration: float` - Auto-advance time (optional)
  - [ ] `CutsceneSequence` array of frames
- [ ] Implement frame display logic:
  - [ ] Load and display image in TextureRect
  - [ ] Fade in new images (0.5s transition)
  - [ ] Display dialogue for current frame
  - [ ] Advance to next frame when dialogue completes
- [ ] Add skip functionality:
  - [ ] Detect hold on `ui_accept` or `ui_cancel` (e.g., 1.5 seconds)
  - [ ] Show skip progress indicator (filling bar/icon)
  - [ ] Emit `cutscene_skipped` signal
  - [ ] Clean up and remove cutscene player
- [ ] Implement cutscene sequencing:
  - [ ] `play_cutscene(sequence: Array[CutsceneFrame])` method
  - [ ] Auto-advance between frames
  - [ ] Handle last frame completion
  - [ ] Emit `cutscene_finished` signal
- [ ] Test with existing cutscene images:
  - [ ] Load `sona-full-photo-above.png`
  - [ ] Display with test dialogue
  - [ ] Advance to `sona-close-up-sad.png`
  - [ ] Test skip functionality
  - [ ] Test full 3-4 image sequence

**Testing Checklist:**
- [ ] Cutscene images display fullscreen correctly
- [ ] Dialogue appears over cutscene images
- [ ] Can advance through multiple frames
- [ ] Skip functionality works (hold button)
- [ ] Skip indicator provides clear feedback
- [ ] Cutscene cleans up properly after completion
- [ ] Background music continues during cutscenes (or stops if intended)

---

## Phase 4: In-Level Cutscene Triggers & Player Control

### Tasks
- [ ] Create `Entities/CutsceneTrigger/` directory
- [ ] Create `cutscene_trigger.tscn`:
  - [ ] Area2D root node
  - [ ] CollisionShape2D (RectangleShape2D)
  - [ ] Visual indicator for editor (Sprite2D or ColorRect, editor-only)
- [ ] Create `cutscene_trigger.gd` script:
  - [ ] Export variables:
    - `@export var trigger_once: bool = true`
    - `@export var cutscene_id: String`
    - `@export var disable_player_control: bool = true`
  - [ ] Detect player entry via `body_entered` signal
  - [ ] Emit `cutscene_triggered(cutscene_id)` signal
  - [ ] Disable trigger after first use (if `trigger_once`)
- [ ] Create `Common/CutsceneDirector.gd`:
  - [ ] Singleton for managing in-level cutscenes
  - [ ] Register cutscene sequences by ID
  - [ ] Handle cutscene playback in levels
  - [ ] Coordinate with DialogueManager
- [ ] Implement player control disable system:
  - [ ] Add method to disable UltimatePlatformerController
  - [ ] Option 1: `set_physics_process(false)` on controller
  - [ ] Option 2: Add `control_enabled` flag to controller script
  - [ ] Store original player velocity
  - [ ] Restore control after cutscene ends
- [ ] Create scripted player animation system:
  - [ ] `PlayerCutsceneAnimator` class for scripted movements
  - [ ] Support movement commands:
    - `walk_to(target_x: float, speed: float)`
    - `stop()`
    - `play_animation(anim_name: String)`
    - `wait(duration: float)`
    - `pickup_item()` (play pickup animation)
  - [ ] Queue-based command system
  - [ ] Emit signals when actions complete
- [ ] Test cutscene trigger in level-1:
  - [ ] Add trigger Area2D to level
  - [ ] Trigger simple dialogue on player entry
  - [ ] Verify player control disables
  - [ ] Test scripted walk animation
  - [ ] Verify control re-enables after cutscene

**Testing Checklist:**
- [ ] Cutscene trigger activates when player enters
- [ ] Trigger only fires once (if configured)
- [ ] Player control disables during cutscene
- [ ] Scripted animations play smoothly
- [ ] Player walks to target position correctly
- [ ] Control re-enables after cutscene ends
- [ ] Multiple triggers can exist in same level
- [ ] Can chain dialogue and animations together

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

## Phase 7: Opening Cutscene Implementation

### Tasks
- [ ] Set up level-1 for opening sequence:
  - [ ] Position player spawn appropriately
  - [ ] Add CutsceneTrigger at start of level
  - [ ] Configure trigger to auto-start on level load
- [ ] Create opening scripted sequence:
  - [ ] Fade into level-1 (SceneManager handles this)
  - [ ] Disable player control
  - [ ] Scripted walk sequence:
    - [ ] Sona walks slowly across cave floor
    - [ ] Stops at position
  - [ ] Dialogue: "I should turn around..."
  - [ ] Pause (1-2 seconds)
  - [ ] Walk forward a few steps
- [ ] Implement photo shard appearance:
  - [ ] Create `Entities/PhotoShard/photo_shard.tscn`
  - [ ] Small sprite at edge of screen
  - [ ] Spawn dynamically during cutscene
  - [ ] Animate in (fade + position tween)
- [ ] Photo shard pickup sequence:
  - [ ] Dialogue: "Huh...?"
  - [ ] Sona walks to photo shard
  - [ ] Play pickup animation
  - [ ] Photo shard disappears
- [ ] Full-screen cutscene sequence:
  - [ ] Transition to CutscenePlayer
  - [ ] Show `looking-at-first-scrappng.png`
  - [ ] Dialogue: "This photo...it looks familiar..."
  - [ ] Next image: `sona-close-up-sad.png`
  - [ ] Dialogue: "I think it's of me and my mom...right before..."
  - [ ] Pause for bat attack sounds (play audio)
  - [ ] Dialogue: "It kills me to be so alone..."
  - [ ] Next image: (appropriate image)
  - [ ] Dialogue: "There could be others out there..."
  - [ ] Dialogue: "But I lost my only family before I learned to fly..."
  - [ ] Fade to black image
  - [ ] Dialogue: "Maybe there's another way..."
- [ ] Transition to title screen:
  - [ ] Use SceneManager to load title screen/main menu
  - [ ] Start adventurous music (BackgroundMusic.play())
- [ ] Test complete opening sequence:
  - [ ] Full sequence plays from start to title
  - [ ] Timing feels natural
  - [ ] All dialogue displays correctly
  - [ ] Images display correctly
  - [ ] Skip functionality works
  - [ ] Music transitions smoothly

**Testing Checklist:**
- [ ] Opening cutscene auto-plays when level-1 loads
- [ ] Sona walks smoothly with scripted animation
- [ ] All dialogue displays in correct order
- [ ] Photo shard appears and pickup works correctly
- [ ] Full-screen cutscenes display proper images
- [ ] Bat attack sounds play at correct moment
- [ ] Fade to black works smoothly
- [ ] Transitions to title screen correctly
- [ ] Adventurous music starts on title screen
- [ ] Can skip entire sequence by holding button
- [ ] First butterfly tutorial tooltip shows after sequence

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

**Overall Progress:** 0/8 Phases Complete

**Last Updated:** 2025-11-09
