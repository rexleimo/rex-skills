# 审查者配置指南

review-loop 技能使用另一个 CLI 代理作为审查者。所有支持的审查者都是功能完整的 AI 编程代理，以非交互模式运行 —— 它们有自己的模型和认证，因此**无需 API 密钥**。

## 工作原理

当您触发审查时，该技能会：
1. 构建审查提示（根据您的项目类型定制）
2. 在您的项目目录中以非交互模式启动审查者 CLI 代理
3. 审查者代理读取您的代码，运行 git diff，分析更改并写入发现
4. 审查结果保存到 `reviews/review-<id>.md`

## 自动检测（默认）

默认情况下（`REVIEW_REVIEWER=auto`），该技能按以下顺序自动检测第一个可用的审查者：

1. **codex** — 首选，因为它支持多代理并行审查
2. **claude** — Claude Code CLI
3. **gemini** — Gemini CLI
4. **opencode** — OpenCode CLI
5. **aider** — Aider CLI

如果都未找到，则回退到**自我审查**（为编程代理生成检查清单）。

## Codex（推荐）

使用 OpenAI 的 Codex CLI，支持多代理。Codex 在内部生成并行审查代理，以实现更快、更彻底的审查。

**安装：**
```bash
npm install -g @openai/codex
```

**运行方式：**
```bash
codex exec --full-auto "<审查提示>"
```

该技能会自动在 `~/.codex/config.toml` 中启用 `multi_agent = true`。

**覆盖标志：**
```bash
export REVIEW_LOOP_CODEX_FLAGS="--full-auto --sandbox danger-full-access"
```

## Claude Code

使用 Anthropic 的 Claude Code CLI 的非交互打印模式。

**安装：**
```bash
npm install -g @anthropic-ai/claude-code
```

**运行方式：**
```bash
claude --dangerously-skip-permissions -p "<审查提示>"
```

## Gemini CLI

使用 Google 的 Gemini CLI 的管道模式。

**安装：**
```bash
npm install -g @anthropic-ai/gemini-cli
```

**运行方式：**
```bash
echo "<审查提示>" | gemini
```

## OpenCode

使用 OpenCode CLI 的非交互模式。

**安装：**
参见 https://opencode.ai 获取安装说明。

**运行方式：**
```bash
opencode run "<审查提示>"
```

## Aider

使用 Aider 的非交互消息模式。

**安装：**
```bash
pip install aider-chat
```

**运行方式：**
```bash
aider --message "<审查提示>" --yes
```

## 自定义命令

运行任何自定义命令作为审查者。

```bash
export REVIEW_REVIEWER=custom
export REVIEW_CUSTOM_CMD="my-review-tool --format markdown"
```

该命令应将其审查输出写入作为参数提供的文件路径，或写入 stdout（将被捕获）。

## 自我审查（回退）

如果未找到任何审查者 CLI，该技能会生成一个自我审查检查清单，供编程代理用于审查自己的更改。这是自动回退方案 —— 安装上述任一 CLI 代理以启用独立审查。