#!/usr/bin/env bash

set -euo pipefail

DEFAULT_RAW_BASE="https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator"
DEFAULT_PATCH_REL="patches/long-running-harness.full.patch"
SCRIPT_PIPE_HINT="curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s --"

REPO_DIR="${HARNESS_REPO_DIR:-${TARGET_REPO:-}}"
PATCH_FILE=""
PATCH_URL="${HARNESS_PATCH_URL:-$DEFAULT_RAW_BASE/$DEFAULT_PATCH_REL}"
ALLOW_DIRTY="false"
SKIP_VERIFY="false"
DRY_RUN="false"
NO_ROLLBACK="false"
CURL_RETRY_ARGS=(--retry 3 --retry-delay 1 --connect-timeout 15)

log() { printf '[installer] %s\n' "$*"; }
warn() { printf '[installer][warn] %s\n' "$*" >&2; }
err() { printf '[installer][error] %s\n' "$*" >&2; }

if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
  CURL_RETRY_ARGS+=(--retry-all-errors)
fi

usage() {
  cat <<'USAGE'
Usage: install.sh [options]

Options:
  --repo <path>         目标项目根目录（默认当前 git 根目录）
  --patch-file <path>   本地补丁文件路径（优先于 --patch-url）
  --patch-url <url>     补丁下载地址（默认官方 raw）
  --allow-dirty         允许在脏工作区安装
  --skip-verify         安装后跳过验证步骤
  --dry-run             仅执行 git apply --check，不落盘
  --no-rollback         验证失败时不自动回滚
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
    --allow-dirty)
      ALLOW_DIRTY="true"
      shift
      ;;
    --skip-verify)
      SKIP_VERIFY="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --no-rollback)
      NO_ROLLBACK="true"
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

if [[ ! -d "$REPO_DIR/.specify" ]]; then
  err "target does not look like a spec-kit repo (missing .specify): $REPO_DIR"
  err "tip: run in target repo (or subdir) or use --repo, e.g. $SCRIPT_PIPE_HINT --repo /path/to/target"
  exit 1
fi

if [[ "$ALLOW_DIRTY" != "true" ]] && [[ -n "$(git -C "$REPO_DIR" status --porcelain)" ]]; then
  err "working tree is dirty, commit/stash first or use --allow-dirty"
  err "tip: $SCRIPT_PIPE_HINT --allow-dirty"
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
      log "local patch not found, downloading from: $PATCH_URL"
      download_patch "$PATCH_URL" "$PATCH_PATH"
    fi
  else
    log "running from stdin, downloading patch from: $PATCH_URL"
    download_patch "$PATCH_URL" "$PATCH_PATH"
  fi
fi

log "checking patch compatibility..."
if git -C "$REPO_DIR" apply --check --whitespace=nowarn "$PATCH_PATH"; then
  log "patch check passed"
else
  if git -C "$REPO_DIR" apply --check -R --whitespace=nowarn "$PATCH_PATH"; then
    log "patch is already installed, nothing to do"
    exit 0
  fi
  err "patch is not applicable to current repo state"
  exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
  log "dry-run complete, no file changed"
  exit 0
fi

log "applying patch..."
git -C "$REPO_DIR" apply --whitespace=nowarn "$PATCH_PATH"
log "patch applied"

if [[ "$SKIP_VERIFY" == "true" ]]; then
  log "skip verify enabled"
  log "done"
  exit 0
fi

set +e
VERIFY_FAILED=0

if [[ -f "$REPO_DIR/.specify/scripts/bash/harness-lib.sh" ]]; then
  shopt -s nullglob
  HARNESS_SCRIPTS=("$REPO_DIR"/.specify/scripts/bash/harness-*.sh)
  shopt -u nullglob
  bash -n "${HARNESS_SCRIPTS[@]}" "$REPO_DIR/.specify/scripts/bash/harness-lib.sh" || VERIFY_FAILED=1
fi

if [[ -x "$REPO_DIR/.specify/scripts/bash/check-prerequisites.sh" ]]; then
  "$REPO_DIR/.specify/scripts/bash/check-prerequisites.sh" --json --include-tasks >/dev/null || VERIFY_FAILED=1
fi

if [[ -f "$REPO_DIR/frontend/package.json" ]] && grep -q '"test:e2e:smoke"' "$REPO_DIR/frontend/package.json"; then
  if ! command -v npm >/dev/null 2>&1; then
    warn "npm not found, skipping optional frontend smoke verify"
  elif [[ ! -d "$REPO_DIR/frontend/node_modules" ]]; then
    warn "frontend/node_modules missing, skipping optional frontend smoke verify"
  else
    npm --prefix "$REPO_DIR/frontend" run test:e2e:smoke -- --list >/dev/null || VERIFY_FAILED=1
  fi
fi
set -e

if [[ $VERIFY_FAILED -ne 0 ]]; then
  err "post-apply verification failed"
  if [[ "$NO_ROLLBACK" != "true" ]]; then
    log "rolling back patch..."
    if git -C "$REPO_DIR" apply -R --whitespace=nowarn "$PATCH_PATH"; then
      err "patch rolled back"
    else
      err "auto rollback failed, rollback manually"
    fi
  fi
  exit 1
fi

log "all checks passed"
log "install success"
