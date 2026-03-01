---
description: '多模型分析 → 消除歧义 → 零决策可执行计划'
---
<!-- CCG:SPEC:PLAN:START -->
**Core Philosophy**
- 计划阶段目标是“零决策执行”：实现时不再新增关键技术决策。
- 所有歧义都要前置消除，并绑定可验证约束。
- PBT 属性用于约束实现正确性，而不仅是文档描述。

**Guardrails**
- 未清零歧义前，不得进入实现阶段。
- 多模型分析为强制项：Codex + Gemini 同轮并行。
- 计划必须可执行：每个任务都有完成定义、验证命令与依赖关系。
- 参考 `openspec/config.yaml`，遵循项目规范。

**OpenSkill Protocol (Mandatory)**
- 命令归一化：`/ccg:spec-plan` 和同义入口都映射为“约束冻结 + 任务化计划”。
- 输出合同：本阶段必须输出 `Decisions / Risks / Evidence / Next`。
- Gate 规则：`Ambiguity = 0` 且 `PBT properties complete` 才能进入 `/ccg:spec-impl`。

**Steps**
1. **Select Change and Load Context**
   - `openspec list --json`
   - `openspec status --change "<change_id>" --json`
   - 确认 proposal 是否包含明确约束与成功判据。

2. **Parallel Multi-Model Analysis (Single Round, Two Calls)**
   - 在同一轮中并行调用 Codex 与 Gemini（`run_in_background: true`）。
   - `{{WORKDIR}}` 必须为目标仓库绝对路径。

   Codex focus:
   - 实施路径
   - 技术风险
   - 边界条件

   Gemini focus:
   - 可维护性
   - 集成风险
   - 交互/前端耦合影响

   获取结果时使用双 `TaskOutput(... timeout: 600000)`，统一汇总后再推进。

3. **Ambiguity Elimination Audit**
   - Codex 输出：`[AMBIGUITY] -> [REQUIRED CONSTRAINT]`
   - Gemini 输出：`[ASSUMPTION] -> [EXPLICIT CONSTRAINT NEEDED]`
   - 与用户确认并冻结最终约束。

4. **Decision Freeze Table**
   - 为每个关键决策记录：
     - decision
     - parameter/value
     - rationale
     - rejection of alternatives

5. **Extract PBT Properties**
   - 每条关键需求至少映射一个可证伪属性：
     - invariant
     - falsification strategy
     - boundary conditions

6. **Generate / Update Artifacts**
   - specs（含 PBT）
   - design（含决策冻结表）
   - tasks（可直接执行，不留关键决策空位）

7. **Gate Evaluation**
   仅当以下全部满足，才可进入实现：
   - [ ] All ambiguities resolved
   - [ ] Decision freeze table complete
   - [ ] PBT properties complete
   - [ ] tasks are executable without new architecture decisions

8. **OpenSkill Stage Output Contract**
   ```markdown
   ### Decisions
   - Frozen constraints and technical decisions

   ### Risks
   - Residual risks with mitigation plan

   ### Evidence
   - Multi-model analysis summaries + artifact paths

   ### Next
   - If gates pass: `/ccg:spec-impl`
   - Else: return to `/ccg:spec-research` or continue planning
   ```

**Reference**
- `openspec list --json`
- `openspec status --change "<id>" --json`
- `rg -n "INVARIANT:|PROPERTY:" openspec/`
<!-- CCG:SPEC:PLAN:END -->
