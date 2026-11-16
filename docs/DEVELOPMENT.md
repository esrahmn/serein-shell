# Developing Serein

Serein is three repositories that are released together (one tag, one version):

| Repo | What it is | Where I keep it |
| --- | --- | --- |
| [serein-shell](https://github.com/esrahmn/serein-shell) | the shell itself (QML) | `/etc/xdg/quickshell/serein` (see below) |
| [serein-plugin](https://github.com/esrahmn/serein-plugin) | native Qt/QML modules (`Serein.*`), C++ | `~/src/serein-plugin` |
| [serein-cli](https://github.com/esrahmn/serein-cli) | the `serein` command (Python) | `~/src/serein-cli` |

The Arch package `serein-shell` (see `packaging/arch/PKGBUILD`) builds all three from the same `v<version>` tag.

## Workflow at a glance

The repositories are the source of truth. For the shell, the working copy **is** the packaged location,
`/etc/xdg/quickshell/serein`: it is a git checkout of serein-shell that you own (`sudo chown -R $USER
/etc/xdg/quickshell/serein` once; the package files and the `.git` folder live side by side). Edits there are live
as soon as the shell restarts, so there is no copy step, no symlink and no second shell running from another path.

| You changed | Run | Takes effect |
| --- | --- | --- |
| Shell QML, assets | restart the shell: `qs -c serein kill; qs -c serein -d` | right away |
| CLI (Python) | nothing, once `~/.local/bin/serein` links to the checkout (see below) | right away |
| Plugin (C++) | build, `cmake --install --prefix ~/.local`, set `QML_IMPORT_PATH` (see below) | after a rebuild |
| Settings (bar position, rain, ...) | Nexus, or edit `serein-ui.json` | live |

Day to day: edit, restart, `git commit` and `git push` (from `/etc/xdg/quickshell/serein`). A package upgrade
(`pacman -U`) rewrites the packaged files with the release contents, so commit and push before upgrading; after an
upgrade `git status` shows any difference between the release and your branch. When you want to ship or repackage,
follow [Releasing](#releasing).

`scripts/serein-deploy` is only for a *separate* checkout: it copies that checkout onto the packaged shell (and
`-n` lists what would change). Run from `/etc/xdg/quickshell/serein` itself it does nothing.

## Which copy is running?

Quickshell looks for a config named `serein` in `~/.config/quickshell` first and in `/etc/xdg/quickshell` second.
Nothing is in the first place by default, so the packaged (and edited in place) copy runs. Check with:

```sh
qs list --all        # "Config path:" shows the shell.qml in use
```

Similarly, a plugin found through `QML_IMPORT_PATH` beats `/usr/lib/qt6/qml/Serein`, and `~/.local/bin` comes before
`/usr/bin` in `PATH`. If something you edited does not show up, check which of these is in play.

## Shell (QML)

Edit the files in `/etc/xdg/quickshell/serein` and restart:

```sh
qs -c serein kill; qs -c serein -d       # config reload is off, so a restart picks the edits up
```

- Logs: `qs log -c serein`, or `/run/user/$UID/quickshell/by-id/<id>/log.log` (`qs list --all` shows the id).
- IPC: `qs -c serein ipc show` lists targets, e.g. `qs -c serein ipc call drawers toggle dashboard`.
- The bar position, lock rain and dashboard overview toggles are stored in `~/.local/state/serein/serein-ui.json`
  and are watched, so editing the file applies live.
- Do not run a second copy from another path (for example a symlink into `~/.config/quickshell`): Quickshell tells
  instances apart by config path, so killing one leaves the other running and you end up with two shells.
- To try a change without touching the running shell, copy the tree somewhere and run
  `qs -p /path/to/copy/shell.qml` (kill the real one first, two shells draw over each other).
- To set the working copy up on a new machine: install the package, then
  `sudo chown -R $USER /etc/xdg/quickshell/serein` and run in that folder `git init -b main`,
  `git remote add origin https://github.com/esrahmn/serein-shell.git`, `git fetch origin main`,
  `git reset --mixed origin/main`, `git ls-files -d | xargs -r -d '\n' git checkout --`.

## Plugin (C++)

```sh
cd ~/src/serein-plugin
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DVERSION=0.1.1 -DGIT_REVISION="$(git rev-parse HEAD)"
cmake --build build
cmake --install build --prefix ~/.local                  # modules go to ~/.local/lib/qt6/qml/Serein
```

Then make Qt look there, for every process that starts the shell: in a Hyprland Lua config
`hl.env("QML_IMPORT_PATH", HOME .. "/.local/lib/qt6/qml")` (or export it before `qs`). To try a build **without
installing**, start the shell with `QML_IMPORT_PATH=~/src/serein-plugin/build/qml`.

`QML_IMPORT_TRACE=1` prints which file each import resolved to, useful when you are unsure which plugin is loaded;
`/proc/<qs pid>/maps` shows the same for libraries. To go back to the packaged plugin, delete
`~/.local/lib/qt6/qml/Serein` and the `QML_IMPORT_PATH` line. The `build/` folder is large (~1.7 GB) and can be
deleted when you are not working on the plugin.

## CLI (Python)

```sh
ln -s ~/src/serein-cli/bin/serein ~/.local/bin/serein    # run straight from the checkout
rm ~/.local/bin/serein                                   # back to /usr/bin/serein
```

`bin/serein` runs `python -m serein` from the checkout (it follows the symlink), so there is nothing to build or
install. Python 3.13 or newer.

## Data and settings

Everything user-specific lives outside the repositories: `~/.config/serein` (`shell.json`), `~/.local/state/serein`
(scheme, wallpaper, `serein-ui.json`), `~/.local/share/serein`, `~/.cache/serein`. Package upgrades never touch them.

## Releasing

1. Commit and push all three repos (plugin: branch `serein`; the others: `main`).
2. Bump `VERSION` in serein-shell and `pkgver` in `packaging/arch/PKGBUILD`.
3. Tag the same version in all three: `git tag -a vX.Y.Z -m "..."` then `git push origin <branch> --tags`.
   Do not move a tag that has been published; make a new one.
4. Build the package from a scratch copy of the PKGBUILD so the sources do not land in the repository:

   ```sh
   mkdir /tmp/serein-pkg && cp packaging/arch/PKGBUILD /tmp/serein-pkg && cd /tmp/serein-pkg && makepkg -f
   sudo pacman -U serein-shell-*.pkg.tar.zst
   ```

   (`makepkg` clones the three repos at the tag and compiles the plugin, a few minutes.)

## Upstream (Caelestia)

- **serein-plugin** is a GitHub fork of `caelestia-dots/shell`, branch `serein` started at upstream `v2.5.0` with the shell
  QML, Nix and CI removed and everything renamed. Upstream's `main` has moved on and is not merged. To pull a newer
  release: `git fetch upstream`, merge the tag into a scratch branch, expect conflicts in the renamed files, and check
  the shell's QML still matches the plugin API before taking it.
- **serein-cli** is a fork of `caelestia-dots/cli` (`upstream` remote). Merging brings back the removed `install`/`update`
  code; drop it again.
- Credit and the GPL-3.0 license stay with the original authors; keep them in every repo.

## Known warnings

The log shows `Binding loop detected for property "active"` from `modules/dashboard/Content.qml` and a Qt thread warning
from the pixmap reader. Both come from the upstream code and are harmless.
