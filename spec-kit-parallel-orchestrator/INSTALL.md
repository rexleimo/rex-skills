# Install Guide (One-Click + Patch Mode)

This guide provides a beginner-friendly one-click installer, with a manual `git apply` fallback.

## Fastest Path (recommended)

Run from your **target repo** (root or any subdirectory):

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s --
```

What it does automatically:
- checks target is a git + spec-kit repo (`.specify/` exists)
- downloads patch
- runs `git apply --check` in `full` mode first
- if `full` mode is incompatible, auto-falls back to `core` mode (installs harness scripts only)
- applies patch
- appends harness guidance to speckit prompts (`.codex`/`.claude`) in best-effort mode
- installs/updates skill directory at `.codex/skills/spec-kit-parallel-orchestrator`
- runs post-apply verification
  - on non-feature branches (e.g. `main`), branch-sensitive `check-prerequisites` is auto-skipped
- auto-rolls back on verification failure
- auto-detects your git root (so subdirectory execution works)
- if patch is already installed, still syncs skill/prompts (idempotent)

From any arbitrary directory, install to a specific repo:

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s -- --repo /path/to/target-repo
```

## Local Script Mode (if you cloned rex-skills)

```bash
bash /path/to/rex-skills/spec-kit-parallel-orchestrator/scripts/install.sh --repo /path/to/target-repo
```

## Optional Flags

```bash
bash scripts/install.sh --repo /path/to/target --dry-run
bash scripts/install.sh --repo /path/to/target --allow-dirty
bash scripts/install.sh --repo /path/to/target --skip-verify
bash scripts/install.sh --repo /path/to/target --skip-skill
bash scripts/install.sh --repo /path/to/target --skip-prompts
bash scripts/install.sh --repo /path/to/target --skill-ref main
bash scripts/install.sh --repo /path/to/target --no-rollback
bash scripts/install.sh --repo /path/to/target --patch-file ./patches/long-running-harness.full.patch
```

## Manual Mode (`git apply`)

```bash
git apply --check long-running-harness.full.patch
git apply long-running-harness.full.patch
```

## Verify After Install

```bash
bash -n .specify/scripts/bash/harness-*.sh .specify/scripts/bash/harness-lib.sh
.specify/scripts/bash/check-prerequisites.sh --json --include-tasks
```

If your repo has `frontend/`:

```bash
npm --prefix frontend run typecheck
npm --prefix frontend run test:e2e:smoke -- --list
```

## Uninstall

One-click uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/uninstall.sh | bash -s --
```

Or local script:

```bash
bash /path/to/rex-skills/spec-kit-parallel-orchestrator/scripts/uninstall.sh --repo /path/to/target-repo
```

## Troubleshooting

1. `working tree is dirty`
- Commit/stash first, or use `--allow-dirty`.

2. `target does not look like a spec-kit repo`
- Ensure target repo has `.specify/`.
- If you are not inside target repo, pass `--repo /path/to/target-repo`.

3. frontend e2e check fails
- Install project deps first, or use `--skip-verify` and verify manually later.

4. installer logs `mode: core`
- This is expected for repos with customized spec-kit templates/prompts or frontend lockfiles.
- In `core` mode, harness scripts are installed, while template/prompt/frontend package edits are skipped.
- Configure your own gate command via `HARNESS_E2E_CMD`, for example:
  - `HARNESS_E2E_CMD="npm --prefix frontend run test:unit" .specify/scripts/bash/harness-end-session.sh --feature 001-my-feature`

5. I only want patch, without skill/prompts
- Add `--skip-skill --skip-prompts`.
