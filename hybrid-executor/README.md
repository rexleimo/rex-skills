# 架构优势与提示

能力互补：你可以利用 Gemini 的 1M Token 超长上下文 处理大规模日志，同时利用 Claude Code SOTA 级别的代码重构能力

上下文整洁：通过 OpenSkills 标准，你可以将这些技能同步到 AGENTS.md 中，实现“渐进式披露”，即只有在调用该技能时才加载相关指令，保持 Codex 的上下文窗口整洁

混合策略建议：
1. 使用 Gemini CLI 进行样板代码生成、文档编写和 PR 描述（因为它免费且额度高）
2. 使用 Claude Code 进行核心逻辑的复杂重构和边缘案例处理
3. 让 Codex CLI 作为主代理负责整体的任务流控制

故障排除:
身份验证：确保在使用前已分别为三个工具运行了登录命令（codex login、claude login、gemini 交互登录），否则 Shell 调用会因权限问题失败。

格式处理：在调用时可以使用 --output-format json 标志来获取更易于解析的数据流

会话内开启：输入 /approval 并选择 Full Access

参数传递：你在 SKILL.md 中使用的 $ARGUMENTS 是一个标准占位符，它会将你输入给 Codex 的后续指令精准传递给底层的 Claude 或 Gemini