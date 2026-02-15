# 安装教程（一键模式 + 补丁模式）

本教程先给普通用户的一键安装，再给手工 `git apply` 兜底方式。

## 最快方式（推荐）

在**目标仓库内**执行（根目录或任意子目录都可以）：

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s --
```

脚本会自动：
- 检查目标是否为 git + spec-kit 项目（存在 `.specify/`）
- 下载补丁
- 先按 `full` 模式执行 `git apply --check`
- 若 `full` 不兼容，自动降级到 `core` 模式（仅安装 harness 脚本）
- 应用补丁
- 以 best-effort 方式为 speckit prompts（`.codex`/`.claude`）追加 harness 指南
- 安装/更新 `.codex/skills/spec-kit-parallel-orchestrator` skill 目录
- 运行补丁后验证
- 验证失败时自动回滚
- 自动识别 git 根目录（在子目录执行也可用）
- 若补丁已安装，也会继续同步 skill/prompts（幂等）

如果你不在目标仓库目录，可显式指定路径：

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s -- --repo /path/to/target-repo
```

## 本地脚本模式（已 clone rex-skills）

```bash
bash /path/to/rex-skills/spec-kit-parallel-orchestrator/scripts/install.sh --repo /path/to/target-repo
```

## 常用参数

```bash
bash scripts/install.sh --repo /path/to/target --dry-run
bash scripts/install.sh --repo /path/to/target --allow-dirty
bash scripts/install.sh --repo /path/to/target --skip-verify
bash scripts/install.sh --repo /path/to/target --skip-skill
bash scripts/install.sh --repo /path/to/target --skip-prompts
bash scripts/install.sh --repo /path/to/target --skill-ref main
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
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/uninstall.sh | bash -s --
```

或本地脚本：

```bash
bash /path/to/rex-skills/spec-kit-parallel-orchestrator/scripts/uninstall.sh --repo /path/to/target-repo
```

## 常见问题

1. `working tree is dirty`
- 先提交/暂存，或者加 `--allow-dirty`。

2. `target does not look like a spec-kit repo`
- 确认目标仓库包含 `.specify/`。
- 如果当前不在目标仓库内，请使用 `--repo /path/to/target-repo`。

3. 前端 e2e 校验失败
- 先安装依赖；或使用 `--skip-verify`，后续手动补验。

4. 安装日志出现 `mode: core`
- 这是预期行为，常见于目标仓库对 spec-kit 模板/提示词或前端 lockfile 做过定制。
- `core` 模式仅安装 harness 脚本，不修改模板、提示词和前端 package 相关文件。
- 可通过 `HARNESS_E2E_CMD` 指定你自己的门禁命令，例如：
  - `HARNESS_E2E_CMD="npm --prefix frontend run test:unit" .specify/scripts/bash/harness-end-session.sh --feature 001-my-feature`

5. 只想打补丁，不安装 skill/prompts
- 加上 `--skip-skill --skip-prompts`。
