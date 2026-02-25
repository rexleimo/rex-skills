#!/usr/bin/env bash
set -euo pipefail

# Review Loop — Cancel Script
# Cancels an active review loop and cleans up state.

STATE_FILE=".review-loop/state.md"
LOG_FILE=".review-loop/review-loop.log"

log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" >> "$LOG_FILE"
}

parse_field() {
  sed -n "s/^${1}: *//p" "$STATE_FILE" | head -1
}

if [ ! -f "$STATE_FILE" ]; then
  echo "No active review loop found."
  exit 0
fi

PHASE=$(parse_field "phase")
REVIEW_ID=$(parse_field "review_id")

log "Review loop cancelled (review_id=$REVIEW_ID, phase=$PHASE)"

rm -f "$STATE_FILE"

echo "Review loop cancelled."
echo "  Was at phase: $PHASE"
echo "  Review ID:    $REVIEW_ID"
