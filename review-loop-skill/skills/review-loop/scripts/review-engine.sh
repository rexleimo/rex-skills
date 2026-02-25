#!/usr/bin/env bash
set -euo pipefail

# Review Engine — Core review logic (agent-agnostic)
#
# Builds the review prompt, calls the configured CLI agent as reviewer,
# and writes the review file.
#
# All supported reviewers are CLI agents that have their own model/auth —
# no API keys needed. They run non-interactively in the project directory
# and can read code, run commands, and write files directly.
#
# Usage: bash review-engine.sh <review_file> <reviewer>
#
# Supported reviewers:
#   codex    — OpenAI Codex CLI (default, supports multi-agent parallel review)
#   claude   — Anthropic Claude Code CLI
#   gemini   — Google Gemini CLI
#   opencode — OpenCode CLI
#   aider    — Aider CLI
#   custom   — Custom command (set REVIEW_CUSTOM_CMD)
#
# Environment variables:
#   REVIEW_LOOP_CODEX_FLAGS  Override codex exec flags (default: --full-auto)
#   REVIEW_CUSTOM_CMD        Custom review command (when reviewer=custom)

REVIEW_FILE="${1:?Usage: review-engine.sh <review_file> <reviewer>}"
REVIEWER="${2:-codex}"

LOG_FILE=".review-loop/review-loop.log"

log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" >> "$LOG_FILE"
}

# ── Project type detection ────────────────────────────────────────────────
detect_nextjs() {
  [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ] || \
    ([ -f "package.json" ] && grep -q '"next"' package.json 2>/dev/null)
}

detect_browser_ui() {
  [ -d "app" ] || [ -d "pages" ] || [ -d "src/app" ] || [ -d "src/pages" ] || \
    [ -d "public" ] || [ -f "index.html" ]
}

# ── Build the multi-agent review prompt (for Codex) ───────────────────────
# Codex supports multi-agent: it can spawn parallel review agents internally.
build_multi_agent_prompt() {
  local REVIEW_FILE="$1"

  local IS_NEXTJS=false
  local HAS_UI=false
  detect_nextjs && IS_NEXTJS=true
  detect_browser_ui && HAS_UI=true

  log "Project detection: nextjs=$IS_NEXTJS, browser_ui=$HAS_UI"

  cat << PREAMBLE_EOF
You are orchestrating a thorough, independent code review of recent changes in this repository.

Use multi-agent to run the following review agents IN PARALLEL. Each agent should return its findings as structured text (not write to files). After ALL agents complete, consolidate their findings into a single deduplicated review file.

IMPORTANT: Spawn one agent per review path below. Wait for all agents to finish. Then deduplicate overlapping findings and write the consolidated review to: ${REVIEW_FILE}

PREAMBLE_EOF

  # Agent 1: Diff Review
  cat << 'DIFF_EOF'
---
AGENT 1: Diff Review (focus on uncommitted and recently committed changes ONLY)

Run `git diff` and `git diff --cached` to see all uncommitted changes. Also run `git log --oneline -5` and `git diff HEAD~5` for recently committed work. Focus your review EXCLUSIVELY on this changed code.

Review criteria:
- Code Quality: well-organized, modular, readable, DRY, clear naming, appropriate abstractions
- Test Coverage: new functions have tests, edge cases covered, tests are isolated and deterministic
- Security: input validation, auth checks, no injection risks, no hardcoded secrets, safe error messages

For each issue: return file path, line number, severity (critical/high/medium/low), category, description, and suggested fix.
DIFF_EOF

  # Agent 2: Holistic Review
  cat << 'HOLISTIC_EOF'
---
AGENT 2: Holistic Review (evaluate overall project structure)

Read the full project directory structure, key config files, README, and any AGENTS.md files.

Review criteria:
- Code Organization: logical structure, proper separation of concerns, no god files
- Documentation: AGENTS.md in major directories, documented conventions and patterns
- Architecture: clean dependency graph, centralized config, consistent error handling

For each issue: return file path (or directory), severity, category, description, and suggested fix.
HOLISTIC_EOF

  # Conditional: Next.js
  if [ "$IS_NEXTJS" = "true" ]; then
    cat << 'NEXTJS_EOF'
---
AGENT 3: Next.js & React Best Practices Review

Review against: Server Components by default, proper data fetching, cache strategy, bundle size optimization, Server Actions validation, React performance patterns.

For each issue: return file path, line number, severity, category, description, and suggested fix.
NEXTJS_EOF
  fi

  # Conditional: UX
  if [ "$HAS_UI" = "true" ]; then
    cat << 'UX_EOF'
---
AGENT (UX): Browser-Based UX Review (SKIP if no dev server available)

If a dev server is running, test: all major routes, key user workflows, responsive design, accessibility, error/loading/empty states.

For each issue: return description, severity, category, and suggested fix.
UX_EOF
  fi

  # Consolidation
  cat << CONSOLIDATION_EOF
---
CONSOLIDATION INSTRUCTIONS (after all agents complete):

1. Collect all findings from all agents
2. Deduplicate overlapping findings
3. Organize by severity (critical → high → medium → low)
4. For each finding: file path, line number, severity, category, description, suggested fix
5. End with summary: total issues by severity, agents that ran, overall assessment
6. Write the COMPLETE consolidated review to: ${REVIEW_FILE}

IMPORTANT: You MUST create the file ${REVIEW_FILE} with the full review.
CONSOLIDATION_EOF
}

