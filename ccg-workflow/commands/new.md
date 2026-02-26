# /ccg:new <change-name>

Start a new change scaffold. This is the **expanded workflow** entry point — creates the directory structure and waits for direction.

## What It Does

1. **Create scaffold** — `.ccg/<change-name>/` directory with metadata
2. **Detect schema** — Read config to determine which schema (default/fast/review-only/custom)
3. **Initialize state** — All artifacts start as BLOCKED or READY based on dependencies
4. **Show status** — Display the dependency graph and what's ready to create

## Orchestration

```
User: /ccg:new add-oauth2

  ┌─────────────────────────────────────────────────────────┐
  │  Create scaffold                                        │
  │                                                         │
  │  .ccg/add-oauth2/                                       │
  │  ├── .ccg-meta.yaml     ← change metadata               │
  │  └── (artifacts created by /ccg:continue or /ccg:ff)    │
  │                                                         │
  │  Schema: default                                        │
  │  ┌──────────┐                                           │
  │  │ enhance  │ READY ← start here                        │
  │  └────┬─────┘                                           │
  │       │                                                 │
  │  ┌────▼─────┐                                           │
  │  │ research │ BLOCKED (needs: enhance)                  │
  │  └────┬─────┘                                           │
  │       │                                                 │
  │  ┌────▼─────┐                                           │
  │  │ ideation │ BLOCKED (needs: research)                 │
  │  └────┬─────┘                                           │
  │       │                                                 │
  │  ┌────▼─────┐                                           │
  │  │   plan   │ BLOCKED (needs: ideation) 🔒              │
  │  └────┬─────┘                                           │
  │       │                                                 │
  │  ┌────▼─────┐                                           │
  │  │ execute  │ BLOCKED (needs: plan)                     │
  │  └────┬─────┘                                           │
  │       │                                                 │
  │  ┌────▼─────┐                                           │
  │  │  review  │ BLOCKED (needs: execute)                  │
  │  └─────────┘                                            │
  └─────────────────────────────────────────────────────────┘
```

## Metadata File (.ccg-meta.yaml)

```yaml
name: add-oauth2
schema: default
created: 2026-02-26T10:00:00+08:00
status: active
backends:
  backend: codex
  frontend: gemini
artifacts:
  enhance: { status: ready }
  research: { status: blocked, requires: [enhance] }
  ideation: { status: blocked, requires: [research] }
  plan: { status: blocked, requires: [ideation], approval_required: true }
  execute: { status: blocked, requires: [plan] }
  review: { status: blocked, requires: [execute] }
```

## After New

| Next Command | When to Use |
|-------------|-------------|
| `/ccg:continue` | Create artifacts one at a time (exploratory) |
| `/ccg:ff` | Fast-forward all planning artifacts (clear requirements) |
| `/ccg:propose` | Abandon scaffold, use quick path instead |

## State Detection

Artifact states are determined by filesystem existence:

```
BLOCKED ────────────► READY ────────────► DONE
   │                    │                    │
Missing              All deps            File exists
dependencies         are DONE            on filesystem
```
