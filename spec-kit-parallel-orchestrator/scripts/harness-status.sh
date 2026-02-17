#!/bin/bash
# harness-status.sh - Display harness and feature status
# Usage: ./harness-status.sh [--json]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/harness-lib.sh"

JSON_OUTPUT=false
if [[ "${1:-}" == "--json" ]]; then
    JSON_OUTPUT=true
fi

if ! harness_exists; then
    if $JSON_OUTPUT; then
        echo '{"error": "harness_not_initialized"}'
    else
        log_error "Harness not initialized. Run harness-init.sh first."
    fi
    exit 1
fi

# Get counts
PASSING=$(count_features_by_status "passing")
IN_PROGRESS=$(count_features_by_status "in_progress")
PENDING=$(count_features_by_status "pending")
FAILED=$(count_features_by_status "failed")
BLOCKED=$(count_features_by_status "blocked")
TOTAL=$((PASSING + IN_PROGRESS + PENDING + FAILED + BLOCKED))

# Get session info
SESSION_STATUS=$(json_get "$HARNESS_DIR/session_state.json" '.status')
CURRENT_FEATURE=$(json_get "$HARNESS_DIR/session_state.json" '.current_feature')
SESSION_ID=$(json_get "$HARNESS_DIR/session_state.json" '.session_id')

if $JSON_OUTPUT; then
    jq -n \
        --argjson passing "$PASSING" \
        --argjson in_progress "$IN_PROGRESS" \
        --argjson pending "$PENDING" \
        --argjson failed "$FAILED" \
        --argjson blocked "$BLOCKED" \
        --argjson total "$TOTAL" \
        --arg session_status "$SESSION_STATUS" \
        --arg current_feature "$CURRENT_FEATURE" \
        --argjson session_id "$SESSION_ID" \
        '{
            summary: {
                total: $total,
                passing: $passing,
                in_progress: $in_progress,
                pending: $pending,
                failed: $failed,
                blocked: $blocked
            },
            session: {
                status: $session_status,
                id: $session_id,
                current_feature: $current_feature
            }
        }'
else
    echo "================================"
    echo "   Spec Kit Harness Status"
    echo "================================"
    echo ""
    echo "### Project"
    echo "- Name: $(json_get "$HARNESS_DIR/feature_list.json" '.project')"
    echo "- Created: $(json_get "$HARNESS_DIR/feature_list.json" '.created')"
    echo ""
    echo "### Feature Summary"
    echo "- Total: $TOTAL"
    echo -e "- ${GREEN}Passing: $PASSING${NC}"
    echo -e "- ${YELLOW}In Progress: $IN_PROGRESS${NC}"
    echo -e "- ${BLUE}Pending: $PENDING${NC}"
    echo -e "- ${RED}Failed: $FAILED${NC}"
    echo -e "- ${RED}Blocked: $BLOCKED${NC}"
    echo ""

    # Progress bar
    if [[ $TOTAL -gt 0 ]]; then
        PERCENT=$((PASSING * 100 / TOTAL))
        FILLED=$((PERCENT / 5))
        EMPTY=$((20 - FILLED))
        printf "Progress: ["
        printf "%${FILLED}s" | tr ' ' '█'
        printf "%${EMPTY}s" | tr ' ' '░'
        printf "] %d%%\n" $PERCENT
    fi
    echo ""

    # Current session
    echo "### Current Session"
    if [[ "$SESSION_STATUS" == "in_progress" ]]; then
        echo -e "Status: ${YELLOW}Active${NC}"
        echo "Session ID: $SESSION_ID"
        echo "Feature: $CURRENT_FEATURE"

        FEATURE_DESC=$(json_get "$HARNESS_DIR/feature_list.json" ".features[] | select(.id == \"$CURRENT_FEATURE\") | .description")
        echo "Description: $FEATURE_DESC"
    else
        echo "Status: Idle"
    fi
    echo ""

    # Feature details by status
    echo "### Features by Status"
    echo ""

    # Failed
    if [[ $FAILED -gt 0 ]]; then
        echo -e "${RED}Failed:${NC}"
        jq -r '.features[] | select(.status == "failed") | "  - " + .id + ": " + .description' "$HARNESS_DIR/feature_list.json"
        echo ""
    fi

    # Blocked
    if [[ $BLOCKED -gt 0 ]]; then
        echo -e "${RED}Blocked:${NC}"
        jq -r '.features[] | select(.status == "blocked") | "  - " + .id + ": " + .description + " [" + (.blocked_reason // "unknown") + "]"' "$HARNESS_DIR/feature_list.json"
        echo ""
    fi

    # In Progress
    if [[ $IN_PROGRESS -gt 0 ]]; then
        echo -e "${YELLOW}In Progress:${NC}"
        jq -r '.features[] | select(.status == "in_progress") | "  - " + .id + ": " + .description' "$HARNESS_DIR/feature_list.json"
        echo ""
    fi

    # Pending (show first 5)
    if [[ $PENDING -gt 0 ]]; then
        echo -e "${BLUE}Pending:${NC}"
        if [[ $PENDING -le 5 ]]; then
            jq -r '.features[] | select(.status == "pending") | "  - " + .id + " [" + .priority + "]: " + .description' "$HARNESS_DIR/feature_list.json"
        else
            jq -r '.features[] | select(.status == "pending") | "  - " + .id + " [" + .priority + "]: " + .description' "$HARNESS_DIR/feature_list.json" | head -5
            echo "  ... and $((PENDING - 5)) more"
        fi
        echo ""
    fi

    # Passing
    if [[ $PASSING -gt 0 ]]; then
        echo -e "${GREEN}Passing:${NC}"
        if [[ $PASSING -le 5 ]]; then
            jq -r '.features[] | select(.status == "passing") | "  - " + .id + ": " + .description' "$HARNESS_DIR/feature_list.json"
        else
            jq -r '.features[] | select(.status == "passing") | "  - " + .id + ": " + .description' "$HARNESS_DIR/feature_list.json" | head -5
            echo "  ... and $((PASSING - 5)) more"
        fi
        echo ""
    fi

    echo "================================"
    echo "Commands:"
    echo "  harness-start.sh   - Start a new session"
    echo "  harness-status.sh  - Show this status"
    echo "  harness-end.sh     - End current session"
    echo "================================"
fi
