#!/usr/bin/env bash

set -euo pipefail

DEFAULT_RAW_BASE="https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator"
DEFAULT_PATCH_REL="patches/long-running-harness.full.patch"
SCRIPT_PIPE_HINT="curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s --"
DEFAULT_SKILL_REPO="rexleimo/rex-skills"
DEFAULT_SKILL_REF="main"
DEFAULT_SKILL_PATH="spec-kit-parallel-orchestrator"
DEFAULT_SKILL_NAME="spec-kit-parallel-orchestrator"
CORE_INCLUDE_PATHS=(
  ".specify/scripts/bash/harness-lib.sh"
  ".specify/scripts/bash/harness-init.sh"
  ".specify/scripts/bash/harness-pick-next.sh"
  ".specify/scripts/bash/harness-start-session.sh"
  ".specify/scripts/bash/harness-end-session.sh"
  ".specify/scripts/bash/harness-verify-e2e.sh"
)

REPO_DIR="${HARNESS_REPO_DIR:-${TARGET_REPO:-}}"
PATCH_FILE=""
PATCH_URL="${HARNESS_PATCH_URL:-$DEFAULT_RAW_BASE/$DEFAULT_PATCH_REL}"
SKILL_REPO="${HARNESS_SKILL_REPO:-$DEFAULT_SKILL_REPO}"
SKILL_REF="${HARNESS_SKILL_REF:-$DEFAULT_SKILL_REF}"
SKILL_PATH="${HARNESS_SKILL_PATH:-$DEFAULT_SKILL_PATH}"
SKILL_NAME="${HARNESS_SKILL_NAME:-$DEFAULT_SKILL_NAME}"
SKILL_DEST="${HARNESS_SKILL_DEST:-}"
INSTALL_SKILL="${HARNESS_INSTALL_SKILL:-true}"
PATCH_PROMPTS="${HARNESS_PATCH_PROMPTS:-true}"
ALLOW_DIRTY="false"
SKIP_VERIFY="false"
DRY_RUN="false"
NO_ROLLBACK="false"
CURL_RETRY_ARGS=(--retry 3 --retry-delay 1 --connect-timeout 15)
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
  SCRIPT_DIR="$(CDPATH="" cd "$(dirname "$SCRIPT_PATH")" && pwd)"
fi

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
  --skip-skill          不安装/更新 .codex skill
  --skip-prompts        不对 speckit prompts 追加 harness 指南
  --skill-dest <path>   指定 skill 安装目录（默认 .codex/skills/spec-kit-parallel-orchestrator）
  --skill-ref <ref>     指定 skill 下载分支/标签（默认 main）
  --dry-run             仅执行 git apply --check，不落盘
  --no-rollback         验证失败时不自动回滚
  -h, --help            显示帮助

Environment:
  HARNESS_REPO_DIR / TARGET_REPO
                       与 --repo 等价，适合 curl | bash 场景
  HARNESS_PATCH_URL     与 --patch-url 等价
  HARNESS_INSTALL_SKILL 与 --skip-skill 相反（true/false）
  HARNESS_PATCH_PROMPTS 与 --skip-prompts 相反（true/false）
  HARNESS_SKILL_DEST    与 --skill-dest 等价
  HARNESS_SKILL_REF     与 --skill-ref 等价
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

build_core_include_args() {
  CORE_INCLUDE_ARGS=()
  local p
  for p in "${CORE_INCLUDE_PATHS[@]}"; do
    CORE_INCLUDE_ARGS+=(--include="$p")
  done
}

can_apply_full_patch() {
  git -C "$REPO_DIR" apply --check --whitespace=nowarn "$PATCH_PATH" >/dev/null 2>&1
}

can_revert_full_patch() {
  git -C "$REPO_DIR" apply --check -R --whitespace=nowarn "$PATCH_PATH" >/dev/null 2>&1
}

can_apply_core_patch() {
  git -C "$REPO_DIR" apply --check --whitespace=nowarn "${CORE_INCLUDE_ARGS[@]}" "$PATCH_PATH" >/dev/null 2>&1
}

can_revert_core_patch() {
  git -C "$REPO_DIR" apply --check -R --whitespace=nowarn "${CORE_INCLUDE_ARGS[@]}" "$PATCH_PATH" >/dev/null 2>&1
}

append_block_if_missing() {
  local file="$1"
  local marker="$2"
  local block="$3"
  if [[ ! -f "$file" ]]; then
    return 0
  fi
  if grep -q "$marker" "$file"; then
    return 0
  fi
  {
    echo
    echo "$block"
    echo
  } >>"$file"
}

