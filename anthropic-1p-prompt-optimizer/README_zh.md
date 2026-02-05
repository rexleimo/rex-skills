# Anthropic 1P 提示词优化器 (Anthropic 1P Prompt Optimizer)

## 概览 (Overview)

**Anthropic 1P 提示词优化器** 遵循一套严格的工作流来优化、重写和评估提示词。它利用了经过验证的技术，例如：

- **角色设定 (Role Prompting)**: 明确设定上下文和目标受众。
- **XML 标签分隔 (XML Tag Separation)**: 使用 `<context>`、`<instructions>` 和 `<input>` 等标签来防止指令注入并提高清晰度。
- **预知/思维链 (Precognition/Chain of Thought)**: 鼓励模型进行分步推理。
- **少样本示例 (Few-Shot Examples)**: 提供清晰的语气和格式范例。
- **减少幻觉 (Hallucination Reduction)**: 实施“证据优先 (evidence-first)”提取和“允许不知 (give an out)”策略。
- **输出预填 (Output Prefilling)**: 引导模型输出的前几个词，以强制执行特定格式。

## 工作流 (Workflow)

### 1. 摄入与诊断 (Intake & Diagnosis)
我们首先理解当前的提示词、其执行上下文、目标行为以及已知的失效模式（如语气偏移、格式问题）。我们会诊断提示词是否存在歧义、结构缺失或约束遗漏。

### 2. 优化积木 (Optimization Building Blocks)
基于诊断结果，我们应用特定的 Anthropic 1P 构建模块：
- **清晰直接的指令**: 消除有歧义的动词。
- **变量与分隔符**: 将动态内容包裹在 XML 标签中。
- **结构化输出**: 为响应定义 JSON Schema 或 XML 结构。
- **护栏 (Guardrails)**: 添加显式约束以最大限度地减少幻觉或意外行为。

### 3. 交付 (Delivery)
优化器将提供：
- **修订后的提示词**: 优化过的 System 和 User 提示词。
- **少样本示例**: 针对特定任务定制的示例。
- **变更日志**: 改进内容的简明摘要。
- **测试计划**: 3-5 个具有清晰通过/失败标准的测试用例，用于迭代优化。

## 参考资料 (Reference Materials)

该技能包含多份专业参考指南，位于 `references/` 目录下：
- `references/anthropic-1p-cheatsheet.md`: 核心模式和最佳实践。
- `references/complex-prompt-template.md`: 高级多部分提示词的骨架。
- `references/guardrails-hallucinations.md`: 提高可靠性和诚实性的技术。
- `references/tool-use-xml.md`: 函数调用和工具集成的 XML 格式模式。
- `references/iteration-checklist.md`: 评估和改进循环的指导。

## 目录结构 (Directory Structure)

```text
anthropic-1p-prompt-optimizer/
├── SKILL.md            # 技能定义和核心工作流
├── README.md           # 英文说明文档
├── README_zh.md        # 中文说明文档（本文档）
├── agents/             # 代理配置 (例如: openai.yaml)
├── references/         # 针对特定技术的深度文档
└── scripts/            # (可选) 用于提示词评估的辅助脚本
```

## 用法 (Usage)

要使用此技能，请在会话中激活它并提供您当前的提示词和目标：

```markdown
"帮我优化这个用于总结法律文档的提示词。我希望它既专业又能始终输出关键点的 JSON 列表。"
```

代理随后将引导您完成 1P 优化流程。
