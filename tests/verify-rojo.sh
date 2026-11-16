#!/usr/bin/env sh
set -eu
command -v rojo >/dev/null || { echo 'rojo is required on PATH' >&2; exit 1; }
command -v python3 >/dev/null || { echo 'python3 is required on PATH' >&2; exit 1; }
file="$(mktemp "${TMPDIR:-/tmp}/aether.XXXXXX.rbxlx")"
trap 'rm -f "$file"' EXIT HUP INT TERM
rojo build default.project.json -o "$file"
python3 tests/verify_build.py "$file"
