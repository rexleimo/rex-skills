# Spec Kit Parallel Orchestrator

Parallel orchestration skill for Spec Kit workflows with long-running harness support.

## Install

```bash
npx skills add https://github.com/rexleimo/rex-skills/tree/main/spec-kit-parallel-orchestrator
```

## Features

- **Parallel decomposition** (3-6 sub-tasks) with dependency-safe execution
- **Stage-aware semantics** aligned with Spec Kit (`constitution -> specify -> clarify -> plan -> tasks -> implement`)
- **Long-running harness** with gate enforcement
- **State persistence** across sessions

## Harness Scripts

After installation, use these scripts in your project:

| Script | Purpose |
|--------|---------|
| `harness-init.sh` | Initialize harness directory |
| `harness-start.sh` | Start a new session |
| `harness-end.sh` | End session with gate enforcement |
| `harness-pick-next.sh` | Select next feature |
| `harness-commit.sh` | Commit progress |
| `harness-verify-e2e.sh` | Run E2E verification |
| `harness-status.sh` | Display status |

## Harness Artifacts

```
specs/harness/
├── feature_list.json     # Feature definitions + status
├── progress.log.md       # Session history (human-readable)
├── session_state.json    # Current context (machine-readable)
├── init.sh               # Environment check script
└── .harness-config.json  # Configuration
```

## State Machine

```
pending → in_progress → verifying → passing
               ↓              ↓
           blocked  ←  failed
```

## Gate Enforcement

Each session must pass these gates:

1. **Working Tree Clean** - All changes committed
2. **New Commit** - At least one commit since session start
3. **E2E Passed** - End-to-end tests pass

## Quick Start

```bash
# 1. Initialize harness
./scripts/harness-init.sh "my-project"

# 2. Edit features
vim specs/harness/feature_list.json

# 3. Start session
./scripts/harness-start.sh

# 4. Implement feature...

# 5. End session (runs gates)
./scripts/harness-end.sh
```

## References

- [Best Practices](./references/best-practices.md)
- [Examples](./references/examples.md)
- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
