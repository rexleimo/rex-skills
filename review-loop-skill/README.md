# review-loop-skill

An automated two-phase code review loop, packaged as an [Agent Skill](https://agentskills.io) for universal compatibility with AI coding agents.

> 中文文档请参阅 [README_zh.md](README_zh.md)。

Inspired by [claude-review-loop](https://github.com/hamelsmu/claude-review-loop), this skill removes the Claude Code dependency and works with **any** Agent Skills compatible tool.

## Install

```bash
npx skills add <owner>/review-loop-skill
```

Or install to specific agents:

```bash
npx skills add <owner>/review-loop-skill -a claude-code -a cursor -a codex
```

## How It Works

```
┌─────────────────┐      ┌───────────────────┐      ┌─────────────────┐
│   Phase 1:      │      │   Review:         │      │   Phase 2:      │
│   Coding agent  │─────▶│   Another CLI     │─────▶│   Coding agent  │
│   implements    │      │   agent reviews   │      │   addresses     │
│   the task      │      │   independently   │      │   feedback      │
└─────────────────┘      └───────────────────┘      └─────────────────┘
     (you)                  (codex/claude/         (you, again)
                             gemini/etc.)
```

The reviewer is another CLI agent running non-interactively. It has its own model and authentication — **no API keys needed**.

## Supported Coding Agents

This skill works with all agents that support the [Agent Skills specification](https://agentskills.io/specification):

| Agent | Hook Automation | Manual Workflow |
|-------|:-:|:-:|
| Claude Code | Yes | Yes |
| Cursor | Yes | Yes |
| Codex | — | Yes |
| Gemini CLI | Partial | Yes |
| OpenCode | — | Yes |
| Windsurf | — | Yes |
| Cline | — | Yes |
| Roo Code | — | Yes |
| GitHub Copilot | — | Yes |
| 30+ more | — | Yes |

## Supported Reviewers

| Reviewer | How It Runs | Install |
|----------|-------------|---------|
| Codex (default) | `codex exec` — multi-agent parallel review | `npm i -g @openai/codex` |
| Claude Code | `claude -p` — non-interactive mode | `npm i -g @anthropic-ai/claude-code` |
| Gemini CLI | `echo prompt \| gemini` — pipe mode | See gemini CLI docs |
| OpenCode | `opencode run` — non-interactive mode | See opencode.ai |
| Aider | `aider --message --yes` — message mode | `pip install aider-chat` |
| Custom | Any command you specify | Set `REVIEW_CUSTOM_CMD` |

Auto-detection: if `REVIEW_REVIEWER` is not set, the skill tries codex → claude → gemini → opencode → aider.

## Quick Start

Once installed, just tell your AI coding agent:

> "Use the review-loop skill to implement [your task]"

The agent will follow the skill instructions to run the full review cycle.

## License

MIT
