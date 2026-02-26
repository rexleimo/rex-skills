# /ccg:continue [change-name]

Create the next artifact based on dependency graph. Shows what's ready, creates one artifact, shows what's unlocked.

## What It Does

1. **Query state** — Check which artifacts are READY (all dependencies DONE)
2. **Pick next** — Select the first READY artifact (or let user choose if multiple)
3. **Load instructions** — Get schema instructions + role prompts + dependency content
4. **Execute** — Create the artifact (may involve multi-model parallel dispatch)
5. **Update state** — Mark as DONE, show what's now unlocked

## Orchestration

```
User: /ccg:continue add-oauth2

  ┌─────────────────────────────────────────────────────────┐
  │  Step 1: Query current state                            │
  │                                                         │
  │  enhance:  DONE ✓                                       │
  │  research: DONE ✓                                       │
  │  ideation: READY ← next                                 │
  │  plan:     BLOCKED (needs: ideation)                    │
  │  execute:  BLOCKED (needs: plan)                        │
  │  review:   BLOCKED (needs: execute)                     │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  Step 2: Execute "ideation" artifact                    │
  │                                                         │
  │  Schema says: backends=[backend, frontend], parallel=true│
  │                                                         │
  │  ┌─────────────┐  ┌─────────────┐                      │
  │  │ Codex CLI   │  │ Gemini CLI  │  ← run_in_background │
  │  │ Backend     │  │ Frontend    │                       │
  │  │ ideation    │  │ ideation    │                       │
  │  └──────┬──────┘  └──────┬──────┘                      │
  │         │                │                              │
  │         └───────┬────────┘                              │
  │                 │                                       │
  │  Coordinator cross-validates + synthesizes              │
  │  → writes .ccg/add-oauth2/ideation.md                   │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  Step 3: Show what's unlocked                           │
  │                                                         │
  │  ✅ ideation: DONE                                      │
  │  🔓 plan: READY (unlocked!)  🔒 requires approval       │
  │                                                         │
  │  Next: /ccg:continue to create plan                     │
  └─────────────────────────────────────────────────────────┘
```

## Multi-Model Dispatch per Artifact

The schema determines how each artifact is created:

| Artifact | Backends | Parallel | Roles |
|----------|----------|----------|-------|
| enhance | coordinator | — | — |
| research | coordinator | — | — |
| ideation | backend, frontend | ✓ | backend-expert, frontend-expert |
| plan | coordinator | — | — |
| execute | backend, frontend, coordinator | ✓ | backend-expert, frontend-expert |
| review | backend, frontend | ✓ | reviewer-backend, reviewer-frontend |

## Invocation Template (for parallel artifacts)

```bash
# Read dependency content
DEPS=$(cat .ccg/<change>/enhance.md .ccg/<change>/research.md)

# Codex (background)
codeagent-wrapper --backend codex - "$WORKDIR" <<EOF
ROLE_FILE: references/roles/backend-expert.md
<TASK>
Phase: ideation
Dependencies: $DEPS
Requirement: <from enhance.md>
Context: <from research context>
</TASK>
OUTPUT: JSON { analysis, approach, risks, effort }
EOF

# Gemini (background)
codeagent-wrapper --backend gemini - "$WORKDIR" <<EOF
ROLE_FILE: references/roles/frontend-expert.md
<TASK>
Phase: ideation
Dependencies: $DEPS
Requirement: <from enhance.md>
Context: <from research context>
</TASK>
OUTPUT: JSON { analysis, approach, risks, effort }
EOF
```

## Multiple READY Artifacts

When multiple artifacts are READY simultaneously (e.g., after proposal in spec-driven schema), present choices:

```
Multiple artifacts ready:
  1. specs (unlocks: tasks)
  2. design (unlocks: tasks)

Which to create? [1/2/all]
```

`all` creates them in parallel if schema allows.
