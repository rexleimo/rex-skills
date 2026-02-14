#!/usr/bin/env bash

set -euo pipefail

DEFAULT_RAW_BASE="https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator"
DEFAULT_PATCH_REL="patches/long-running-harness.full.patch"

REPO_DIR="$(pwd)"
PATCH_FILE=""
PATCH_URL="${HARNESS_PATCH_URL:-$DEFAULT_RAW_BASE/$DEFAULT_PATCH_REL}"
ALLOW_DIRTY="false"
SKIP_VERIFY="false"
DRY_RUN="false"
NO_ROLLBACK="false"

log() { printf '[installer] %s\n' "$*"; }
err() { printf '[installer][error] %s\n' "$*" >&2; }

usage() {
  cat <<'USAGE'
Usage: install.sh [options]

Options:
  --repo <path>         目标项目根目录（默认当前目录）
  --patch-file <path>   本地补丁文件路径（优先于 --patch-url）
  --patch-url <url>     补丁下载地址（默认官方 raw）
  --allow-dirty         允许在脏工作区安装
  --skip-verify         安装后跳过验证步骤
  --dry-run             仅执行 git apply --check，不落盘
  --no-rollback         验证失败时不自动回滚
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

if [[ ! -d "$REPO_DIR" ]]; then
  err "repo dir not found: $REPO_DIR"
  exit 1
fi

if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  err "target is not a git repo: $REPO_DIR"
  exit 1
fi

if [[ ! -d "$REPO_DIR/.specify" ]]; then
  err "target does not look like a spec-kit repo (missing .specify): $REPO_DIR"
  exit 1
fi

if [[ "$ALLOW_DIRTY" != "true" ]] && [[ -n "$(git -C "$REPO_DIR" status --porcelain)" ]]; then
  err "working tree is dirty, commit/stash first or use --allow-dirty"
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
      curl -fsSL "$PATCH_URL" -o "$PATCH_PATH"
    fi
  else
    log "running from stdin, downloading patch from: $PATCH_URL"
    curl -fsSL "$PATCH_URL" -o "$PATCH_PATH"
  fi
fi

log "checking patch compatibility..."
git -C "$REPO_DIR" apply --check --whitespace=nowarn "$PATCH_PATH"
log "patch check passed"

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
  bash -n "$REPO_DIR"/.specify/scripts/bash/harness-*.sh "$REPO_DIR/.specify/scripts/bash/harness-lib.sh" || VERIFY_FAILED=1
fi

if [[ -x "$REPO_DIR/.specify/scripts/bash/check-prerequisites.sh" ]]; then
  "$REPO_DIR/.specify/scripts/bash/check-prerequisites.sh" --json --include-tasks >/dev/null || VERIFY_FAILED=1
fi

if [[ -f "$REPO_DIR/frontend/package.json" ]] && grep -q '"test:e2e:smoke"' "$REPO_DIR/frontend/package.json"; then
  if command -v npm >/dev/null 2>&1; then
    npm --prefix "$REPO_DIR/frontend" run test:e2e:smoke -- --list >/dev/null || VERIFY_FAILED=1
  else
    err "npm not found, cannot verify frontend e2e smoke"
    VERIFY_FAILED=1
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
