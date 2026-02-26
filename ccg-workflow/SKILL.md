---
name: ccg-workflow
description: Multi-agent orchestration workflow for software development. Coordinates Claude Code (Coordinator), Codex CLI (Backend Authority), and Gemini CLI (Frontend Authority) through slash commands (/ccg:*). Supports propose, explore, new, continue, ff, apply, verify, archive, status, config commands. Schema-driven artifact dependency graph with parallel invocation, session reuse, cross-validation, and trust-based conflict resolution.
---

# CCG Workflow - Multi-Agent Orchestration

Orchestrate multi-model collaboration (Claude + Codex + Gemini) through **slash commands**. Derived from [ccg-workflow](https://github.com/fengshao1227/ccg-workflow), simplified for lightweight OpenSkill use.

## Getting Started

```
/ccg:onboard
```

Or just tell your AI what you want:

```
/ccg:propose <what-you-want-to-build>
```

If you want the expanded workflow (`/ccg:new`, `/ccg:continue`, `/ccg:ff`, `/ccg:verify`, `/ccg:status`), select it with `/ccg:config profile` and apply with `/ccg:config schema`.

## Command Reference

### Core Commands (default profile)

| Command | What It Does |
|---------|-------------|
| `/ccg:propose <what>` | **Quick path**: idea → enhance → parallel analysis → plan → approval |
| `/ccg:explore <topic>` | **Think & research**: multi-model perspectives, no artifacts created |
| `/ccg:apply [change]` | **Implement**: execute tasks from plan, Coordinator writes code |
| `/ccg:archive [change]` | **Done**: generate commit, archive artifacts, clean up |

### Expanded Commands (expanded profile)

| Command | What It Does |
|---------|-------------|
| `/ccg:new <name>` | Start a change scaffold with dependency graph |
| `/ccg:continue [change]` | Create next READY artifact (one at a time) |
| `/ccg:ff [change]` | Fast-forward: create all planning artifacts at once |
| `/ccg:verify [change]` | Multi-model parallel review with structured scoring |
| `/ccg:status [change]` | Show current state of change(s) |

### Config Commands

| Command | What It Does |
|---------|-------------|
| `/ccg:config show` | Display current configuration |
| `/ccg:config init` | Generate config file in project root |
| `/ccg:config profile` | Switch command profile (core / expanded / full) |
| `/ccg:config schema` | List, fork, or switch workflow schemas |
| `/ccg:onboard` | Guided end-to-end walkthrough for new users |

### Command Details

Each command has a detailed reference in [commands/](commands/):

| Command | Reference |
|---------|-----------|
| `/ccg:propose` | [commands/propose.md](commands/propose.md) |
| `/ccg:explore` | [commands/explore.md](commands/explore.md) |
| `/ccg:new` | [commands/new.md](commands/new.md) |
| `/ccg:continue` | [commands/continue.md](commands/continue.md) |
| `/ccg:ff` | [commands/ff.md](commands/ff.md) |
| `/ccg:apply` | [commands/apply.md](commands/apply.md) |
| `/ccg:verify` | [commands/verify.md](commands/verify.md) |
| `/ccg:archive` | [commands/archive.md](commands/archive.md) |
| `/ccg:status` | [commands/status.md](commands/status.md) |
| `/ccg:config` | [commands/config.md](commands/config.md) |
| `/ccg:onboard` | [commands/onboard.md](commands/onboard.md) |

## Typical Flows

### Quick Path (most users)

```
/ccg:propose Add user authentication with OAuth2
  → Review plan → Approve
/ccg:apply
  → Code gets written
/ccg:archive
  → Commit & done
```

### Expanded Path (complex features)

```
/ccg:new add-oauth2
/ccg:ff                    ← fast-forward all planning
  → Review plan → Approve
/ccg:apply                 ← implement
/ccg:verify                ← multi-model review
  → Fix issues if any
/ccg:archive               ← commit & done
```

### Exploratory Path (unclear requirements)

```
/ccg:explore Should we use GraphQL or REST?
  → Multi-model perspectives
/ccg:new api-redesign
/ccg:continue              ← one artifact at a time
/ccg:continue
/ccg:continue
  → Review plan → Approve
/ccg:apply
/ccg:verify
/ccg:archive
```

## Architecture

CCG Workflow is a **three-model orchestration system**:

| Layer | Component | Role |
|-------|-----------|------|
| Coordinator | Claude (self) | Orchestrates phases, synthesizes results, writes code |
| Backend Authority | Codex CLI | API, database, algorithms, security, performance |
| Frontend Authority | Gemini CLI | UI/UX, components, accessibility, responsive design |
| Orchestration Engine | codeagent-wrapper | Unified CLI for invoking backends |

**Key principle**: External models (Codex/Gemini) have **ZERO file-system write access**. Only the Coordinator writes code.

### Multi-Model Orchestration

See [references/orchestration.md](references/orchestration.md) for the full architecture:
- Backend registry and routing
- Parallel invocation protocol (`run_in_background` + `TaskOutput`)
- Session reuse across phases (`SESSION_ID` + `resume`)
- Batch parallel execution with dependency topological sort
- Invocation templates (new session / resume / parallel dispatch)
- Phase-specific role file routing matrix
- Error handling and timeout management

## Schema System

Schemas define the artifact dependency graph — what gets created and in what order.

### Built-in Schema

The `default` schema provides the full 6-phase workflow: Enhance → Research → Ideation → Plan → Execute → Review. Fork it to create custom variants (e.g., fast mode skipping Enhance + Ideation, or review-only mode).

### Artifact Dependency Graph (DAG)

```
              enhance
             (root node)
                  │
                  ▼
              research
           (requires: enhance)
                  │
                  ▼
              ideation        ← Parallel Codex + Gemini
           (requires: research)
                  │
                  ▼
               plan           🔒 Approval gate
           (requires: ideation)
                  │
                  ▼
              execute         ← Coordinator writes code
           (requires: plan)
                  │
                  ▼
              review          ← Parallel Codex + Gemini
           (requires: execute)
```

State transitions: `BLOCKED → READY → DONE` (filesystem-based detection).

### Schema Management

```
/ccg:config schema list              # List all schemas
/ccg:config schema fork default mine  # Fork for customization
/ccg:config schema use mine           # Switch active schema
```

## Configuration

Three levels of customization, inspired by [OpenSpec](https://github.com/Fission-AI/OpenSpec):

| Level | What It Controls | How to Use |
|-------|-----------------|------------|
| **Project Config** (`ccg-workflow.yaml`) | Models, trust rules, workflow behavior, safety | `/ccg:config init` then edit |
| **Custom Schemas** (`ccg-schemas/`) | Phases, dependencies, role assignments | `/ccg:config schema fork` |
| **Runtime Overrides** (env vars) | Quick per-run changes | `CCG_SCHEMA=fast` |

### Key Config Sections

```yaml
# ccg-workflow.yaml
schema: default                    # Which workflow schema
backends:                          # Model selection per role
  backend: { provider: codex }
  frontend: { provider: gemini, model: gemini-2.5-pro }
trust:                             # Conflict resolution
  backend_domain: codex
  frontend_domain: gemini
  conflict_strategy: domain_expert # domain_expert | always_ask | majority_vote
workflow:                          # Per-phase behavior
  enhance: { enabled: true }
  ideation: { parallel: true }
  plan: { require_approval: true }
  review: { min_score: 80 }
safety:
  max_files_per_execute: 20
  require_user_confirm_before_write: true
  timeout_seconds: 600
```

See [config.yaml](config.yaml) for the full annotated reference.

## Task Type Routing

| Task Type | Keywords | Primary Backend | Secondary |
|-----------|----------|-----------------|-----------|
| Frontend | page, component, UI, style | Gemini | Codex (API contracts) |
| Backend | API, endpoint, database, auth | Codex | Gemini (consumer view) |
| Fullstack | Both frontend + backend | Both parallel | Cross-validate |
| Debug | error, bug, fix, crash | Both parallel | Domain expert decides |
| Review | review, audit, check | Both parallel | Cross-validate |

## Trust Rules

Configurable via `trust` section in config:

1. **Backend domain** (API, DB, security) → `trust.backend_domain` authoritative (default: Codex)
2. **Frontend domain** (UI, UX, accessibility) → `trust.frontend_domain` authoritative (default: Gemini)
3. **Cross-cutting** (architecture, testing) → Coordinator synthesizes
4. **Conflicts** → `trust.conflict_strategy` (default: domain_expert wins)

## Expert Role Prompts

Load from `references/roles/` when performing specialized analysis:

| Role | File | Domain |
|------|------|--------|
| Backend Expert | [roles/backend-expert.md](references/roles/backend-expert.md) | API, DB, algorithms |
| Frontend Expert | [roles/frontend-expert.md](references/roles/frontend-expert.md) | UI/UX, components |
| Backend Reviewer | [roles/reviewer-backend.md](references/roles/reviewer-backend.md) | Backend code review |
| Frontend Reviewer | [roles/reviewer-frontend.md](references/roles/reviewer-frontend.md) | Frontend code review |
| Backend Debugger | [roles/debugger-backend.md](references/roles/debugger-backend.md) | Backend diagnostics |
| Frontend Debugger | [roles/debugger-frontend.md](references/roles/debugger-frontend.md) | UI diagnostics |
| Optimizer | [roles/optimizer.md](references/roles/optimizer.md) | Performance tuning |
| Tester | [roles/tester.md](references/roles/tester.md) | Test strategy |

## Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/load_config.py` | Load, validate, query config | `--init`, `--validate`, `--get`, `--summary` |
| `scripts/manage_schema.py` | Manage workflow schemas | `list`, `show`, `fork`, `validate`, `which` |
| `scripts/enhance_prompt.py` | Enhance vague prompts | `--prompt "..." [--format json]` |
| `scripts/score_review.py` | Score review findings | `--findings '[...]' [--threshold 80]` |
| `scripts/generate_plan.py` | Generate implementation plan | `--requirement "..." --type feature` |

## Safety Guardrails

1. **External models have ZERO write access** — Only Coordinator modifies files
2. **Approval gates** — User must approve plans before code changes
3. **Score gates** — Review score < threshold triggers iteration
4. **File change limits** — Max files per execution phase
5. **Timeout protection** — Model responses timeout after configured seconds
6. **Never kill background tasks** — Poll or ask user before terminating
