# Rex Skills 🚀

[English](#english) | [简体中文](#简体中文)

<a name="english"></a>

## 📖 Overview

Welcome to **Rex Skills**, a curated collection of high-performance agent skills designed to supercharge your AI CLI experience.

> **"Open source is not just code; it's a culture of collaboration and innovation."**

This repository hosts specialized skills (sub-agents) that extend the capabilities of your AI assistant. Whether you need rigorous prompt engineering, automated code audits, or hybrid model orchestration, these skills are built to production-grade standards.

## 📦 Available Skills

### 1. [Anthropic 1P Prompt Optimizer](./anthropic-1p-prompt-optimizer/)
* **Goal**: Transform vague instructions into robust, production-ready prompts.
* **Methodology**: Follows Anthropic's "1P" interactive workflow (Role Prompting, XML separation, Chain of Thought, Guardrails).
* **Use Case**: When you need to rewrite system prompts, enforce JSON/XML outputs, or reduce hallucinations.

### 2. [Code Review](./code-review/)
* **Goal**: Automated, high-signal code review for Pull Requests and local diffs.
* **Architecture**: Multi-agent system (Guideline Checkers, Bug Detector, Context Analyzer) with confidence scoring.
* **Features**: Filters false positives (requires >80/100 confidence), integrates with GitHub/GitLab, and respects project-specific `CLAUDE.md` or `.cursorrules`.

### 3. [Hybrid Executor](./hybrid-executor/)
* **Goal**: The "right tool for the job" orchestrator.
* **Function**: Seamlessly delegates tasks across different AI CLIs:
    * **Gemini CLI**: For massive context analysis (logs, documentation).
    * **Claude Code**: For SOTA-level complex refactoring.
    * **Codex/Main Agent**: For task flow control.

### 4. [OpenSpec Parallel Agents](./openspec-parallel-agents/)
* **Goal**: Orchestrate concurrent sub-agents for OpenSpec workflows.
* **Features**: Supports OPSX, legacy openspec, and Codex CLI commands. Safely handles multiple changes through dependency analysis.
* **Use Case**: When you need parallel execution of OpenSpec proposals, applications, or archival tasks while avoiding write conflicts.

### 5. [Spec Kit Parallel Orchestrator](./spec-kit-parallel-orchestrator/)
* **Goal**: Parallelize Spec Kit workflows (define, plan, implement).
* **Methodology**: Splits tasks into 3-6 parallel sub-agents with staged rollups.
* **Use Case**: When using `/speckit.*` commands or requesting Spec-driven concurrent development flows.

### 6. [Superpowers Parallel Agents](./superpowers-parallel-agents/)
* **Goal**: Accelerate "superpowers" tasks by splitting them into independent domains.
* **Workflow**: Schedules parallel agents for implementation and validation, ensuring non-overlapping edit scopes.
* **Use Case**: When tasks can be divided into different problem domains that can be solved and validated concurrently.

### 7. [Review Loop Skill](./review-loop-skill/)
* **Goal**: Automated two-phase code review loop for universal AI coding agents.
* **Architecture**: Implements task → independent CLI agent review → feedback addressing workflow.
* **Features**: Works with any Agent Skills compatible tool (Claude Code, Cursor, Codex, Gemini CLI, etc.), supports multiple reviewers (Codex, Claude, Gemini, OpenCode, Aider).

### 8. [CCG Workflow OpenSkill](./ccg-workflow-openskill/)
* **Goal**: Normalize `ccg-workflow` into an OpenSkill-compliant, gated workflow.
* **Methodology**: Command-to-lane routing (`/ccg:*`), phase gates, and Codex/Gemini parallel orchestration.
* **Use Case**: When migrating, executing, or optimizing `ccg-workflow` with OpenSkill protocol constraints.

## 🚀 Installation & Usage

To use these skills, you typically register the `SKILL.md` file with your AI CLI agent.

For example, to register the **Code Review** skill:
1. Navigate to the skill directory.
2. Point your agent to the `SKILL.md` file or copy its content into your agent's configuration.

```bash
# Example directory structure
rex-skills/
├── anthropic-1p-prompt-optimizer/  # Prompt Engineering
├── code-review/                    # Automated Auditing
└── hybrid-executor/                # Model Orchestration
```

## 🤝 Contributing

We love pull requests! If you have a new skill idea or an improvement to an existing one:

1. Fork the repo.
2. Create a new branch (`git checkout -b feature/amazing-skill`).
3. Commit your changes.
4. Open a Pull Request.

Please ensure your skill follows the `SKILL.md` metadata standard and includes adequate documentation.

---

<a name="简体中文"></a>

## 📖 简介 (Overview)

欢迎来到 **Rex Skills**，这是一个精选的高性能 Agent 技能集合，旨在增强你的 AI CLI 体验。

> **“开源不仅仅是代码，更是一种协作和创新的文化。”**

本仓库托管了多种专用技能（子代理），用于扩展 AI 助手的核心能力。无论你需要严谨的提示词工程（Prompt Engineering）、自动化的代码审计，还是混合模型的编排调度，这些技能都已达到生产级标准。

## 📦 可用技能 (Available Skills)

### 1. [Anthropic 1P 提示词优化器](./anthropic-1p-prompt-optimizer/)
* **目标**: 将模糊的指令转化为健壮的、生产就绪的提示词（Prompt）。
* **方法论**: 遵循 Anthropic "1P" 交互式工作流（角色设定、XML 分隔、思维链 CoT、护栏 Guardrails）。
* **适用场景**: 当你需要重写 System Prompt、强制要求 JSON/XML 输出格式，或减少模型幻觉时。

### 2. [代码审查 (Code Review)](./code-review/)
* **目标**: 针对 Pull Request 和本地 Diff 进行自动化的、高信噪比代码审查。
* **架构**: 多代理系统（规范检查器、Bug 检测器、上下文分析器），基于置信度评分。
* **特性**: 过滤误报（仅保留 >80/100 置信度的问题），集成 GitHub/GitLab，并遵守项目特定的 `CLAUDE.md` 或 `.cursorrules` 规范。

### 3. [混合执行器 (Hybrid Executor)](./hybrid-executor/)
* **目标**: “工欲善其事，必先利其器” —— 智能编排器。
* **功能**: 在不同的 AI CLI 之间无缝委派任务：
    * **Gemini CLI**: 用于超长上下文分析（大规模日志、文档）。
    * **Claude Code**: 用于 SOTA 级别的复杂代码重构。
    * **Codex/Main Agent**: 用于整体任务流控制。

### 4. [OpenSpec 并行代理 (OpenSpec Parallel Agents)](./openspec-parallel-agents/)
* **目标**: 编排 OpenSpec 工作流的并发子代理。
* **特性**: 支持 OPSX、旧版 openspec 和 Codex CLI 命令。通过依赖分析安全处理多个变更。
* **适用场景**: 需要并行执行 OpenSpec 提案、应用或归档任务，且需避免写入冲突时。

### 5. [Spec Kit 并行编排器 (Spec Kit Parallel Orchestrator)](./spec-kit-parallel-orchestrator/)
* **目标**: 并行化 Spec Kit 工作流（定义、计划、实现）。
* **方法论**: 将任务拆分为 3-6 个并行子代理，并进行阶段性汇总。
* **适用场景**: 使用 `/speckit.*` 命令或请求基于 Spec 驱动的并发开发流程时。

### 6. [Superpowers 并行代理 (Superpowers Parallel Agents)](./superpowers-parallel-agents/)
* **目标**: 通过将任务拆分为独立领域来加速 "superpowers" 任务。
* **工作流**: 调度并行代理进行实现和验证，确保编辑范围不重叠。
* **适用场景**: 当任务可以划分为不同的问题域，且可以并发解决和验证时。

### 7. [Review Loop 技能 (Review Loop Skill)](./review-loop-skill/)
* **目标**: 为通用 AI 编程代理提供自动化的两阶段代码审查循环。
* **架构**: 实现任务 → 独立 CLI 代理审查 → 反馈处理工作流。
* **特性**: 兼容任何 Agent Skills 工具（Claude Code、Cursor、Codex、Gemini CLI 等），支持多种审查者（Codex、Claude、Gemini、OpenCode、Aider）。

### 8. [CCG Workflow OpenSkill](./ccg-workflow-openskill/)
* **目标**: 将 `ccg-workflow` 规范化为符合 OpenSkill 协议的可复用工作流。
* **方法论**: 统一 `/ccg:*` 命令路由、阶段门禁、双模型并行编排与 OpenSpec 兼容约束。
* **适用场景**: 需要迁移、执行或优化 `ccg-workflow`，并要求严格遵循 OpenSkill 规范协议时。

## 🚀 安装与使用 (Installation & Usage)

要使用这些技能，通常需要将 `SKILL.md` 文件注册到你的 AI CLI Agent 中。

例如，注册 **Code Review** 技能：
1. 进入对应的技能目录。
2. 将 Agent 指向 `SKILL.md` 文件，或将其内容复制到 Agent 的配置中。

```bash
# 目录结构示例
rex-skills/
├── anthropic-1p-prompt-optimizer/  # 提示词工程
├── code-review/                    # 自动化审计
└── hybrid-executor/                # 模型编排
```

## 🤝 贡献 (Contributing)

我们非常欢迎 Pull Request！如果你有新的技能想法或想要改进现有技能：

1. Fork 本仓库。
2. 创建一个新分支 (`git checkout -b feature/amazing-skill`)。
3. 提交你的更改。
4. 发起 Pull Request。

请确保你的技能符合 `SKILL.md` 元数据标准，并包含充分的文档。

---

*Built with ❤️ for the Open Source Community.*
