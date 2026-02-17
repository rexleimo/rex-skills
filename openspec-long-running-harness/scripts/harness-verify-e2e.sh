#!/bin/bash
# harness-verify-e2e.sh - Run E2E verification for the current feature
# Usage: ./harness-verify-e2e.sh [--timeout 300]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/harness-lib.sh"

require_harness

# Parse arguments
TIMEOUT=300
while [[ $# -gt 0 ]]; do
    case $1 in
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

log_info "Running E2E verification..."

# Get E2E command from config
E2E_CMD=$(json_get "$HARNESS_DIR/.harness-config.json" '.e2e_command')

if [[ -z "$E2E_CMD" || "$E2E_CMD" == "null" ]]; then
    log_error "No E2E command configured in .harness-config.json"
    log_info "Set e2e_command in $HARNESS_DIR/.harness-config.json"
    exit 1
fi

log_info "Command: $E2E_CMD"
log_info "Timeout: ${TIMEOUT}s"
echo ""

# Run E2E
set +e
E2E_OUTPUT=$(timeout "$TIMEOUT" bash -c "$E2E_CMD" 2>&1)
E2E_EXIT=$?
set -e

# Output results
echo "$E2E_OUTPUT"
echo ""

if [[ $E2E_EXIT -eq 0 ]]; then
    log_success "E2E verification PASSED"
    exit 0
elif [[ $E2E_EXIT -eq 124 ]]; then
    log_error "E2E verification TIMED OUT after ${TIMEOUT}s"
    exit 124
else
    log_error "E2E verification FAILED (exit code: $E2E_EXIT)"
    exit $E2E_EXIT
fi
