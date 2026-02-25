# Reviewer Configuration Guide

The review-loop skill uses another CLI agent as the reviewer. All supported reviewers are full-featured AI coding agents that run non-interactively — they have their own models and authentication, so **no API keys are needed**.

> 中文版本请参阅 [reviewer-config_zh.md](reviewer-config_zh.md)。

## How It Works

When you trigger a review, the skill:
1. Builds a review prompt (tailored to your project type)
2. Launches the reviewer CLI agent non-interactively in your project directory
3. The reviewer agent reads your code, runs git diff, analyzes changes, and writes findings
4. The review is saved to `reviews/review-<id>.md`

## Auto-Detection (Default)

By default (`REVIEW_REVIEWER=auto`), the skill auto-detects the first available reviewer in this order:

1. **codex** — preferred because it supports multi-agent parallel review
2. **claude** — Claude Code CLI
3. **gemini** — Gemini CLI
4. **opencode** — OpenCode CLI
5. **aider** — Aider CLI

If none are found, falls back to **self-review** (generates a checklist for the coding agent).

## Codex (Recommended)

Uses OpenAI's Codex CLI with multi-agent support. Codex spawns parallel review agents internally for faster, more thorough reviews.

**Install:**
```bash
npm install -g @openai/codex
```

**How it runs:**
```bash
codex exec --full-auto "<review prompt>"
```

The skill automatically enables `multi_agent = true` in `~/.codex/config.toml`.

**Override flags:**
```bash
export REVIEW_LOOP_CODEX_FLAGS="--full-auto --sandbox danger-full-access"
```

## Claude Code

Uses Anthropic's Claude Code CLI in non-interactive print mode.

**Install:**
```bash
npm install -g @anthropic-ai/claude-code
```

**How it runs:**
```bash
claude --dangerously-skip-permissions -p "<review prompt>"
```

## Gemini CLI

Uses Google's Gemini CLI in pipe mode.

**Install:**
```bash
npm install -g @anthropic-ai/gemini-cli
```

**How it runs:**
```bash
echo "<review prompt>" | gemini
```

## OpenCode

Uses OpenCode CLI in non-interactive mode.

**Install:**
See https://opencode.ai for installation.

**How it runs:**
```bash
opencode run "<review prompt>"
```

## Aider

Uses Aider in non-interactive message mode.

**Install:**
```bash
pip install aider-chat
```

**How it runs:**
```bash
aider --message "<review prompt>" --yes
```

## Custom Command

Run any custom command as the reviewer.

```bash
export REVIEW_REVIEWER=custom
export REVIEW_CUSTOM_CMD="my-review-tool --format markdown"
```

The command should write its review output to the file path provided as an argument, or to stdout (which will be captured).

## Self-Review (Fallback)

If no reviewer CLI is found, the skill generates a self-review checklist that the coding agent uses to review its own changes. This is the automatic fallback — install any CLI agent above to enable independent review.
