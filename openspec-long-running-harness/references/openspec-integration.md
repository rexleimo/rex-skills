# OpenSpec Integration Guide

## 概述

本文档说明如何将 OpenSpec Long-Running Harness 与 OpenSpec 工作流集成。

## 命令映射

### OPSX 新命令

| 命令 | Harness 行为 | 实现状态 |
|------|--------------|----------|
| `/opsx:new` | 初始化 harness + 创建 feature_list.json | ✅ |
| `/opsx:explore` | 读取 feature_list.json 了解项目 | ✅ |
| `/opsx:continue` | 继续当前 feature | ✅ |
| `/opsx:ff` | 快速前进，跳过非必要步骤 | ✅ |
| `/opsx:apply` | 选择下一个 failing/pending feature，启动实现 | ✅ |
| `/opsx:verify` | 运行 E2E 验证，更新状态 | ✅ |
| `/opsx:sync` | 同步状态到远程 | ⏳ |
| `/opsx:archive` | 验证所有 features passing，归档 | ✅ |
| `/opsx:bulk-archive` | 批量归档多个 change | ✅ |
| `/opsx:onboard` | 项目入职引导 | ⏳ |

### Legacy 旧命令

| 命令 | 映射到 | Harness 行为 |
|------|--------|--------------|
| `/openspec:proposal` | `/opsx:new` + `/opsx:ff` | 创建 harness 结构 |
| `/openspec:apply` | `/opsx:apply` | 开始实现 feature |
| `/openspec:archive` | `/opsx:archive` | 归档完成的 work |

## 集成流程

### 1. 初始化项目

```bash
# 用户运行
/opsx:new "项目描述"

# Harness 自动创建
openspec/harness/
├── feature_list.json
├── progress.log.md
├── session_state.json
├── .harness-config.json
└── init.sh
```

### 2. 定义 Features

用户编辑 `feature_list.json`：

```json
{
  "features": [
    {
      "id": "F001",
      "category": "functional",
      "priority": "P1",
      "description": "实现用户认证",
      "steps": ["登录表单", "API 端点", "Session 管理"],
      "status": "pending"
    },
    {
      "id": "F002",
      "category": "api",
      "priority": "P1",
      "description": "实现用户 API",
      "steps": ["CRUD 端点", "验证", "错误处理"],
      "status": "pending",
      "depends_on": ["F001"]
    }
  ]
}
```

### 3. 开始实现

```bash
# 用户运行
/opsx:apply

# Agent 执行
1. 读取 progress.log.md (历史)
2. 读取 feature_list.json (选择任务)
3. 运行 init.sh (环境检查)
4. 更新 session_state.json
5. 开始实现

# 选择策略
- Priority: P1 > P2 > P3
- Status: failed > in_progress > pending
- 依赖检查: 跳过被阻塞的 feature
```

### 4. 会话结束

```bash
# Agent 自动执行
1. Gate 1: 工作区干净检查
2. Gate 2: 新 commit 存在检查
3. Gate 3: E2E 验证
4. 更新 feature 状态
5. 写入会话摘要
```

### 5. 归档

```bash
# 用户运行
/opsx:archive

# 验证
- 所有 features status == "passing"
- 没有未完成的工作
```

## Agent Prompt 集成

### 会话开始 Prompt

```
You are continuing a long-running project. Follow this protocol:

1. Run `pwd` to confirm directory
2. Read `openspec/harness/progress.log.md` for recent work
3. Read `openspec/harness/feature_list.json` to understand remaining tasks
4. Run `openspec/harness/init.sh` to verify environment
5. Select the next task using priority: P1 > P2 > P3, status: failed > in_progress > pending
6. Update `openspec/harness/session_state.json`

Begin implementation. Work on ONE feature at a time.
```

### 会话结束 Prompt

```
Before ending this session, complete gate enforcement:

1. Verify working tree is clean: `git status`
2. Verify new commit exists since session start
3. Run E2E verification

If all gates pass:
- Mark feature as "passing" in feature_list.json
- Write session summary to progress.log.md

If any gate fails:
- Mark feature as "failed"
- Document the issue
- Do not claim success
```

## 配置文件

### .harness-config.json

```json
{
  "e2e_command": "npm test",
  "e2e_timeout": 300,
  "require_clean_tree": true,
  "auto_commit": false
}
```

| 字段 | 描述 |
|------|------|
| `e2e_command` | E2E 验证命令 |
| `e2e_timeout` | 超时时间（秒） |
| `require_clean_tree` | 是否要求工作区干净 |
| `auto_commit` | 是否自动提交更改 |

## 与 OpenSpec Parallel Agents 协同

当使用 `/opsx:apply` 时，可以结合并行执行：

```markdown
### Parallel Plan (3-6 tasks)
1. Task A: 实现登录表单 → src/components/Login.vue
2. Task B: 创建认证 API → src/api/auth.js
3. Task C: 编写测试 → tests/auth.test.js

### Serial Chain (dependency)
D: 设计 schema → E: 实现 migration → F: 创建 model
```

参考 `../openspec-parallel-agents/SKILL.md` 了解更多并行策略。

## 故障排除

### Feature 被阻塞

```bash
# 检查状态
./scripts/harness-status.sh

# 查看原因
cat openspec/harness/feature_list.json | jq '.features[] | select(.status == "blocked")'
```

### E2E 持续失败

```bash
# 手动运行 E2E
./scripts/harness-verify-e2e.sh

# 检查配置
cat openspec/harness/.harness-config.json
```

### 会话状态不一致

```bash
# 重置会话
echo '{"session_id": 0, "status": "idle"}' > openspec/harness/session_state.json

# 重新开始
./scripts/harness-start.sh
```

## 迁移指南

### 从旧 OpenSpec 工作流迁移

1. **创建 Harness**

```bash
./scripts/harness-init.sh "my-project"
```

2. **导入 Features**

将现有的 change 规格转换为 feature_list.json 格式：

```json
{
  "id": "F001",
  "description": "<change-title>",
  "steps": ["<from change steps>"],
  "status": "pending"
}
```

3. **继续工作**

使用 `/opsx:apply` 继续实现。

## 最佳实践

1. **每个 Feature 一个 Session** - 避免跨多个 feature
2. **清晰的 Steps** - 每个 feature 3-5 个步骤最佳
3. **准确的依赖** - 正确设置 `depends_on`
4. **及时更新** - 状态变更立即写入
5. **E2E 配置** - 确保 E2E 命令能正确验证功能
