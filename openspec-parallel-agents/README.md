# OpenSpec Parallel Agents

该技能用于 OpenSpec 的并发子代理编排，兼容 OPSX 新命令、旧版 openspec 命令以及 Codex CLI 提示词命令。目标是同时覆盖新旧命令语义，并在多 change 场景下安全并发、受控汇总、避免写冲突。

## 功能特性

- **多入口兼容**：支持 `/opsx:*` (新版), `/openspec:*` (旧版), `/prompts:*` (Codex CLI) 三类命令入口。
- **并发编排**：针对多 change 场景，智能拆分 3-6 个子任务并行执行。
- **冲突管理**：依赖分析，识别强依赖链（串行）与独立节点（并行），避免写冲突。
- **统一汇总**：每轮并发结束后统一汇总状态，裁决下一轮计划。

## 安装

使用 `npx skills` 安装此技能：

```bash
npx skills add https://github.com/rexleimo/rex-skills/tree/main/openspec-parallel-agents
```

## 使用场景

- **OPSX 新命令**：`/opsx:explore`, `/opsx:new`, `/opsx:apply`, `/opsx:archive` 等。
- **Legacy 旧命令**：`/openspec:proposal`, `/openspec:apply` 等（自动映射到 OPSX 语义）。
- **Codex CLI**：`/prompts:opsx-*` 或 `/prompts:openspec-*`。

当满足以下任一条件时自动触发：
1. 同时处理 2 个及以上 change。
2. 需要批量归档 (`/opsx:bulk-archive`)。
3. 任务中同时存在可并行节点与强依赖链。
4. 用户明确要求并行执行。
