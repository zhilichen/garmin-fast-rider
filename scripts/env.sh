#!/usr/bin/env bash
# Source this file. No host-specific SDK or JDK version is embedded in the repo.
TASK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -n "${CIQ_HOME:-}" ]; then
  TASK_CIQ_HOME="$CIQ_HOME"
elif [ "$(uname -s)" = Darwin ]; then
  TASK_CIQ_HOME="$HOME/Library/Application Support/Garmin/ConnectIQ"
else
  TASK_CIQ_HOME="$HOME/.Garmin/ConnectIQ"
fi
if [ -z "${CIQ_SDK_PATH:-}" ] && [ -f "$TASK_CIQ_HOME/current-sdk.cfg" ]; then
  CIQ_SDK_PATH="$(tr -d '\r\n' < "$TASK_CIQ_HOME/current-sdk.cfg")"
fi
if [ -n "${CIQ_SDK_PATH:-}" ]; then export CIQ_SDK_PATH; export PATH="$CIQ_SDK_PATH/bin:$PATH"; fi
TASK_KEY="${CIQ_DEVELOPER_KEY:-$TASK_ROOT/.local/developer_key.der}"
TASK_DEVICE_HOME="$TASK_CIQ_HOME"
if [ -f "$TASK_CIQ_HOME/sdkmanager-download-location.cfg" ]; then
  TASK_DEVICE_HOME="$(tr -d '\r\n' < "$TASK_CIQ_HOME/sdkmanager-download-location.cfg")"
fi
