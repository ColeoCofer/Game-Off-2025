# DialogueBox Component

A retro-styled dialogue box with typewriter text effect for displaying game dialogue.

## Features

- **Typewriter Effect**: Text appears character-by-character at configurable speed
- **Input Handling**: Press Space/Enter/A button to advance or instantly complete text
- **Fade Animations**: Smooth fade in/out transitions
- **Visual Indicators**: Blinking arrow shows when ready to advance
- **Character Names**: Optional character name display above dialogue
- **Audio Support**: Built-in audio player for text blip sounds (sound file not yet added)
- **Customizable**: Export variables for typing speed, fade duration, auto-advance, etc.

## Usage

### Basic Setup

1. **Instance the Scene**: Add `dialogue_box.tscn` to your scene
2. **Position**: The dialogue box anchors to the bottom of the screen by default
3. **Connect Signals**: Connect to dialogue events in your script

### Example Code

```gdscript
extends Node2D

@onready var dialogue_box = $DialogueBox

var dialogues = [
    "Hello! This is the first line.",
    "Here's the second line of dialogue.",
    "And this is the final line."
]
var current_index = 0

func _ready():
    # Connect signals
    dialogue_box.dialogue_advanced.connect(_on_dialogue_advanced)
    dialogue_box.dialogue_box_shown.connect(_on_box_shown)
    dialogue_box.dialogue_box_hidden.connect(_on_box_hidden)

    # Start dialogue
    start_dialogue()

func start_dialogue():
    dialogue_box.show_box()
    await dialogue_box.dialogue_box_shown
    show_next_line()

func show_next_line():
    if current_index < dialogues.size():
        dialogue_box.show_dialogue(dialogues[current_index])
    else:
        dialogue_box.hide_box()

func _on_dialogue_advanced():
    current_index += 1
    show_next_line()

func _on_box_shown():
    print("Dialogue box appeared!")

func _on_box_hidden():
    print("Dialogue box hidden!")
    current_index = 0
```

## API Reference

### Methods

#### `show_box()`
Fades in the dialogue box with animation.

#### `hide_box()`
Fades out the dialogue box with animation.

#### `show_dialogue(text: String, character_name: String = "")`
Displays dialogue text with optional character name and starts typewriter effect.
- `text`: The dialogue text to display
- `character_name`: Optional name to show above dialogue (empty string to hide)

#### `set_typing_speed(speed: float)`
Changes the typing speed in characters per second.
- `speed`: Characters per second (default: 30.0)

#### `is_text_complete() -> bool`
Returns true if typewriter effect has finished and dialogue can be advanced.

#### `clear()`
Clears all dialogue text and resets the dialogue box state.

### Signals

#### `dialogue_advanced`
Emitted when the player presses the advance button (Space/Enter/A) and text is complete.

#### `text_fully_displayed`
Emitted when the typewriter effect completes displaying all text.

#### `dialogue_box_shown`
Emitted when the fade-in animation completes.

#### `dialogue_box_hidden`
Emitted when the fade-out animation completes.

### Export Variables

Configure these in the Godot Inspector:

- **typing_speed** (float): Characters per second for typewriter effect. Default: 30.0
- **fade_duration** (float): Seconds for fade in/out animations. Default: 0.2
- **auto_advance_delay** (float): Seconds before auto-advancing. 0 = manual only. Default: 0.0
- **play_text_blip** (bool): Play sound on each character. Default: true
- **blip_interval** (int): Play blip every N characters (reduces spam). Default: 2

## Testing

Run `dialogue_box_test.tscn` to test the component:
1. Open the scene in Godot
2. Press F6 or click "Run Current Scene"
3. Click the button or press Enter to start test dialogue
4. Press Space/Enter to advance through test lines
5. Press while text is appearing to complete instantly

## Integration with DialogueManager

This component is designed to be used with the DialogueManager autoload (Phase 2).
The manager will handle:
- Instantiating dialogue boxes
- Managing dialogue sequences
- Coordinating with game systems

For standalone use (like in cutscenes), you can directly instance and control the dialogue box as shown in the examples above.

## TODO

- [ ] Add audio file for text blip sound effect
- [ ] Create retro pixel art border texture (currently using ColorRect)
- [ ] Add character portrait support
- [ ] Implement BBCode styling for text effects (bold, color, etc.)
- [ ] Add dialogue history/backlog feature
