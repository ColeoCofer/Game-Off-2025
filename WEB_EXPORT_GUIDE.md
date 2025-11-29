# Exporting Godot 4.5 Game to HTML5 for itch.io

This guide covers how to export the game for web/browser play on itch.io.

## Key Requirements

### 1. Renderer Change Required

The project currently uses **Forward Plus** renderer, but web export only works with **Compatibility** renderer.

To change:
- Go to **Project → Project Settings → Rendering → Renderer**
- Change to **Compatibility** (or create a separate export preset with Compatibility)

### 2. Export Templates

- Open **Editor → Manage Export Templates**
- Download the Web export templates if not already installed

### 3. Create Web Export

- Go to **Project → Export**
- Click **Add...** → **Web**
- Configure the preset

## The SharedArrayBuffer Situation

Godot 4 originally required SharedArrayBuffer (threading), which caused issues on itch.io. Good news: **Godot 4.3+ lets you disable threads**!

In your Web export settings:
- **Uncheck "Thread Support"** - This avoids the SharedArrayBuffer requirement entirely
- Note: This may affect audio streaming quality slightly, but works on all browsers

If you keep threads enabled:
- Enable **"SharedArrayBuffer support"** in itch.io's Embed Options → Frame Options
- Game will only work in Chrome-based browsers (not Firefox/Safari)

## itch.io Upload Requirements

| Requirement | Specification |
|------------|---------------|
| File format | ZIP file only |
| Entry point | Must have `index.html` |
| Max files | 1,000 files |
| Max size | 500MB total, 200MB per file |
| Paths | Relative paths only, case-sensitive |

## Recommended Export Steps

1. **Change renderer** to Compatibility (or test if your shaders work)
2. **Install Web export templates** in Godot
3. **Create Web export preset** with Thread Support disabled
4. **Export** to a folder
5. **ZIP** the exported files
6. **Upload** to itch.io as HTML game
7. Set viewport dimensions to **1280x720** (the 2x scale)

## Potential Issues to Watch

- Custom shaders (10 total) may need adjustment for Compatibility renderer
- Audio autoplay is restricted in browsers - user interaction required first
- Safari has WebGL 2.0 issues - recommend Chromium/Firefox

## Sources

- [itch.io HTML5 Documentation](https://itch.io/docs/creators/html5)
- [Godot Web Export Documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [itch.io SharedArrayBuffer Support](https://itch.io/t/2025776/experimental-sharedarraybuffer-support)
- [Godot 4.3 Web Export Progress](https://godotengine.org/article/progress-report-web-export-in-4-3/)
- [How to export Godot 4 to itch.io](https://foosel.net/til/how-to-export-a-godot-4-game-to-run-on-the-web-on-itchio/)
