#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: make-patch.sh --source-repo <path> [--output <patch-file>]

说明：
- 从 source-repo 中抽取 long-running harness 相关改动，生成 full patch。
- 仅用于维护者更新补丁。
USAGE
}

SOURCE_REPO=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo)
      SOURCE_REPO="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$SOURCE_REPO" ]]; then
  echo "--source-repo is required" >&2
  exit 1
fi

if [[ -z "$OUTPUT" ]]; then
  SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  OUTPUT="$SCRIPT_DIR/../patches/long-running-harness.full.patch"
fi

if [[ ! -d "$SOURCE_REPO" ]]; then
  echo "source repo not found: $SOURCE_REPO" >&2
  exit 1
fi

if ! git -C "$SOURCE_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "source repo is not git: $SOURCE_REPO" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"
: > "$OUTPUT"

tracked_files=(
  ".codex/prompts/speckit.plan.md"
  ".codex/prompts/speckit.tasks.md"
  ".codex/prompts/speckit.implement.md"
  ".claude/commands/speckit.plan.md"
  ".claude/commands/speckit.tasks.md"
  ".claude/commands/speckit.implement.md"
  ".specify/scripts/bash/common.sh"
  ".specify/scripts/bash/check-prerequisites.sh"
  ".specify/templates/plan-template.md"
  "specs/README.md"
  "frontend/package.json"
  "frontend/package-lock.json"
)

new_files=(
  ".specify/scripts/bash/harness-lib.sh"
  ".specify/scripts/bash/harness-init.sh"
  ".specify/scripts/bash/harness-pick-next.sh"
  ".specify/scripts/bash/harness-start-session.sh"
  ".specify/scripts/bash/harness-end-session.sh"
  ".specify/scripts/bash/harness-verify-e2e.sh"
  "frontend/playwright.smoke.config.mjs"
  "frontend/tests/e2e/smoke.spec.mjs"
  "tests/specify/harness_scripts_test.sh"
)

existing_tracked=()
for f in "${tracked_files[@]}"; do
  if [[ -e "$SOURCE_REPO/$f" ]]; then
    existing_tracked+=("$f")
  fi
done

if [[ ${#existing_tracked[@]} -gt 0 ]]; then
  git -C "$SOURCE_REPO" diff -- "${existing_tracked[@]}" >> "$OUTPUT"
fi

for f in "${new_files[@]}"; do
  if [[ -e "$SOURCE_REPO/$f" ]]; then
    git -C "$SOURCE_REPO" diff --no-index -- /dev/null "$SOURCE_REPO/$f" >> "$OUTPUT" || true
  fi
done

wc -l "$OUTPUT"
echo "patch generated: $OUTPUT"
