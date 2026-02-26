#!/usr/bin/env python3
"""
Code Review Scoring Script

Calculate confidence scores for code review findings to filter false positives.
Only findings with score >= 80 are considered high-signal.

Usage:
    python score_review.py --finding "Missing input validation" --evidence "No sanitization before DB query" --category security
    python score_review.py --file findings.json
"""

import argparse
import json
import sys
from dataclasses import dataclass, asdict
from typing import Optional


@dataclass
class ReviewFinding:
    finding: str
    evidence: str
    category: str
    file_path: Optional[str] = None
    line_range: Optional[str] = None
    confidence: int = 0
    is_high_signal: bool = False
    reasoning: str = ""


# Category weights - higher weight = more likely to be real issue
CATEGORY_WEIGHTS = {
    "security": 1.3,
    "bug": 1.2,
    "logic_error": 1.2,
    "type_error": 1.1,
    "performance": 0.9,
    "accessibility": 0.9,
    "design_consistency": 0.8,
    "code_quality": 0.7,
    "style": 0.5,
    "suggestion": 0.4,
}

# Evidence strength indicators
STRONG_EVIDENCE = [
    "missing", "undefined", "null", "injection", "hardcoded",
    "no validation", "no sanitization", "no check", "unhandled",
    "race condition", "deadlock", "memory leak", "n+1",
    "broken", "crash", "exception", "error", "fail",
]

WEAK_EVIDENCE = [
    "could", "might", "possibly", "consider", "maybe",
    "subjective", "preference", "style", "opinion",
    "potential", "theoretical",
]


def score_finding(finding: ReviewFinding) -> ReviewFinding:
    """Calculate confidence score for a review finding."""

    base_score = 50
    reasoning_parts = [f"Base score: {base_score}"]

    # Category weight
    category = finding.category.lower().replace(" ", "_")
    weight = CATEGORY_WEIGHTS.get(category, 0.7)
    category_bonus = int((weight - 0.7) * 50)
    base_score += category_bonus
    reasoning_parts.append(f"Category '{category}' weight {weight}: {category_bonus:+d}")

    # Evidence strength
    evidence_lower = finding.evidence.lower()
    strong_count = sum(1 for indicator in STRONG_EVIDENCE if indicator in evidence_lower)
    weak_count = sum(1 for indicator in WEAK_EVIDENCE if indicator in evidence_lower)

    evidence_bonus = strong_count * 8 - weak_count * 12
    base_score += evidence_bonus
    reasoning_parts.append(
        f"Evidence: {strong_count} strong, {weak_count} weak indicators: {evidence_bonus:+d}"
    )

    # Finding specificity (longer, more specific findings score higher)
    finding_words = len(finding.finding.split())
    if finding_words >= 10:
        specificity_bonus = 5
    elif finding_words >= 5:
        specificity_bonus = 0
    else:
        specificity_bonus = -10
    base_score += specificity_bonus
    reasoning_parts.append(f"Specificity ({finding_words} words): {specificity_bonus:+d}")

    # File path provided (more specific = higher confidence)
    if finding.file_path:
        base_score += 5
        reasoning_parts.append("File path provided: +5")

    # Line range provided
    if finding.line_range:
        base_score += 5
        reasoning_parts.append("Line range provided: +5")

    # Clamp to 0-100
    final_score = max(0, min(100, base_score))

    finding.confidence = final_score
    finding.is_high_signal = final_score >= 80
    finding.reasoning = " | ".join(reasoning_parts)

    return finding


def process_findings_file(filepath: str) -> list[dict]:
    """Process a JSON file of findings."""
    with open(filepath) as f:
        data = json.load(f)

    results = []
    for item in data:
        finding = ReviewFinding(
            finding=item.get("finding", ""),
            evidence=item.get("evidence", ""),
            category=item.get("category", "code_quality"),
            file_path=item.get("file_path"),
            line_range=item.get("line_range"),
        )
        scored = score_finding(finding)
        results.append(asdict(scored))

    return results


def main():
    parser = argparse.ArgumentParser(description="Score code review findings")
    parser.add_argument("--finding", type=str, help="The finding description")
    parser.add_argument("--evidence", type=str, help="Evidence supporting the finding")
    parser.add_argument("--category", type=str, default="code_quality",
                        choices=list(CATEGORY_WEIGHTS.keys()),
                        help="Finding category")
    parser.add_argument("--file-path", type=str, help="Source file path")
    parser.add_argument("--line-range", type=str, help="Line range (e.g., L10-L15)")
    parser.add_argument("--file", type=str, help="JSON file with multiple findings")
    parser.add_argument("--format", choices=["text", "json"], default="text")

    args = parser.parse_args()

    if args.file:
        results = process_findings_file(args.file)
        high_signal = [r for r in results if r["is_high_signal"]]
        low_signal = [r for r in results if not r["is_high_signal"]]

        if args.format == "json":
            print(json.dumps(results, indent=2, ensure_ascii=False))
        else:
            print(f"Total findings: {len(results)}")
            print(f"High signal (≥80): {len(high_signal)}")
            print(f"Filtered out (<80): {len(low_signal)}")
            print()
            for r in sorted(results, key=lambda x: x["confidence"], reverse=True):
                signal = "✓" if r["is_high_signal"] else "✗"
                print(f"  [{signal}] {r['confidence']:3d}/100 | {r['category']:20s} | {r['finding']}")
    else:
        if not args.finding or not args.evidence:
            print("Error: Provide --finding and --evidence, or --file", file=sys.stderr)
            sys.exit(1)

        finding = ReviewFinding(
            finding=args.finding,
            evidence=args.evidence,
            category=args.category,
            file_path=args.file_path,
            line_range=args.line_range,
        )
        scored = score_finding(finding)

        if args.format == "json":
            print(json.dumps(asdict(scored), indent=2, ensure_ascii=False))
        else:
            signal = "HIGH SIGNAL" if scored.is_high_signal else "LOW SIGNAL (filtered)"
            print(f"Score: {scored.confidence}/100 [{signal}]")
            print(f"Category: {scored.category}")
            print(f"Finding: {scored.finding}")
            print(f"Evidence: {scored.evidence}")
            print(f"Reasoning: {scored.reasoning}")


if __name__ == "__main__":
    main()
