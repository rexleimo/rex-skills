# OpenSpec Long-Running Agent Harness

基于 Anthropic 的 "Effective Harnesses for Long-Running Agents" 文章，结合 OpenSpec 规范的长时运行 Agent 工作流框架。

## 解决什么问题？

当你需要 Agent 完成一个大型项目（跨越多个会话/context window）时：

| 问题 | Harness 解决方案 |
|------|------------------|
| Agent 每次会话没有之前的记忆 | 通过文件持久化状态 |
| 不知道上次做到哪了 | `progress.log.md` 记录历史 |
| 不知道接下来做什么 | `feature_list.json` 管理任务队列 |
| 无法验证功能是否完成 | Gate Enforcement + E2E 测试 |
| 中途失败不知道怎么恢复 | 状态机 + 优先恢复 failed 任务 |

---

## 使用方式

### 方式一：作为 Claude Code Skill 使用（推荐）

1. **将此 skill 链接到 Claude Code**
   ```bash
   # 确保 rex-skills 目录被 Claude Code 识别
   # 在 ~/.claude/settings.json 中配置 skills 路径
   ```

2. **在项目中初始化 harness**
   ```bash
   cd /path/to/your/project
   /path/to/openspec-long-running-harness/scripts/harness-init.sh "项目名称"
   ```

3. **编辑 feature_list.json 定义任务**
   ```bash
   vim openspec/harness/feature_list.json
   ```

4. **告诉 Claude 开始实现**
   ```
   请使用 openspec-long-running-harness skill 帮我实现项目。
   运行 harness-start.sh 开始第一个任务。
   ```

5. **Claude 会自动：**
   - 读取 `progress.log.md` 了解历史
   - 从 `feature_list.json` 选择下一个任务
   - 运行 `init.sh` 检查环境
   - 实现功能
   - 结束时运行 Gate Enforcement
   - 更新状态文件

### 方式二：作为独立脚本使用

适合手动管理或与其他工具集成。

#### Step 1: 初始化

```bash
cd /path/to/your/project

# 确保是 git 仓库
git init

# 初始化 harness
/path/to/openspec-long-running-harness/scripts/harness-init.sh "my-project"
```

创建的文件：
```
openspec/harness/
├── feature_list.json     # 任务清单
├── progress.log.md       # 会话历史
├── session_state.json    # 当前状态
├── init.sh               # 环境检查
└── .harness-config.json  # 配置
```

#### Step 2: 定义 Features

编辑 `openspec/harness/feature_list.json`：

```json
{
  "project": "my-project",
  "features": [
    {
      "id": "F001",
      "category": "functional",
      "priority": "P1",
      "description": "实现用户认证功能",
      "steps": [
        "创建登录表单组件",
        "添加 /api/login 端点",
        "实现 JWT session 管理"
      ],
      "status": "pending",
      "depends_on": []
    },
    {
      "id": "F002",
      "category": "api",
      "priority": "P1",
      "description": "实现用户 CRUD API",
      "steps": [
        "GET /api/users",
        "POST /api/users",
        "PUT /api/users/:id",
        "DELETE /api/users/:id"
      ],
      "status": "pending",
      "depends_on": ["F001"]
    },
    {
      "id": "F003",
      "category": "ui",
      "priority": "P2",
      "description": "用户管理界面",
      "steps": ["用户列表页", "用户详情页", "编辑表单"],
      "status": "pending",
      "depends_on": ["F002"]
    }
  ]
}
```

#### Step 3: 配置 E2E 测试命令

编辑 `openspec/harness/.harness-config.json`：

```json
{
  "e2e_command": "npm test",
  "e2e_timeout": 300,
  "require_clean_tree": true
}
```

#### Step 4: 配置环境检查

编辑 `openspec/harness/init.sh`，添加项目特定的检查：

```bash
#!/bin/bash
set -euo pipefail

echo "=== Environment Check ==="

# 检查 Node.js
command -v node >/dev/null || { echo "需要 Node.js"; exit 1; }

# 检查依赖
[ -d "node_modules" ] || { echo "运行 npm install"; exit 1; }

# 检查环境变量
[ -n "$DATABASE_URL" ] || { echo "设置 DATABASE_URL"; exit 1; }

echo "=== Environment OK ==="
```

#### Step 5: 开始实现

```bash
# 查看当前状态
./scripts/harness-status.sh

# 开始新会话（选择下一个任务）
./scripts/harness-start.sh

# 手动提交进度
./scripts/harness-commit.sh "feat(F001): 实现登录表单"

# 结束会话（运行 Gate Enforcement）
./scripts/harness-end.sh
```

---

## 完整工作流示例

### 场景：实现一个博客系统

