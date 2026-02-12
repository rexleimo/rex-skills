# Spec Kit Parallel Orchestrator

用于 Spec Kit 工作流的并发编排技能。将传统的单线程执行模式切换为“3-6 个子代理并行 + 阶段汇总”模式，优先并行无依赖节点，严格串行强依赖链，显著缩短端到端耗时并保持输出一致性。

## 功能特性

- **工作流并行化**：将 Spec Kit 各阶段（Constitution, Specify, Plan, Implement 等）的任务拆解为可并行的子任务。
- **智能调度**：默认拆分 3-6 个子任务，仅对无依赖节点并发，强依赖链保持串行。
- **阶段校验**：执行前进行依赖分析与阶段校验，防止跨阶段越权执行。
- **统一汇总**：每轮执行后进行一致性检查与结果汇总，决定进入下一轮或结束。

## 安装

使用 `npx skills` 安装此技能：

```bash
npx skills add https://github.com/rexleimo/rex-skills/tree/main/spec-kit-parallel-orchestrator
```

## 使用场景

- 用户输入 `/speckit.*` 开头的命令 (e.g., `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`).
- Codex CLI 兼容命令 `/prompts:speckit.*`。
- 用户明确提到“spec kit 工作流”、“workflow prompt”并要求拆解或多代理协作。

## 官方语义对齐

遵循 `github/spec-kit` 标准阶段：
`constitution -> specify -> clarify -> plan -> tasks -> implement`

在并行执行时，确保 `/speckit.implement` 等命令严格遵循任务依赖关系。
