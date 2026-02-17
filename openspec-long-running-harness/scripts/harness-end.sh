#!/bin/bash
# harness-end.sh - End the current harness session with gate enforcement
# Usage: ./harness-end.sh [--force-fail "reason"]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/harness-lib.sh"

require_harness

# Check for active session
CURRENT_STATUS=$(json_get "$HARNESS_DIR/session_state.json" '.status')
if [[ "$CURRENT_STATUS" != "in_progress" ]]; then
    log_error "No active session to end."
    exit 1
fi

# Get session info
SESSION_ID=$(json_get "$HARNESS_DIR/session_state.json" '.session_id')
CURRENT_FEATURE=$(json_get "$HARNESS_DIR/session_state.json" '.current_feature')
START_COMMIT=$(json_get "$HARNESS_DIR/session_state.json" '.start_commit')

# Check for force fail
FORCE_FAIL=false
FORCE_FAIL_REASON=""
if [[ "${1:-}" == "--force-fail" ]]; then
    FORCE_FAIL=true
    FORCE_FAIL_REASON="${2:-"No reason provided"}"
fi

log_info "Ending session $SESSION_ID for feature: $CURRENT_FEATURE"

# Gate 1: Working tree clean?
GATE_CLEAN=false
if is_working_tree_clean; then
    GATE_CLEAN=true
    log_success "Gate 1: Working tree clean ✓"
else
    log_warning "Gate 1: Working tree has uncommitted changes ✗"
    git status --short
    echo ""
    read -p "Commit changes now? (Y/n) " -n 1 -r
    echo
    if [[ $REPLY != "n" && $REPLY != "N" ]]; then
        FEATURE_DESC=$(json_get "$HARNESS_DIR/feature_list.json" ".features[] | select(.id == \"$CURRENT_FEATURE\") | .description")
        git add -A
        git commit -m "feat($CURRENT_FEATURE): $FEATURE_DESC - session complete"
        GATE_CLEAN=true
        log_success "Gate 1: Working tree now clean ✓"
    fi
fi

# Gate 2: New commit exists?
CURRENT_COMMIT=$(get_git_commit)
GATE_COMMIT=false
if [[ "$CURRENT_COMMIT" != "$START_COMMIT" ]]; then
    GATE_COMMIT=true
    log_success "Gate 2: New commit created ($CURRENT_COMMIT) ✓"
else
    log_warning "Gate 2: No new commit since session start ✗"
fi

# Gate 3: E2E verification
GATE_E2E=false
E2E_OUTPUT=""
if $FORCE_FAIL; then
    log_warning "Gate 3: Forced failure - $FORCE_FAIL_REASON"
    E2E_OUTPUT="Forced failure: $FORCE_FAIL_REASON"
elif [[ "$GATE_CLEAN" == "true" && "$GATE_COMMIT" == "true" ]]; then
    log_info "Gate 3: Running E2E verification..."

    # Get E2E command from config
    E2E_CMD=$(json_get "$HARNESS_DIR/.harness-config.json" '.e2e_command')
    E2E_TIMEOUT=$(json_get "$HARNESS_DIR/.harness-config.json" '.e2e_timeout')

    if [[ -n "$E2E_CMD" && "$E2E_CMD" != "null" ]]; then
        log_info "Running: $E2E_CMD"

        # Run E2E with timeout
        set +e
        E2E_OUTPUT=$(timeout "${E2E_TIMEOUT:-300}" bash -c "$E2E_CMD" 2>&1)
        E2E_EXIT=$?
        set -e

        if [[ $E2E_EXIT -eq 0 ]]; then
            GATE_E2E=true
            log_success "Gate 3: E2E verification passed ✓"
        elif [[ $E2E_EXIT -eq 124 ]]; then
            log_error "Gate 3: E2E verification timed out ✗"
            E2E_OUTPUT="TIMEOUT after ${E2E_TIMEOUT:-300}s\n$E2E_OUTPUT"
        else
            log_error "Gate 3: E2E verification failed ✗"
        fi
    else
        log_warning "Gate 3: No E2E command configured - skipping"
        GATE_E2E=true  # Allow pass if no E2E configured
    fi
