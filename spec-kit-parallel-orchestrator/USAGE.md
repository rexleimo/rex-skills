# Usage Guide (Long-Running Harness)

## 0. Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash
```

## 1. What the Harness Adds

Per feature directory (`specs/<feature-id>/harness/`):

- `feature_list.json`: feature-level status tracking (`failing|in_progress|passing|blocked`)
- `progress.log.md`: session timeline and notes
- `session_state.json`: current session state and last commit/e2e result
- `init.sh`: baseline bootstrapping check script

## 2. Session Lifecycle

### Step A: Initialize (once per feature)

```bash
.specify/scripts/bash/harness-init.sh --feature <feature-id> --tool codex
# or
.specify/scripts/bash/harness-init.sh --feature <feature-id> --tool claude
```

### Step B: Start session

```bash
.specify/scripts/bash/harness-start-session.sh --feature <feature-id> --tool codex
# or tool claude
```

This command:
- runs `harness/init.sh`
- picks next feature (`harness-pick-next.sh`)
- marks selected item `in_progress`

### Step C: Implement + Commit

- implement incremental change
- keep working tree clean
- create commit

### Step D: End session (enforced gate)

```bash
.specify/scripts/bash/harness-end-session.sh --feature <feature-id> --tool codex
```

Gate checks:
- no dirty working tree
- has new commit since session start
- e2e verification passes

If all pass, item is promoted to `passing`.

## 3. E2E Gate Strategy

### Frontend projects

`harness-verify-e2e.sh` will run:

```bash
npm --prefix frontend run test:e2e:smoke
```

### Non-frontend projects

Set custom command:

```bash
HARNESS_E2E_CMD='go test ./... -run Smoke' \
.specify/scripts/bash/harness-end-session.sh --feature <feature-id> --tool codex
```

## 4. Spec Kit Command Integration

### Codex CLI

- `/prompts:speckit.plan`
- `/prompts:speckit.tasks`
- `/prompts:speckit.implement`

### Claude Code

- `/speckit.plan`
- `/speckit.tasks`
- `/speckit.implement`

Patch-enhanced prompts will automatically include harness lifecycle instructions.

## 5. Common Failures

1. `No new commit detected`
- Create commit, then retry `harness-end-session.sh`.

2. `Working tree is dirty`
- Commit or clean files before ending session.

3. `No e2e command configured`
- Add frontend smoke script or set `HARNESS_E2E_CMD`.
