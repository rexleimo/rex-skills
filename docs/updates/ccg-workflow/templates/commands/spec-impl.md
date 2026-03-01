---
description: '按规范执行 + 多模型协作 + 归档'
---
<!-- CCG:SPEC:IMPL:START -->
**Core Philosophy**
- 实现阶段是机械执行阶段：关键决策已在 Plan 阶段冻结。
- 外部模型仅产出建议 patch，最终代码由主代理审查并落盘。
- 以最小可验证增量推进，防止一次性大改导致回归失控。

**Guardrails**
- 禁止直接应用外部模型 patch，必须重写/审校后再应用。
- 仅允许 `tasks` 范围内改动，超范围改动需回到 `spec-plan`。
- 每个实现批次必须有验证证据（测试/命令输出）。
- 保持 side-effect review：不破坏无关模块和公开接口。

**OpenSkill Protocol (Mandatory)**
- 命令归一化：`/ccg:spec-impl` 映射为“按已冻结计划实施 + Gate 验证 + 归档准备”。
- 输出合同：每个批次和阶段结尾都输出 `Decisions / Risks / Evidence / Next`。
- Gate 规则：存在 Critical 审查问题或验证失败时，禁止归档。

**Steps**
1. **Select Change and Load Tasks**
   - `openspec list --json`
   - `openspec status --change "<change_id>" --json`
   - 读取 tasks，确认本轮目标批次。

2. **Define Minimal Verifiable Batch**
   - 从 tasks 中选取最小可验证子集（不要一次做完整变更）。
   - 声明本轮范围：`Batch X: <task ids>`。

3. **Route Batch Tasks to Models (Prototype Only)**
   - 前端/UI 任务优先 Gemini。
   - 后端/逻辑任务优先 Codex。
   - 输出必须是 `Unified Diff Patch`。

4. **Rewrite and Apply as Production Code**
   - 对 patch 进行重写与项目风格对齐。
   - 确认无冗余、无不必要依赖、命名清晰。

5. **Mandatory Side-Effect Review**
   - [ ] 不超出 tasks 范围
   - [ ] 不影响无关模块
   - [ ] 不引入未批准新依赖
   - [ ] 不破坏现有接口

6. **Parallel Multi-Model Review (Codex + Gemini)**
   - 同一轮并行双调用，不可串行等待后再发第二个。
   - 双 `TaskOutput(... timeout: 600000)` 后统一汇总。
   - Critical 问题必须先修复。

7. **Update Task Progress and Run Verification**
   - 在 tasks 中标记已完成项。
   - 运行对应测试/验证命令，记录结果。

8. **Context Checkpoint**
   - 如上下文接近上限，建议 `/clear` 后继续 `/ccg:spec-impl`。

9. **Archive Only When All Gates Pass**
   - 仅当 tasks 全部完成 + 验证通过 + Critical=0 时执行归档。

10. **OpenSkill Stage Output Contract**
   ```markdown
   ### Decisions
   - Batch scope and applied implementation choices

   ### Risks
   - Remaining warnings or deferred non-critical items

   ### Evidence
   - Diff/test/review outputs and updated task status

   ### Next
   - Continue next batch or archive when all gates pass
   ```

**Reference**
- `openspec status --change "<id>" --json`
- `openspec list --json`
- `rg -n "function|class" <file>`
<!-- CCG:SPEC:IMPL:END -->
