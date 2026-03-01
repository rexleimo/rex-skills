---
description: '初始化 OpenSpec (OPSX) 环境 + 验证多模型 MCP 工具'
---
<!-- CCG:SPEC:INIT:START -->
**Core Philosophy**
- OPSX 提供规范骨架，CCG 提供多模型协同执行能力。
- 初始化阶段的目标是提前发现阻塞项，避免在执行中途失败。
- 工具状态必须可验证，不接受“看起来可用”。

**Guardrails**
- `openspec` 是唯一 CLI 命令名；`/opsx:*` 是斜杠命令别名，不可混淆。
- 每个检查步骤失败时必须立即给出修复建议并停止后续依赖步骤。
- 不覆盖用户已有配置，涉及改写时必须明确说明。
- 工作目录必须是目标项目绝对路径（`{{WORKDIR}}`）。

**OpenSkill Protocol (Mandatory)**
- 命令归一化：用户入口统一映射为 `/ccg:spec-init` 初始化语义。
- 输出合同：本阶段必须输出 `Decisions / Risks / Evidence / Next` 四段。
- Gate 规则：若 `OpenSpec CLI` 或 `Project Initialized` 失败，禁止进入 `/ccg:spec-research`。

**Steps**
1. **Normalize Workspace + OS Detection**
   - 确认目标工作目录并回显：`{{WORKDIR}}`。
   - 识别 OS（Unix: `uname -s`；Windows: 环境变量）。

2. **Check / Install OpenSpec CLI**
   - 先检查：
     ```bash
     npx @fission-ai/openspec --version
     ```
   - 如果未安装，执行：
     ```bash
     npm install -g @fission-ai/openspec@latest
     ```
   - 再验证：
     ```bash
     openspec --version
     ```
   - 若全局命令不可用，保留 `npx @fission-ai/openspec` 作为 fallback。

3. **Initialize OpenSpec Project State**
   - 检查是否已初始化：
     ```bash
     ls -la openspec/ .claude/skills/openspec-* 2>/dev/null || echo "Not initialized"
     ```
   - 若未初始化，执行：
     ```bash
     npx @fission-ai/openspec init --tools claude
     ```
   - 验证目录与命令模板是否生成：
     - `openspec/`
     - `.claude/skills/openspec-*`
     - `.claude/commands/opsx/`

4. **Validate codeagent-wrapper and Model Backends**
   - wrapper 版本检查：
     ```bash
     ~/.claude/bin/codeagent-wrapper --version
     ```
   - Codex backend smoke test：
     ```bash
     ~/.claude/bin/codeagent-wrapper --backend codex - "{{WORKDIR}}" <<< "echo test"
     ```
   - Gemini backend smoke test：
     ```bash
     ~/.claude/bin/codeagent-wrapper --backend gemini --gemini-model gemini-3.1-pro-preview - "{{WORKDIR}}" <<< "echo test"
     ```

5. **Validate Retrieval MCP (Optional but Recommended)**
   - 检查当前会话是否可用：`{{MCP_SEARCH_TOOL}}`。
   - 检查配置文件（`~/.claude.json` 或 Windows 对应路径）是否有相关 `mcpServers`。
   - 标记状态：`Active / Configured but inactive / Not installed`。

6. **Emit Gate Summary (Must Be Explicit)**
   输出状态表：
   ```
   Component                 Status
   ─────────────────────────────────
   OpenSpec CLI             ✓/✗
   Project Initialized      ✓/✗
   OPSX Skills/Commands     ✓/✗
   codeagent-wrapper        ✓/✗
   Codex Backend            ✓/✗
   Gemini Backend           ✓/✗
   Retrieval MCP (optional) ✓/✗/○
   ```

7. **OpenSkill Stage Output Contract**
   ```markdown
   ### Decisions
   - CLI command normalization confirmed (`openspec`)

   ### Risks
   - Missing components and remediation steps

   ### Evidence
   - Key command outputs and paths checked

   ### Next
   - If all critical gates pass: `/ccg:spec-research "<需求描述>"`
   - If gate fails: stop and resolve blockers first
   ```

**Reference**
- OpenSpec CLI help: `npx @fission-ai/openspec --help`
- CCG Workflow: `npx ccg-workflow`
- OPSX slash commands: `/opsx:new`, `/opsx:continue`, `/opsx:apply`
<!-- CCG:SPEC:INIT:END -->
