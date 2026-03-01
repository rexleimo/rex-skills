---
description: '双模型交叉审查（独立工具，随时可用）'
---
<!-- CCG:SPEC:REVIEW:START -->
**Core Philosophy**
- 双模型交叉审查用于降低单模型盲点。
- 审查以“规范一致性 + 风险分级”而不是主观风格偏好为核心。
- 该命令可独立执行，不强依赖归档流程。

**Guardrails**
- Codex 与 Gemini 审查都完成后才能汇总结论。
- 审查范围仅限当前 proposal/change 改动，不扩散范围。
- Critical 问题未处理前，不允许建议归档。

**OpenSkill Protocol (Mandatory)**
- 命令归一化：`/ccg:spec-review` 映射为“双模型并行审查 + 归档准入裁决”。
- 输出合同：必须输出 `Decisions / Risks / Evidence / Next`。
- Gate 规则：`Critical = 0` 才能进入归档建议。

**Steps**
1. **Select Proposal/Change**
   - `openspec list --json`
   - `openspec status --change "<proposal_id>" --json`
   - 载入 specs/tasks 与当前改动上下文。

2. **Collect Artifacts**
   - 汇总该 proposal 的改动文件、diff、约束与 PBT 属性。

3. **Parallel Dual-Model Review (Same Round)**
   - Codex 审查维度：spec compliance / pbt / logic / security / regression。
   - Gemini 审查维度：patterns / maintainability / integration / frontend security / intent alignment。
   - Gemini 调用需显式模型参数：`--gemini-model gemini-3.1-pro-preview`。
   - 两个任务都返回后统一 `TaskOutput` 汇总。

4. **Synthesize and Classify Findings**
   - 去重并分级：Critical / Warning / Info。
   - 每条发现应包含：文件、行号、问题描述、约束引用、修复建议。

5. **Decision Gate**
   - 若 `Critical > 0`：
     - 要求先修复，返回 `/ccg:spec-impl` 或当前会话内修复。
   - 若 `Critical = 0`：
     - 给出归档建议（Warning 可附带改进建议）。

6. **Optional Inline Fix Loop**
   - 用户选择立即修复时，按问题归属路由模型生成 patch 建议并复验。

7. **OpenSkill Stage Output Contract**
   ```markdown
   ### Decisions
   - Review verdict and archive eligibility decision

   ### Risks
   - Remaining warning/info items and impact

   ### Evidence
   - Dual-model findings, diff references, spec constraint checks

   ### Next
   - Back to `/ccg:spec-impl` for fixes OR proceed to archive path
   ```

**Exit Criteria**
- [ ] Codex and Gemini reviews completed
- [ ] Findings deduplicated and severity classified
- [ ] Critical issues resolved or explicitly blocked
- [ ] User decision captured

**Reference**
- `openspec status --change "<id>" --json`
- `rg -n "CONSTRAINT:|MUST|INVARIANT:" openspec/changes/<id>/specs/`
- `git diff`
<!-- CCG:SPEC:REVIEW:END -->
