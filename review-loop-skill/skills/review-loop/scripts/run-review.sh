#!/usr/bin/env bash
set -euo pipefail

# Review Loop — Run Review Script
# Reads the current state, runs the review engine, transitions to addressing phase.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STATE_FILE=".review-loop/state.md"
LOG_FILE=".review-loop/review-loop.log"

log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" >> "$LOG_FILE"
}

# Parse a field from the YAML frontmatter
parse_field() {
  sed -n "s/^${1}: *//p" "$STATE_FILE" | head -1
}

# Check state file exists
if [ ! -f "$STATE_FILE" ]; then
  echo "Error: No active review loop. Run setup.sh first."
  exit 1
fi

ACTIVE=$(parse_field "active")
PHASE=$(parse_field "phase")
REVIEW_ID=$(parse_field "review_id")
REVIEWER=$(parse_field "reviewer")

# Validate state
if [ "$ACTIVE" != "true" ]; then
  echo "Error: Review loop is not active."
  rm -f "$STATE_FILE"
  exit 1
fi

if [ "$PHASE" != "task" ]; then
  echo "Error: Review loop is in '$PHASE' phase, expected 'task'."
  echo "  If you've already run the review, address the feedback and run complete.sh"
  exit 1
fi

# Validate review_id format
if ! echo "$REVIEW_ID" | grep -qE '^[0-9]{8}-[0-9]{6}-[0-9a-f]{6}$'; then
  log "ERROR: invalid review_id format: $REVIEW_ID"
  echo "Error: Invalid review ID format. Cleaning up."
  rm -f "$STATE_FILE"
  exit 1
fi

REVIEW_FILE="reviews/review-${REVIEW_ID}.md"
mkdir -p reviews

echo "Running review (reviewer: ${REVIEWER:-codex})..."
echo ""

# Find and run the review engine
REVIEW_ENGINE=""
if [ -f "$SCRIPT_DIR/review-engine.sh" ]; then
  REVIEW_ENGINE="$SCRIPT_DIR/review-engine.sh"
elif [ -f ".review-loop/scripts/review-engine.sh" ]; then
  REVIEW_ENGINE=".review-loop/scripts/review-engine.sh"
fi

if [ -z "$REVIEW_ENGINE" ]; then
  log "ERROR: review-engine.sh not found"
  echo "Error: review-engine.sh not found."
  exit 1
fi

# Run the review engine
bash "$REVIEW_ENGINE" "$REVIEW_FILE" "${REVIEWER:-codex}" || {
  log "ERROR: review engine failed"
  echo "Error: Review engine failed. Check .review-loop/review-loop.log"
  exit 1
}

# Transition to addressing phase
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' 's/^phase: task$/phase: addressing/' "$STATE_FILE"
else
  sed -i 's/^phase: task$/phase: addressing/' "$STATE_FILE"
fi

log "Transitioned to addressing phase"

echo ""
echo "Review complete!"
echo "  Review file: $REVIEW_FILE"
echo "  Phase:       2/2 — Address feedback"
echo ""
echo "Next steps:"
echo "  1. Read $REVIEW_FILE"
echo "  2. Address each finding (fix or explain why you disagree)"
echo "  3. Run: bash .review-loop/scripts/complete.sh"
echo ""
