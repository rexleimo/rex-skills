# Spec Kit Parallel Orchestrator Best Practices

## Overview

This document summarizes best practices for long-running agents, based on Anthropic's "Effective Harnesses for Long-Running Agents" article, combined with practical project experience.

## Core Principles

### 1. State Persistence

Each session starts with no memory of previous sessions. State must be persisted via the file system:

```
specs/harness/
├── feature_list.json     # Feature definitions and status
├── progress.log.md       # Session history and decision records
├── session_state.json    # Current session context
└── init.sh               # Environment verification script
```

**Best Practices:**
- Write state changes to files immediately
- Use structured formats (JSON) for programmatic parsing
- Use human-readable formats (Markdown) for review

### 2. Incremental Progress

Each session handles one feature, with clear progress tracking:

**Session Start:**
1. Confirm directory and branch
2. Read progress.log.md to understand history
3. Select next task from feature_list.json
4. Run init.sh to verify environment

**During Session:**
- Split into 3-6 parallel subtasks
- Each subtask completes independently
- Avoid write conflicts

**Session End:**
- Gate enforcement verification
- Update state files
- Write session summary

### 3. Gate Enforcement

Each session must pass three gates before completion:

| Gate | Verification Command | Failure Handling |
|------|----------------------|------------------|
| Working Tree Clean | `git status` | Commit or discard changes |
| New Commit Exists | `git log` | Create commit |
| E2E Passed | Custom command | Fix issues and retry |

**Why Important:**
- Ensures work is not lost
- Ensures code can run
- Ensures feature is truly complete

## Parallel Execution Strategy

### Parallelizable Scenarios

```
Task A: Implement login form → src/components/Login.vue
Task B: Create auth API → src/api/auth.js
Task C: Write tests → tests/auth.test.js
```

These tasks modify different files and can execute simultaneously.

### Serial-required Scenarios

```
Task A: Design database schema → docs/schema.sql
Task B: Implement migration → migrations/001.sql
Task C: Create model → src/models/User.js
```

B depends on A's output, C depends on B's completion - must be serial.

### Conflict Avoidance

When multiple tasks need to modify the same file:

1. **File Boundary Redistribution** - Split files by module/function
2. **Degraded Serial** - Execute serially when conflicts are unavoidable
3. **Atomic Regions** - Define independent regions within files

## Feature Definition Specification

### Required Fields

```json
{
  "id": "F001",
  "category": "functional",
  "priority": "P1",
  "description": "Feature description",
  "steps": ["Step 1", "Step 2", "Step 3"],
  "status": "pending"
}
```

### Optional Fields

```json
{
  "depends_on": ["F000"],
  "blocked_reason": null,
  "started_at": "2024-01-15T10:00:00Z",
  "completed_at": "2024-01-15T12:00:00Z",
  "commits": ["abc1234", "def5678"]
}
```

### Category Types

| Category | Description |
|----------|-------------|
| `functional` | Core business functionality |
| `api` | API endpoints or interfaces |
| `ui` | User interface components |
| `security` | Security-related features |
| `performance` | Performance optimization |
| `refactor` | Code refactoring |

### Priority Levels

| Priority | Description | Examples |
|----------|-------------|----------|
| `P1` | High priority, blocks other work | Core features, critical bugs |
| `P2` | Medium priority, important but not blocking | Important features, improvements |
| `P3` | Low priority, enhancement features | Optimizations, non-essential features |

## Error Handling

### E2E Verification Failed

1. Mark feature as `failed`
2. Record failure reason in progress.log.md
3. Keep workspace state (don't auto-rollback)
4. Prioritize in next session

### Environment Check Failed

1. Record issue in progress.log.md
2. Mark feature as `blocked`
3. Record `blocked_reason`
4. Wait for manual user fix

### Dependency Blocked

```json
{
  "id": "F002",
  "depends_on": ["F001"],
  "status": "pending"
}
```

If F001 is not complete, F002 is automatically skipped.

## Progress Log Specification

### Format

```markdown
## Session 001 - 2024-01-15

### Started
- **Task**: F001 - User authentication
- **Priority**: P1
- **Steps**: 3

### Progress
- Commit: abc1234 - Implement login form
- Commit: def5678 - Add API endpoint
- Commit: ghi9012 - Write tests

### Verified
- [x] Working tree clean
- [x] New commit created: ghi9012
- [x] E2E passed

### Ended
- Status: passing
- Duration: 2h
- Next: F002
```

### Why Markdown

- Human readable, easy to review
- Supports Git diff for tracking changes
- Can include code blocks and formatting

## Environment Check Script

### Best Practices

```bash
#!/bin/bash
set -euo pipefail

# 1. Check required tools
command -v node >/dev/null || { echo "Node.js required"; exit 1; }

# 2. Check dependencies installed
[ -d "node_modules" ] || { echo "Run npm install"; exit 1; }

# 3. Check environment variables
[ -n "$DATABASE_URL" ] || { echo "Set DATABASE_URL"; exit 1; }

# 4. Check service connections
curl -s http://localhost:3000/health >/dev/null || { echo "Start service"; exit 1; }
```

### Avoid These Issues

- Don't execute time-consuming operations
- Don't modify the file system
- Don't depend on network state (unless necessary)

## Spec Kit Integration

| Stage | Harness Behavior |
|-------|------------------|
| `constitution` | Define project constraints |
| `specify` | Create feature_list.json |
| `clarify` | Refine feature descriptions |
| `plan` | Add steps to features |
| `tasks` | Split into parallel subtasks |
| `implement` | Execute with gate enforcement |

## Debugging Tips

### View Status

```bash
./scripts/harness-status.sh
```

### Check Session

```bash
cat specs/harness/session_state.json | jq .
```

### View Progress

```bash
tail -50 specs/harness/progress.log.md
```

### Reset Feature

```bash
# Manually edit feature_list.json
# Change status to "pending"
# Clear commits array
```

## State Machine

```
pending → in_progress → verifying → passing
               ↓              ↓
           blocked  ←  failed
```

| Status | Trigger Condition |
|--------|-------------------|
| `pending` | Initial state (replaces original `failing`) |
| `in_progress` | `harness-start.sh` selects task |
| `verifying` | `harness-end.sh` begins verification |
| `passing` | All gates passed |
| `failed` | E2E test failed |
| `blocked` | Dependency incomplete or environment check failed |

## References

- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [OpenSpec Long-Running Harness](../openspec-long-running-harness/SKILL.md)
