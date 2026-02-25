#!/usr/bin/env bash
set -euo pipefail

# Review Loop — Complete Script
# Marks the review loop as done and cleans up state.

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

ACTIVE=$(parse_field "active")
PHASE=$(parse_field "phase")
REVIEW_ID=$(parse_field "review_id")

if [ "$ACTIVE" != "true" ]; then
  echo "Review loop is not active. Cleaning up."
  rm -f "$STATE_FILE"
  exit 0
fi

if [ "$PHASE" != "addressing" ]; then
  echo "Warning: Review loop is in '$PHASE' phase, expected 'addressing'."
  echo "  If you haven't run the review yet, run: bash .review-loop/scripts/run-review.sh"
  echo "  Completing anyway..."
fi

log "Review loop complete (review_id=$REVIEW_ID)"

# Clean up state file but keep the log and scripts
rm -f "$STATE_FILE"

echo ""
echo "Review loop complete!"
echo "  Review ID: $REVIEW_ID"
echo "  Review:    reviews/review-${REVIEW_ID}.md"
echo "  Log:       .review-loop/review-loop.log"
echo ""
