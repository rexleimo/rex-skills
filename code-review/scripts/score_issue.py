#!/usr/bin/env python3
"""
Calculate confidence score for a code review issue.

Usage:
    python score_issue.py --type <issue_type> --evidence <evidence_level> [options]
    
Arguments:
    --type: bug, guideline, context, style
    --evidence: strong, moderate, weak, none
    --verified: true/false (has the issue been independently verified?)
    --pre-existing: true/false (does the issue exist before this change?)
    --linter-catchable: true/false (would a linter catch this?)
    
Output: JSON with score (0-100) and recommendation (flag/skip)
"""

import argparse
import json
import sys


def calculate_score(
    issue_type: str,
    evidence: str,
    verified: bool = False,
    pre_existing: bool = False,
    linter_catchable: bool = False
) -> dict:
    """Calculate confidence score for an issue."""
    
    # Base scores by issue type
    base_scores = {
        'bug': 70,           # Bugs start high
        'guideline': 60,     # Guideline issues need verification
        'context': 50,       # Context issues are often subjective
        'style': 20          # Style issues are usually filtered
    }
    
    # Evidence multipliers
    evidence_multipliers = {
        'strong': 1.4,       # Clear, undeniable evidence
        'moderate': 1.1,     # Good evidence but some ambiguity
        'weak': 0.7,         # Circumstantial evidence
        'none': 0.3          # No concrete evidence
    }
    
    # Start with base score
    score = base_scores.get(issue_type, 50)
    
    # Apply evidence multiplier
    multiplier = evidence_multipliers.get(evidence, 1.0)
    score = score * multiplier
    
    # Verification bonus
    if verified:
        score += 15
    
    # Penalties
    if pre_existing:
        score -= 50  # Major penalty for pre-existing issues
    
    if linter_catchable:
        score -= 30  # Don't flag what linters catch
    
    # Clamp to 0-100
    score = max(0, min(100, int(score)))
    
    # Determine recommendation
    if score >= 80:
        recommendation = 'flag'
        reason = 'High confidence issue, should be reported'
    elif score >= 50:
        recommendation = 'review'
        reason = 'Moderate confidence, may need manual review'
    else:
        recommendation = 'skip'
        reason = 'Low confidence, likely false positive'
    
    return {
        'score': score,
        'recommendation': recommendation,
        'reason': reason,
        'factors': {
            'issue_type': issue_type,
            'evidence': evidence,
            'verified': verified,
            'pre_existing': pre_existing,
            'linter_catchable': linter_catchable
        }
    }


def main():
    parser = argparse.ArgumentParser(description='Calculate confidence score for code review issue')
    parser.add_argument('--type', required=True, choices=['bug', 'guideline', 'context', 'style'],
                        help='Type of issue')
    parser.add_argument('--evidence', required=True, choices=['strong', 'moderate', 'weak', 'none'],
                        help='Strength of evidence')
    parser.add_argument('--verified', type=lambda x: x.lower() == 'true', default=False,
                        help='Has the issue been verified?')
    parser.add_argument('--pre-existing', type=lambda x: x.lower() == 'true', default=False,
                        help='Is this a pre-existing issue?')
    parser.add_argument('--linter-catchable', type=lambda x: x.lower() == 'true', default=False,
                        help='Would a linter catch this?')
    
    args = parser.parse_args()
    
    result = calculate_score(
        issue_type=args.type,
        evidence=args.evidence,
        verified=args.verified,
        pre_existing=args.pre_existing,
        linter_catchable=args.linter_catchable
    )
    
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
