#!/usr/bin/env bash

set -euo pipefail

DEFAULT_RAW_BASE="https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator"
DEFAULT_PATCH_REL="patches/long-running-harness.full.patch"

REPO_DIR="$(pwd)"
PATCH_FILE=""
PATCH_URL="${HARNESS_PATCH_URL:-$DEFAULT_RAW_BASE/$DEFAULT_PATCH_REL}"
DRY_RUN="false"

log() { printf '[uninstall] %s\n' "$*"; }
err() { printf '[uninstall][error] %s\n' "$*" >&2; }

usage() {
  cat <<'USAGE'
Usage: uninstall.sh [options]

Options:
  --repo <path>         目标项目根目录（默认当前目录）
  --patch-file <path>   本地补丁文件路径（优先于 --patch-url）
  --patch-url <url>     补丁下载地址（默认官方 raw）
  --dry-run             仅检查可否反向应用，不真正回滚
  -h, --help            显示帮助
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_DIR="$2"
      shift 2
      ;;
    --patch-file)
      PATCH_FILE="$2"
      shift 2
      ;;
    --patch-url)
      PATCH_URL="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

command -v git >/dev/null 2>&1 || { err "git not found"; exit 1; }
command -v curl >/dev/null 2>&1 || { err "curl not found"; exit 1; }

if [[ ! -d "$REPO_DIR" ]]; then
  err "repo dir not found: $REPO_DIR"
  exit 1
fi

if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  err "target is not a git repo: $REPO_DIR"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
PATCH_PATH="$TMP_DIR/long-running-harness.full.patch"

if [[ -n "$PATCH_FILE" ]]; then
  if [[ ! -f "$PATCH_FILE" ]]; then
    err "patch file not found: $PATCH_FILE"
    exit 1
  fi
  cp "$PATCH_FILE" "$PATCH_PATH"
else
  SCRIPT_PATH="${BASH_SOURCE[0]:-}"
  if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
    SCRIPT_DIR="$(CDPATH="" cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    LOCAL_PATCH="$SCRIPT_DIR/../patches/long-running-harness.full.patch"
    if [[ -f "$LOCAL_PATCH" ]]; then
      cp "$LOCAL_PATCH" "$PATCH_PATH"
    else
      curl -fsSL "$PATCH_URL" -o "$PATCH_PATH"
    fi
  else
    curl -fsSL "$PATCH_URL" -o "$PATCH_PATH"
  fi
fi

log "checking reverse patch..."
git -C "$REPO_DIR" apply --check -R --whitespace=nowarn "$PATCH_PATH"
log "reverse check passed"

if [[ "$DRY_RUN" == "true" ]]; then
  log "dry-run complete, no file changed"
  exit 0
fi

log "reverting patch..."
git -C "$REPO_DIR" apply -R --whitespace=nowarn "$PATCH_PATH"
log "uninstall success"