patch_prompts_files() {
  local plan_block
  local tasks_block
  local impl_block

  plan_block="$(cat <<'EOF'
<!-- HARNESS_PROMPT_PATCH_PLAN_V1 -->
## Long-Running Harness
- Initialize harness before implementation:
  - `.specify/scripts/bash/harness-init.sh --feature <feature-id> --tool codex|claude`
- Ensure plan/quickstart includes these artifacts:
  - `harness/feature_list.json`
  - `harness/progress.log.md`
  - `harness/session_state.json`
  - `harness/init.sh`
EOF
)"

  tasks_block="$(cat <<'EOF'
<!-- HARNESS_PROMPT_PATCH_TASKS_V1 -->
## Long-Running Harness
- Include lifecycle tasks in tasks.md:
  - `harness-start-session.sh`
  - `harness-pick-next.sh`
  - `harness-end-session.sh`
  - `harness-verify-e2e.sh`
- Status transition updates in `harness/feature_list.json` should be sequential (avoid parallel writes).
EOF
)"

  impl_block="$(cat <<'EOF'
<!-- HARNESS_PROMPT_PATCH_IMPLEMENT_V1 -->
## Long-Running Harness
- Start each session with:
  - `.specify/scripts/bash/harness-start-session.sh --feature <feature-id> --tool codex|claude`
- End each session with:
  - `.specify/scripts/bash/harness-end-session.sh --feature <feature-id> --tool codex|claude`
- Enforce commit + e2e gate before setting a feature to `passing`.
EOF
)"

  append_block_if_missing "$REPO_DIR/.codex/prompts/speckit.plan.md" "HARNESS_PROMPT_PATCH_PLAN_V1" "$plan_block"
  append_block_if_missing "$REPO_DIR/.claude/commands/speckit.plan.md" "HARNESS_PROMPT_PATCH_PLAN_V1" "$plan_block"
  append_block_if_missing "$REPO_DIR/.codex/prompts/speckit.tasks.md" "HARNESS_PROMPT_PATCH_TASKS_V1" "$tasks_block"
  append_block_if_missing "$REPO_DIR/.claude/commands/speckit.tasks.md" "HARNESS_PROMPT_PATCH_TASKS_V1" "$tasks_block"
  append_block_if_missing "$REPO_DIR/.codex/prompts/speckit.implement.md" "HARNESS_PROMPT_PATCH_IMPLEMENT_V1" "$impl_block"
  append_block_if_missing "$REPO_DIR/.claude/commands/speckit.implement.md" "HARNESS_PROMPT_PATCH_IMPLEMENT_V1" "$impl_block"
}

install_skill_dir() {
  local src_dir=""
  local skill_tar_url=""
  local skill_tar_path=""
  local skill_extract_dir=""
  local extracted_root=""

  if [[ -n "${SCRIPT_PATH:-}" && -f "${SCRIPT_PATH:-}" ]]; then
    SCRIPT_DIR="$(CDPATH="" cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    if [[ -f "$SCRIPT_DIR/../SKILL.md" ]]; then
      src_dir="$(CDPATH="" cd "$SCRIPT_DIR/.." && pwd)"
    fi
  fi

  if [[ -z "$src_dir" ]]; then
    command -v tar >/dev/null 2>&1 || {
      err "tar not found, cannot download skill bundle"
      return 1
    }
    skill_tar_url="https://codeload.github.com/${SKILL_REPO}/tar.gz/refs/heads/${SKILL_REF}"
    skill_tar_path="$TMP_DIR/rex-skills-${SKILL_REF}.tar.gz"
    skill_extract_dir="$TMP_DIR/rex-skills-${SKILL_REF}"
    mkdir -p "$skill_extract_dir"
    log "downloading skill bundle: $skill_tar_url"
    curl -fsSL "${CURL_RETRY_ARGS[@]}" "$skill_tar_url" -o "$skill_tar_path"
    tar -xzf "$skill_tar_path" -C "$skill_extract_dir"
    extracted_root="$(find "$skill_extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    if [[ -z "$extracted_root" ]]; then
      err "failed to extract skill bundle"
      return 1
    fi
    src_dir="$extracted_root/$SKILL_PATH"
  fi

  if [[ ! -f "$src_dir/SKILL.md" ]]; then
    err "invalid skill source (SKILL.md missing): $src_dir"
    return 1
  fi

  mkdir -p "$(dirname "$SKILL_DEST")"
  rm -rf "$SKILL_DEST"
  mkdir -p "$SKILL_DEST"
  cp -a "$src_dir"/. "$SKILL_DEST"/
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
    --skip-skill)
      INSTALL_SKILL="false"
      shift
      ;;
    --skip-prompts)
      PATCH_PROMPTS="false"
      shift
      ;;
    --skill-dest)
      require_option_arg "$@"
      SKILL_DEST="$2"
      shift 2
      ;;
    --skill-ref)
      require_option_arg "$@"
      SKILL_REF="$2"
      shift 2
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
if [[ -z "$SKILL_DEST" ]]; then
  SKILL_DEST="$REPO_DIR/.codex/skills/$SKILL_NAME"
