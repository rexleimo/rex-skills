# Hook-Based Automation Setup

This document explains how to configure automatic review triggering via hooks for agents that support them.

> 中文版本请参阅 [hooks-setup_zh.md](hooks-setup_zh.md)。

## Claude Code

Add the following to your project's `.claude/hooks.json` (or merge into existing):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".agents/skills/review-loop/scripts/claude-code-stop-hook.sh",
            "timeout": 900,
            "statusMessage": "Review loop: checking phase..."
          }
        ]
      }
    ]
  }
}
```

Adjust the path if your skill is installed at a different location (e.g., `.claude/skills/review-loop/scripts/...`).

## Cursor

Add the following to your project's `.cursor/hooks.json`:

```json
{
  "hooks": {
    "agent-stop": [
      {
        "command": ".agents/skills/review-loop/scripts/cursor-stop-hook.sh",
        "timeout": 900
      }
    ]
  }
}
```

## Gemini CLI

Add to your `~/.gemini/settings.json`:

```json
{
  "hooks": {
    "AfterAgent": [
      {
        "command": "bash .agents/skills/review-loop/scripts/run-review.sh 2>/dev/null || true"
      }
    ]
  }
}
```

Note: Gemini CLI hooks cannot block the agent, so the review will run but the agent won't automatically address feedback. Use the manual workflow instead.

## Agents Without Hook Support

For agents like Codex, OpenCode, Windsurf, Cline, etc., use the manual workflow described in the main SKILL.md:

1. Run `setup.sh` to start the loop
2. Implement the task
3. Run `run-review.sh` to trigger the review
4. Address the feedback
5. Run `complete.sh` to finish

The SKILL.md instructions guide the agent through this workflow automatically.
