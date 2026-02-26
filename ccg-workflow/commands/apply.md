# /ccg:apply [change-name]

Implement tasks from the plan, updating artifacts as needed. This is where code gets written.

## What It Does

1. **Load plan** — Read `.ccg/<change>/plan.md` for task list
2. **Route tasks** — Dispatch each task to appropriate backend based on type
3. **Coordinator writes code** — External models advise, only Coordinator modifies files
4. **Track progress** — Check off tasks as completed
5. **Handle iterations** — If something's wrong, update the artifact and continue

## Orchestration

```
User: /ccg:apply add-oauth2

  ┌─────────────────────────────────────────────────────────┐
  │  Load plan.md → Extract task list                       │
  │                                                         │
  │  Tasks:                                                 │
  │  [ ] 1. Create OAuth2 provider config                   │
  │  [ ] 2. Implement auth middleware                       │
  │  [ ] 3. Create login/callback routes                   │
  │  [ ] 4. Add OAuth2 login button component              │
  │  [ ] 5. Write integration tests                        │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  For each task, route by type:                          │
  │                                                         │
  │  Task 1 (backend) → Codex advises → Coordinator writes  │
  │  Task 2 (backend) → Codex advises → Coordinator writes  │
  │  Task 3 (backend) → Codex advises → Coordinator writes  │
  │  Task 4 (frontend) → Gemini advises → Coordinator writes│
  │  Task 5 (testing) → Both advise → Coordinator writes    │
  │                                                         │
  │  Progress tracked in plan.md:                           │
  │  [x] 1. Create OAuth2 provider config ✓                │
  │  [x] 2. Implement auth middleware ✓                    │
  │  [ ] 3. Create login/callback routes  ← current        │
  └─────────────────────────────────────────────────────────┘
```

## Task Routing

| Task Keywords | Primary Backend | Role File |
|--------------|-----------------|-----------|
| API, endpoint, database, auth, middleware | Codex | roles/backend-expert.md |
| component, page, UI, style, layout | Gemini | roles/frontend-expert.md |
| test, spec, coverage | Both parallel | roles/tester.md |
| performance, optimize, cache | Both parallel | roles/optimizer.md |

## Invocation Template (per task)

```bash
# For a backend task — get Codex advice, then Coordinator implements
codeagent-wrapper --backend codex - "$WORKDIR" <<'EOF'
ROLE_FILE: references/roles/backend-expert.md
<TASK>
Implement: Create OAuth2 provider configuration
Plan context: <from plan.md>
Existing code: <relevant files>
Constraints: <from research.md>
</TASK>
OUTPUT: JSON {
  approach: "step-by-step implementation guide",
  code_snippets: "key code blocks to write",
  files_to_modify: ["list of files"],
  tests_needed: "what to test"
}
EOF

# Coordinator reads advice → writes actual code
```

## Session Reuse

Tasks within the same domain reuse sessions for context continuity:

```bash
# Task 1: New session
codeagent-wrapper --backend codex - "$WORKDIR" <<'EOF'
...
EOF
# Returns SESSION_ID: abc123

# Task 2: Resume session (has context from Task 1)
codeagent-wrapper --backend codex resume abc123 - "$WORKDIR" <<'EOF'
...
EOF
```

## Iteration During Apply

If implementation reveals a problem:

```
During task 3, discovered that OAuth2 callback needs PKCE flow.

Options:
  1. Update plan.md and continue (minor adjustment)
  2. Update ideation.md + plan.md (approach changed)
  3. /ccg:new (fundamentally different work)

→ User chooses 1
→ Coordinator updates plan.md, continues with adjusted task
```

## Safety

- **Coordinator-only writes** — External models never modify files directly
- **File change limits** — Respects `safety.max_files_per_execute` from config
- **User confirmation** — Respects `safety.require_user_confirm_before_write` from config
- **Progress persistence** — Task checkboxes saved to plan.md, resumable after interruption
