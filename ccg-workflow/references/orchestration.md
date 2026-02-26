# Multi-Model Orchestration Engine

This document defines the core orchestration mechanism for coordinating Claude Code, Codex CLI, and Gemini CLI in a multi-agent collaboration workflow. This is the **central nervous system** of CCG Workflow.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Coordinator (Claude)                  │
│              Orchestrates, Synthesizes, Writes Code      │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Codex CLI    │  │ Gemini CLI   │  │ Claude CLI   │  │
│  │ (Backend     │  │ (Frontend    │  │ (Sub-agent   │  │
│  │  Authority)  │  │  Authority)  │  │  Fallback)   │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │           │
│         └────────┬────────┘                 │           │
│                  │                          │           │
│         codeagent-wrapper (Go binary)       │           │
│         Unified CLI → Backend Router        │           │
└─────────────────────────────────────────────────────────┘
```

The system has three layers:

1. **Coordinator (Claude)** — The orchestrating agent. It plans phases, dispatches tasks to backend models, collects results, synthesizes insights, and is the only entity with file-system write access.

2. **codeagent-wrapper** — A Go binary that provides a unified CLI interface to invoke Codex, Gemini, or Claude as sub-agents. It handles process management, session persistence, output parsing, and parallel execution.

3. **Backend CLIs** — The actual AI model CLIs (codex, gemini, claude) that perform specialized analysis, review, or code generation.

## Backend Registry

| Backend | CLI Command | Strengths | Trust Domain |
|---------|-------------|-----------|-------------|
| `codex` | `codex` | API design, algorithms, security, DB, performance | **Backend authoritative** |
| `gemini` | `gemini` | UI/UX, components, accessibility, responsive, visual | **Frontend authoritative** |
| `claude` | `claude` | Orchestration, synthesis, general tasks | Coordinator fallback |

## Invocation Protocol

### Single Task (New Session)

```bash
codeagent-wrapper --backend <codex|gemini|claude> [--gemini-model <model>] - "<WORKDIR>" <<'EOF'
ROLE_FILE: <path/to/role-prompt.md>
<TASK>
需求：<enhanced requirement>
上下文：<project context from previous phases>
</TASK>
OUTPUT: <expected output format>
EOF
```

Key parameters:

| Parameter | Description |
|-----------|-------------|
| `--backend <name>` | Select backend: `codex`, `gemini`, or `claude` |
| `--gemini-model <model>` | Specify Gemini model (e.g., `gemini-3-pro-preview`). Only for `--backend gemini` |
| `--lite` or `-L` | Lite mode: faster response, reduced logging |
| `-` (dash) | Read task from stdin (heredoc) |
| `"<WORKDIR>"` | Working directory (absolute path) |
| `ROLE_FILE:` | Path to role prompt file (injected into task) |

### Session Resume (Context Reuse)

```bash
codeagent-wrapper --backend <codex|gemini> resume <SESSION_ID> - "<WORKDIR>" <<'EOF'
ROLE_FILE: <path/to/role-prompt.md>
<TASK>
需求：<follow-up requirement>
上下文：<accumulated context>
</TASK>
OUTPUT: <expected output format>
EOF
```

Each invocation returns a `SESSION_ID: xxx` in its output. Use `resume <SESSION_ID>` to continue the conversation with the same backend, preserving context across phases (e.g., analysis → planning → review).

### Parallel Execution

For parallel multi-model invocation within Claude Code, use `Bash` tool with `run_in_background: true`:

```javascript
// FIRST call (Codex) — background
Bash({
  command: "codeagent-wrapper --backend codex - \"<WORKDIR>\" <<'EOF'\n...\nEOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Codex backend analysis"
})

// SECOND call (Gemini) — background, IN THE SAME MESSAGE
Bash({
  command: "codeagent-wrapper --backend gemini --gemini-model gemini-3-pro-preview - \"<WORKDIR>\" <<'EOF'\n...\nEOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Gemini frontend analysis"
})

// Wait for both results
TaskOutput({ task_id: "<codex_task_id>", block: true, timeout: 600000 })
TaskOutput({ task_id: "<gemini_task_id>", block: true, timeout: 600000 })
```

### Batch Parallel Execution (Advanced)

For complex scenarios with dependencies, use the `--parallel` mode with structured stdin:

```bash
codeagent-wrapper --parallel [--backend <default-backend>] [--full-output] <<'EOF'
---TASK---
id: backend-analysis
workdir: /path/to/project
backend: codex
---CONTENT---
ROLE_FILE: roles/backend-expert.md
<TASK>Analyze the authentication module</TASK>
OUTPUT: Technical feasibility report

---TASK---
id: frontend-analysis
workdir: /path/to/project
backend: gemini
---CONTENT---
ROLE_FILE: roles/frontend-expert.md
<TASK>Analyze the login UI components</TASK>
OUTPUT: UI/UX assessment report

