# Spec Kit Parallel Orchestrator

Parallel orchestration skill for Spec Kit workflows. This skill now ships with a **patch-based long-running harness** so other projects can adopt the same multi-session execution pattern (`initializer + incremental sessions + commit/e2e gate`).

## Features

- Parallel decomposition (3-6 sub-tasks) with dependency-safe execution.
- Stage-aware semantics aligned with Spec Kit (`constitution -> specify -> clarify -> plan -> tasks -> implement`).
- Patch-based distribution for cross-project adoption.
- Long-running harness contract:
  - `harness/feature_list.json`
  - `harness/progress.log.md`
  - `harness/session_state.json`
  - `harness/init.sh`

## Install Skill

```bash
npx skills add https://github.com/rexleimo/rex-skills/tree/main/spec-kit-parallel-orchestrator
```

## Install Patch (for your own project)

Recommended one-command installer:

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s --
```

You can also run from anywhere and pin target repo:

```bash
curl -fsSL https://raw.githubusercontent.com/rexleimo/rex-skills/main/spec-kit-parallel-orchestrator/scripts/install.sh | bash -s -- --repo /path/to/your/project
```

Local installer (from this repo checkout):

```bash
bash ./scripts/install.sh --repo /path/to/your/project
```

Advanced/manual mode (`git apply`) from your target project root:

```bash
git apply --check path/to/long-running-harness.full.patch
git apply path/to/long-running-harness.full.patch
```

Detailed guide:
- English: [`INSTALL.md`](./INSTALL.md)
- 简体中文: [`INSTALL_zh.md`](./INSTALL_zh.md)

## Usage

Detailed operational guide:
- English: [`USAGE.md`](./USAGE.md)
- 简体中文: [`USAGE_zh.md`](./USAGE_zh.md)

## Patch Bundle

- Patch file: [`patches/long-running-harness.full.patch`](./patches/long-running-harness.full.patch)
- Manifest: [`patches/manifests/long-running-harness.full.manifest.json`](./patches/manifests/long-running-harness.full.manifest.json)
- One-click scripts:
  - [`scripts/install.sh`](./scripts/install.sh)
  - [`scripts/uninstall.sh`](./scripts/uninstall.sh)
  - [`scripts/make-patch.sh`](./scripts/make-patch.sh)
- Tree examples:
  - [`patches/examples/target-tree.before.txt`](./patches/examples/target-tree.before.txt)
  - [`patches/examples/target-tree.after.txt`](./patches/examples/target-tree.after.txt)
