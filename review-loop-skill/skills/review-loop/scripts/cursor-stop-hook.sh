#!/usr/bin/env bash
# Review Loop — Cursor Stop Hook Adapter
#
# This script is designed to be used as a Cursor agent hook (stop event).
# Cursor hooks use exit codes: 0 = approve, non-zero = block with message on stderr.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STATE_FILE=".review-loop/state.md"

# No active loop → allow exit
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

parse_field() {
  sed -n "s/^${1}: *//p" "$STATE_FILE" | head -1
}

ACTIVE=$(parse_field "active")
PHASE=$(parse_field "phase")
REVIEW_ID=$(parse_field "review_id")
REVIEWER=$(parse_field "reviewer")

if [ "$ACTIVE" != "true" ]; then
  rm -f "$STATE_FILE"
  exit 0
fi

if ! echo "$REVIEW_ID" | grep -qE '^[0-9]{8}-[0-9]{6}-[0-9a-f]{6}$'; then
  rm -f "$STATE_FILE"
  exit 0
fi

case "$PHASE" in
  task)
    REVIEW_FILE="reviews/review-${REVIEW_ID}.md"
    mkdir -p reviews

    bash "$SCRIPT_DIR/review-engine.sh" "$REVIEW_FILE" "${REVIEWER:-codex}" 2>/dev/null || true

    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/^phase: task$/phase: addressing/' "$STATE_FILE"
    else
      sed -i 's/^phase: task$/phase: addressing/' "$STATE_FILE"
    fi

    if [ -f "$REVIEW_FILE" ]; then
      echo "Review written to ${REVIEW_FILE}. Please read and address the feedback, then stop again." >&2
    else
      echo "Review engine failed. Loop cancelled." >&2
      rm -f "$STATE_FILE"
    fi
    exit 1  # Block: Cursor will show stderr as reason
    ;;

  addressing)
    rm -f "$STATE_FILE"
    exit 0  # Approve
    ;;

  *)
    rm -f "$STATE_FILE"
    exit 0
    ;;
esac
