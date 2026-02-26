#!/usr/bin/env python3
"""
Prompt Enhancement Script

Analyzes a vague user prompt and produces a structured, enhanced version
with clear goals, constraints, scope, and acceptance criteria.

Usage:
    python enhance_prompt.py --prompt "add login page" [--context "React + TypeScript project"]
    python enhance_prompt.py --file prompt.txt [--context-file context.txt]
"""

import argparse
import json
import sys
from dataclasses import dataclass, asdict
from typing import Optional


@dataclass
class EnhancedPrompt:
    original: str
    intent: str
    missing_info: list[str]
    implicit_assumptions: list[str]
    enhanced: str
    goal: str
    technical_constraints: list[str]
    scope_boundaries: dict[str, list[str]]
    acceptance_criteria: list[str]
    relevant_context: list[str]
    completeness_score: int  # 0-10


def analyze_prompt(prompt: str, context: Optional[str] = None) -> EnhancedPrompt:
    """Analyze a prompt and identify gaps, assumptions, and enhancement opportunities."""

    words = prompt.strip().split()
    word_count = len(words)

    # Detect intent keywords
    intent_keywords = {
        "add": "create/implement new functionality",
        "fix": "debug and resolve an issue",
        "update": "modify existing functionality",
        "remove": "delete/deprecate functionality",
        "refactor": "restructure without changing behavior",
        "optimize": "improve performance",
        "review": "evaluate code quality",
        "test": "add or improve tests",
        "deploy": "release to environment",
        "migrate": "move to new system/version",
    }

    detected_intent = "general development task"
    for keyword, intent in intent_keywords.items():
        if keyword in prompt.lower():
            detected_intent = intent
            break

    # Identify missing information
    missing = []
    checks = {
        "technical stack not specified": not any(
            tech in prompt.lower()
            for tech in [
                "react", "vue", "angular", "python", "go", "rust",
                "typescript", "javascript", "java", "node",
            ]
        ),
        "no acceptance criteria defined": not any(
            w in prompt.lower() for w in ["should", "must", "expect", "criteria"]
        ),
        "scope boundaries unclear": word_count < 15,
        "no error handling requirements": "error" not in prompt.lower(),
        "no performance requirements": not any(
            w in prompt.lower() for w in ["fast", "performance", "optimize", "speed"]
        ),
        "no accessibility requirements": not any(
            w in prompt.lower() for w in ["accessible", "a11y", "wcag", "aria"]
        ),
        "no responsive design requirements": not any(
            w in prompt.lower() for w in ["responsive", "mobile", "tablet", "breakpoint"]
        ),
    }
    missing = [desc for desc, is_missing in checks.items() if is_missing]

    # Detect implicit assumptions
    assumptions = []
    if "page" in prompt.lower() or "component" in prompt.lower():
        assumptions.append("Assumes a web-based UI project")
    if "api" in prompt.lower() or "endpoint" in prompt.lower():
        assumptions.append("Assumes a REST/GraphQL backend exists")
    if "database" in prompt.lower() or "db" in prompt.lower():
        assumptions.append("Assumes database infrastructure is available")
    if not assumptions:
        assumptions.append("No strong assumptions detected - context needed")

    # Calculate completeness score
    score = max(0, 10 - len(missing))

    # Build enhanced prompt
    enhanced_parts = [prompt.strip()]
    if context:
        enhanced_parts.append(f"Project context: {context}")

    # Build structured output
    return EnhancedPrompt(
        original=prompt.strip(),
        intent=detected_intent,
        missing_info=missing,
        implicit_assumptions=assumptions,
        enhanced=" | ".join(enhanced_parts),
        goal=f"{detected_intent}: {prompt.strip()}",
        technical_constraints=[c for c in [context] if c] if context else ["Not specified - detect from project"],
        scope_boundaries={
            "in_scope": [prompt.strip()],
            "out_of_scope": ["Infrastructure changes", "CI/CD pipeline modifications"],
        },
        acceptance_criteria=[
            "Feature works as described",
            "No regressions in existing functionality",
            "Code passes linting and type checks",
        ],
        relevant_context=[context] if context else ["Detect from project structure"],
        completeness_score=score,
    )


def format_output(enhanced: EnhancedPrompt, output_format: str = "markdown") -> str:
    """Format the enhanced prompt for display."""

    if output_format == "json":
        return json.dumps(asdict(enhanced), indent=2, ensure_ascii=False)

    lines = []
    lines.append("# Prompt Enhancement Report")
    lines.append("")
    lines.append(f"**Completeness Score**: {enhanced.completeness_score}/10")
    lines.append("")
    lines.append("## Original Prompt")
    lines.append(f"> {enhanced.original}")
    lines.append("")
    lines.append("## Analysis")
    lines.append(f"**Detected Intent**: {enhanced.intent}")
    lines.append("")

    if enhanced.missing_info:
        lines.append("### Missing Information")
        for item in enhanced.missing_info:
            lines.append(f"- {item}")
        lines.append("")

    if enhanced.implicit_assumptions:
        lines.append("### Implicit Assumptions")
        for item in enhanced.implicit_assumptions:
            lines.append(f"- {item}")
        lines.append("")

    lines.append("## Enhanced Prompt")
    lines.append(f"**Goal**: {enhanced.goal}")
    lines.append("")

    if enhanced.technical_constraints:
        lines.append("**Technical Constraints**:")
        for c in enhanced.technical_constraints:
            lines.append(f"- {c}")
        lines.append("")

    lines.append("**Scope**:")
    lines.append(f"- In scope: {', '.join(enhanced.scope_boundaries['in_scope'])}")
    lines.append(f"- Out of scope: {', '.join(enhanced.scope_boundaries['out_of_scope'])}")
    lines.append("")

    lines.append("**Acceptance Criteria**:")
    for i, criteria in enumerate(enhanced.acceptance_criteria, 1):
        lines.append(f"{i}. {criteria}")
    lines.append("")

    if enhanced.completeness_score < 7:
        lines.append("---")
        lines.append("**⚠️ Score < 7: Recommend clarifying missing information before proceeding.**")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Enhance vague prompts into structured tasks")
    parser.add_argument("--prompt", type=str, help="The prompt to enhance")
    parser.add_argument("--file", type=str, help="File containing the prompt")
    parser.add_argument("--context", type=str, help="Project context string")
    parser.add_argument("--context-file", type=str, help="File containing project context")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown", help="Output format")

    args = parser.parse_args()

    # Get prompt
    if args.prompt:
        prompt = args.prompt
    elif args.file:
        with open(args.file) as f:
            prompt = f.read()
    else:
        print("Error: Provide --prompt or --file", file=sys.stderr)
        sys.exit(1)

    # Get context
    context = None
    if args.context:
        context = args.context
    elif args.context_file:
        with open(args.context_file) as f:
            context = f.read()

    enhanced = analyze_prompt(prompt, context)
    print(format_output(enhanced, args.format))


if __name__ == "__main__":
    main()
