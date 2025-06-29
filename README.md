# 🧠 Send2Discord – Smart Hotkey-Based Mention Launcher

This AutoHotkey v2 script lets you define keyboard shortcuts that copy a link and paste it into Discord, along with auto-typed mentions like `@fletcher` or `<@123>`.

---

## 📦 Features

- ⚡ Hotkey binding for link sharing  
- 🎯 Dynamic mention tagging via popup  
- 💬 GUI for adding/editing hotkeys  
- 🧾 Saves settings to `send2settings.ini`  

---

## 🚀 Setup

1. Run the script
2. Choose your global hotkey and context-menu offset
3. Use the global hotkey to open the manager

---

## 🎛️ Hotkey Manager GUI

- Add, edit, or delete hotkeys with modifiers, keys, and mentions  
- Click "Edit Mentions" to launch a dynamic tag editor  
- Tags appear as pill-style buttons - click any to remove  
- Reflows automatically and supports name resizing

---

## ⚙️ How It Works

1. Right-clicks mouse position  
2. Presses Down to reach “Copy link address”  
3. Switches to Discord and pastes the link  
4. Types out each mention using auto-suggest and `{Tab}`  

---

## 🔒 Notes

- Works with Discord desktop only  
- Mentions are stored per-hotkey in the `.ini` file  
- Clipboard contents are preserved after posting  

---

> Created with ❤️ using AutoHotkey v2
