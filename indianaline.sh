#!/usr/bin/env bash
set -euo pipefail

IR_DEVICE="${IR_DEVICE:-/dev/lirc0}"

declare -A BUTTONS=(
  [KEY_VOLUMEUP]=0x02c8
  [KEY_VOLUMEDOWN]=0x0248
  [KEY_MUTE]=0x0270
  [KEY_MENU]=0x0230
  [KEY_FN_1]=0x02e8
  [KEY_FN_2]=0x0268
)

usage() {
  echo "Usage: $(basename "$0") BUTTON_NAME"
  echo
  echo "Sends an IR signal for the INDIANALINE remote via ir-ctl."
  echo "Device defaults to /dev/lirc0; override with IR_DEVICE."
  echo
  echo "Valid button names:"
  for key in "${!BUTTONS[@]}"; do
    echo "  $key"
  done | sort
}

if [[ $# -ne 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && exit 0
  exit 1
fi

BUTTON="$1"

if [[ -z "${BUTTONS[$BUTTON]:-}" ]]; then
  echo "Error: unknown button '$BUTTON'" >&2
  echo >&2
  usage >&2
  exit 1
fi

CODE="${BUTTONS[$BUTTON]}"

ir-ctl -d "$IR_DEVICE" -S "nec:${CODE}"
