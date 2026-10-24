#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$TASK_ROOT"
"$TASK_ROOT/scripts/check-env.sh"
mode="${1:-live}"
case "$mode" in
  live) jungle=monkey.jungle ;;
  demo) jungle=demo.jungle ;;
  hardware) jungle=hardware.jungle ;;
  test) jungle=demo.jungle ;;
  *) echo 'Usage: scripts/build.sh [live|demo|hardware|test]' >&2; exit 2 ;;
esac
if [ ! -f "$TASK_KEY" ]; then
  mkdir -p "$(dirname "$TASK_KEY")"
  (umask 077; openssl genrsa 4096 2>/dev/null | openssl pkcs8 -topk8 -inform PEM -outform DER -nocrypt -out "$TASK_KEY")
fi
mkdir -p bin
args=(-f "$jungle" -d edge840 -o "bin/FastRider-$mode.prg" -y "$TASK_KEY" -w)
if [ "$mode" = test ]; then args+=(-t); fi
monkeyc "${args[@]}"
