# CCG Workflow OpenSkill Optimization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Pull upstream `ccg-workflow` and deliver an optimized OpenSkill-compatible workflow package aligned with this repository's skill protocol.

**Architecture:** Keep upstream command semantics, but normalize them into OpenSkill phases with explicit gate checks and deterministic routing rules. Package the result as a reusable skill (`SKILL.md + references`) instead of ad-hoc command prose.

**Tech Stack:** Markdown, OpenSkill frontmatter protocol, local validation script.

### Task 1: Baseline Analysis and Gap Capture

**Files:**
- Read: `/Users/molei/codes/rex-skills/tmp/ccg-workflow-main/README.md`
- Read: `/Users/molei/codes/rex-skills/tmp/ccg-workflow-main/templates/commands/workflow.md`
- Read: `/Users/molei/codes/rex-skills/tmp/ccg-workflow-main/templates/commands/spec-plan.md`
- Read: `/Users/molei/codes/rex-skills/tmp/ccg-workflow-main/templates/commands/spec-impl.md`

**Step 1: Identify protocol mismatches**
- Confirm missing or weak OpenSkill trigger semantics.
- Confirm command-to-phase mapping is not centralized.

**Step 2: Define optimization target**
- Preserve CCG phases and model routing.
- Enforce OpenSkill guardrails, checklists, and command normalization.

### Task 2: Create Optimized OpenSkill Package

**Files:**
- Create: `/Users/molei/codes/rex-skills/ccg-workflow-openskill/SKILL.md`
- Create: `/Users/molei/codes/rex-skills/ccg-workflow-openskill/references/ccg-command-mapping.md`
- Create: `/Users/molei/codes/rex-skills/ccg-workflow-openskill/references/phase-checklists.md`

**Step 1: Write SKILL frontmatter and core workflow**
- Add concise trigger-rich `description`.
- Define orchestrator loop and gate rules.

**Step 2: Extract heavy tables into references**
- Keep `SKILL.md` lean.
- Store detailed command matrix and phase checklists in references.

### Task 3: Validate and Report

**Files:**
- Read/Validate: `/Users/molei/codes/rex-skills/ccg-workflow-openskill/SKILL.md`

**Step 1: Run validator**
Run:
```bash
python3 /Users/molei/.codex/skills/.system/skill-creator/scripts/quick_validate.py /Users/molei/codes/rex-skills/ccg-workflow-openskill
```
Expected: validation passes.

**Step 2: Summarize optimization**
- Document what was improved versus upstream workflow.
- Provide file references and next integration options.
