# Changelog

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
