#!/bin/bash
# harness-commit.sh - Create a commit and update progress
# Usage: ./harness-commit.sh "commit message"

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/harness-lib.sh"

require_harness

# Check for active session
CURRENT_STATUS=$(json_get "$HARNESS_DIR/session_state.json" '.status')
if [[ "$CURRENT_STATUS" != "in_progress" ]]; then
    log_error "No active session. Run harness-start.sh first."
    exit 1
fi

CURRENT_FEATURE=$(json_get "$HARNESS_DIR/session_state.json" '.current_feature')
COMMIT_MSG="${1:-}"

if [[ -z "$COMMIT_MSG" ]]; then
    # Generate default commit message
    FEATURE_DESC=$(json_get "$HARNESS_DIR/feature_list.json" ".features[] | select(.id == \"$CURRENT_FEATURE\") | .description")
    COMMIT_MSG="feat($CURRENT_FEATURE): $FEATURE_DESC"
    log_info "Using auto-generated commit message."
fi

log_info "Creating commit for feature: $CURRENT_FEATURE"

# Check for changes
if is_working_tree_clean; then
    log_warning "No changes to commit."
    exit 0
fi

# Show what will be committed
echo ""
log_info "Changes to commit:"
git status --short
echo ""

read -p "Proceed with commit? (Y/n) " -n 1 -r
echo
if [[ $REPLY == "n" || $REPLY == "N" ]]; then
    log_info "Aborted."
    exit 0
fi

# Stage all changes
git add -A

# Create commit
git commit -m "$COMMIT_MSG"

COMMIT_HASH=$(get_git_commit)
log_success "Created commit: $COMMIT_HASH"

# Add commit to feature
add_commit_to_feature "$CURRENT_FEATURE" "$COMMIT_HASH"

# Update progress log
TIMESTAMP=$(get_timestamp)
cat >> "$HARNESS_DIR/progress.log.md" << EOF

#### Progress Update - $(date +"%H:%M:%S")
- Commit: \`$COMMIT_HASH\`
- Message: $COMMIT_MSG
- Time: $TIMESTAMP

EOF

log_info "Progress log updated."
echo ""
log_success "Commit complete. Continue implementing or run harness-end.sh when ready."
