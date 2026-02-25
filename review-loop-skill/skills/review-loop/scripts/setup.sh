#!/usr/bin/env bash
set -euo pipefail

# Review Loop — Setup Script (Agent Skills compatible)
# Creates state file and prepares the review loop lifecycle.
# Works with any AI coding agent.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h)
      cat << 'HELP'
Usage: setup.sh <task description>

Starts a review loop:
  1. The coding agent implements your task
  2. An independent CLI agent performs code review
  3. The coding agent addresses the feedback

Reviewer selection (REVIEW_REVIEWER env var):
  codex    — OpenAI Codex CLI (default, multi-agent parallel review)
  claude   — Anthropic Claude Code CLI
  gemini   — Google Gemini CLI
  opencode — OpenCode CLI
  aider    — Aider CLI
  custom   — Custom command (set REVIEW_CUSTOM_CMD)

All reviewers are CLI agents with their own model and auth.
No API keys needed — they use their own login state.

Example:
  bash setup.sh "Add user authentication with JWT tokens and proper test coverage"
HELP
      exit 0
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

PROMPT="${ARGS[*]:-}"

if [ -z "$PROMPT" ]; then
  echo "Error: No task description provided."
  echo "Usage: bash setup.sh <task description>"
  exit 1
fi

# Check dependencies
if ! command -v jq &> /dev/null; then
  echo "Error: 'jq' is required but not found."
  echo "  macOS:  brew install jq"
  echo "  Linux:  apt install jq  /  yum install jq"
  exit 1
fi

if ! command -v git &> /dev/null; then
  echo "Error: 'git' is required but not found."
  exit 1
fi

# Check for existing loop
STATE_DIR=".review-loop"
STATE_FILE="$STATE_DIR/state.md"

if [ -f "$STATE_FILE" ]; then
  echo "Error: A review loop is already active."
  echo "Use 'bash $SKILL_DIR/scripts/cancel.sh' to abort it first."
  exit 1
fi

# Generate unique ID: timestamp + random hex
if command -v openssl &> /dev/null; then
  RAND_HEX=$(openssl rand -hex 3)
else
  RAND_HEX=$(head -c 3 /dev/urandom | od -An -tx1 | tr -d ' \n')
fi
REVIEW_ID="$(date +%Y%m%d-%H%M%S)-${RAND_HEX}"

# Detect reviewer — all are CLI agents, no API keys needed
REVIEWER="${REVIEW_REVIEWER:-auto}"

if [ "$REVIEWER" = "auto" ]; then
  # Auto-detect: prefer codex, then claude, then gemini, then opencode, then aider
  if command -v codex &> /dev/null; then
    REVIEWER="codex"
  elif command -v claude &> /dev/null; then
    REVIEWER="claude"
  elif command -v gemini &> /dev/null; then
    REVIEWER="gemini"
  elif command -v opencode &> /dev/null; then
    REVIEWER="opencode"
  elif command -v aider &> /dev/null; then
    REVIEWER="aider"
  else
    echo "Warning: No reviewer CLI agent found (codex, claude, gemini, opencode, aider)."
    echo "  Falling back to self-review mode."
    echo "  Install any CLI agent to enable independent review."
    REVIEWER="self"
  fi
fi

# Verify the selected reviewer is installed
if [ "$REVIEWER" != "self" ] && [ "$REVIEWER" != "auto" ] && [ "$REVIEWER" != "custom" ]; then
  if ! command -v "$REVIEWER" &> /dev/null; then
    echo "Warning: '$REVIEWER' CLI not found. Falling back to self-review."
    REVIEWER="self"
  fi
fi

# Create state directory and file
mkdir -p "$STATE_DIR/scripts"
cat > "$STATE_FILE" << STATE_EOF
---
active: true
phase: task
review_id: ${REVIEW_ID}
reviewer: ${REVIEWER}
started_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
---

${PROMPT}
STATE_EOF

# Copy scripts into the project for easy access
for script in run-review.sh complete.sh cancel.sh review-engine.sh; do
  cp "$SKILL_DIR/scripts/$script" "$STATE_DIR/scripts/$script" 2>/dev/null || true
done

# Ensure reviews directory exists
mkdir -p reviews

echo ""
echo "Review Loop activated"
echo "  ID:       ${REVIEW_ID}"
echo "  Phase:    1/2 — Task implementation"
echo "  Reviewer: ${REVIEWER}"
echo "  Review:   reviews/review-${REVIEW_ID}.md"
echo ""
echo "  Lifecycle:"
echo "    1. Implement the task"
echo "    2. Run: bash .review-loop/scripts/run-review.sh"
echo "    3. Address the feedback"
echo "    4. Run: bash .review-loop/scripts/complete.sh"
echo ""
echo "  Cancel: bash .review-loop/scripts/cancel.sh"
echo ""