# ── Build a single-agent review prompt (for Claude, Gemini, OpenCode, etc.) ──
# These CLI agents don't have multi-agent, so we give them a comprehensive
# single prompt and let them do the review in one pass.
build_single_agent_prompt() {
  local REVIEW_FILE="$1"

  local IS_NEXTJS=false
  local HAS_UI=false
  detect_nextjs && IS_NEXTJS=true
  detect_browser_ui && HAS_UI=true

  cat << PROMPT_EOF
You are performing a thorough, independent code review of recent changes in this repository.

First, examine the changes:
- Run \`git diff\` and \`git diff --cached\` for uncommitted changes
- Run \`git log --oneline -5\` and \`git diff HEAD~5\` for recent commits

Review the changes against these criteria:

## Code Quality
- Well-organized, modular, readable code
- DRY principles followed, no copy-pasted blocks
- Clear naming conventions consistent with the codebase
- Appropriate abstraction levels

## Test Coverage
- New functions/endpoints/components have corresponding tests
- Edge cases covered: empty inputs, nulls, boundary values, error paths
- Tests are isolated, deterministic, and fast

## Security
- Input validation and sanitization on all user inputs
- Auth checks on protected routes/actions
- No injection risks (SQL, XSS, command injection, path traversal)
- No hardcoded secrets, API keys, or tokens
- Safe error messages (no stack traces leaked to users)

## Project Structure
- Logical organization, proper separation of concerns
- Clean dependency graph, no circular dependencies
- Consistent error handling across the codebase
- Configuration centralized rather than scattered
PROMPT_EOF

  if [ "$IS_NEXTJS" = "true" ]; then
    cat << 'NEXTJS_EOF'

## Next.js Best Practices
- Server Components used by default, 'use client' only when needed
- Data fetched in Server Components, parallel fetches with Promise.all
- Proper cache strategy and invalidation
- Bundle size optimized, no barrel file imports
NEXTJS_EOF
  fi

  cat << FOOTER_EOF

For each issue found, report:
- **File**: path and line number
- **Severity**: critical / high / medium / low
- **Category**: Code Quality / Test Coverage / Security / Structure
- **Description**: clear explanation
- **Fix**: concrete, actionable recommendation

End with a summary of total issues by severity and an overall assessment.

Write the complete review to: ${REVIEW_FILE}
FOOTER_EOF
}

# ── Reviewer backends ─────────────────────────────────────────────────────
# Each reviewer is a CLI agent with its own model and authentication.
# No API keys needed — they use their own login state.

run_codex_review() {
  # Codex supports multi-agent parallel review
  local PROMPT
  PROMPT=$(build_multi_agent_prompt "$REVIEW_FILE")

  # Ensure multi_agent is enabled
  local CODEX_CONFIG="${HOME}/.codex/config.toml"
  if [ ! -f "$CODEX_CONFIG" ]; then
    mkdir -p "${HOME}/.codex"
    printf '[features]\nmulti_agent = true\n' > "$CODEX_CONFIG"
    log "Created ~/.codex/config.toml with multi_agent enabled"
  elif ! grep -qE '^\s*multi_agent\s*=\s*true' "$CODEX_CONFIG"; then
    if grep -qE '^\[features\]' "$CODEX_CONFIG"; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^\[features\]/a\'$'\n''multi_agent = true' "$CODEX_CONFIG"
      else
        sed -i '/^\[features\]/a multi_agent = true' "$CODEX_CONFIG"
      fi
    else
      printf '\n[features]\nmulti_agent = true\n' >> "$CODEX_CONFIG"
    fi
    log "Enabled multi_agent in ~/.codex/config.toml"
  fi

  local CODEX_FLAGS="${REVIEW_LOOP_CODEX_FLAGS:---full-auto}"
  log "Starting Codex multi-agent review (flags: $CODEX_FLAGS)"

  local START_TIME
  START_TIME=$(date +%s)
  local EXIT_CODE=0
  # shellcheck disable=SC2086
  codex exec $CODEX_FLAGS "$PROMPT" >/dev/null 2>&1 || EXIT_CODE=$?
  local ELAPSED=$(( $(date +%s) - START_TIME ))
  log "Codex finished (exit=$EXIT_CODE, elapsed=${ELAPSED}s)"
}

run_claude_review() {
  local PROMPT
  PROMPT=$(build_single_agent_prompt "$REVIEW_FILE")

  log "Starting Claude Code CLI review"
  local START_TIME
  START_TIME=$(date +%s)
  claude --dangerously-skip-permissions -p "$PROMPT" >/dev/null 2>&1 || true
  local ELAPSED=$(( $(date +%s) - START_TIME ))
  log "Claude finished (elapsed=${ELAPSED}s)"
}

run_gemini_review() {
  local PROMPT
  PROMPT=$(build_single_agent_prompt "$REVIEW_FILE")

  log "Starting Gemini CLI review"
  local START_TIME
  START_TIME=$(date +%s)
  echo "$PROMPT" | gemini >/dev/null 2>&1 || true
  local ELAPSED=$(( $(date +%s) - START_TIME ))
  log "Gemini finished (elapsed=${ELAPSED}s)"
}

run_opencode_review() {
  local PROMPT
  PROMPT=$(build_single_agent_prompt "$REVIEW_FILE")

  log "Starting OpenCode CLI review"
  local START_TIME
  START_TIME=$(date +%s)
  opencode run "$PROMPT" >/dev/null 2>&1 || true
  local ELAPSED=$(( $(date +%s) - START_TIME ))
  log "OpenCode finished (elapsed=${ELAPSED}s)"
}

run_aider_review() {
  local PROMPT
  PROMPT=$(build_single_agent_prompt "$REVIEW_FILE")

  log "Starting Aider review"
  local START_TIME
  START_TIME=$(date +%s)
  aider --message "$PROMPT" --yes >/dev/null 2>&1 || true
  local ELAPSED=$(( $(date +%s) - START_TIME ))
  log "Aider finished (elapsed=${ELAPSED}s)"
}

run_custom_review() {
  local CMD="${REVIEW_CUSTOM_CMD:?REVIEW_CUSTOM_CMD must be set when reviewer=custom}"
  log "Starting custom review: $CMD"
  eval "$CMD" > "$REVIEW_FILE" 2>/dev/null || true
  log "Custom review complete"
}

run_self_review() {
  # Fallback: generate a review checklist for the coding agent itself
  local PROMPT
  PROMPT=$(build_single_agent_prompt "$REVIEW_FILE")

  cat > "$REVIEW_FILE" << SELF_EOF
# Self-Review Required

No external reviewer CLI agent is available. Please perform a self-review of your changes.

## Review Checklist

${PROMPT}

---

*This is a self-review prompt generated because no reviewer CLI was found.*
*Install one of: codex, claude, gemini, opencode, or aider to enable independent review.*
SELF_EOF
  log "Self-review prompt generated"
}

# ── Main ──────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$REVIEW_FILE")"

log "Review engine started (reviewer=$REVIEWER, output=$REVIEW_FILE)"

case "$REVIEWER" in
  codex)    run_codex_review ;;
  claude)   run_claude_review ;;
  gemini)   run_gemini_review ;;
  opencode) run_opencode_review ;;
  aider)    run_aider_review ;;
  custom)   run_custom_review ;;
  self)     run_self_review ;;
  *)
    log "ERROR: unknown reviewer '$REVIEWER', falling back to self-review"
    run_self_review
    ;;
esac

if [ -f "$REVIEW_FILE" ]; then
  log "Review written to $REVIEW_FILE"
  echo "Review complete: $REVIEW_FILE"
else
  log "WARNING: Review file not created"
  echo "Warning: Review file was not created. Check .review-loop/review-loop.log for details."
fi
