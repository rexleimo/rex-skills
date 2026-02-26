# /ccg:explore <topic-or-question>

Think through ideas, investigate problems, compare options. No structure required — just multi-model thinking partners.

## What It Does

1. **Parse Intent** — Understand what the user wants to explore
2. **Parallel Research** — Dispatch to Codex + Gemini for independent perspectives
3. **Synthesize** — Coordinator combines insights, highlights agreements and disagreements
4. **Present** — Show findings in conversational format, no artifacts created

## Orchestration

```
User: /ccg:explore Should we use GraphQL or REST for the new API?

  ┌─────────────────────────────────────────────────────────┐
  │  Parallel Research                                      │
  │                                                         │
  │  ┌─────────────┐  ┌─────────────┐                      │
  │  │ Codex CLI   │  │ Gemini CLI  │  ← run_in_background │
  │  │ Backend     │  │ Frontend    │                       │
  │  │ perspective │  │ perspective │                       │
  │  └──────┬──────┘  └──────┬──────┘                      │
  │         │                │                              │
  │         └───────┬────────┘                              │
  │                 │                                       │
  │  Coordinator synthesizes both views                     │
  └─────────────────────────────────────────────────────────┘
```

## Key Behaviors

- **No artifacts created** — This is pure exploration, no files written
- **No approval gates** — Conversational, low-friction
- **Multi-perspective** — Backend expert + Frontend expert give different angles
- **Transition ready** — When insights crystallize, suggest `/ccg:propose` or `/ccg:new`

## Invocation Templates

```bash
# Codex — Backend perspective
codeagent-wrapper --backend codex - "$WORKDIR" <<'EOF'
ROLE_FILE: references/roles/backend-expert.md
<TASK>
Explore: <user's question>
Project context: <current project info>
Provide: pros/cons, trade-offs, recommendations from backend perspective
</TASK>
OUTPUT: Markdown analysis
EOF

# Gemini — Frontend/UX perspective
codeagent-wrapper --backend gemini - "$WORKDIR" <<'EOF'
ROLE_FILE: references/roles/frontend-expert.md
<TASK>
Explore: <user's question>
Project context: <current project info>
Provide: pros/cons, trade-offs, recommendations from frontend/UX perspective
</TASK>
OUTPUT: Markdown analysis
EOF
```

## Transition

When the user is ready to act on insights:

> 💡 Ready to build? Use `/ccg:propose <what-to-build>` to create a plan.
> 
> Want more control? Use `/ccg:new <change-name>` to start a change scaffold.
