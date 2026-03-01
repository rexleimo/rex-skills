---
description: '需求 → 约束集（并行探索 + OPSX 提案）'
---
<!-- CCG:SPEC:RESEARCH:START -->
**Core Philosophy**
- 研究阶段只产出“约束集”，不产出实现方案。
- 每条约束都要缩小后续决策空间，避免实现阶段自由发挥。
- 产物必须可验证：约束、风险、成功判据都能落到后续计划与测试。

**Guardrails**
- 第一步必须先做 Prompt Enhancement，禁止跳过。
- 子任务拆分按上下文边界，不按角色头衔拆分。
- 并行探索输出必须结构化，便于后续自动汇总。
- 出现关键歧义必须向用户确认，不能猜测补全。

**OpenSkill Protocol (Mandatory)**
- 命令归一化：`/ccg:spec-research`、`/opsx:explore`、相关旧入口统一映射到“约束发现”语义。
- 输出合同：本阶段必须输出 `Decisions / Risks / Evidence / Next`。
- Gate 规则：若存在未解决关键歧义，禁止进入 `/ccg:spec-plan`。

**Steps**
0. **Enhance Requirement (Mandatory)**
   - 对 `$ARGUMENTS` 进行增强：补全目标、边界、约束、验收标准。
   - 后续所有分析均使用增强版需求。

1. **Select or Create Change**
   - 列出现有变更：
     ```bash
     openspec list --json
     ```
   - 若不存在对应 change，创建：
     ```bash
     openspec new change "<brief-descriptive-name>"
     ```
   - 记录本轮 `change_id`。

2. **Codebase Baseline Scan**
   - 使用 `{{MCP_SEARCH_TOOL}}` 与必要的 `rg` 扫描相关模块。
   - 判断是否为多目录/多模块场景，并确定是否启用并行探索。

3. **Define Context Boundaries for Parallel Exploration**
   - 依据文件/模块边界切分 3-6 个探索任务。
   - 每个任务必须独立可完成，避免跨任务强依赖。

4. **Run Parallel Exploration (Codex + Gemini)**
   - 后端/逻辑边界优先交给 Codex；前端/交互边界优先交给 Gemini。
   - 统一输出模板：
   ```json
   {
     "module_name": "context boundary",
     "constraints_discovered": ["hard/soft constraints"],
     "dependencies": ["cross-module dependencies"],
     "risks": ["blockers"],
     "open_questions": ["needs user decision"],
     "success_criteria_hints": ["observable outcomes"]
   }
   ```

5. **Synthesize Constraint Set**
   - 汇总为：硬约束、软约束、依赖关系、风险列表。
   - 去重并明确优先级（P0/P1/P2）。

6. **Resolve Ambiguities with User**
   - 把未决问题按优先级发给用户确认。
   - 用户决策回填为新增约束（带来源）。

7. **Update Proposal Artifacts**
   - 将约束集写入 proposal：
     - Context
     - Requirements (constraint-driven)
     - Success Criteria
     - Risks + Mitigation

8. **OpenSkill Stage Output Contract**
   ```markdown
   ### Decisions
   - Confirmed constraints and scope boundaries

   ### Risks
   - Remaining blockers and dependency risks

   ### Evidence
   - `openspec` command outputs + key codebase findings

   ### Next
   - If no critical ambiguity: `/ccg:spec-plan`
   - If unresolved ambiguity remains: continue research clarification
   ```

**Reference**
- `openspec list --json`
- `openspec status --change "<id>" --json`
- `ls openspec/changes/*/`
<!-- CCG:SPEC:RESEARCH:END -->
