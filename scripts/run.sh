#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
mode="${1:-demo}"
"$TASK_ROOT/scripts/build.sh" "$mode"
if ! pgrep -f 'ConnectIQ.app/Contents/MacOS' >/dev/null; then
  open "$CIQ_SDK_PATH/bin/ConnectIQ.app"
fi
# Inspect the listener without opening a connection into the shell protocol.
for attempt in {1..30}; do
  if lsof -nP -a -c simulator -iTCP:1234 -sTCP:LISTEN >/dev/null 2>&1; then break; fi
  sleep 1
done
if ! lsof -nP -a -c simulator -iTCP:1234 -sTCP:LISTEN >/dev/null 2>&1; then
  echo 'Connect IQ simulator did not open its port (1234). Open ConnectIQ.app and retry.' >&2
  exit 1
fi
cd "$TASK_ROOT"
if [ "$mode" = test ]; then
  # SDK 9.3 may return 1 even after the VM prints PASSED. Use the VM summary.
  mkdir -p .local
  set +e
  monkeydo "bin/Summit-test.prg" edge840 -t 2>&1 | tee .local/simulator-tests.txt
  set -e
  if ! grep -Eq '^PASSED \(passed=[0-9]+, failed=0, errors=0\)$' .local/simulator-tests.txt; then
    exit 1
  fi
else
  monkeydo "bin/Summit-$mode.prg" edge840
fi
