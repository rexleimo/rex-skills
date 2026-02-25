# 基于钩子的自动化设置

本文档解释了如何为支持钩子的代理配置自动触发审查。

## Claude Code

将以下内容添加到项目的 `.claude/hooks.json`（或合并到现有配置中）：

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

如果您的技能安装在不同路径（例如 `.claude/skills/review-loop/scripts/...`），请调整路径。

## Cursor

将以下内容添加到项目的 `.cursor/hooks.json`：

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

添加到 `~/.gemini/settings.json`：

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

注意：Gemini CLI 钩子不能阻塞代理，因此审查会运行，但代理不会自动处理反馈。请改用手动工作流。

## 不支持钩子的代理

对于 Codex、OpenCode、Windsurf、Cline 等代理，请使用主 SKILL.md 中描述的手动工作流：

1. 运行 `setup.sh` 开始循环
2. 实现任务
3. 运行 `run-review.sh` 触发审查
4. 处理反馈
5. 运行 `complete.sh` 完成

SKILL.md 中的说明会自动引导代理完成此工作流。