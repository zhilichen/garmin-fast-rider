#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
device="${1:-edge840}"
if [ -z "${CIQ_SDK_PATH:-}" ] || [ ! -x "$CIQ_SDK_PATH/bin/monkeyc" ]; then
  echo 'Install the official Connect IQ SDK, or set CIQ_SDK_PATH to its extracted directory.' >&2; exit 1
fi
if ! java -version >/dev/null 2>&1; then echo 'Install JDK 17 and put java on PATH.' >&2; exit 1; fi
if [ ! -f "$TASK_DEVICE_HOME/Devices/$device/compiler.json" ]; then
  echo "Missing $device package. Install that Edge device in the official SDK Manager." >&2; exit 1
fi
