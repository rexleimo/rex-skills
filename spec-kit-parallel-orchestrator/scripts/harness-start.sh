#!/bin/bash
# harness-start.sh - Start a new harness session
# Usage: ./harness-start.sh

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/harness-lib.sh"

require_harness

log_info "Starting new harness session..."

# Check requirements
if ! check_requirements; then
    exit 1
fi

# Check for existing active session
CURRENT_STATUS=$(json_get "$HARNESS_DIR/session_state.json" '.status')
if [[ "$CURRENT_STATUS" == "in_progress" ]]; then
    log_warning "Active session already exists!"
    log_info "Current feature: $(json_get "$HARNESS_DIR/session_state.json" '.current_feature')"
    read -p "End current session and start new? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Continuing with current session."
        exit 0
    fi
    # Force end current session
    "$SCRIPT_DIR/harness-end.sh" --force-fail "Session superseded"
fi

# Run init.sh to verify environment
log_info "Running environment check..."
if [[ -x "$HARNESS_DIR/init.sh" ]]; then
    if ! "$HARNESS_DIR/init.sh"; then
        log_error "Environment check failed. Fix issues before starting."
        exit 1
    fi
else
    log_warning "init.sh not executable. Skipping environment check."
fi

# Select next feature
NEXT_FEATURE=$(find_next_feature)
if [[ -z "$NEXT_FEATURE" ]]; then
    log_success "No pending features. All work complete!"
    exit 0
fi

# Check dependencies
DEP_CHECK=$(check_dependencies "$NEXT_FEATURE")
if [[ "$DEP_CHECK" == blocked:* ]]; then
    BLOCKING="${DEP_CHECK#blocked:}"
    log_warning "Feature $NEXT_FEATURE is blocked by: $BLOCKING"

    # Update feature status
    update_feature_status "$NEXT_FEATURE" "blocked"
    json_set "$HARNESS_DIR/feature_list.json" \
        ".features[] | select(.id == \"$NEXT_FEATURE\") | .blocked_reason" \
        "\"Blocked by: $BLOCKING\""

    # Try to find another feature
    NEXT_FEATURE=$(find_next_feature)
    if [[ -z "$NEXT_FEATURE" ]]; then
        log_warning "No unblocked features available."
        exit 1
    fi
fi

# Get feature info
FEATURE_INFO=$(get_feature_info "$NEXT_FEATURE")
FEATURE_PRIORITY=$(echo "$FEATURE_INFO" | jq -r '.priority')
FEATURE_DESC=$(echo "$FEATURE_INFO" | jq -r '.description')
FEATURE_STEPS=$(echo "$FEATURE_INFO" | jq -r '.steps | length')

# Update session state
SESSION_ID=$(get_next_session_id)
TIMESTAMP=$(get_timestamp)
START_COMMIT=$(get_git_commit)
BRANCH=$(get_git_branch)

cat > "$HARNESS_DIR/session_state.json" << EOF
{
  "session_id": $SESSION_ID,
  "tool": "claude",
  "started_at": "$TIMESTAMP",
  "current_feature": "$NEXT_FEATURE",
  "start_commit": "$START_COMMIT",
  "end_commit": null,
  "e2e_result": null,
  "status": "in_progress"
}
EOF

# Update feature status to in_progress
update_feature_status "$NEXT_FEATURE" "in_progress"

# Write session start to progress log
cat >> "$HARNESS_DIR/progress.log.md" << EOF

## Session $(printf "%03d" $SESSION_ID) - $(get_display_date)

### Started
- **Task**: $NEXT_FEATURE - $FEATURE_DESC
- **Priority**: $FEATURE_PRIORITY
- **Steps**: $FEATURE_STEPS
- **Branch**: $BRANCH
- **Start Commit**: $START_COMMIT

### Environment
- Directory: \`$PWD\`
- Tool: Claude Code

### Plan
> Agent will implement this feature in this session.
> Parallel subtasks: 3-6 independent tasks
> Serial chains: dependency-required sequences

---
EOF

# Output session info for Agent
echo ""
log_success "=== Session $SESSION_ID Started ==="
echo ""
echo "### Environment"
echo "- Directory: $PWD"
echo "- Git Branch: $BRANCH"
echo "- Start Commit: $START_COMMIT"
echo ""
echo "### Selected Task"
echo "- ID: $NEXT_FEATURE"
echo "- Priority: $FEATURE_PRIORITY"
echo "- Description: $FEATURE_DESC"
echo "- Steps: $FEATURE_STEPS"
echo ""
echo "### Feature Details"
echo '```json'
echo "$FEATURE_INFO" | jq '.'
echo '```'
echo ""
echo "Session state saved to: $HARNESS_DIR/session_state.json"
echo "Progress log updated: $HARNESS_DIR/progress.log.md"
