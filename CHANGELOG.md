# Changelog

## Unreleased

- OSD: the volume and microphone sliders fill with a moving sine wave, and the brightness
  handle shows a moon whose phase follows the brightness.
- New `scripts/restart`: restarts the shell, shows the errors if it does not load, and falls back to the last copy that
  worked (kept in `~/.cache/serein/last-good`), so a mistake never leaves you without a bar.
- Left/right bar now matches the top/bottom one: the workspace pill collapses to the focused workspace and expands on
  hover, the window title sits right below it, the clock is centred and the tray sits next to the status icons.
- Fix: the control center showed "AC, No battery" on laptops (a property named `onBattery` clashed with QML's signal
  handler naming); it now shows the real level and charging time.
- Fix: `drawers list` / `isOpen` no longer fail when there is no active monitor.

## 0.2.0

**Dashboard**
- Night sky hero on the Dashboard tab: moon phase, 24-hour clock, weather and your CPU, memory and disk as three
  layered waves. Rain falls in it when it rains. Below it: this week, now playing (the cat sits on the card) and you.
- Media tab redesigned: big centred (karaoke style) lyrics, the cover with the cava ring in the header, and a control
  bar with a transport pill (play turns into a cookie while playing), wavy seek bar and Shuffle / Repeat chips.
  Performance tab gets a "System load" wave header.
- Weather tab redesigned: a night-sky scene with the sun (or moon) travelling along its arc and the moon phase, the
  next hours as a temperature curve, and the week with temperature range bars.
- New IPC: `dashboard tab <0-4>` switches the dashboard tab.

**Wallpaper**
- New wallpapers are revealed by a shape sweeping across instead of a plain fade: a big moon (default), a wave
  front or slanted rain streaks. Pick one, or plain fade, in Nexus → Serein → Wallpaper.

**Shortcuts**
- Wallpaper picker: global shortcut `wallpaper` (or `qs -c serein ipc call wallpaperpicker toggle`) opens the
  launcher on its wallpaper list. Bind it to Ctrl + Super + T.
- Random wallpaper: global shortcut `wallpaperRandom` (Ctrl + Super + Alt + T) or `ipc call wallpaper random`.

## 0.1.2

**Control center**
- New card opened from the status icons in the bar (hover or click, all four bar edges): brightness as a moon phase,
  Wi-Fi / Bluetooth / Quiet and Mic / Awake / Record tiles, wavy volume slider, battery drop and power mode.
  Right-click the Wi-Fi or Bluetooth tile for the network or device list. IPC: `controlcenter toggle`.
- Status icons share this one panel instead of a separate popout each.

**Bar**
- No background pills: the bar follows the panel, which is transparent when transparency is on.
- Workspaces collapse to a single pill that expands on hover; window icons are gone.
- Top/bottom bar: the window title sits next to the workspaces, the clock is centred, and the tray sits next to the
  status icons. Bluetooth and the clock's calendar icon are off by default.

**Look**
- Line icons (Phosphor, MIT) in place of Material Symbols, switchable in Nexus. Active icons use the bold weight.
- Bar and panel opacity slider; blur now follows it.
- Popouts get the same transparency and blur as the bar.

**Identity**
- Rain can follow the real weather (only while it rains). Lock screen and control center.
- Moon phase of the day on the dashboard weather card.
- New Nexus page "Serein" with the Serein-only settings in one place.

**Other**
- Utilities panel no longer repeats Keep awake and the quick toggles (they live in the control center).
- Fixes: calendar contrast, icon centring, a screenshot picker that closed every panel.

Needs serein-plugin 0.1.2 for the new defaults.
