#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
mode="${1:-demo}"
device="${2:-edge840}"
"$TASK_ROOT/scripts/build.sh" "$mode" "$device"
if [ "$(uname -s)" = Darwin ] && ! pgrep -f 'ConnectIQ.app/Contents/MacOS/simulator' >/dev/null; then
  open "$CIQ_SDK_PATH/bin/ConnectIQ.app"
fi
cd "$TASK_ROOT"
if [ "$mode" = test ]; then
  mkdir -p .local/test-results
  set +e
  monkeydo "bin/$device/FastRider-test.prg" "$device" -t 2>&1 | tee ".local/test-results/$device.txt"
  set -e
  grep -Eq '^PASSED \(passed=[0-9]+, failed=0, errors=0\)$' ".local/test-results/$device.txt"
else
  monkeydo "bin/$device/FastRider-$mode.prg" "$device"
fi
