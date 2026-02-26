# /ccg:status [change-name]

Show current state of a change or all active changes. The dashboard for your workflow.

## What It Does

1. **Scan** — Find all `.ccg/*/` directories (active changes)
2. **Resolve state** — Check each artifact's status (BLOCKED/READY/DONE)
3. **Display** — Show dependency graph with status indicators

## Output Format

### Single Change

```
/ccg:status add-oauth2

Change: add-oauth2
Schema: default
Created: 2026-02-26 10:00

  enhance   ✅ DONE
  research  ✅ DONE
  ideation  ✅ DONE
  plan      ✅ DONE (approved)
  execute   🔄 IN PROGRESS (3/5 tasks)
  review    ⏳ BLOCKED (needs: execute)

Next: /ccg:apply add-oauth2 to continue implementation
```

### All Changes

```
/ccg:status

Active changes:
  add-oauth2      execute (3/5 tasks)    schema: default
  fix-login-bug   plan (pending approval) schema: fast
  update-docs     review (ready)         schema: review-only

Archived: 3 changes in .ccg/archive/
```

## State Icons

| Icon | State | Meaning |
|------|-------|---------|
| ✅ | DONE | Artifact exists on filesystem |
| 🔄 | IN PROGRESS | Partially complete (tasks with checkboxes) |
| 🟢 | READY | All dependencies met, can be created |
| ⏳ | BLOCKED | Missing dependencies |
| 🔒 | APPROVAL | Requires user approval before proceeding |

## Config Check

Also shows active configuration:

```
Config: ccg-workflow.yaml (project)
Schema: default
Backend: codex | Frontend: gemini
Trust: domain_expert
```
