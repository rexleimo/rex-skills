#!/usr/bin/env python3
"""
Analyze git diff output and extract structured information about changes.

Usage:
    python analyze_diff.py [diff_file]
    git diff | python analyze_diff.py
    
Output: JSON with file changes, line ranges, and statistics.
"""

import sys
import re
import json
from dataclasses import dataclass, asdict
from typing import Optional


@dataclass
class FileChange:
    """Represents changes to a single file."""
    path: str
    old_path: Optional[str]  # For renames
    status: str  # added, modified, deleted, renamed
    additions: int
    deletions: int
    hunks: list  # List of (old_start, old_count, new_start, new_count, content)


@dataclass
class DiffAnalysis:
    """Complete analysis of a diff."""
    files: list
    total_additions: int
    total_deletions: int
    total_files: int
    is_trivial: bool  # True if changes are minimal


def parse_diff(diff_text: str) -> DiffAnalysis:
    """Parse unified diff format and extract structured information."""
    files = []
    current_file = None
    current_hunks = []
    
    # Patterns
    diff_header = re.compile(r'^diff --git a/(.+) b/(.+)$')
    file_mode = re.compile(r'^(new|deleted) file mode')
    rename_from = re.compile(r'^rename from (.+)$')
    rename_to = re.compile(r'^rename to (.+)$')
    hunk_header = re.compile(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)$')
    
    lines = diff_text.split('\n')
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # New file diff
        match = diff_header.match(line)
        if match:
            # Save previous file
            if current_file:
                current_file.hunks = current_hunks
                files.append(current_file)
            
            old_path, new_path = match.groups()
            current_file = FileChange(
                path=new_path,
                old_path=None,
                status='modified',
                additions=0,
                deletions=0,
                hunks=[]
            )
            current_hunks = []
            i += 1
            continue
        
        # File mode changes
        if current_file:
            if file_mode.match(line):
                if 'new file' in line:
                    current_file.status = 'added'
                elif 'deleted file' in line:
                    current_file.status = 'deleted'
            
            # Rename detection
            rename_match = rename_from.match(line)
            if rename_match:
                current_file.old_path = rename_match.group(1)
                current_file.status = 'renamed'
            
            rename_match = rename_to.match(line)
            if rename_match:
                current_file.path = rename_match.group(1)
        
        # Hunk header
        hunk_match = hunk_header.match(line)
        if hunk_match and current_file:
            old_start = int(hunk_match.group(1))
            old_count = int(hunk_match.group(2) or 1)
            new_start = int(hunk_match.group(3))
            new_count = int(hunk_match.group(4) or 1)
            context = hunk_match.group(5).strip()
            
            # Collect hunk content
            hunk_content = []
            i += 1
            while i < len(lines):
                hunk_line = lines[i]
                if hunk_line.startswith('diff --git') or hunk_line.startswith('@@'):
                    i -= 1  # Reprocess this line
                    break
                if hunk_line.startswith('+') and not hunk_line.startswith('+++'):
                    current_file.additions += 1
                    hunk_content.append(hunk_line)
                elif hunk_line.startswith('-') and not hunk_line.startswith('---'):
                    current_file.deletions += 1
                    hunk_content.append(hunk_line)
                elif hunk_line.startswith(' ') or hunk_line == '':
                    hunk_content.append(hunk_line)
                i += 1
            
            current_hunks.append({
                'old_start': old_start,
                'old_count': old_count,
                'new_start': new_start,
                'new_count': new_count,
                'context': context,
                'content': '\n'.join(hunk_content)
            })
            continue
        
        i += 1
    
    # Save last file
    if current_file:
        current_file.hunks = current_hunks
        files.append(current_file)
    
    # Calculate totals
    total_additions = sum(f.additions for f in files)
    total_deletions = sum(f.deletions for f in files)
    
    # Determine if trivial (< 10 total changes, no code files)
    code_extensions = {'.py', '.js', '.ts', '.jsx', '.tsx', '.java', '.go', '.rs', '.cpp', '.c', '.h'}
    has_code_files = any(
        any(f.path.endswith(ext) for ext in code_extensions)
        for f in files
    )
    is_trivial = (total_additions + total_deletions < 10) and not has_code_files
    
    return DiffAnalysis(
        files=[asdict(f) for f in files],
        total_additions=total_additions,
        total_deletions=total_deletions,
        total_files=len(files),
        is_trivial=is_trivial
    )


def main():
    # Read from file or stdin
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            diff_text = f.read()
    else:
        diff_text = sys.stdin.read()
    
    if not diff_text.strip():
        print(json.dumps({
            'files': [],
            'total_additions': 0,
            'total_deletions': 0,
            'total_files': 0,
            'is_trivial': True
        }, indent=2))
        return
    
    analysis = parse_diff(diff_text)
    print(json.dumps(asdict(analysis), indent=2))


if __name__ == '__main__':
    main()
