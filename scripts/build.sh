#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$TASK_ROOT"
mode="${1:-live}"
device="${2:-edge840}"
case "$mode" in live) jungle=monkey.jungle ;; demo|hardware|test) jungle="$mode.jungle" ;; snapshot) jungle="" ;; *) echo 'Usage: scripts/build.sh [live|demo|hardware|test|snapshot] [device|all]' >&2; exit 2 ;; esac
python3 scripts/generate-project.py --check
list_devices() { python3 -c 'import json;print("\n".join(json.load(open("config/devices.json"))["devices"]))'; }
known="$(list_devices)"
if [ "$device" != all ] && ! printf '%s\n' "$known" | grep -Fxq "$device"; then echo "Unknown device: $device" >&2; exit 2; fi
if [ ! -f "$TASK_KEY" ]; then
  mkdir -p "$(dirname "$TASK_KEY")"
  (umask 077; openssl genrsa 4096 2>/dev/null | openssl pkcs8 -topk8 -inform PEM -outform DER -nocrypt -out "$TASK_KEY")
fi
if [ "$device" = all ]; then targets="$known"; else targets="$device"; fi
while IFS= read -r target; do
  "$TASK_ROOT/scripts/check-env.sh" "$target"
  mkdir -p "bin/$target"
  if [ "$mode" = snapshot ]; then jungle="$(python3 scripts/prepare-snapshot.py "$target" --case "${SNAPSHOT_CASE:-default}")"; fi
  args=(-f "$jungle" -d "$target" -o "bin/$target/FastRider-$mode.prg" -y "$TASK_KEY" -w)
  if [ "$mode" = test ]; then args+=(-t); fi
  echo "Building $target ($mode)"
  monkeyc "${args[@]}"
  if [ "$mode" != snapshot ]; then python3 scripts/build_metadata.py "$target" "$mode"; fi
done <<< "$targets"
