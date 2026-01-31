# AI Coding Tools Integration

This guide explains how to use the code-review skill with various AI coding assistants.

## Claude Code

Claude Code natively supports this workflow through its plugin system.

### Usage

```
/code-review [--comment]
```

### Configuration

Place in `.claude-plugin/plugin.json`:

```json
{
  "name": "code-review",
  "description": "Automated code review with multi-agent architecture",
  "version": "1.0.0"
}
```

## OpenAI Codex / ChatGPT

### System Prompt Integration

Add to your system prompt or custom instructions:

```
When asked to review code or a PR, follow this workflow:

1. Pre-check: Skip if PR is closed, draft, or trivial
2. Gather context: Collect guideline files (CLAUDE.md, .cursorrules, CONTRIBUTING.md)
3. Launch parallel analysis:
   - Guideline compliance check
   - Bug detection (diff only)
   - Context/history analysis
4. Score each issue 0-100, keep only ≥80
5. Validate high-confidence issues
6. Output in standard format

High-signal issues only:
- Syntax/type errors, missing imports
- Clear logic errors
- Explicit guideline violations

Do NOT flag: style concerns, potential issues, subjective suggestions
```

### API Usage

```python
from openai import OpenAI

client = OpenAI()

response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": CODE_REVIEW_SYSTEM_PROMPT},
        {"role": "user", "content": f"Review this PR diff:\n\n{diff_content}"}
    ]
)
```

## Cursor

### .cursorrules Configuration

Create `.cursorrules` in project root:

```
# Code Review Guidelines

When reviewing code changes:

## Review Process
1. Check guideline files: CLAUDE.md, CONTRIBUTING.md, this file
2. Focus on high-signal issues only
3. Score confidence 0-100, report only ≥80
4. Validate before reporting

## Flag These Issues
- Syntax errors, type errors, missing imports
- Unresolved references
- Clear logic errors
- Explicit guideline violations (quote the rule)

## Do NOT Flag
- Code style or quality concerns
- Potential issues depending on inputs
- Subjective suggestions
- Pre-existing issues not in this change
- Issues linters will catch

## Output Format
For each issue:
1. Brief description
2. Reason (bug/guideline/context)
3. File path and line numbers
4. Suggested fix (if simple)
```

### Cursor Chat Command

```
@codebase Review the changes in this PR. Follow the code review workflow:
1. Check for guideline compliance
2. Detect obvious bugs
3. Analyze context from git history
4. Score issues 0-100, report only high-confidence (≥80)
```

## Windsurf

### Cascade Integration

Add to your Windsurf workspace settings:

```json
{
  "cascade.customInstructions": {
    "codeReview": {
      "enabled": true,
      "workflow": [
        "Check guideline files",
        "Detect bugs in diff",
        "Analyze git context",
        "Score and filter issues"
      ],
      "confidenceThreshold": 80,
      "outputFormat": "markdown"
    }
  }
}
```

### Usage

```
/review - Review current changes
/review --pr 123 - Review specific PR
```

## Cline / Continue

### Configuration

Add to `.continue/config.json`:

```json
{
  "customCommands": [
    {
      "name": "code-review",
      "description": "Automated code review with confidence scoring",
      "prompt": "Review the following code changes using multi-agent analysis. Check for: 1) Guideline compliance 2) Obvious bugs 3) Context issues. Score each issue 0-100 and only report issues with confidence ≥80. Format: issue description, reason, file:line, suggested fix."
    }
  ]
}
```

## Aider

### Usage

```bash
# Review staged changes
aider --message "Review the staged changes for bugs and guideline compliance. Use confidence scoring (0-100) and only report issues ≥80."

# Review specific files
aider src/main.py src/utils.py --message "Code review these files..."
```

## Generic Integration Pattern

For any AI coding tool, use this prompt template:

```
You are a code review agent. Review the provided code changes following this workflow:

**Step 1: Pre-check**
- Skip if changes are trivial or already reviewed

**Step 2: Gather Context**
- Read guideline files: CLAUDE.md, .cursorrules, CONTRIBUTING.md
- Understand the intent from commit message or PR description

**Step 3: Multi-perspective Analysis**
- Guideline compliance: Check against project rules
- Bug detection: Focus on the diff, not pre-existing code
- Context analysis: Consider git history and surrounding code

**Step 4: Confidence Scoring**
Score each potential issue 0-100:
- 0: False positive
- 25: Might be real
- 50: Real but minor
- 75: Real and important
- 100: Definitely real

**Step 5: Filter and Validate**
- Keep only issues with score ≥80
- Re-verify each issue before reporting

**Step 6: Output**
Format each issue as:
1. [Description] ([Reason: guideline/bug/context])
   File: path/to/file.ext
   Lines: start-end
   [Suggested fix if applicable]

**High-signal issues only:**
✓ Syntax/type errors, missing imports, unresolved references
✓ Clear logic errors (wrong results regardless of inputs)
✓ Explicit guideline violations (quote the exact rule)

✗ Do NOT flag: style concerns, potential issues, subjective suggestions, pre-existing issues, linter-catchable issues
```
