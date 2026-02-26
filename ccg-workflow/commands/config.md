# /ccg:config [action]

View or modify CCG Workflow configuration. Manage schemas and profiles.

## Actions

### /ccg:config show

Display current configuration with resolution sources:

```
/ccg:config show

CCG Workflow Configuration
──────────────────────────
Source: ccg-workflow.yaml (project)

Schema:    default
Backend:   codex (default model)
Frontend:  gemini (gemini-2.5-pro)

Trust Rules:
  Backend domain:    codex authoritative
  Frontend domain:   gemini authoritative
  Conflict strategy: domain_expert

Workflow:
  Enhance:    enabled
  Ideation:   parallel
  Plan:       approval required
  Review:     min score 80

Safety:
  Max files:  20
  Timeout:    600s
  Confirm:    before write

Output:
  Language:   zh-CN
  Verbosity:  normal
```

### /ccg:config init

Generate a config file in the project root:

```
/ccg:config init

Created ccg-workflow.yaml with default settings.
Edit to customize model backends, trust rules, and workflow behavior.
```

### /ccg:config profile

Switch between workflow profiles:

```
/ccg:config profile

Available profiles:
  1. core     — propose, explore, apply, archive (4 commands)
  2. expanded — + new, continue, ff, verify, status (9 commands)
  3. full     — + team, debug, review, analyze (13 commands)

Current: expanded
Switch to: [1/2/3]
```

### /ccg:config schema

Manage workflow schemas:

```
/ccg:config schema list

Name          Source    Description
──────────────────────────────────────────────────────────
default       builtin  Full 6-phase workflow
fast          builtin  Streamlined 4-phase workflow
review-only   builtin  Review-only 3-phase workflow

/ccg:config schema fork default my-workflow
→ Created ccg-schemas/my-workflow/schema.yaml

/ccg:config schema use fast
→ Schema set to 'fast' in ccg-workflow.yaml
```

## Environment Variable Overrides

Quick per-run changes without editing config:

```bash
CCG_SCHEMA=fast CCG_BACKEND_PROVIDER=gemini claude
```

| Variable | Overrides |
|----------|-----------|
| `CCG_SCHEMA` | `schema` |
| `CCG_BACKEND_PROVIDER` | `backends.backend.provider` |
| `CCG_BACKEND_MODEL` | `backends.backend.model` |
| `CCG_FRONTEND_PROVIDER` | `backends.frontend.provider` |
| `CCG_FRONTEND_MODEL` | `backends.frontend.model` |
| `CCG_LANGUAGE` | `output.language` |
| `CCG_MIN_SCORE` | `workflow.review.min_score` |
| `CCG_TIMEOUT` | `safety.timeout_seconds` |
