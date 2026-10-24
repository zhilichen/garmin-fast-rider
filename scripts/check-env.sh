#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
java -version
if [ ! -x "$CIQ_SDK_PATH/bin/monkeyc" ]; then
  echo "Missing SDK: $CIQ_SDK_PATH" >&2; exit 1
fi
monkeyc -v
TASK_DEVICE_HOME="$TASK_CIQ_HOME"
if [ -f "$TASK_CIQ_HOME/sdkmanager-download-location.cfg" ]; then
  TASK_DEVICE_HOME="$(cat "$TASK_CIQ_HOME/sdkmanager-download-location.cfg" | tr -d '\r\n')"
fi
if [ ! -f "$TASK_DEVICE_HOME/Devices/edge840/compiler.json" ]; then
  echo 'Missing Edge 840 device package. In Garmin SDK Manager → Devices, install Edge 840 and wait for the download to finish (sign in if prompted).' >&2
  exit 1
fi
echo "Ready: $TASK_DEVICE_HOME/Devices/edge840"
