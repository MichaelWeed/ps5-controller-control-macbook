# PS5 DualSense Controller → macOS Productivity Remote

> **Turn a $70 gaming controller into a professional-grade productivity tool.**

This guide documents a complete solution for using a PlayStation 5 DualSense controller as a productivity remote on macOS. It includes a "kill switch" to toggle between gaming and productivity modes, D-pad navigation, voice dictation, and unlimited customization.

**Use cases:** Video editing, music production, coding, presentations, accessibility, couch computing, standing desk workflows, or anything where you want fewer keyboard shortcuts to memorize.

**Time to complete:** ~30 minutes (vs. the 5 hours of trial-and-error this guide saves you)

---

## Table of Contents

1. [The Problem](#the-problem)
2. [The Solution Architecture](#the-solution-architecture)
3. [Prerequisites](#prerequisites)
4. [Part 1: Karabiner-Elements Setup](#part-1-karabiner-elements-setup)
5. [Part 2: BetterTouchTool Setup](#part-2-bettertouchtool-setup)
6. [Part 3: Whisper Voice Dictation](#part-3-whisper-voice-dictation)
7. [The Complete Button Map](#the-complete-button-map)
8. [Troubleshooting](#troubleshooting)
9. [Future Enhancements](#future-enhancements)

---

## The Problem

Standard game controllers are seen by macOS as "Game Controllers," not productivity tools. Trying to map them directly fails because:

| Issue                  | Why It Breaks                                                                |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Click Conflict**     | macOS hardwires `Control+Click` to Right Click, breaking Hyper Key combos    |
| **D-Pad Non-Standard** | PS5 D-pad sends HID Usage IDs (144-147), not standard button presses         |
| **Secure Input**       | AppleScript/event injection fails in password managers or secure terminals   |
| **No Toggle**          | You can't switch between "gaming" and "productivity" without restarting apps |

---

## The Solution Architecture

We bypass these limits with a **three-layer stack**:

```
┌─────────────────────────────────────────────────────────────┐
│                    PS5 DualSense Controller                  │
│                  (Vendor: 1356, Product: 3302)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              LAYER 1: Karabiner-Elements                     │
│  • Intercepts raw HID signals                                │
│  • Transforms buttons → "Hyper Keys" (⌘+⌃+⌥+⇧ + key)        │
│  • "Kill Switch" variable: devjoyable_active                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              LAYER 2: BetterTouchTool                        │
│  • Listens for Hyper Key combos                              │
│  • Executes actions: launch apps, OCR, dictation             │
│  • Handles "Left Click Without Modifiers" fix                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              LAYER 3: Shell Scripts                          │
│  • whisper_dictation.sh: Local voice-to-text                 │
│  • Developer text replacements (and and → &&)                │
└─────────────────────────────────────────────────────────────┘
```

### What is a "Hyper Key"?

A **Hyper Key** is pressing all four modifier keys simultaneously: `⌘ Command + ⌃ Control + ⌥ Option + ⇧ Shift`. This combination is virtually never used by any application, making it a "private namespace" for custom shortcuts.

When you press a controller button, Karabiner converts it to `Hyper + [key]`. BetterTouchTool then intercepts this combo and runs your custom action.

**Example:** Pressing **L1** on your controller sends `Hyper + 1`, which BTT could map to "Show/Hide Terminal."

---

## Prerequisites

### Required Software

| Software                                                   | Purpose                     | Install                                  |
| ---------------------------------------------------------- | --------------------------- | ---------------------------------------- |
| [Karabiner-Elements](https://karabiner-elements.pqrs.org/) | Low-level input remapping   | `brew install --cask karabiner-elements` |
| [BetterTouchTool](https://folivora.ai/)                    | Action execution & gestures | Download from website (paid, ~$10)       |
| [sox](http://sox.sourceforge.net/)                         | Audio recording             | `brew install sox`                       |
| [whisper-cpp](https://github.com/ggerganov/whisper.cpp)    | Local voice transcription   | `brew install whisper-cpp`               |

### Required Permissions

Grant these in **System Settings → Privacy & Security**:

- **Accessibility**: Karabiner-Elements, BetterTouchTool
- **Input Monitoring**: Karabiner-Elements, Karabiner-EventViewer
- **Microphone**: Terminal, BetterTouchTool (for voice dictation)

---

## Part 1: Karabiner-Elements Setup

### Step 1.1: Enable Your Controller

1. Open **Karabiner-Elements** → **Devices** tab
2. Find your DualSense controller: `DualSense Wireless Controller (Vendor ID: 1356)`
3. Check **"Modify events"**

### Step 1.2: Install the Configuration

Copy this JSON file to your Karabiner complex modifications folder:

```bash
cp dualsense_devjoyable.json ~/.config/karabiner/assets/complex_modifications/
```

<details>
<summary><strong>📄 Click to expand: dualsense_devjoyable.json</strong></summary>

```json
{
  "title": "DualSense DevJoyable (Final Stabilized)",
  "rules": [
    {
      "description": "DualSense Integrated - Toggle and Remap",
      "manipulators": [
        {
          "type": "basic",
          "description": "Toggle mode (Options button10)",
          "from": { "pointing_button": "button10" },
          "to": [
            { "set_variable": { "name": "devjoyable_active", "value": 1 } }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            {
              "type": "variable_unless",
              "name": "devjoyable_active",
              "value": 1
            }
          ]
        },
        {
          "type": "basic",
          "description": "Untoggle mode (Options button10)",
          "from": { "pointing_button": "button10" },
          "to": [
            { "set_variable": { "name": "devjoyable_active", "value": 0 } }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "L1 -> Hyper+1",
          "from": { "pointing_button": "button5" },
          "to": [
            {
              "key_code": "1",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "R1 -> Hyper+2",
          "from": { "pointing_button": "button6" },
          "to": [
            {
              "key_code": "2",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "Square -> Hyper+3",
          "from": { "pointing_button": "button1" },
          "to": [
            {
              "key_code": "3",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "Cross -> Hyper+4",
          "from": { "pointing_button": "button2" },
          "to": [
            {
              "key_code": "4",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "Circle -> Hyper+5",
          "from": { "pointing_button": "button3" },
          "to": [
            {
              "key_code": "5",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "Triangle -> Hyper+6",
          "from": { "pointing_button": "button4" },
          "to": [
            {
              "key_code": "6",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "L2 -> Hyper+7",
          "from": { "pointing_button": "button7" },
          "to": [
            {
              "key_code": "7",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "R2 -> Hyper+8",
          "from": { "pointing_button": "button8" },
          "to": [
            {
              "key_code": "8",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "Share -> Hyper+9",
          "from": { "pointing_button": "button9" },
          "to": [
            {
              "key_code": "9",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "Touchpad -> Hyper+0",
          "from": { "pointing_button": "button14" },
          "to": [
            {
              "key_code": "0",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "L3 -> Hyper+L",
          "from": { "pointing_button": "button11" },
          "to": [
            {
              "key_code": "l",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "R3 -> Hyper+R",
          "from": { "pointing_button": "button12" },
          "to": [
            {
              "key_code": "r",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "D-Pad Up -> Hyper+Up",
          "from": { "generic_desktop": "dpad_up" },
          "to": [
            {
              "key_code": "up_arrow",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "D-Pad Down -> Hyper+Down",
          "from": { "generic_desktop": "dpad_down" },
          "to": [
            {
              "key_code": "down_arrow",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "D-Pad Right -> Hyper+Right",
          "from": { "generic_desktop": "dpad_right" },
          "to": [
            {
              "key_code": "right_arrow",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        },
        {
          "type": "basic",
          "description": "D-Pad Left -> Hyper+Left",
          "from": { "generic_desktop": "dpad_left" },
          "to": [
            {
              "key_code": "left_arrow",
              "modifiers": ["command", "control", "option", "shift"]
            }
          ],
          "conditions": [
            {
              "type": "device_if",
              "identifiers": [{ "vendor_id": 1356, "product_id": 3302 }]
            },
            { "type": "variable_if", "name": "devjoyable_active", "value": 1 }
          ]
        }
      ]
    }
  ]
}
```

</details>

### Step 1.3: Enable the Rule

1. Open **Karabiner-Elements** → **Complex Modifications**
2. Click **"Add rule"**
3. Enable **"DualSense Integrated - Toggle and Remap"**

### Step 1.4: Verify It Works

1. Open **Karabiner-EventViewer** (comes with Karabiner-Elements)
2. Press **Options** button on your controller
3. Press any face button (e.g., Triangle)
4. You should see `key_code: 6` with all four modifiers

---

## Part 2: BetterTouchTool Setup

### Understanding the "Kill Switch"

Your controller now has two modes:

| Mode            | Options LED | Behavior                            |
| --------------- | ----------- | ----------------------------------- |
| **Gaming Mode** | Off         | Controller works normally for games |
| **Dev Mode**    | On          | Buttons trigger Hyper Key macros    |

Press **Options** to toggle between modes.

### Step 2.1: Create Hyper Key Triggers

In BetterTouchTool:

1. Go to **Keyboard Shortcuts** section
2. Click **+** to add a new trigger
3. Record the shortcut: `⌘⌃⌥⇧ + [key]`
4. Assign an action

### Example Mappings

| Button   | Hyper Key      | Suggested Action               |
| -------- | -------------- | ------------------------------ |
| L1       | `Hyper+1`      | Show/Hide Terminal             |
| R1       | `Hyper+2`      | Show/Hide Browser              |
| Square   | `Hyper+3`      | ⌘F (Find)                      |
| Cross    | `Hyper+4`      | Enter                          |
| Circle   | `Hyper+5`      | ⌘W (Close Tab)                 |
| Triangle | `Hyper+6`      | ⌘T (New Tab)                   |
| L2       | `Hyper+7`      | Mission Control                |
| R2       | `Hyper+8`      | ⌘L (Address Bar)               |
| Share    | `Hyper+9`      | Screenshot to Clipboard        |
| Touchpad | `Hyper+0`      | Whisper Dictation (see Part 3) |
| L3       | `Hyper+L`      | Left Click (Without Modifiers) |
| R3       | `Hyper+R`      | Right Click                    |
| D-Pad    | `Hyper+Arrows` | Arrow key navigation           |

### Step 2.2: The Left Click Fix

**Problem:** Because Hyper Key includes `Control`, macOS interprets Left Click as Right Click.

**Solution:** In BTT, use the action **"Left Click - Without Modifier Keys"** to strip modifiers before clicking.

1. Add trigger: `Hyper+L`
2. Action: **Left Click - Without Modifier Keys**

---

## Part 3: Whisper Voice Dictation

### Why Whisper Instead of Apple Dictation?

Apple's dictation often produces developer-hostile results:

- "Firebase" → "fire base"
- "GitHub" → "get hub"
- "npm install" → "in PM install"

**Whisper.cpp** runs locally with higher accuracy and allows custom text replacements.

### Step 3.1: Download the Whisper Model

```bash
mkdir -p ~/.whisper-models
cd ~/.whisper-models
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin" -o ggml-base.bin
```

### Step 3.2: Install the Dictation Script

Save this script as `whisper_dictation.sh`:

<details>
<summary><strong>📄 Click to expand: whisper_dictation.sh</strong></summary>

```bash
#!/bin/zsh

# Voice Dictation with Whisper (Hold-to-Record Version)
# Usage: Run this script from BetterTouchTool

# Configuration
TEMP_DIR="${TMPDIR:-/tmp}/whisper_dictation"
AUDIO_FILE="$TEMP_DIR/recording.wav"
TRANSCRIPTION_FILE="${AUDIO_FILE}.txt"
PID_FILE="$TEMP_DIR/sox.pid"

# Paths
SOX_PATH="/opt/homebrew/bin/sox"
WHISPER_PATH="/opt/homebrew/bin/whisper-cli"
WHISPER_MODEL="$HOME/.whisper-models/ggml-base.bin"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Cleanup function
cleanup() {
    rm -f "$AUDIO_FILE" "$TRANSCRIPTION_FILE" "$PID_FILE"
}

# Check if we're stopping a recording
if [ -f "$PID_FILE" ]; then
    echo "Stopping recording..."
    SOX_PID=$(cat "$PID_FILE")
    kill -INT $SOX_PID 2>/dev/null
    sleep 1
    rm -f "$PID_FILE"

    if [ ! -f "$AUDIO_FILE" ] || [ ! -s "$AUDIO_FILE" ]; then
        echo "Error: Recording failed"
        cleanup
        exit 1
    fi

    echo "Transcribing..."
    $WHISPER_PATH -m "$WHISPER_MODEL" -otxt "$AUDIO_FILE" 2>/dev/null

    if [ ! -f "$TRANSCRIPTION_FILE" ]; then
        echo "Error: Transcription failed"
        cleanup
        exit 1
    fi

    TRANSCRIPTION=$(cat "$TRANSCRIPTION_FILE" | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Developer text replacements
    TRANSCRIPTION=$(echo "$TRANSCRIPTION" | sed -E '
        s/\bfire base\b/firebase/gi
        s/\bgit hub\b/github/gi
        s/\btype script\b/typescript/gi
        s/\band and\b/\&\&/g
        s/\bor or\b/||/g
        s/\bdash dash\b/--/g
        s/\bequals equals\b/==/g
    ')

    # Notification
    osascript -e "display notification \"Typing transcription...\" with title \"Whisper\""

    # Type into frontmost app
    osascript -e "tell application \"System Events\" to keystroke \"$TRANSCRIPTION\"" 2>/dev/null

    cleanup
    echo "Done!"
else
    echo "Starting recording..."
    $SOX_PATH -d -r 16000 -c 1 -b 16 "$AUDIO_FILE" >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    echo "Recording... (Run again to stop)"
fi
```

</details>

Make it executable:

```bash
chmod +x whisper_dictation.sh
```

### Step 3.3: Configure BTT for Hold-to-Record

1. Create trigger: `Hyper+0` (Touchpad button)
2. Action: **Execute Shell Script**
3. Launch Path: `/bin/zsh`
4. Parameters: `-c`
5. Script: `/path/to/whisper_dictation.sh`

**Usage:**

- **Press Touchpad** → Starts recording
- **Press Again** → Stops, transcribes, types result

---

## The Complete Button Map

| Button          | Gaming Mode | Dev Mode (Hyper Key) | Suggested Action  |
| --------------- | ----------- | -------------------- | ----------------- |
| **Options**     | Pause       | Toggle Dev Mode      | Kill Switch       |
| **L1**          | L1          | `Hyper+1`            | Show Terminal     |
| **R1**          | R1          | `Hyper+2`            | Show Browser      |
| **Square**      | Square      | `Hyper+3`            | Find (⌘F)         |
| **Cross**       | Cross       | `Hyper+4`            | Enter             |
| **Circle**      | Circle      | `Hyper+5`            | Close Tab         |
| **Triangle**    | Triangle    | `Hyper+6`            | New Tab           |
| **L2**          | L2          | `Hyper+7`            | Mission Control   |
| **R2**          | R2          | `Hyper+8`            | Address Bar       |
| **Share**       | Share       | `Hyper+9`            | Screenshot        |
| **Touchpad**    | Click       | `Hyper+0`            | Whisper Dictation |
| **L3**          | L3          | `Hyper+L`            | Left Click        |
| **R3**          | R3          | `Hyper+R`            | Right Click       |
| **D-Pad Up**    | Up          | `Hyper+↑`            | Arrow Up          |
| **D-Pad Down**  | Down        | `Hyper+↓`            | Arrow Down        |
| **D-Pad Left**  | Left        | `Hyper+←`            | Arrow Left        |
| **D-Pad Right** | Right       | `Hyper+→`            | Arrow Right       |

---

## Troubleshooting

### Nothing happens when I press buttons

1. **Check Kill Switch:** Press Options first to enable Dev Mode
2. **Check Karabiner:** Verify rule is enabled and controller is in Devices
3. **Check EventViewer:** Confirm buttons are sending Hyper combos

### D-Pad doesn't work

The DualSense D-pad uses `generic_desktop` events, not `hat_switch`. Use:

```json
"from": { "generic_desktop": "dpad_up" }
```

**Not:**

```json
"from": { "hat_switch": 0 }
```

### Left Click triggers Right Click menu

This happens because `Control+Click = Right Click` on macOS. In BTT, use:

- **Action:** "Left Click - Without Modifier Keys"

### Whisper transcription fails

1. Verify model exists: `ls ~/.whisper-models/ggml-base.bin`
2. Check it's not corrupted: Should be ~141MB
3. Re-download if needed (see Part 3)

### AppleScript typing doesn't work

Grant **Accessibility** permissions to BetterTouchTool:

1. System Settings → Privacy & Security → Accessibility
2. Toggle BetterTouchTool OFF then ON

---

## Future Enhancements

### DualSense Haptic Feedback

The DualSense supports haptics over Bluetooth. Ideas:

- **Heavy pulse** when Kill Switch activates
- **Light tap** when Whisper transcription completes
- **Rumble pattern** for errors

### Adaptive Triggers

Use L2/R2 resistance for:

- Text selection intensity
- Scroll speed control
- Volume adjustment

---

## Credits

- **Karabiner-Elements** by pqrs.org
- **BetterTouchTool** by folivora.ai
- **Whisper.cpp** by ggerganov
- **sox** by the SoX team

---

## License

MIT License - Use freely, attribution appreciated.

---

**Questions?** Open an issue or find us on the [BetterTouchTool Forum](https://community.folivora.ai/).
