#!/usr/bin/env python3
"""
Implementation Plan Generator

Generate a structured implementation plan from requirements.
Outputs a markdown plan file ready for user approval.

Usage:
    python generate_plan.py --task "Implement user login" --type feature --output plan.md
    python generate_plan.py --task "Fix date formatting bug" --type bugfix --output plan.md
    python generate_plan.py --file requirements.txt --type feature --output plan.md
"""

import argparse
import json
import sys
from datetime import datetime
from typing import Optional


PLAN_TEMPLATES = {
    "feature": """# Implementation Plan: {task_name}

**Created**: {timestamp}
**Type**: Feature Development
**Status**: Pending Approval

---

## 1. Overview

**Goal**: {task_description}

**Scope**:
- In scope: {in_scope}
- Out of scope: Infrastructure changes, CI/CD modifications

## 2. Technical Approach

### Architecture Decision
[Describe the chosen approach and rationale]

### Key Design Choices
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision 1] | [Choice] | [Why] |
| [Decision 2] | [Choice] | [Why] |

## 3. File Changes

| File | Action | Description |
|------|--------|-------------|
| [path/to/file] | Create/Modify | [What changes] |

## 4. Implementation Steps

### Step 1: [Setup/Foundation]
- [ ] [Specific task]
- [ ] [Specific task]

### Step 2: [Core Implementation]
- [ ] [Specific task]
- [ ] [Specific task]

### Step 3: [Integration]
- [ ] [Specific task]
- [ ] [Specific task]

### Step 4: [Testing]
- [ ] [Specific task]
- [ ] [Specific task]

## 5. Acceptance Criteria

- [ ] Feature works as described
- [ ] No regressions in existing functionality
- [ ] Code passes linting and type checks
- [ ] Tests cover happy path and error cases
- [ ] Responsive design verified (if UI)
- [ ] Accessibility checked (if UI)

## 6. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk 1] | [High/Medium/Low] | [How to mitigate] |

---

**Approve this plan? (Y/N/Modify)**
""",

    "bugfix": """# Fix Plan: {task_name}

**Created**: {timestamp}
**Type**: Bug Fix
**Status**: Pending Approval

---

## 1. Problem Description

**Bug**: {task_description}

**Symptoms**:
- [Observable issue 1]
- [Observable issue 2]

**Reproduction Steps**:
1. [Step 1]
2. [Step 2]

## 2. Root Cause Analysis

**Probable Cause**: [Description]
**Evidence**: [Supporting data]
**Confidence**: [High/Medium/Low]

## 3. Fix Approach

### Strategy
[Describe the fix approach]

### File Changes

| File | Action | Description |
|------|--------|-------------|
| [path/to/file] | Modify | [What changes] |

## 4. Implementation Steps

- [ ] [Fix step 1]
- [ ] [Fix step 2]
- [ ] [Add regression test]
- [ ] [Verify fix]

## 5. Verification

- [ ] Bug no longer reproducible
- [ ] Regression test passes
- [ ] No side effects on related functionality
- [ ] Existing tests still pass

## 6. Side Effect Assessment

| Area | Risk | Check |
|------|------|-------|
| [Related feature] | [Low/Medium/High] | [How to verify] |

---

**Approve this fix plan? (Y/N/Modify)**
""",

    "refactor": """# Refactoring Plan: {task_name}

**Created**: {timestamp}
**Type**: Refactoring
**Status**: Pending Approval

---

## 1. Motivation

**Why refactor**: {task_description}

**Current Issues**:
- [Issue 1]
- [Issue 2]

## 2. Approach

### Before
[Current structure/pattern]

### After
[Target structure/pattern]

### Key Changes

| Change | Before | After | Rationale |
|--------|--------|-------|-----------|
| [Change 1] | [Old] | [New] | [Why] |

## 3. File Changes

| File | Action | Description |
|------|--------|-------------|
| [path/to/file] | Modify/Move/Delete | [What changes] |

## 4. Migration Steps

- [ ] [Step 1 - safe, reversible]
- [ ] [Step 2]
- [ ] [Step 3]
- [ ] [Update tests]
- [ ] [Verify behavior unchanged]

## 5. Verification

- [ ] All existing tests pass (behavior unchanged)
- [ ] No new warnings or errors
- [ ] Performance not degraded
- [ ] Code metrics improved (complexity, duplication)

---

**Approve this refactoring plan? (Y/N/Modify)**
""",
}


def generate_plan(
    task: str,
    plan_type: str = "feature",
    output: Optional[str] = None,
) -> str:
    """Generate a structured implementation plan."""

    template = PLAN_TEMPLATES.get(plan_type, PLAN_TEMPLATES["feature"])

    # Extract task name (first line or first N words)
    task_name = task.strip().split("\n")[0][:80]

    plan = template.format(
        task_name=task_name,
        task_description=task.strip(),
        timestamp=datetime.now().strftime("%Y-%m-%d %H:%M"),
        in_scope=task_name,
    )

    if output:
        with open(output, "w") as f:
            f.write(plan)
        print(f"Plan written to: {output}")
    else:
        print(plan)

    return plan


def main():
    parser = argparse.ArgumentParser(description="Generate structured implementation plans")
    parser.add_argument("--task", type=str, help="Task description")
    parser.add_argument("--file", type=str, help="File containing task description")
    parser.add_argument(
        "--type",
        choices=["feature", "bugfix", "refactor"],
        default="feature",
        help="Plan type",
    )
    parser.add_argument("--output", type=str, help="Output file path")
    parser.add_argument("--list-types", action="store_true", help="List available plan types")

    args = parser.parse_args()

    if args.list_types:
        print("Available plan types:")
        for t in PLAN_TEMPLATES:
            print(f"  - {t}")
        return

    if args.task:
        task = args.task
    elif args.file:
        with open(args.file) as f:
            task = f.read()
    else:
        print("Error: Provide --task or --file", file=sys.stderr)
        sys.exit(1)

    generate_plan(task, args.type, args.output)


if __name__ == "__main__":
    main()