---TASK---
id: integration-review
workdir: /path/to/project
backend: codex
dependencies: backend-analysis, frontend-analysis
---CONTENT---
ROLE_FILE: roles/reviewer-backend.md
<TASK>Review integration points between backend and frontend</TASK>
OUTPUT: Integration review report
EOF
```

Task metadata fields:

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique task identifier |
| `workdir` | No | Working directory (default: `.`) |
| `backend` | No | Backend override (default: global `--backend`) |
| `session_id` | No | Resume existing session |
| `dependencies` | No | Comma-separated task IDs that must complete first |

The wrapper performs **topological sort** on dependencies, groups tasks into layers, and executes each layer in parallel with configurable concurrency (`CODEAGENT_MAX_PARALLEL_WORKERS` env var).

## Orchestration Patterns

### Pattern 1: Parallel Analysis → Cross-Validation

Used in: `/analyze`, `/review`, `/debug`, Phase 2 of `/workflow`

```
Phase N: Parallel Dispatch
├── Codex (backend perspective) ──┐
│                                 ├── Wait for both
└── Gemini (frontend perspective) ┘
                │
Phase N+1: Cross-Validation (Claude)
├── Identify agreements (strong signal)
├── Identify disagreements (apply trust rules)
├── Identify complementary insights
└── Synthesize unified output
```

### Pattern 2: Sequential Pipeline with Session Reuse

Used in: `/workflow` (Research → Ideation → Plan → Execute → Review)

```
Phase 1: Research
├── Codex analysis (new session) → save CODEX_SESSION
└── Gemini analysis (new session) → save GEMINI_SESSION

Phase 2: Planning
├── Codex planning (resume CODEX_SESSION) → accumulated context
└── Gemini planning (resume GEMINI_SESSION) → accumulated context

Phase 3: Execute (Claude writes code based on plans)

Phase 4: Review
├── Codex review (new or resume) → backend quality check
└── Gemini review (new or resume) → frontend quality check
```

### Pattern 3: Team Parallel Execution (Agent Teams)

Used in: `/team-research`, `/team-plan`, `/team-exec`, `/team-review`

```
Lead (Claude) ──┬── spawn Builder 1 (Sonnet) ── Task 1 files
                ├── spawn Builder 2 (Sonnet) ── Task 2 files
                ├── spawn Builder 3 (Sonnet) ── Task 3 files
                └── Monitor + Aggregate results

Rules:
- Lead never writes product code
- Each Builder has strict file scope isolation
- Dependencies create execution layers (Layer 1 parallel → Layer 2 waits)
```

## Role Prompt Routing

Each phase maps to specific role prompts per backend:

| Phase | Codex Role | Gemini Role |
|-------|-----------|-------------|
| Analysis | `roles/backend-expert.md` | `roles/frontend-expert.md` |
| Architecture | `roles/backend-expert.md` | `roles/frontend-expert.md` |
| Implementation | `roles/backend-expert.md` | `roles/frontend-expert.md` |
| Review | `roles/reviewer-backend.md` | `roles/reviewer-frontend.md` |
| Debug | `roles/debugger-backend.md` | `roles/debugger-frontend.md` |
| Optimization | `roles/optimizer.md` | `roles/optimizer.md` |
| Testing | `roles/tester.md` | `roles/tester.md` |

## Task Type Routing

Automatically route tasks to the appropriate backend based on content:

| Task Type | Detection Keywords | Primary Backend | Secondary Backend |
|-----------|-------------------|-----------------|-------------------|
| Frontend | page, component, UI, style, layout, responsive | Gemini | Codex (for API contracts) |
| Backend | API, endpoint, database, logic, algorithm, auth | Codex | Gemini (for API consumer view) |
| Fullstack | Both frontend + backend keywords | Both (parallel) | Cross-validate |
| Debug | error, bug, fix, crash, exception | Both (parallel) | Domain expert decides |
| Review | review, audit, check | Both (parallel) | Cross-validate |

## Trust Rules and Conflict Resolution

When Codex and Gemini disagree:

1. **Backend domain** (API, DB, security, performance) → **Codex wins**
2. **Frontend domain** (UI, UX, accessibility, responsive) → **Gemini wins**
3. **Cross-cutting** (architecture, testing strategy) → **Coordinator synthesizes**, present both views to user
4. **Ambiguous** → **Ask user** via `AskUserQuestion`

## Safety Guardrails

1. **External models have ZERO file-system write access** — Only the Coordinator (Claude) can modify files
2. **Never kill background tasks** — If a task times out, poll with `TaskOutput` or ask user
3. **Hard stops before execution** — User must approve plans before code changes
4. **Score gates** — Completeness score < 7/10 blocks progression; review score < 80/100 triggers iteration
5. **Context checkpoints** — Monitor context window usage; suggest `/clear` when approaching 80K tokens

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CODEAGENT_LITE_MODE` | `false` | Enable lite mode (faster, less logging) |
| `CODEAGENT_MAX_PARALLEL_WORKERS` | `0` (unlimited) | Max concurrent parallel tasks |
| `CODEAGENT_POST_MESSAGE_DELAY` | `5` | Seconds to wait after agent message before termination |
| `CODEAGENT_ASCII_MODE` | `false` | Use ASCII-only output (no emoji) |
| `GEMINI_MODEL` | (none) | Default Gemini model name |
| `CODEAGENT_SKIP_PERMISSIONS` | `false` | Skip permission checks |
