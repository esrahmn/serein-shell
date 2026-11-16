#!/usr/bin/env sh

cat ~/.local/state/serein/sequences.txt 2>/dev/null

exec "$@"
