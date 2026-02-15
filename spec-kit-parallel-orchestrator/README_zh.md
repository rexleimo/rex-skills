# Spec Kit 并行编排器

这是一个用于 Spec Kit 工作流并行编排的技能。现在额外提供了**补丁化长时运行 harness**，可以让其他项目也复用同一套多轮会话执行模式（`initializer + 增量会话 + commit/e2e 门禁`）。

## 功能特性

- 3-6 子任务并行拆分，并保持依赖安全。
- 与 Spec Kit 阶段语义对齐（`constitution -> specify -> clarify -> plan -> tasks -> implement`）。
- 支持 `git apply` 的跨项目补丁分发。
- 内置长时运行文件契约：
  - `harness/feature_list.json`
  - `harness/progress.log.md`
  - `harness/session_state.json`
  - `harness/init.sh`

## 安装技能

```bash
npx skills add https://github.com/rexleimo/rex-skills/tree/main/spec-kit-parallel-orchestrator
```

## 安装补丁（给你的项目打补丁）

推荐一键安装（最简单）：

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s --
```

安装器行为：
- 优先尝试 `full` 模式（应用完整补丁）
- 若目标仓库存在版本漂移，自动降级到 `core` 模式（仅安装 harness 脚本）

如果不在目标仓库目录，可显式指定：

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s -- --repo /path/to/your/project
```

本地脚本安装（你已 clone rex-skills）：

```bash
bash ./scripts/install.sh --repo /path/to/your/project
```

高级/手工方式（`git apply`）：

```bash
git apply --check path/to/long-running-harness.full.patch
git apply path/to/long-running-harness.full.patch
```

详细安装文档：
- 中文：[`INSTALL_zh.md`](./INSTALL_zh.md)
- English: [`INSTALL.md`](./INSTALL.md)

## 使用说明

详细使用文档：
- 中文：[`USAGE_zh.md`](./USAGE_zh.md)
- English: [`USAGE.md`](./USAGE.md)

## 补丁包内容

- 补丁文件：[`patches/long-running-harness.full.patch`](./patches/long-running-harness.full.patch)
- 清单文件：[`patches/manifests/long-running-harness.full.manifest.json`](./patches/manifests/long-running-harness.full.manifest.json)
- 一键脚本：
  - [`scripts/install.sh`](./scripts/install.sh)
  - [`scripts/uninstall.sh`](./scripts/uninstall.sh)
  - [`scripts/make-patch.sh`](./scripts/make-patch.sh)
- 目录变更示例：
  - [`patches/examples/target-tree.before.txt`](./patches/examples/target-tree.before.txt)
  - [`patches/examples/target-tree.after.txt`](./patches/examples/target-tree.after.txt)
