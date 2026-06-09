#!/usr/bin/env bash
set -euo pipefail

# Legacy entrypoint kept for compatibility.
# This script delegates to setup_mcp_v2.sh, which is the maintained version.
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="${SCRIPT_DIR}/setup_mcp_v2.sh"

if [[ ! -f "${TARGET_SCRIPT}" ]]; then
  echo "[setup_mcp] missing target script: ${TARGET_SCRIPT}" >&2
  exit 1
fi

if [[ ! -r "${TARGET_SCRIPT}" ]]; then
  echo "[setup_mcp] target script is not readable: ${TARGET_SCRIPT}" >&2
  exit 1
fi

if [[ "${TARGET_SCRIPT}" == "${BASH_SOURCE[0]}" ]]; then
  echo "[setup_mcp] invalid self-reference detected: ${TARGET_SCRIPT}" >&2
  exit 1
fi

exec bash "${TARGET_SCRIPT}" "$@"
