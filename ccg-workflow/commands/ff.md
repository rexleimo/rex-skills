# /ccg:ff [change-name]

Fast-forward: create all planning artifacts at once. Use when you have a clear picture of what you're building.

## What It Does

1. **Topological sort** — Order all planning artifacts by dependencies
2. **Sequential creation** — Create each artifact in dependency order
3. **Multi-model dispatch** — Parallel Codex+Gemini where schema specifies
4. **Stop at approval gate** — Pause at any artifact with `approval_required: true`

## Orchestration

```
User: /ccg:ff add-oauth2

  ┌─────────────────────────────────────────────────────────┐
  │  Topological order: enhance → research → ideation → plan│
  │                                                         │
  │  ┌──────────┐                                           │
  │  │ enhance  │ Coordinator enhances prompt               │
  │  └────┬─────┘ → .ccg/add-oauth2/enhance.md ✓           │
  │       │                                                 │
  │  ┌────▼─────┐                                           │
  │  │ research │ Coordinator scans project                 │
  │  └────┬─────┘ → .ccg/add-oauth2/research.md ✓          │
  │       │                                                 │
  │  ┌────▼─────┐                                           │
  │  │ ideation │ Parallel Codex + Gemini                   │
  │  └────┬─────┘ → .ccg/add-oauth2/ideation.md ✓          │
  │       │                                                 │
  │  ┌────▼─────┐                                           │
  │  │   plan   │ Coordinator generates plan                │
  │  └────┬─────┘ → .ccg/add-oauth2/plan.md ✓              │
  │       │                                                 │
  │  🔒 APPROVAL GATE — plan has approval_required: true    │
  │  Present plan to user, wait for confirmation            │
  └─────────────────────────────────────────────────────────┘
```

## Difference from /ccg:propose

| Aspect | `/ccg:propose` | `/ccg:ff` |
|--------|---------------|-----------|
| Prerequisite | None | Must have `/ccg:new` scaffold first |
| Artifacts | Ephemeral (in conversation) | Persisted to `.ccg/<name>/` |
| Resumable | No | Yes — can `/ccg:continue` from any point |
| Customizable | Uses config defaults | Uses scaffold's schema |

## Skip Already-Done Artifacts

If some artifacts already exist (e.g., from previous `/ccg:continue` calls), `/ccg:ff` skips them:

```
Skipping enhance (already DONE)
Skipping research (already DONE)
Creating ideation... ✓
Creating plan... ✓
🔒 Approval required for plan. Review and confirm.
```

## After FF

Tell your AI: `/ccg:apply` to start implementation.
