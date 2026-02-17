#!/bin/bash
# harness-lib.sh - Common functions for Spec Kit Parallel Orchestrator Harness
# Source this file in other scripts: source harness-lib.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default harness directory - adjusted for spec-kit structure
HARNESS_DIR="${HARNESS_DIR:-specs/harness}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if harness is initialized
harness_exists() {
    [[ -d "$HARNESS_DIR" && -f "$HARNESS_DIR/feature_list.json" ]]
}

# Ensure harness is initialized
require_harness() {
    if ! harness_exists; then
        log_error "Harness not initialized. Run harness-init.sh first."
        exit 1
    fi
}

# Get current git branch
get_git_branch() {
    git branch --show-current 2>/dev/null || echo "unknown"
}

# Get current git commit hash (short)
get_git_commit() {
    git rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

# Check if working tree is clean
is_working_tree_clean() {
    git diff-index --quiet HEAD -- 2>/dev/null
}

# Get timestamp in ISO format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Get date for display
get_display_date() {
    date +"%Y-%m-%d"
}

# Generate session ID (incremental)
get_next_session_id() {
    local progress_file="$HARNESS_DIR/progress.log.md"
    if [[ -f "$progress_file" ]]; then
        local last_id=$(grep -E "^## Session [0-9]+" "$progress_file" | tail -1 | grep -oE "[0-9]+" || echo "0")
        echo $((last_id + 1))
    else
        echo "1"
    fi
}

# Read JSON value using jq (requires jq)
json_get() {
    local file="$1"
    local path="$2"
    jq -r "$path" "$file" 2>/dev/null || echo ""
}

# Set JSON value using jq (requires jq)
json_set() {
    local file="$1"
    local path="$2"
    local value="$3"
    local tmp_file=$(mktemp)
    jq "$path = $value" "$file" > "$tmp_file" && mv "$tmp_file" "$file"
}

# Find next feature by priority and status
# Priority: P1 > P2 > P3
# Status: failed > in_progress > blocked > pending
find_next_feature() {
    local feature_file="$HARNESS_DIR/feature_list.json"

    if [[ ! -f "$feature_file" ]]; then
        echo ""
        return
    fi

    # Try failed first (highest priority to fix)
    local failed=$(jq -r '.features[] | select(.status == "failed") | select(.blocked_reason == null or .blocked_reason == "") | .id' "$feature_file" | head -1)
    if [[ -n "$failed" ]]; then
        echo "$failed"
        return
    fi

    # Try in_progress (resume work)
    local in_progress=$(jq -r '.features[] | select(.status == "in_progress") | select(.blocked_reason == null or .blocked_reason == "") | .id' "$feature_file" | head -1)
    if [[ -n "$in_progress" ]]; then
        echo "$in_progress"
        return
    fi

    # Try pending by priority (P1 > P2 > P3)
    for priority in "P1" "P2" "P3"; do
        local pending=$(jq -r --arg p "$priority" '.features[] | select(.status == "pending" and .priority == $p) | select(.blocked_reason == null or .blocked_reason == "") | .id' "$feature_file" | head -1)
        if [[ -n "$pending" ]]; then
            echo "$pending"
            return
        fi
    done

    echo ""
}

# Update feature status
update_feature_status() {
    local feature_id="$1"
    local new_status="$2"
    local feature_file="$HARNESS_DIR/feature_list.json"
    local timestamp=$(get_timestamp)

    local tmp_file=$(mktemp)
    jq --arg id "$feature_id" --arg status "$new_status" --arg ts "$timestamp" '
        (.features[] | select(.id == $id)) |= (
            .status = $status |
            if $status == "in_progress" and .started_at == null then .started_at = $ts
            elif $status == "passing" then .completed_at = $ts
            else . end
        )
    ' "$feature_file" > "$tmp_file" && mv "$tmp_file" "$feature_file"

    log_info "Feature $feature_id status updated to: $new_status"
}

# Get feature info as JSON
get_feature_info() {
    local feature_id="$1"
    local feature_file="$HARNESS_DIR/feature_list.json"

    jq --arg id "$feature_id" '.features[] | select(.id == $id)' "$feature_file"
}

# Add commit to feature
add_commit_to_feature() {
    local feature_id="$1"
    local commit_hash="$2"
    local feature_file="$HARNESS_DIR/feature_list.json"

    local tmp_file=$(mktemp)
    jq --arg id "$feature_id" --arg hash "$commit_hash" '
        (.features[] | select(.id == $id)).commits += [$hash]
    ' "$feature_file" > "$tmp_file" && mv "$tmp_file" "$feature_file"
}

# Check if all dependencies are passing
check_dependencies() {
    local feature_id="$1"
    local feature_file="$HARNESS_DIR/feature_list.json"

    local deps=$(jq -r --arg id "$feature_id" '.features[] | select(.id == $id) | .depends_on // [] | .[]' "$feature_file" 2>/dev/null)

    for dep in $deps; do
        local dep_status=$(jq -r --arg dep "$dep" '.features[] | select(.id == $dep) | .status' "$feature_file")
        if [[ "$dep_status" != "passing" ]]; then
            echo "blocked:$dep"
            return
        fi
    done

    echo "ok"
}

# Format feature for display
format_feature_status() {
    local feature_id="$1"
    local feature_file="$HARNESS_DIR/feature_list.json"

    jq -r --arg id "$feature_id" '
        .features[] | select(.id == $id) |
        "ID: \(.id)\nPriority: \(.priority)\nStatus: \(.status)\nDescription: \(.description)\nSteps: \(.steps | length)"
    ' "$feature_file"
}

# Count features by status
count_features_by_status() {
    local status="$1"
    local feature_file="$HARNESS_DIR/feature_list.json"

    jq --arg s "$status" '[.features[] | select(.status == $s)] | length' "$feature_file"
}

# Check required commands
check_requirements() {
    local missing=()

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        log_info "Install with: brew install ${missing[*]}"
        return 1
    fi

    return 0
}
