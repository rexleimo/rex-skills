---
name: review-loop
description: >-
  Automated two-phase code review loop: the coding agent implements a task,
  then an independent CLI agent (Codex, Claude, Gemini, OpenCode, Aider, or custom)
  reviews the changes, and the coding agent addresses the feedback.
  Use when the user requests a review loop, code review cycle, or says "review-loop".
license: MIT
compatibility: >-
  Works with any Agent Skills compatible tool (Claude Code, Cursor, Codex, Gemini CLI,
  OpenCode, Windsurf, Cline, Roo Code, etc.). Requires bash, jq, and git.
  The reviewer is another CLI agent (codex, claude, gemini, opencode, or aider) —
  no API keys needed, each uses its own model and authentication.
metadata:
  author: community
  version: "2.1.0"
  upstream: https://github.com/hamelsmu/claude-review-loop
allowed-tools: Bash(git:*) Bash(jq:*) Bash(codex:*) Bash(claude:*) Bash(gemini:*) Bash(opencode:*) Bash(aider:*) Bash(sed:*) Bash(date:*) Bash(mkdir:*) Bash(cat:*) Bash(rm:*) Bash(openssl:*) Bash(head:*) Bash(od:*) Bash(grep:*) Read Write Edit Glob Grep
---

# Review Loop

An automated two-phase code review loop that works across all major AI coding agents.

## Overview

This skill implements a review cycle inspired by [claude-review-loop](https://github.com/hamelsmu/claude-review-loop), generalized to work with any Agent Skills compatible tool:

1. **Phase 1 (Task)**: You (the coding agent) implement the user's task
2. **Review**: An independent CLI agent reviews the changes
3. **Phase 2 (Addressing)**: You address the review feedback

The key insight: the reviewer is another CLI agent (like Codex, Claude, Gemini) running non-interactively. These tools have their own models and authentication — no API keys or extra configuration needed.

## When to Use

Activate this skill when:
- The user says "review-loop", "start review loop", or "review my code"
- The user wants an independent code review after task completion
- The user wants a two-phase implement-then-review workflow

## How to Start a Review Loop

Run the setup script to initialize the review loop:

```bash
bash "$(dirname "$(find . -path '*/review-loop/scripts/setup.sh' -type f | head -1)")/setup.sh" "<task description>"
```

Or if the skill is installed at a known path:

```bash
bash .agents/skills/review-loop/scripts/setup.sh "<task description>"
```

This creates a state file at `.review-loop/state.md` and a `reviews/` directory. The setup script auto-detects which reviewer CLI is available (prefers codex > claude > gemini > opencode > aider).

## Two-Phase Workflow

### Phase 1: Implement the Task

After setup, implement the user's task thoroughly:
- Write clean, well-structured, well-tested code
- Complete the task to the best of your ability before stopping
- Do not stop prematurely or skip parts of the task

### Phase 2: Run Review and Address Feedback

When the task is complete, run the review engine:

```bash
bash .review-loop/scripts/run-review.sh
```

This script will:
1. Detect the project type (Next.js, browser UI, etc.)
2. Launch the reviewer CLI agent non-interactively to analyze changes
3. The reviewer writes its findings to `reviews/review-<id>.md`
4. Transition the state to "addressing" phase

Then read the review file and address the feedback:
1. Read the review carefully
2. For each item, independently decide if you agree
3. For items you AGREE with: implement the fix
4. For items you DISAGREE with: briefly note why you are skipping them
5. Focus on critical and high severity items first

### Completing the Loop

After addressing all relevant review items, run:

```bash
bash .review-loop/scripts/complete.sh
```

This cleans up the state file and marks the review loop as done.

## Cancelling a Review Loop

To cancel an active review loop at any time:

```bash
bash .review-loop/scripts/cancel.sh
```

## Configuring the Reviewer

The reviewer is another CLI agent that runs non-interactively in your project directory. It uses its own model and login — no API keys needed. Set `REVIEW_REVIEWER` to choose, or leave it as `auto` to auto-detect:

| Reviewer | Value | Install | How It Runs |
|----------|-------|---------|-------------|
| Codex (default) | `codex` | `npm i -g @openai/codex` | `codex exec` with multi-agent parallel review |
| Claude Code | `claude` | `npm i -g @anthropic-ai/claude-code` | `claude -p` non-interactive mode |
| Gemini CLI | `gemini` | `npm i -g @anthropic-ai/gemini-cli` | `echo prompt \| gemini` pipe mode |
| OpenCode | `opencode` | See opencode.ai | `opencode run` non-interactive mode |
| Aider | `aider` | `pip install aider-chat` | `aider --message --yes` mode |
| Custom | `custom` | Your tool | Set `REVIEW_CUSTOM_CMD` |
| Auto-detect | `auto` | — | Tries codex → claude → gemini → opencode → aider |

Example:
```bash
export REVIEW_REVIEWER=claude  # Use Claude Code CLI as reviewer
```

## Hook-Based Automation (Optional)

For agents that support hooks (Claude Code, Cursor), the review can run automatically when the agent stops. See `references/hooks-setup.md` for configuration details.

## Rules

- Always complete the task fully before triggering the review
- The review loop state lives in `.review-loop/state.md` — always clean up on exit
- On any error, fail-open: allow the agent to continue rather than trapping in a broken loop
- Review IDs are validated to prevent path traversal
- No secrets or credentials are stored in state files
