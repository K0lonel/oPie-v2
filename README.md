# oPie v2

A lightweight, hardware-accelerated radial menu built in AutoHotkey v2.

This project renders a customizable ring of icons using Direct2D. It automatically scans for icons, extracts their dominant vibrant colors, and dynamically tints the UI elements (borders, glows) to match the selected item.

### Features
* **Fast Rendering:** Uses Direct2D via `ShinsOverlayClass` for smooth, antialiased graphics.
* **Dynamic Theming:** Automatically calculates HSL color values from your icons to tint the menu elements in real-time.
* **Auto-Discovery:** Simply drop images into the assets folder; the script scans and builds the menu automatically.
* **Smart Selection:** Uses mouse angle detection rather than collision boxes for fluid gesture selection.
* **Shape Control:** Supports circular or elliptical ("Earth-like") rendering.
* **Execution:** Bind unique, custom AHK scripts to each box independently.
* **Plugin Support:** Define complex custom functions in an external `Plugins.ahk` file and invoke them directly from the menu.

### Setup & Usage

1. Ensure you have [AutoHotkey v2](https://www.autohotkey.com/) installed (experimental as exe).
2. Ensure `ShinsOverlayClass.ahk` and `cJson.ahk` are in your Lib folder.
3. Run `oPie.ahk`.
4. Default hotkey is **Alt+D** (Hold to open, release to select, center to cancel).

### Custom Functions (Plugins)
To keep your logic clean, you can define your own functions in `Plugins.ahk`. The script automatically includes this file, allowing you to call these functions directly from your `settings.json`.

**Example:**
1. In `Plugins.ahk`:
   ```autohotkey
   MyCustomMacro() {
       MsgBox "Hello from Plugins!"
   }
   ```
2. In `settings.json`:
   ```json
   { "icon": "star", "script": "MyCustomMacro()" }
   ```

### Folder Structure
The script relies on a specific folder structure to load assets:

```text
/assets
    /wheel      # Base UI elements (circle.png, border.png, pointer.png, etc.)
    /icons      # Your item icons (diamond.png, firefox.png, etc.) where you can add your own and then use it in the settings.json
```

### Credits
* [ShinsOverlayClass](https://github.com/Spawnova/ShinsOverlayClass) by Spawnova: The Direct2D wrapper used for all rendering operations.
* [cJson](https://github.com/G33kDude/cJson.ahk) by G33kDude: The first and only AutoHotkey JSON library to use embedded compiled C for high performance.
* GDI+: Used for the initial bitmap analysis and color extraction logic.