fi
CURRENT_BRANCH="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

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
CORE_INCLUDE_ARGS=()

if [[ -n "$PATCH_FILE" ]]; then
  if [[ ! -f "$PATCH_FILE" ]]; then
    err "patch file not found: $PATCH_FILE"
    exit 1
  fi
  cp "$PATCH_FILE" "$PATCH_PATH"
else
  if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
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

build_core_include_args

log "checking patch compatibility..."
INSTALL_MODE=""
PATCH_ALREADY_INSTALLED="false"
if can_apply_full_patch; then
  INSTALL_MODE="full"
  log "patch check passed (mode: full)"
else
  if can_revert_full_patch; then
    INSTALL_MODE="full"
    PATCH_ALREADY_INSTALLED="true"
    log "patch already installed (mode: full), will continue with skill/prompts sync"
  else
    warn "full patch is not applicable; trying compatibility mode (core harness files only)"
    if can_apply_core_patch; then
      INSTALL_MODE="core"
      log "patch check passed (mode: core)"
      warn "compatibility mode skips template/prompt/frontend/package changes; configure HARNESS_E2E_CMD if needed"
    elif can_revert_core_patch; then
      INSTALL_MODE="core"
      PATCH_ALREADY_INSTALLED="true"
      log "patch already installed (mode: core), will continue with skill/prompts sync"
    else
      err "patch is not applicable to current repo state (full/core checks both failed)"
      exit 1
    fi
  fi
fi

if [[ "$DRY_RUN" == "true" ]]; then
  log "dry-run complete, no file changed (mode: ${INSTALL_MODE:-unknown})"
  exit 0
fi

if [[ "$PATCH_ALREADY_INSTALLED" == "true" ]]; then
  log "skip patch apply (already installed)"
  PATCH_APPLIED="false"
else
  log "applying patch (mode: ${INSTALL_MODE:-full})..."
  if [[ "$INSTALL_MODE" == "core" ]]; then
    git -C "$REPO_DIR" apply --whitespace=nowarn "${CORE_INCLUDE_ARGS[@]}" "$PATCH_PATH"
  else
    git -C "$REPO_DIR" apply --whitespace=nowarn "$PATCH_PATH"
  fi
  log "patch applied (mode: ${INSTALL_MODE:-full})"
  PATCH_APPLIED="true"
fi

if [[ "$PATCH_APPLIED" == "true" ]] && [[ "$SKIP_VERIFY" != "true" ]]; then
  set +e
  VERIFY_FAILED=0

  if [[ -f "$REPO_DIR/.specify/scripts/bash/harness-lib.sh" ]]; then
    shopt -s nullglob
    HARNESS_SCRIPTS=("$REPO_DIR"/.specify/scripts/bash/harness-*.sh)
    shopt -u nullglob
    bash -n "${HARNESS_SCRIPTS[@]}" "$REPO_DIR/.specify/scripts/bash/harness-lib.sh" || VERIFY_FAILED=1
  fi

  if [[ -x "$REPO_DIR/.specify/scripts/bash/check-prerequisites.sh" ]]; then
    if [[ "$CURRENT_BRANCH" =~ ^[0-9]{3}- ]]; then
      "$REPO_DIR/.specify/scripts/bash/check-prerequisites.sh" --json --include-tasks >/dev/null || VERIFY_FAILED=1
    else
      warn "skip check-prerequisites on non-feature branch: ${CURRENT_BRANCH:-unknown}"
    fi
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
    if [[ "$NO_ROLLBACK" != "true" ]] && [[ "$PATCH_APPLIED" == "true" ]]; then
      log "rolling back patch..."
      if git -C "$REPO_DIR" apply -R --whitespace=nowarn "$PATCH_PATH"; then
        err "patch rolled back"
      else
        err "auto rollback failed, rollback manually"
      fi
    fi
    exit 1
  fi
else
  if [[ "$SKIP_VERIFY" == "true" ]]; then
    log "skip verify enabled"
  else
    log "skip verify (no patch changes in this run)"
  fi
fi

if [[ "$PATCH_PROMPTS" == "true" ]]; then
  patch_prompts_files
  log "prompts patched (best-effort append mode)"
else
  log "skip prompts patch enabled"
fi

if [[ "$INSTALL_SKILL" == "true" ]]; then
  if install_skill_dir; then
    log "skill installed: $SKILL_DEST"
  else
    err "skill install failed"
    exit 1
  fi
else
  log "skip skill install enabled"
fi

log "all checks passed"
log "install success (mode: ${INSTALL_MODE:-full}, skill: ${INSTALL_SKILL}, prompts: ${PATCH_PROMPTS})"
