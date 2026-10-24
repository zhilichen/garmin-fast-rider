#!/usr/bin/env bash
# Source this file; handles macOS SDK paths containing spaces.
TASK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_CIQ_HOME="$HOME/Library/Application Support/Garmin/ConnectIQ"
if [ -z "${CIQ_SDK_PATH:-}" ] && [ -f "$TASK_CIQ_HOME/current-sdk.cfg" ]; then
  CIQ_SDK_PATH="$(cat "$TASK_CIQ_HOME/current-sdk.cfg" | tr -d '\r\n')"
fi
if [ -z "${CIQ_SDK_PATH:-}" ]; then
  CIQ_SDK_PATH="$TASK_CIQ_HOME/Sdks/connectiq-sdk-mac-9.3.0-2026-10-20-95888f262"
fi
export CIQ_SDK_PATH
export PATH="$CIQ_SDK_PATH/bin:$PATH"
TASK_KEY="${CIQ_DEVELOPER_KEY:-$TASK_ROOT/.local/developer_key.der}"
