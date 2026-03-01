# CCG Command Mapping (OpenSkill Normalized)

## 1. Workflow Lanes

| 命令 | 归一化通道 | 目标产出 | 默认模型路由 |
|---|---|---|---|
| `/ccg:workflow` | 主流程(6阶段) | 端到端交付结果 | Codex + Gemini + 主代理 |
| `/ccg:plan` | 主流程-计划子通道 | 任务计划文档 | Codex + Gemini |
| `/ccg:execute` | 主流程-执行子通道 | 按计划实施结果 | 主代理(落盘) + 外部模型建议 |
| `/ccg:feat` | 主流程(需求到交付) | 新功能完整交付 | Codex + Gemini + 主代理 |

## 2. Domain Commands

| 命令 | 归一化通道 | 主关注点 | 默认模型 |
|---|---|---|---|
| `/ccg:frontend` | 专项通道 | UI/交互/样式 | Gemini |
| `/ccg:backend` | 专项通道 | API/逻辑/数据 | Codex |
| `/ccg:analyze` | 专项通道 | 技术分析与风险 | Codex + Gemini |
| `/ccg:debug` | 专项通道 | 问题定位与修复 | Codex + Gemini |
| `/ccg:optimize` | 专项通道 | 性能与复杂度优化 | Codex + Gemini |
| `/ccg:test` | 专项通道 | 测试补齐与验证 | 跟随目标模块 |
| `/ccg:review` | 专项通道 | 审查与风险分级 | Codex + Gemini |

## 3. Spec Commands (OpenSpec/OPSX)

| 命令 | 归一化阶段 | 必要检查 |
|---|---|---|
| `/ccg:spec-init` | Spec 初始化 | `openspec` 可用性 + 项目初始化状态 |
| `/ccg:spec-research` | 需求约束化 | 需求边界、约束集、验收标准 |
| `/ccg:spec-plan` | 零决策规划 | Ambiguity 清零 + PBT 属性明确 |
| `/ccg:spec-impl` | 规范执行 | 仅执行 `tasks` 范围内改动 |
| `/ccg:spec-review` | 归档前审查 | Critical 必修复 + 归档准入 |

## 4. Team Commands

| 命令 | 归一化阶段 | 并行规则 |
|---|---|---|
| `/ccg:team-research` | Team 需求研究 | 可并行探索，统一约束集 |
| `/ccg:team-plan` | Team 任务拆分 | 3-6 子任务，文件边界隔离 |
| `/ccg:team-exec` | Team 并行实施 | 禁止重叠写入，冲突即降级串行 |
| `/ccg:team-review` | Team 双模型审查 | 双模型审查后统一裁决 |

## 5. Utility Commands

| 命令 | 归一化通道 | 约束 |
|---|---|---|
| `/ccg:init` | 工具通道 | 初始化上下文文件，避免覆盖用户自定义内容 |
| `/ccg:commit` | 工具通道 | 必须先验证再生成提交 |
| `/ccg:rollback` | 工具通道 | 禁止无确认回滚 |
| `/ccg:clean-branches` | 工具通道 | 仅清理可安全删除分支 |
| `/ccg:worktree` | 工具通道 | 多任务隔离优先 |

## 6. Legacy Compatibility

1. 若用户混用 `/opsx:*`、`/openspec:*`、`/ccg:spec-*`，统一映射为 Spec 通道并保持当前上下文继续执行。
2. 若命令意图不明确，先确认目标通道再执行，不可猜测。
