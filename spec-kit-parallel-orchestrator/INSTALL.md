# Install Guide (One-Click + Patch Mode)

This guide provides a beginner-friendly one-click installer, with a manual `git apply` fallback.

## Fastest Path (recommended)

From your **target project root**:

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash
```

What it does automatically:
- checks target is a git + spec-kit repo (`.specify/` exists)
- downloads patch
- runs `git apply --check`
- applies patch
- runs post-apply verification
- auto-rolls back on verification failure

## Local Script Mode (if you cloned rex-skills)

```bash
bash /path/to/rex-skills/spec-kit-parallel-orchestrator/scripts/install.sh --repo /path/to/target-repo
```

## Optional Flags

```bash
bash scripts/install.sh --repo /path/to/target --dry-run
bash scripts/install.sh --repo /path/to/target --allow-dirty
bash scripts/install.sh --repo /path/to/target --skip-verify
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
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/uninstall.sh | bash
```

Or local script:

```bash
bash /path/to/rex-skills/spec-kit-parallel-orchestrator/scripts/uninstall.sh --repo /path/to/target-repo
```

## Troubleshooting

1. `working tree is dirty`
- Commit/stash first, or use `--allow-dirty`.

2. `target does not look like a spec-kit repo`
- Ensure `.specify/` exists in target root.

3. frontend e2e check fails
- Install project deps first, or use `--skip-verify` and verify manually later.
