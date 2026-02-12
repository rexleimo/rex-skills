# Superpowers Parallel Agents

该技能组合了 `dispatching-parallel-agents` 与 `subagent-driven-development`，用于在多个独立的问题域下并发推进实现任务。旨在缩短处理时间的同时，确保代码质量、可审查性与可回归性。

## 功能特性

- **领域拆分**：将复杂任务按“独立问题域”拆分，而非简单按工时拆分。
- **并发实现**：每个子代理独立负责一个问题域的实现与自测，互不干扰。
- **冲突隔离**：确保子任务编辑范围不重叠，通过边界隔离避免写冲突。
- **闭环验证**：包含实现、自测、审查与统一回归验证的完整闭环。

## 安装

使用 `npx skills` 安装此技能：

```bash
npx skills add https://github.com/rexleimo/rex-skills/tree/main/superpowers-parallel-agents
```

## 使用场景

- 任务可拆分为 2 个及以上互相独立的问题域。
- 子任务编辑范围不重叠。
- 用户明确要求并行推进或加速执行。

**注意**：存在强依赖链、根因未明或涉及高风险全局改动时，将自动回退为串行模式。
