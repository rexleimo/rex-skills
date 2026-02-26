# /ccg:verify [change-name]

Validate implementation against planning artifacts. Multi-model parallel review with structured scoring.

## What It Does

1. **Gather context** — Read plan.md, collect all modified files
2. **Parallel review** — Dispatch to Codex (backend review) + Gemini (frontend review) simultaneously
3. **Score** — Calculate confidence scores per finding (scripts/score_review.py)
4. **Filter** — Only surface high-signal findings (score ≥ config threshold)
5. **Report** — Structured report with pass/fail per acceptance criterion

## Orchestration

```
User: /ccg:verify add-oauth2

  ┌─────────────────────────────────────────────────────────┐
  │  Gather: plan.md + git diff + modified files            │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  Parallel Review                                        │
  │                                                         │
  │  ┌─────────────┐  ┌─────────────┐                      │
  │  │ Codex CLI   │  │ Gemini CLI  │  ← run_in_background │
  │  │ reviewer-   │  │ reviewer-   │                       │
  │  │ backend.md  │  │ frontend.md │                       │
  │  └──────┬──────┘  └──────┬──────┘                      │
  │         │                │                              │
  │         └───────┬────────┘                              │
  │                 │                                       │
  │  Score each finding (scripts/score_review.py)           │
  │  Filter: score ≥ min_score (default: 80)                │
  │  Trust rules: backend issues → Codex authoritative      │
  │               frontend issues → Gemini authoritative    │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  Verification Report                                    │
  │                                                         │
  │  Acceptance Criteria:                                   │
  │  ✅ OAuth2 login flow works                             │
  │  ✅ Tokens stored securely                              │
  │  ⚠️ PKCE flow not tested (score: 85)                   │
  │  ❌ No rate limiting on callback (score: 92)            │
  │                                                         │
  │  Overall: 3/4 passed — needs fixes                      │
  │  → .ccg/add-oauth2/verify.md                            │
  └─────────────────────────────────────────────────────────┘
```

## Invocation Templates

```bash
# Codex — Backend review
codeagent-wrapper --backend codex - "$WORKDIR" <<'EOF'
ROLE_FILE: references/roles/reviewer-backend.md
<TASK>
Review implementation against plan:
Plan: <plan.md content>
Modified files: <file list with diffs>
Check: security, API correctness, error handling, performance
</TASK>
OUTPUT: JSON [{ finding, severity, file, line, evidence, category }]
EOF

# Gemini — Frontend review
codeagent-wrapper --backend gemini - "$WORKDIR" <<'EOF'
ROLE_FILE: references/roles/reviewer-frontend.md
<TASK>
Review implementation against plan:
Plan: <plan.md content>
Modified files: <file list with diffs>
Check: UI correctness, accessibility, responsive design, UX
</TASK>
OUTPUT: JSON [{ finding, severity, file, line, evidence, category }]
EOF
```

## After Verify

| Result | Next Action |
|--------|-------------|
| All passed | `/ccg:archive` |
| Minor issues | Fix and `/ccg:verify` again |
| Major issues | `/ccg:apply` to fix, then `/ccg:verify` |
| Plan was wrong | Edit plan.md, then `/ccg:apply` |
