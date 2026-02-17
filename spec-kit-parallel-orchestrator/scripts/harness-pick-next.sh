#!/bin/bash
# harness-pick-next.sh - Select the next feature to work on
# Usage: ./harness-pick-next.sh [--json]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/harness-lib.sh"

require_harness

JSON_OUTPUT=false
if [[ "${1:-}" == "--json" ]]; then
    JSON_OUTPUT=true
fi

# Find next feature
NEXT_FEATURE=$(find_next_feature)

if [[ -z "$NEXT_FEATURE" ]]; then
    if $JSON_OUTPUT; then
        echo '{"error": "no_pending_features", "message": "All features complete or blocked"}'
    else
        log_success "No pending features. All work complete!"
    fi
    exit 0
fi

# Get feature info
FEATURE_INFO=$(get_feature_info "$NEXT_FEATURE")

if $JSON_OUTPUT; then
    echo "$FEATURE_INFO"
else
    log_info "Next feature to work on:"
    echo ""
    format_feature_status "$NEXT_FEATURE"
    echo ""
    echo "Run harness-start.sh to begin this feature."
fi
