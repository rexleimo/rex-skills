# 安装教程（一键模式 + 补丁模式）

本教程先给普通用户的一键安装，再给手工 `git apply` 兜底方式。

## 最快方式（推荐）

在**目标项目根目录**执行：

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash
```

脚本会自动：
- 检查目标是否为 git + spec-kit 项目（存在 `.specify/`）
- 下载补丁
- 执行 `git apply --check`
- 应用补丁
- 运行补丁后验证
- 验证失败时自动回滚

## 本地脚本模式（已 clone rex-skills）

```bash
bash /path/to/rex-skills/spec-kit-parallel-orchestrator/scripts/install.sh --repo /path/to/target-repo
```

## 常用参数

```bash
bash scripts/install.sh --repo /path/to/target --dry-run
bash scripts/install.sh --repo /path/to/target --allow-dirty
bash scripts/install.sh --repo /path/to/target --skip-verify
bash scripts/install.sh --repo /path/to/target --no-rollback
bash scripts/install.sh --repo /path/to/target --patch-file ./patches/long-running-harness.full.patch
```

## 手工方式（`git apply`）

```bash
git apply --check long-running-harness.full.patch
git apply long-running-harness.full.patch
```

## 安装后验证

```bash
bash -n .specify/scripts/bash/harness-*.sh .specify/scripts/bash/harness-lib.sh
.specify/scripts/bash/check-prerequisites.sh --json --include-tasks
```

如果项目存在 `frontend/`：

```bash
npm --prefix frontend run typecheck
npm --prefix frontend run test:e2e:smoke -- --list
```

## 卸载

一键卸载：

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/uninstall.sh | bash
```

或本地脚本：

```bash
bash /path/to/rex-skills/spec-kit-parallel-orchestrator/scripts/uninstall.sh --repo /path/to/target-repo
```

## 常见问题

1. `working tree is dirty`
- 先提交/暂存，或者加 `--allow-dirty`。

2. `target does not look like a spec-kit repo`
- 确认目标根目录包含 `.specify/`。

3. 前端 e2e 校验失败
- 先安装依赖；或使用 `--skip-verify`，后续手动补验。