```bash
# 1. 初始化
cd ~/projects/my-blog
/path/to/openspec-long-running-harness/scripts/harness-init.sh "my-blog"

# 2. 定义 features（手动编辑）
cat > openspec/harness/feature_list.json << 'EOF'
{
  "project": "my-blog",
  "features": [
    {"id": "F001", "priority": "P1", "description": "文章数据模型", "steps": ["schema", "migration", "model"], "status": "pending"},
    {"id": "F002", "priority": "P1", "description": "文章 CRUD API", "steps": ["list", "create", "update", "delete"], "status": "pending", "depends_on": ["F001"]},
    {"id": "F003", "priority": "P2", "description": "文章列表页", "steps": ["组件", "分页", "筛选"], "status": "pending", "depends_on": ["F002"]},
    {"id": "F004", "priority": "P2", "description": "文章编辑器", "steps": ["Markdown", "预览", "保存"], "status": "pending", "depends_on": ["F002"]},
    {"id": "F005", "priority": "P3", "description": "评论功能", "steps": ["模型", "API", "UI"], "status": "pending", "depends_on": ["F003"]}
  ]
}
EOF

# 3. 配置 E2E
echo '{"e2e_command": "npm test", "e2e_timeout": 120}' > openspec/harness/.harness-config.json

# 4. 开始第一个会话
./scripts/harness-start.sh
# 输出: Session 1 Started - F001 文章数据模型

# 5. 实现 F001（手动或让 Agent 实现）
# ... 编写代码 ...

# 6. 提交进度
./scripts/harness-commit.sh "feat(F001): add article model and migration"

# 7. 结束会话
./scripts/harness-end.sh
# Gate 1: ✓ Working tree clean
# Gate 2: ✓ New commit created
# Gate 3: ✓ E2E passed
# Status: passing

# 8. 继续下一个
./scripts/harness-start.sh
# 输出: Session 2 Started - F002 文章 CRUD API（因为 F002 depends_on F001 已完成）
```

---

## 给 Agent 的 Prompt 模板

如果你想让 Claude/Codex 等 Agent 使用这个 harness，可以这样提示：

```
你正在使用 OpenSpec Long-Running Harness 工作流。

## 会话开始例行
1. 运行 pwd 确认目录
2. 读取 openspec/harness/progress.log.md 了解历史
3. 读取 openspec/harness/feature_list.json 选择下一个任务
4. 运行 openspec/harness/init.sh 检查环境
5. 更新 openspec/harness/session_state.json

## 执行规则
- 每个会话只处理一个 feature
- 支持并行执行 3-6 个独立子任务
- 有依赖的任务必须串行
- 只能修改 feature 的 status，不能修改定义

## 会话结束例行（Gate Enforcement）
1. git status 确认工作区干净
2. 确认有新 commit
3. 运行 E2E 测试
4. 更新 feature 状态为 passing/failed
5. 写会话摘要到 progress.log.md

现在开始执行。
```

---

## 状态机

```
pending → in_progress → verifying → passing
               ↓              ↓
           blocked  ←   failed
```

| 状态 | 触发条件 |
|------|----------|
| `pending` | 初始状态 |
| `in_progress` | `harness-start.sh` 选择任务 |
| `verifying` | `harness-end.sh` 开始验证 |
| `passing` | 所有 Gate 通过 |
| `failed` | E2E 测试失败 |
| `blocked` | 依赖未完成或环境检查失败 |

---

## Gate Enforcement

每个会话结束前必须通过三道门：

| Gate | 检查 | 失败处理 |
|------|------|----------|
| 1. Working Tree Clean | `git status` 无更改 | 提示提交或丢弃更改 |
| 2. New Commit Exists | 有新 commit 相对会话开始 | 提示创建 commit |
| 3. E2E Passed | 运行配置的测试命令 | 标记为 failed，保持更改供调试 |

---

## 脚本参考

| 脚本 | 用途 | 使用时机 |
|------|------|----------|
| `harness-init.sh` | 初始化 harness 目录 | 项目开始时 |
| `harness-status.sh` | 查看状态 | 随时 |
| `harness-start.sh` | 开始新会话 | 实现 feature 前 |
| `harness-pick-next.sh` | 选择下一个任务 | 被 harness-start.sh 调用 |
| `harness-commit.sh` | 提交并记录 | 完成阶段性工作后 |
| `harness-end.sh` | 结束会话 | feature 实现完成后 |
| `harness-verify-e2e.sh` | 运行 E2E 测试 | 被 harness-end.sh 调用 |

---

## 常见问题

### Q: 如何跳过某个 feature？

直接编辑 `feature_list.json`，将其 status 改为 `blocked`，并添加 `blocked_reason`。

### Q: 如何重新实现已完成的 feature？

将 status 从 `passing` 改回 `pending`，清空 `commits` 数组。

### Q: E2E 测试一直失败怎么办？

1. 手动运行测试命令排查问题
2. 修复后重新运行 `harness-end.sh`
3. 或者手动标记为 `passing`（不推荐）

### Q: 如何查看历史会话？

```bash
cat openspec/harness/progress.log.md
```

---

## 参考

- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [OpenSpec Parallel Agents](../openspec-parallel-agents/SKILL.md)
