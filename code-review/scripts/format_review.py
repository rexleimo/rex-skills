#!/usr/bin/env python3
"""
Format code review output for different platforms.

Usage:
    python format_review.py --platform <platform> --issues <issues_json>
    echo '<issues_json>' | python format_review.py --platform github
    
Arguments:
    --platform: github, gitlab, terminal, markdown
    --issues: JSON string or file path with issues array
    --repo: Repository in owner/repo format (for links)
    --sha: Full commit SHA (for links)
    
Issue JSON format:
[
    {
        "description": "Missing null check",
        "reason": "bug",
        "file": "src/utils.ts",
        "start_line": 45,
        "end_line": 48,
        "suggestion": "Add optional chaining"
    }
]
"""

import argparse
import json
import sys
from typing import Optional


def format_github(issues: list, repo: str, sha: str) -> str:
    """Format for GitHub PR comment."""
    if not issues:
        return "## Code Review\n\nNo issues found. Checked for bugs and guideline compliance."
    
    lines = [f"## Code Review\n\nFound {len(issues)} issue(s):\n"]
    
    for i, issue in enumerate(issues, 1):
        desc = issue.get('description', 'No description')
        reason = issue.get('reason', 'unknown')
        file_path = issue.get('file', '')
        start = issue.get('start_line', 1)
        end = issue.get('end_line', start)
        suggestion = issue.get('suggestion', '')
        
        # Build link
        link = f"https://github.com/{repo}/blob/{sha}/{file_path}#L{start}-L{end}"
        
        lines.append(f"{i}. **{desc}** ({reason})\n")
        lines.append(f"   {link}\n")
        
        if suggestion:
            lines.append(f"\n   > Suggestion: {suggestion}\n")
        
        lines.append("")
    
    return '\n'.join(lines)


def format_gitlab(issues: list, repo: str, sha: str) -> str:
    """Format for GitLab MR comment."""
    if not issues:
        return "## Code Review\n\nNo issues found. Checked for bugs and guideline compliance."
    
    lines = [f"## Code Review\n\nFound {len(issues)} issue(s):\n"]
    
    for i, issue in enumerate(issues, 1):
        desc = issue.get('description', 'No description')
        reason = issue.get('reason', 'unknown')
        file_path = issue.get('file', '')
        start = issue.get('start_line', 1)
        end = issue.get('end_line', start)
        suggestion = issue.get('suggestion', '')
        
        # GitLab link format
        link = f"https://gitlab.com/{repo}/-/blob/{sha}/{file_path}#L{start}"
        
        lines.append(f"{i}. **{desc}** ({reason})\n")
        lines.append(f"   {link}\n")
        
        if suggestion:
            lines.append(f"\n   > Suggestion: {suggestion}\n")
        
        lines.append("")
    
    return '\n'.join(lines)


def format_terminal(issues: list, repo: Optional[str] = None, sha: Optional[str] = None) -> str:
    """Format for terminal output with colors."""
    if not issues:
        return "\033[92m✓ Code Review: No issues found\033[0m"
    
    lines = [f"\033[93m⚠ Code Review: Found {len(issues)} issue(s)\033[0m\n"]
    
    for i, issue in enumerate(issues, 1):
        desc = issue.get('description', 'No description')
        reason = issue.get('reason', 'unknown')
        file_path = issue.get('file', '')
        start = issue.get('start_line', 1)
        end = issue.get('end_line', start)
        suggestion = issue.get('suggestion', '')
        
        # Color based on reason
        color = {
            'bug': '\033[91m',      # Red
            'guideline': '\033[93m', # Yellow
            'context': '\033[94m',   # Blue
            'style': '\033[90m'      # Gray
        }.get(reason, '\033[0m')
        
        lines.append(f"{color}{i}. {desc}\033[0m")
        lines.append(f"   Reason: {reason}")
        lines.append(f"   File: {file_path}")
        lines.append(f"   Lines: {start}-{end}")
        
        if suggestion:
            lines.append(f"   \033[92mSuggestion: {suggestion}\033[0m")
        
        lines.append("")
    
    return '\n'.join(lines)


def format_markdown(issues: list, repo: Optional[str] = None, sha: Optional[str] = None) -> str:
    """Format as plain markdown (no platform-specific links)."""
    if not issues:
        return "## Code Review\n\nNo issues found. Checked for bugs and guideline compliance."
    
    lines = [f"## Code Review\n\nFound {len(issues)} issue(s):\n"]
    
    for i, issue in enumerate(issues, 1):
        desc = issue.get('description', 'No description')
        reason = issue.get('reason', 'unknown')
        file_path = issue.get('file', '')
        start = issue.get('start_line', 1)
        end = issue.get('end_line', start)
        suggestion = issue.get('suggestion', '')
        
        lines.append(f"### {i}. {desc}\n")
        lines.append(f"- **Reason**: {reason}")
        lines.append(f"- **File**: `{file_path}`")
        lines.append(f"- **Lines**: {start}-{end}")
        
        if suggestion:
            lines.append(f"- **Suggestion**: {suggestion}")
        
        lines.append("")
    
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description='Format code review output')
    parser.add_argument('--platform', required=True, 
                        choices=['github', 'gitlab', 'terminal', 'markdown'],
                        help='Target platform')
    parser.add_argument('--issues', help='JSON string or file path with issues')
    parser.add_argument('--repo', default='owner/repo', help='Repository (owner/repo)')
    parser.add_argument('--sha', default='HEAD', help='Full commit SHA')
    
    args = parser.parse_args()
    
    # Read issues from argument, file, or stdin
    if args.issues:
        if args.issues.startswith('['):
            issues = json.loads(args.issues)
        else:
            with open(args.issues, 'r') as f:
                issues = json.load(f)
    else:
        issues = json.load(sys.stdin)
    
    # Format based on platform
    formatters = {
        'github': format_github,
        'gitlab': format_gitlab,
        'terminal': format_terminal,
        'markdown': format_markdown
    }
    
    formatter = formatters[args.platform]
    
    if args.platform in ['github', 'gitlab']:
        output = formatter(issues, args.repo, args.sha)
    else:
        output = formatter(issues, args.repo, args.sha)
    
    print(output)


if __name__ == '__main__':
    main()
