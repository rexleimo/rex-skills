#!/usr/bin/env bash

set -euo pipefail

DEFAULT_RAW_BASE="https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator"
DEFAULT_PATCH_REL="patches/long-running-harness.full.patch"
SCRIPT_PIPE_HINT="curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/uninstall.sh | bash -s --"

REPO_DIR="${HARNESS_REPO_DIR:-${TARGET_REPO:-}}"
PATCH_FILE=""
PATCH_URL="${HARNESS_PATCH_URL:-$DEFAULT_RAW_BASE/$DEFAULT_PATCH_REL}"
DRY_RUN="false"
CURL_RETRY_ARGS=(--retry 3 --retry-delay 1 --connect-timeout 15)

log() { printf '[uninstall] %s\n' "$*"; }
err() { printf '[uninstall][error] %s\n' "$*" >&2; }

if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
  CURL_RETRY_ARGS+=(--retry-all-errors)
fi

usage() {
  cat <<'USAGE'
Usage: uninstall.sh [options]

Options:
  --repo <path>         目标项目根目录（默认当前 git 根目录）
  --patch-file <path>   本地补丁文件路径（优先于 --patch-url）
  --patch-url <url>     补丁下载地址（默认官方 raw）
  --dry-run             仅检查可否反向应用，不真正回滚
  -h, --help            显示帮助

Environment:
  HARNESS_REPO_DIR / TARGET_REPO
                       与 --repo 等价，适合 curl | bash 场景
  HARNESS_PATCH_URL     与 --patch-url 等价
USAGE
}

require_option_arg() {
  if [[ $# -lt 2 || -z "$2" ]]; then
    err "option $1 requires a value"
    usage
    exit 1
  fi
}

download_patch() {
  local url="$1"
  local dst="$2"
  curl -fsSL "${CURL_RETRY_ARGS[@]}" "$url" -o "$dst"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      require_option_arg "$@"
      REPO_DIR="$2"
      shift 2
      ;;
    --patch-file)
      require_option_arg "$@"
      PATCH_FILE="$2"
      shift 2
      ;;
    --patch-url)
      require_option_arg "$@"
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

if [[ -z "$REPO_DIR" ]]; then
  if GIT_TOPLEVEL="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    REPO_DIR="$GIT_TOPLEVEL"
    log "auto-detected repo root: $REPO_DIR"
  else
    REPO_DIR="$(pwd)"
  fi
fi

if [[ ! -d "$REPO_DIR" ]]; then
  err "repo dir not found: $REPO_DIR"
  exit 1
fi

REPO_DIR="$(CDPATH="" cd "$REPO_DIR" && pwd)"

if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  err "target is not a git repo: $REPO_DIR"
  err "tip: specify target repo explicitly, e.g. $SCRIPT_PIPE_HINT --repo /path/to/target"
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
      download_patch "$PATCH_URL" "$PATCH_PATH"
    fi
  else
    download_patch "$PATCH_URL" "$PATCH_PATH"
  fi
fi

log "checking reverse patch..."
if git -C "$REPO_DIR" apply --check -R --whitespace=nowarn "$PATCH_PATH"; then
  log "reverse check passed"
else
  if git -C "$REPO_DIR" apply --check --whitespace=nowarn "$PATCH_PATH"; then
    log "patch is not installed, nothing to uninstall"
    exit 0
  fi
  err "patch state is incompatible with current repo"
  exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
  log "dry-run complete, no file changed"
  exit 0
fi

log "reverting patch..."
git -C "$REPO_DIR" apply -R --whitespace=nowarn "$PATCH_PATH"
log "uninstall success"
