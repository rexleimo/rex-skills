#!/usr/bin/env bash
# Review Loop — Claude Code Stop Hook Adapter
#
# This script is designed to be used as a Claude Code stop hook.
# It integrates the review-loop skill into Claude Code's hook system.
#
# Two-phase lifecycle:
#   Phase 1 (task):       Claude finishes work → hook runs review → blocks exit
#   Phase 2 (addressing): Claude addresses review → hook allows exit
#
# On any error, default to allowing exit (never trap the user in a broken loop).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

trap 'printf "{\"decision\":\"approve\"}\n"; exit 0' ERR

# Consume stdin (hook input JSON)
HOOK_INPUT=$(cat)

STATE_FILE=".review-loop/state.md"

# No active loop → allow exit
if [ ! -f "$STATE_FILE" ]; then
  printf '{"decision":"approve"}\n'
  exit 0
fi

parse_field() {
  sed -n "s/^${1}: *//p" "$STATE_FILE" | head -1
}

ACTIVE=$(parse_field "active")
PHASE=$(parse_field "phase")
REVIEW_ID=$(parse_field "review_id")
REVIEWER=$(parse_field "reviewer")

# Not active → clean up and exit
if [ "$ACTIVE" != "true" ]; then
  rm -f "$STATE_FILE"
  printf '{"decision":"approve"}\n'
  exit 0
fi

# Validate review_id
if ! echo "$REVIEW_ID" | grep -qE '^[0-9]{8}-[0-9]{6}-[0-9a-f]{6}$'; then
  rm -f "$STATE_FILE"
  printf '{"decision":"approve"}\n'
  exit 0
fi

# Safety: prevent infinite loops
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$STOP_HOOK_ACTIVE" = "true" ] && [ "$PHASE" = "task" ]; then
  rm -f "$STATE_FILE"
  printf '{"decision":"approve"}\n'
  exit 0
fi

case "$PHASE" in
  task)
    REVIEW_FILE="reviews/review-${REVIEW_ID}.md"
    mkdir -p reviews

    # Run the review engine
    bash "$SCRIPT_DIR/review-engine.sh" "$REVIEW_FILE" "${REVIEWER:-codex}" 2>/dev/null || true

    # Transition to addressing phase
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/^phase: task$/phase: addressing/' "$STATE_FILE"
    else
      sed -i 's/^phase: task$/phase: addressing/' "$STATE_FILE"
    fi

    if [ ! -f "$REVIEW_FILE" ]; then
      rm -f "$STATE_FILE"
      jq -n '{decision:"block", reason:"Review engine failed to produce output. Loop cancelled."}'
      exit 0
    fi

    REASON="An independent code review has been written to ${REVIEW_FILE}.

Please:
1. Read the review carefully
2. For each item, independently decide if you agree
3. For items you AGREE with: implement the fix
4. For items you DISAGREE with: briefly note why you are skipping them
5. Focus on critical and high severity items first
6. When done addressing all relevant items, you may stop

Use your own judgment. Do not blindly accept every suggestion."

    SYS_MSG="Review Loop [${REVIEW_ID}] — Phase 2/2: Address review feedback"

    jq -n --arg r "$REASON" --arg s "$SYS_MSG" \
      '{decision:"block", reason:$r, systemMessage:$s}'
    ;;

  addressing)
    rm -f "$STATE_FILE"
    printf '{"decision":"approve"}\n'
    ;;

  *)
    rm -f "$STATE_FILE"
    printf '{"decision":"approve"}\n'
    ;;
esac
