# OpenSpec Long-Running Harness Best Practices

## 概述

本文档基于 Anthropic 的 "Effective Harnesses for Long-Running Agents" 文章，结合实际项目经验，总结长时运行 Agent 的最佳实践。

## 核心原则

### 1. 状态持久化

每个会话开始时，Agent 没有之前的记忆。必须通过文件系统持久化状态：

```
openspec/harness/
├── feature_list.json     # 功能定义和状态
├── progress.log.md       # 会话历史和决策记录
├── session_state.json    # 当前会话上下文
└── init.sh               # 环境验证脚本
```

**最佳实践：**
- 每次状态变更立即写入文件
- 使用结构化格式（JSON）便于程序解析
- 使用人类可读格式（Markdown）便于审查

### 2. 增量进展

每个会话只处理一个 feature，明确记录进展：

**会话开始：**
1. 确认目录和分支
2. 读取 progress.log.md 了解历史
3. 从 feature_list.json 选择下一个任务
4. 运行 init.sh 验证环境

**会话进行中：**
- 拆分为 3-6 个并行子任务
- 每个子任务独立完成
- 避免写冲突

**会话结束：**
- Gate enforcement 验证
- 更新状态文件
- 写入会话摘要

### 3. Gate Enforcement

会话结束前必须通过三个门禁：

| Gate | 验证命令 | 失败处理 |
|------|----------|----------|
| Working Tree Clean | `git status` | 提交或丢弃更改 |
| New Commit Exists | `git log` | 创建 commit |
| E2E Passed | 自定义命令 | 修复问题后重试 |

**为什么重要：**
- 确保工作不会丢失
- 确保代码可以运行
- 确保功能真正完成

## 并行执行策略

### 可并行的场景

```
Task A: 实现登录表单 → src/components/Login.vue
Task B: 创建认证 API → src/api/auth.js
Task C: 编写测试 → tests/auth.test.js
```

这些任务修改不同文件，可以同时执行。

### 必须串行的场景

```
Task A: 设计数据库 schema → docs/schema.sql
Task B: 实现 migration → migrations/001.sql
Task C: 创建 model → src/models/User.js
```

B 依赖 A 的输出，C 依赖 B 的完成，必须串行。

### 冲突避免

当多个任务需要修改同一文件时：

1. **文件边界重分** - 按模块/功能拆分文件
2. **降级串行** - 无法避免冲突时串行执行
3. **原子性区域** - 在文件内划分独立区域

## Feature 定义规范

### 必要字段

```json
{
  "id": "F001",
  "category": "functional",
  "priority": "P1",
  "description": "Feature description",
  "steps": ["Step 1", "Step 2", "Step 3"],
  "status": "pending"
}
```

### 可选字段

```json
{
  "depends_on": ["F000"],
  "blocked_reason": null,
  "started_at": "2024-01-15T10:00:00Z",
  "completed_at": "2024-01-15T12:00:00Z",
  "commits": ["abc1234", "def5678"]
}
```

### Category 类型

| Category | 描述 |
|----------|------|
| `functional` | 核心业务功能 |
| `api` | API 端点或接口 |
| `ui` | 用户界面组件 |
| `security` | 安全相关功能 |
| `performance` | 性能优化 |
| `refactor` | 代码重构 |

### Priority 优先级

| Priority | 描述 | 示例 |
|----------|------|------|
| `P1` | 高优先级，阻塞其他工作 | 核心功能、严重 bug |
| `P2` | 中优先级，重要但不阻塞 | 重要功能、改进 |
| `P3` | 低优先级，增强功能 | 优化、非必要功能 |

## 错误处理

### E2E 验证失败

1. 标记 feature 为 `failed`
2. 记录失败原因到 progress.log.md
3. 保持工作区状态（不自动回滚）
4. 下次会话优先处理

### 环境检查失败

1. 记录问题到 progress.log.md
2. 标记 feature 为 `blocked`
3. 记录 `blocked_reason`
4. 等待用户手动修复

### 依赖阻塞

```json
{
  "id": "F002",
  "depends_on": ["F001"],
  "status": "pending"
}
```

如果 F001 未完成，F002 自动跳过。

## 进度日志规范

### 格式

```markdown
## Session 001 - 2024-01-15

### Started
- **Task**: F001 - 用户认证
- **Priority**: P1
- **Steps**: 3

### Progress
- Commit: abc1234 - 实现登录表单
- Commit: def5678 - 添加 API 端点
- Commit: ghi9012 - 编写测试

### Verified
- [x] Working tree clean
- [x] New commit created: ghi9012
- [x] E2E passed

### Ended
- Status: passing
- Duration: 2h
- Next: F002
```

### 为什么用 Markdown

- 人类可读，便于审查
- 支持 Git diff 追踪变更
- 可以包含代码块和格式化

## 环境检查脚本

### 最佳实践

```bash
#!/bin/bash
set -euo pipefail

# 1. 检查必需工具
command -v node >/dev/null || { echo "需要 Node.js"; exit 1; }

# 2. 检查依赖安装
[ -d "node_modules" ] || { echo "运行 npm install"; exit 1; }

# 3. 检查环境变量
[ -n "$DATABASE_URL" ] || { echo "设置 DATABASE_URL"; exit 1; }

# 4. 检查服务连接
curl -s http://localhost:3000/health >/dev/null || { echo "启动服务"; exit 1; }
```

### 避免的问题

- 不要执行耗时操作
- 不要修改文件系统
- 不要依赖网络状态（除非必要）

## 与 OpenSpec 集成

### 命令映射

| OpenSpec 命令 | Harness 行为 |
|---------------|--------------|
| `/opsx:new` | 创建 harness + feature_list.json |
| `/opsx:apply` | 选择任务，开始实现 |
| `/opsx:verify` | 运行 E2E 验证 |
| `/opsx:archive` | 归档完成的 features |

### 工作流整合

```
1. 用户: /opsx:new "项目描述"
   → 创建 openspec/harness/

2. 用户: 编辑 feature_list.json

3. 用户: /opsx:apply
   → Agent 读取 harness 状态
   → 选择下一个 feature
   → 开始实现

4. Agent: 实现完成
   → 运行 gate enforcement
   → 更新状态

5. 用户: /opsx:archive
   → 归档 passing features
```

## 调试技巧

### 查看状态

```bash
./scripts/harness-status.sh
```

### 检查会话

```bash
cat openspec/harness/session_state.json | jq .
```

### 查看进度

```bash
tail -50 openspec/harness/progress.log.md
```

### 重置 feature

```bash
# 手动编辑 feature_list.json
# 将 status 改为 "pending"
# 清空 commits 数组
```

## 参考

- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [OpenSpec Parallel Agents](../openspec-parallel-agents/SKILL.md)
- [Spec Kit Orchestrator](../spec-kit-parallel-orchestrator/SKILL.md)