else
    log_warning "Gate 3: Skipped (previous gates failed)"
fi

# Determine final status
TIMESTAMP=$(get_timestamp)
FINAL_STATUS="failed"

if $GATE_CLEAN && $GATE_COMMIT && $GATE_E2E; then
    FINAL_STATUS="passing"
elif $GATE_CLEAN && $GATE_COMMIT && ! $GATE_E2E; then
    FINAL_STATUS="failed"
elif ! $GATE_CLEAN || ! $GATE_COMMIT; then
    FINAL_STATUS="in_progress"  # Keep in progress if no commit
fi

# Update feature status
update_feature_status "$CURRENT_FEATURE" "$FINAL_STATUS"

# Update session state
cat > "$HARNESS_DIR/session_state.json" << EOF
{
  "session_id": $SESSION_ID,
  "tool": "claude",
  "started_at": "$(json_get "$HARNESS_DIR/session_state.json" '.started_at')",
  "current_feature": "$CURRENT_FEATURE",
  "start_commit": "$START_COMMIT",
  "end_commit": "$CURRENT_COMMIT",
  "e2e_result": $GATE_E2E,
  "status": "completed",
  "final_status": "$FINAL_STATUS"
}
EOF

# Update progress log
cat >> "$HARNESS_DIR/progress.log.md" << EOF

### Session End - $(get_display_date)

#### Gate Results
- [$(if $GATE_CLEAN; then echo "x"; else echo " "; fi)] Working tree clean
- [$(if $GATE_COMMIT; then echo "x"; else echo " "; fi)] New commit created: \`$CURRENT_COMMIT\`
- [$(if $GATE_E2E; then echo "x"; else echo " "; fi)] E2E verification passed

#### Final Status: **$FINAL_STATUS**

EOF

if [[ -n "$E2E_OUTPUT" ]]; then
    cat >> "$HARNESS_DIR/progress.log.md" << EOF

#### E2E Output
\`\`\`
$E2E_OUTPUT
\`\`\`

EOF
fi

# Calculate remaining features
PENDING=$(count_features_by_status "pending")
IN_PROGRESS=$(count_features_by_status "in_progress")
FAILED=$(count_features_by_status "failed")
PASSING=$(count_features_by_status "passing")

cat >> "$HARNESS_DIR/progress.log.md" << EOF

#### Feature Summary
- Passing: $PASSING
- In Progress: $IN_PROGRESS
- Pending: $PENDING
- Failed: $FAILED

---

EOF

# Output summary
echo ""
echo "================================"
if [[ "$FINAL_STATUS" == "passing" ]]; then
    log_success "=== Session $SESSION_ID Complete ==="
else
    log_error "=== Session $SESSION_ID Ended (Not Passing) ==="
fi
echo "================================"
echo ""
echo "### Summary"
echo "- Feature: $CURRENT_FEATURE"
echo "- Status: $FINAL_STATUS"
echo "- Commits: $START_COMMIT → $CURRENT_COMMIT"
echo ""
echo "### Gate Results"
echo "- Working tree clean: $(if $GATE_CLEAN; then echo "✓"; else echo "✗"; fi)"
echo "- New commit: $(if $GATE_COMMIT; then echo "✓"; else echo "✗"; fi)"
echo "- E2E passed: $(if $GATE_E2E; then echo "✓"; else echo "✗"; fi)"
echo ""
echo "### Progress"
echo "- Passing: $PASSING"
echo "- Pending: $PENDING"
echo "- Failed: $FAILED"
echo ""

if [[ "$FINAL_STATUS" == "passing" ]]; then
    echo "Run harness-start.sh to begin the next feature."
else
    echo "Fix issues and run harness-end.sh again, or run harness-start.sh to retry."
fi
