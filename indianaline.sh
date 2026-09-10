#!/usr/bin/env bash
set -euo pipefail

IR_DEVICE="${IR_DEVICE:-/dev/lirc0}"

# Timings copied verbatim from lircd.conf. ir-ctl's built-in "nec:" scancode
# encoder uses standard NEC timings (9000/4500 header, 560/560 or 560/1690
# bits), which are close but not identical to what this remote actually
# uses, and the TV's receiver won't decode it. Replaying the exact raw
# pulse/space timings below reproduces what irsend/lircd sends.
HEADER_PULSE=8920
HEADER_SPACE=4368
ONE_PULSE=594
ONE_SPACE=1603
ZERO_PULSE=594
ZERO_SPACE=491
TRAILER_PULSE=591

declare -A BUTTONS=(
  [KEY_VOLUMEUP]=0x02FDC837
  [KEY_VOLUMEDOWN]=0x02FD48B7
  [KEY_MUTE]=0x02FD708F
  [KEY_MENU]=0x02FD30CF
  [KEY_FN_1]=0x02FDE817
  [KEY_FN_2]=0x02FD6897
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

CODE=$((${BUTTONS[$BUTTON]}))

PULSE_FILE="$(mktemp)"
trap 'rm -f "$PULSE_FILE"' EXIT

{
  echo "pulse $HEADER_PULSE"
  echo "space $HEADER_SPACE"
  for ((bit = 31; bit >= 0; bit--)); do
    if (((CODE >> bit) & 1)); then
      echo "pulse $ONE_PULSE"
      echo "space $ONE_SPACE"
    else
      echo "pulse $ZERO_PULSE"
      echo "space $ZERO_SPACE"
    fi
  done
  echo "pulse $TRAILER_PULSE"
} > "$PULSE_FILE"

ir-ctl -d "$IR_DEVICE" -s "$PULSE_FILE"
