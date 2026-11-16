#!/usr/bin/env sh
set -eu
command -v luau >/dev/null || { echo 'luau is required on PATH' >&2; exit 1; }
command -v luau-compile >/dev/null || { echo 'luau-compile is required on PATH' >&2; exit 1; }
command -v python3 >/dev/null || { echo 'python3 is required on PATH' >&2; exit 1; }
for test in tests/*.test.luau; do luau "$test"; done
python3 tests/player_data_mock.py
python3 tests/server_flow_mock.py
python3 tests/ui_flow_mock.py
find src tests -name '*.luau' -type f | sort | while IFS= read -r file; do
    luau-compile "$file" >/dev/null
    echo "PASS compile: $file"
done
