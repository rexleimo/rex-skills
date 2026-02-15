# 使用说明（Long-Running Harness）

## 0. 快速安装

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s --
```

## 1. Harness 增加了什么

每个 feature 下新增目录 `specs/<feature-id>/harness/`：

- `feature_list.json`：功能级状态跟踪（`failing|in_progress|passing|blocked`）
- `progress.log.md`：会话时间线与进度记录
- `session_state.json`：当前会话状态、最近提交与 e2e 结果
- `init.sh`：会话启动前的基线检查脚本

## 2. 会话生命周期

### 步骤 A：初始化（每个 feature 一次）

```bash
.specify/scripts/bash/harness-init.sh --feature <feature-id> --tool codex
# 或
.specify/scripts/bash/harness-init.sh --feature <feature-id> --tool claude
```

### 步骤 B：开始会话

```bash
.specify/scripts/bash/harness-start-session.sh --feature <feature-id> --tool codex
# 或 tool claude
```

该命令会：
- 运行 `harness/init.sh`
- 选择下一项任务（`harness-pick-next.sh`）
- 将目标条目标记为 `in_progress`

### 步骤 C：实现并提交

- 做增量改动
- 保持工作区干净
- 提交 commit

### 步骤 D：结束会话（强制门禁）

```bash
.specify/scripts/bash/harness-end-session.sh --feature <feature-id> --tool codex
```

门禁检查：
- 工作区必须干净
- 会话开始后必须有新 commit
- e2e 验证必须通过

通过后，当前条目会升级为 `passing`。

## 3. E2E 门禁策略

### 前端项目

`harness-verify-e2e.sh` 默认执行：

```bash
npm --prefix frontend run test:e2e:smoke
```

### 非前端项目

通过环境变量指定自定义门禁命令：

```bash
HARNESS_E2E_CMD='go test ./... -run Smoke' \
.specify/scripts/bash/harness-end-session.sh --feature <feature-id> --tool codex
```

## 4. Spec Kit 命令接入

### Codex CLI

- `/prompts:speckit.plan`
- `/prompts:speckit.tasks`
- `/prompts:speckit.implement`

### Claude Code

- `/speckit.plan`
- `/speckit.tasks`
- `/speckit.implement`

应用补丁后，上述命令会自动携带 harness 生命周期步骤。

## 5. 常见失败与处理

1. `No new commit detected`
- 先提交代码，再重试 `harness-end-session.sh`。

2. `Working tree is dirty`
- 先清理或提交工作区，再结束会话。

3. `No e2e command configured`
- 增加前端 smoke 脚本，或设置 `HARNESS_E2E_CMD`。
