---
name: code-review
description: Automated code review for pull requests and code changes using multi-agent architecture with confidence-based scoring. Use when reviewing PRs, auditing code changes, checking guideline compliance, or detecting bugs in diffs. Works with GitHub, GitLab, and local git repositories. Compatible with Claude Code, Codex, Cursor, Windsurf, and other AI coding tools.
---

# Code Review Skill

Perform automated code review using parallel review agents with confidence-based scoring to filter false positives.

## Overview

This skill launches multiple independent review agents to audit code changes from different perspectives:

| Agent | Focus | Priority |
|-------|-------|----------|
| Guideline Compliance (x2) | Check adherence to project guidelines | High |
| Bug Detector | Scan for obvious bugs in the diff | Critical |
| Context Analyzer | Analyze git history for context-based issues | Medium |

## Quick Start

### For GitHub PRs

```bash
# Get PR info
gh pr view --json number,title,body,headRefName
gh pr diff
```

### For Local Changes

```bash
# Staged changes
git diff --cached

# Branch changes vs main
git diff main...HEAD
```

## Review Workflow

1. **Pre-check**: Skip if PR is closed, draft, trivial, or already reviewed

2. **Gather context**:
   - Collect guideline files (CLAUDE.md, .cursorrules, CONTRIBUTING.md)
   - Get PR title/description for intent
   - Summarize changes

3. **Launch parallel reviews** (4 agents):
   - Agents 1-2: Guideline compliance
   - Agent 3: Bug detection (diff only)
   - Agent 4: History/context analysis

4. **Score issues** (0-100): Keep only ≥80

5. **Validate**: Re-verify each high-confidence issue

6. **Output**: Terminal or PR comment

## High-Signal Issue Criteria

**Flag:**
- Syntax/type errors, missing imports, unresolved references
- Clear logic errors (wrong results regardless of inputs)
- Explicit guideline violations (quote exact rule)

**Do NOT flag:**
- Style/quality concerns
- Input-dependent potential issues
- Subjective suggestions
- Pre-existing issues
- Linter-catchable issues

## Output Format

```markdown
## Code Review

Found N issues:

1. [Description] ([Reason])
   https://github.com/owner/repo/blob/[full-sha]/path/file#L[start]-L[end]
```

## Platform Integration

- **GitHub/GitLab**: See [references/platforms.md](references/platforms.md)
- **AI Tools (Codex/Cursor/Windsurf)**: See [references/ai-tools.md](references/ai-tools.md)

## Guideline Files (Priority Order)

1. `CLAUDE.md` - Claude-specific guidelines
2. `.cursorrules` - Cursor AI rules
3. `CONTRIBUTING.md` - Contribution guidelines
4. `.github/CODEOWNERS` - Code ownership
5. `docs/STYLE_GUIDE.md` - Style guide

## Scripts

- `scripts/analyze_diff.py` - Parse git diff, extract changed files and line ranges
- `scripts/score_issue.py` - Calculate confidence score for issues
- `scripts/format_review.py` - Format output for different platforms
