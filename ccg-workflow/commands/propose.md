# /ccg:propose <what-you-want-to-build>

Create a change and generate all planning artifacts in one step. This is the **default quick path** — from idea to actionable plan.

## What It Does

1. **Enhance** — Analyze the user's input, fill in missing details, produce structured requirement
2. **Research** — Scan project context (tech stack, existing code, constraints)
3. **Parallel Ideation** — Dispatch to Codex (backend) + Gemini (frontend) simultaneously for analysis
4. **Cross-Validate** — Compare both models' outputs, resolve conflicts via trust rules
5. **Generate Plan** — Produce implementation plan with tasks, acceptance criteria, and file list
6. **Present for Approval** — Show plan to user, wait for confirmation before any code changes

## Orchestration

```
User: /ccg:propose Add user authentication with OAuth2

  ┌─────────────────────────────────────────────────────────┐
  │  Phase 1: Enhance                                       │
  │  Coordinator analyzes input → structured requirement    │
  │  (scripts/enhance_prompt.py)                            │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  Phase 2: Research                                      │
  │  Coordinator scans project: package.json, tsconfig,     │
  │  existing auth code, API routes, DB schema              │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  Phase 3: Parallel Ideation                             │
  │                                                         │
  │  ┌─────────────┐  ┌─────────────┐                      │
  │  │ Codex CLI   │  │ Gemini CLI  │  ← run_in_background │
  │  │ Backend     │  │ Frontend    │                       │
  │  │ analysis    │  │ analysis    │                       │
  │  └──────┬──────┘  └──────┬──────┘                      │
  │         │                │                              │
  │         └───────┬────────┘                              │
  │                 │                                       │
  │  Cross-validate + Trust rules                           │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  Phase 4: Generate Plan                                 │
  │  Coordinator synthesizes → structured plan              │
  │  (scripts/generate_plan.py)                             │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  🔒 APPROVAL GATE                                       │
  │  Present plan to user → Wait for confirmation           │
  └─────────────────────────────────────────────────────────┘
```

## Invocation Templates

### Parallel Ideation (Codex + Gemini)

```bash
# Codex — Backend analysis (background)
codeagent-wrapper --backend codex - "$WORKDIR" <<'EOF'
ROLE_FILE: references/roles/backend-expert.md
<TASK>
Requirement: <enhanced requirement>
Project context: <research results>
Analyze: API design, data models, security, performance implications
</TASK>
OUTPUT: JSON { analysis, recommendations, risks, effort_estimate }
EOF

# Gemini — Frontend analysis (background, SAME message)
codeagent-wrapper --backend gemini - "$WORKDIR" <<'EOF'
ROLE_FILE: references/roles/frontend-expert.md
<TASK>
Requirement: <enhanced requirement>
Project context: <research results>
Analyze: UI/UX impact, component design, accessibility, responsive design
</TASK>
OUTPUT: JSON { analysis, recommendations, risks, effort_estimate }
EOF
```

## Artifacts Generated

| Artifact | Path | Description |
|----------|------|-------------|
| Enhanced Requirement | `.ccg/<change-name>/requirement.md` | Structured requirement |
| Research Context | `.ccg/<change-name>/context.md` | Project analysis |
| Ideation Results | `.ccg/<change-name>/ideation.md` | Multi-model analysis |
| Implementation Plan | `.ccg/<change-name>/plan.md` | Actionable plan with tasks |

## After Propose

Tell your AI: `/ccg:apply` to start implementation, or edit the plan first.

## Config Overrides

- `workflow.enhance.enabled: false` → Skip enhancement, use raw input
- `workflow.ideation.parallel: false` → Sequential instead of parallel
- `workflow.ideation.auto_select: true` → Auto-pick best analysis without asking
- `workflow.plan.require_approval: false` → Skip approval gate (⚠️ risky)
