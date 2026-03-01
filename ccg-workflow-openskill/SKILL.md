---
name: ccg-workflow-openskill
description: OpenSkill protocol adaptation for CCG multi-model workflows. Use when users ask to run, migrate, or optimize ccg-workflow, mention /ccg:* commands, or need Codex+Gemini+Claude orchestration with explicit phase gates, OpenSpec/OPSX compatibility, and deterministic command-to-phase routing.
---

# CCG Workflow OpenSkill

## 概述

将上游 `ccg-workflow` 的命令驱动体系转换为 OpenSkill 协议下可复用的标准流程：

1. 命令标准化：把 `/ccg:*` 请求映射到固定流程通道。
2. 阶段化执行：每个通道都有硬性 Gate（确认点、停止条件、产出格式）。
3. 多模型编排：Codex 与 Gemini 只做分析/补丁建议，Claude/Codex 主代理负责最终落盘。

## 执行入口（先判定）

收到请求后先归类命令：

1. 主流程通道：`/ccg:workflow` `/ccg:plan` `/ccg:execute` `/ccg:feat`
2. 专项通道：`/ccg:frontend` `/ccg:backend` `/ccg:debug` `/ccg:optimize` `/ccg:test` `/ccg:review`
3. Spec 通道：`/ccg:spec-init` `/ccg:spec-research` `/ccg:spec-plan` `/ccg:spec-impl` `/ccg:spec-review`
4. Team 通道：`/ccg:team-research` `/ccg:team-plan` `/ccg:team-exec` `/ccg:team-review`
5. 工具通道：`/ccg:commit` `/ccg:rollback` `/ccg:clean-branches` `/ccg:worktree` `/ccg:init`

详细映射见 `references/ccg-command-mapping.md`。

## 全局协议约束

1. 先约束后实现：需求不完整时，不进入编码。
2. 外部模型只读：外部模型输出仅作建议或 patch 草案，不可直接落盘。
3. 并行要对称：需要双模型分析时，同一轮同时发起 Codex+Gemini，统一汇总后再推进。
4. 阶段必须可验收：每阶段结束都输出决策、风险、下一步，不得只给过程描述。
5. 发现歧义即停：出现关键歧义时回到上个阶段，或向用户提问确认。

## 通道执行规则

### A. 主流程通道（6 阶段）

按以下顺序执行，不跳阶段：

1. 研究：补全需求边界、成功标准、非目标。
2. 构思：至少两种方案对比，明确选型依据。
3. 计划：拆成可执行任务，定义验收标准与回滚点。
4. 执行：按任务单落地，优先最小可验证增量。
5. 优化：性能/稳定性/可维护性审视。
6. 评审：回归计划目标，形成交付结论。

### B. Spec 通道（OpenSpec/OPSX）

1. 统一使用 `openspec` CLI 语义，不混淆斜杠命令别名。
2. `spec-plan` 输出必须达到“零决策执行”标准：实现阶段不再新增关键技术决策。
3. `spec-impl` 仅按 `tasks` 执行；任何范围外改动需先回到 plan。
4. `spec-review` 以归档门禁为目标，必须包含 Critical/Warning 分层。

### C. Team 通道（并行实施）

1. 先拆分文件边界，再并行；禁止并行改同一文件重叠区域。
2. 每轮并行建议 3-6 个任务；不足 3 个需说明串行原因。
3. 每轮结束统一汇总冲突、风险、阻塞，再决定下一轮。

## 模型路由规范

1. Codex：后端逻辑、算法、边界条件、回归风险。
2. Gemini：前端交互、视觉一致性、集成可维护性。
3. 主代理：最终决策、代码修改、测试与验收。

### 推荐并行点

1. 方案分析（构思阶段）
2. 实施后审查（优化/评审阶段）
3. Spec 的 ambiguity audit 与 property 提炼

## 阶段输出模板

每阶段统一输出四段：

1. `Decisions`：本阶段已确定的硬约束。
2. `Risks`：风险与触发条件。
3. `Evidence`：命令输出、测试结果、关键文件。
4. `Next`：下一阶段入口条件。

可直接套用 `references/phase-checklists.md` 的模板与门禁表。

## 失败与回退

1. 双模型结论冲突：先列冲突点，再给单一推荐，不允许并列结论直接前进。
2. 上下文过载：保存当前阶段产物并建议 `/clear` 后继续下一阶段。
3. 验证失败：回退到最近一个“决策已冻结”的阶段重新迭代。

## 参考文件加载规则

1. 需要全命令映射时读取 `references/ccg-command-mapping.md`。
2. 需要阶段门禁/模板时读取 `references/phase-checklists.md`。
3. 不要一次性加载全部参考文件，按当前通道最小化读取。
