---
name: superpowers-parallel-agents
description: Use when superpowers tasks can be split into two or more independent domains with non-overlapping edit scopes for concurrent subagent execution.
---

# Superpowers Parallel Agents

## 概述

该技能用于将 `dispatching-parallel-agents` 与 `subagent-driven-development` 组合使用，在多独立问题域下并发推进实现任务。
核心目标是缩短处理时间，同时保持输出质量、可审查性与可回归性。

## 必用子技能

1. `superpowers:dispatching-parallel-agents`：先做问题域拆分与并发派工。
2. `superpowers:subagent-driven-development`：对子任务执行实现、自测、审查闭环。
3. `superpowers:verification-before-completion`：在宣告完成前进行统一验证。

## 触发条件

满足任一条件即触发：

1. 可拆分为 2 个及以上互相独立的问题域。
2. 子任务编辑范围不重叠，或可通过边界隔离避免冲突。
3. 用户明确要求并行推进、多代理协作、加速执行。

## 并发规则

1. 按问题域拆分，不按工时平均拆分。
2. 每个子代理只负责一个问题域，禁止跨域改动。
3. 同一文件同一区域禁止并发写入，有冲突风险立刻转串行。
4. 每个子任务必须明确输入、输出、验收标准、禁改范围。
5. 一轮并发必须全量返回后再汇总，不允许边返回边合并。
6. 汇总后必须统一审查和回归验证，未通过不得结束。

## 标准流程

1. 拆分阶段
- 识别独立问题域与强依赖链。
- 形成并行任务卡：目标、文件范围、禁改项、验收条件。

2. 并行阶段
- 并发启动子代理执行实现与自测。
- 子代理返回根因、改动清单、验证证据。

3. 汇总阶段
- 统一检查接口、类型、命名、配置一致性。
- 处理冲突并裁决是否需要回退到串行。

4. 验证阶段
- 执行受影响测试与关键路径回归。
- 验证失败时仅回退对应问题域重做，避免全量返工。

## 何时不要并发

出现以下任一情况必须串行：

1. 存在强依赖链（A 完成后 B 才能开始）。
2. 根因未澄清，多个现象可能来自同一底层缺陷。
3. 需要先统一架构决策（核心接口或全局模型重构）。
4. 高风险改动需逐步验证（数据库结构、权限、计费主链路）。
5. 当前缺少统一回归环境，无法保证并发收口质量。

## 完成判定

仅当以下条件全部满足才可宣告完成：

1. 所有子任务达到验收标准。
2. 汇总审查无冲突、无未决高风险。
3. 统一回归验证通过。
4. 每项改动都能追溯到对应问题域与子任务输出。
