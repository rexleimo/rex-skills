# review-loop-skill

一个自动化的两阶段代码审查循环，打包为 [Agent Skill](https://agentskills.io)，可与任何 AI 编程代理兼容。

灵感来自 [claude-review-loop](https://github.com/hamelsmu/claude-review-loop)，此技能移除了对 Claude Code 的依赖，可与**任何**兼容 Agent Skills 的工具协同工作。

## 安装

```bash
npx skills add <owner>/review-loop-skill
```

或安装到特定代理：

```bash
npx skills add <owner>/review-loop-skill -a claude-code -a cursor -a codex
```

## 工作原理

```
┌─────────────────┐      ┌───────────────────┐      ┌─────────────────┐
│   第一阶段：     │      │   审查：          │      │   第二阶段：    │
│   编程代理      │─────▶│   另一个 CLI      │─────▶│   编程代理      │
│   实现任务      │      │   代理独立审查    │      │   处理反馈      │
└─────────────────┘      └───────────────────┘      └─────────────────┘
     (您)                   (codex/claude/         (您，再次)
                            gemini/etc.)
```

审查者是另一个以非交互模式运行的 CLI 代理。它有自己的模型和认证 —— **无需 API 密钥**。

## 支持的编程代理

此技能适用于所有支持 [Agent Skills 规范](https://agentskills.io/specification) 的代理：

| 代理 | 钩子自动化 | 手动工作流 |
|-------|:-:|:-:|
| Claude Code | 是 | 是 |
| Cursor | 是 | 是 |
| Codex | — | 是 |
| Gemini CLI | 部分 | 是 |
| OpenCode | — | 是 |
| Windsurf | — | 是 |
| Cline | — | 是 |
| Roo Code | — | 是 |
| GitHub Copilot | — | 是 |
| 30+ 更多 | — | 是 |

## 支持的审查者

| 审查者 | 运行方式 | 安装 |
|----------|-------------|---------|
| Codex (默认) | `codex exec` — 多代理并行审查 | `npm i -g @openai/codex` |
| Claude Code | `claude -p` — 非交互模式 | `npm i -g @anthropic-ai/claude-code` |
| Gemini CLI | `echo prompt \| gemini` — 管道模式 | 参见 gemini CLI 文档 |
| OpenCode | `opencode run` — 非交互模式 | 参见 opencode.ai |
| Aider | `aider --message --yes` — 消息模式 | `pip install aider-chat` |
| 自定义 | 您指定的任何命令 | 设置 `REVIEW_CUSTOM_CMD` |

自动检测：如果未设置 `REVIEW_REVIEWER`，技能将尝试 codex → claude → gemini → opencode → aider。

## 快速开始

安装后，只需告诉您的 AI 编程代理：

> "使用 review-loop 技能来实现 [您的任务]"

代理将按照技能说明运行完整的审查循环。

## 许可证

MIT