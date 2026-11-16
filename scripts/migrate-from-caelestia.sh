#!/bin/sh
# One-time migration of user data from the Caelestia layout to Serein's.
#
# serein-plugin, serein-cli and the shell all read and write ~/.config/serein, ~/.local/state/serein,
# ~/.local/share/serein and ~/.cache/serein. This copies (never moves or deletes) whatever exists in the
# matching caelestia folders, so the Caelestia install keeps working untouched. Existing serein folders
# are left alone.

set -eu

copy_dir() {
    old="$1"
    new="$2"

    if [ ! -d "$old" ]; then
        echo "skip   $old (not found)"
    elif [ -e "$new" ]; then
        echo "skip   $new (already exists)"
    else
        mkdir -p "$(dirname "$new")"
        cp -a "$old" "$new"
        echo "copied $old -> $new"
    fi
}

config="${XDG_CONFIG_HOME:-$HOME/.config}"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
state="${XDG_STATE_HOME:-$HOME/.local/state}"
cache="${XDG_CACHE_HOME:-$HOME/.cache}"

copy_dir "$config/caelestia" "$config/serein"
copy_dir "$data/caelestia" "$data/serein"
copy_dir "$state/caelestia" "$state/serein"
copy_dir "$cache/caelestia" "$cache/serein"

echo "done. Restart the shell."
