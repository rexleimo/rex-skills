# Anthropic 1P Prompt Optimizer

[中文版 (Chinese Version)](README_zh.md)

## Overview

The **Anthropic 1P Prompt Optimizer** follows a rigorous workflow to optimize, rewrite, and evaluate prompts. It leverages proven techniques such as:
- **Role Prompting**: Setting the context and audience.
- **XML Tag Separation**: Using tags like `<context>`, `<instructions>`, and `<input>` to prevent instruction injection and improve clarity.
- **Precognition/Chain of Thought**: Encouraging step-by-step reasoning.
- **Few-Shot Examples**: Providing clear patterns for tone and formatting.
- **Hallucination Reduction**: Implementing "evidence-first" extraction and "give an out" strategies.
- **Output Prefilling**: Directing the model's first few words to enforce specific formats.

## Workflow

### 1. Intake & Diagnosis
We start by understanding the current prompt, its execution context, target behavior, and known failure modes (e.g., tone drift, formatting issues). We diagnose the prompt for ambiguity, lack of structure, or missing constraints.

### 2. Optimization Building Blocks
Based on the diagnosis, we apply specific Anthropic 1P building blocks:
- **Clear & Direct Instructions**: Eliminating ambiguous verbs.
- **Variables & Delimiters**: Wrapping dynamic content in XML tags.
- **Structured Outputs**: Defining JSON schemas or XML structures for the response.
- **Guardrails**: Adding explicit constraints to minimize hallucinations or unwanted behavior.

### 3. Delivery
The optimizer provides:
- **Revised Prompts**: Optimized System and User prompts.
- **Few-Shot Examples**: Tailored to the specific task.
- **Change Log**: A concise summary of improvements.
- **Test Plan**: 3–5 test cases with clear pass/fail criteria for iterative refinement.

## Reference Materials

The skill includes several specialized reference guides:
- `references/anthropic-1p-cheatsheet.md`: Core patterns and best practices.
- `references/complex-prompt-template.md`: Skeleton for advanced, multi-part prompts.
- `references/guardrails-hallucinations.md`: Techniques for reliability and honesty.
- `references/tool-use-xml.md`: Patterns for function-calling and tool integration.
- `references/iteration-checklist.md`: Guidance for the evaluation and refinement loop.

## Directory Structure

```text
anthropic-1p-prompt-optimizer/
├── SKILL.md            # Skill definition and core workflow
├── README.md           # This file
├── agents/             # Agent configuration (e.g., openai.yaml)
├── references/         # Deep-dive documentation on specific techniques
└── scripts/            # (Optional) Helper scripts for prompt evaluation
```

## Usage

To use this skill, activate it within your session and provide your current prompt and goals:

```markdown
"Help me optimize this prompt for summarizing legal documents. I want it to be professional and always output a JSON list of key points."
```

The agent will then guide you through the 1P optimization process.
