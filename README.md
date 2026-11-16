# Serein

A [Quickshell](https://quickshell.org) desktop shell for Hyprland, forked from
[Caelestia](https://github.com/caelestia-dots/shell) and rebranded around a crescent moon and fine rain
(*sérein*: rain falling from a clear evening sky).

Serein keeps Caelestia's shell (bar, dashboard, launcher, sidebar, notifications, lock screen, the Nexus
settings app) and adds its own identity and a few features on top.

> Serein is a fork and is **not affiliated with** the Caelestia project. All credit for the original shell
> goes to its authors; see [Credits and license](#credits-and-license).

## What is different from Caelestia

- **Branding**: Serein name, logo (crescent moon and rain, drawn as vectors so it follows the theme colours),
  animated logo on the About page, and its own version number.
- **Bar on any edge**: left, right, top or bottom, switchable live from Nexus. The top/bottom bar is a
  separate horizontal layout (workspaces with window icons, clock, tray, status icons, active window).
- **Workspaces tab in the dashboard**: a grid of workspaces with live window previews (screencopy). Click a
  workspace to switch to it, click a window to focus it, or drag a window onto another workspace to move it.
- **Lock screen**: falling rain over the blurred background, and a Media card that switches to a compact row
  when the column is short.
- **Window info panel**: clicking the active window title in the bar opens the detached window info panel
  (preview, details, move-to-workspace buttons).
- **Nexus options** for the above: Panels → Taskbar → Position, Panels → Dashboard → Tabs → Workspaces,
  Panels → Lock screen.

## Requirements

Serein reuses Caelestia's compiled plugin (the `Caelestia.*` QML modules) instead of shipping its own, so you
need Caelestia's shell package installed alongside it, with its dependencies:

- Hyprland (the Lua config API is used for some dispatchers; legacy dispatch strings are used as a fallback)
- `quickshell` (a recent build; Caelestia tracks `quickshell-git`)
- `caelestia-shell` **2.5.0**: provides the plugin in `/usr/lib/qt6/qml/Caelestia`
- [`serein-cli`](https://github.com/esrahmn/serein-cli) (a fork of `caelestia-cli`): used for wallpapers, colour
  schemes, recording, the clipboard and emoji pickers, and for talking to the running shell (`serein shell ...`).
  Install it so `serein` is on your `PATH`; see its README

**Pin `caelestia-shell`.** Serein's QML is written against plugin version 2.5.0. If the package updates and the
plugin API changes, Serein can break while stock Caelestia keeps working. On Arch, add it to `IgnorePkg` in
`/etc/pacman.conf`, and compare against the new upstream release before updating.

## Install

```sh
git clone https://github.com/esrahmn/serein-shell ~/.config/quickshell/serein
qs -c serein
```

To start it with Hyprland, run `qs -c serein` from your autostart (for example `hl.exec_cmd("qs -c serein")` in a
Lua config). Do not run it at the same time as the stock Caelestia shell: they would draw over each other.

## Keybinds

Serein registers its global shortcuts under the `serein` app id (Caelestia's are under `caelestia`). Example
Hyprland Lua binds:

```lua
hl.bind("SUPER + I", hl.dsp.global("serein:nexus"),     { description = "Open Nexus settings" })
hl.bind("SUPER + J", hl.dsp.global("serein:sidebar"),   { description = "Toggle sidebar" })
hl.bind("CTRL + ALT + Delete", hl.dsp.global("serein:session"), { description = "Session menu" })
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("qs -c serein ipc call drawers toggle launcher"), { release = true })
```

Available shortcuts: `nexus`, `showall`, `dashboard`, `session`, `launcher`, `launcherInterrupt`, `sidebar`,
`utilities`, plus media, brightness and screenshot shortcuts. Run `qs -c serein ipc show` to list every IPC
target (`drawers`, `lock`, `nexus`, `notifs`, `mpris`, `audio`, `wallpaper`, ...).

## Configuration

| File | What it holds |
| --- | --- |
| `~/.config/caelestia/shell.json` | Caelestia's own settings (same format and location as upstream, deliberately: the plugin and the CLI read it) |
| `~/.local/state/caelestia/serein-ui.json` | Serein's own settings, which the Caelestia config has no field for |

`serein-ui.json` keys (all editable from Nexus; the file is watched, so changes apply live):

| Key | Values | Default |
| --- | --- | --- |
| `barPosition` | `"left"`, `"right"`, `"top"`, `"bottom"` | `"left"` |
| `lockRain` | `true` / `false` | `true` |
| `dashboardOverview` | `true` / `false` | `true` |

## Notes

- Bar on the right: the sidebar, utilities, notifications and OSD stay on the right as well, next to the bar.
- Top/bottom bar: the dashboard (top) and launcher / utilities (bottom) open from the very edge of the screen
  instead of the whole bar.
- The horizontal workspace indicator does not draw special workspaces separately; it only dims.

## Credits and license

Serein is a modified version of **Caelestia** (<https://github.com/caelestia-dots/shell>), copyright its
authors, and it keeps Caelestia's license.

Serein is free software, released under the **GNU General Public License v3.0**; see [LICENSE](LICENSE). In
line with the GPL, the changes made on top of Caelestia are listed above and in the git history.
