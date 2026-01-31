# Platform Integration Guide

## GitHub

### Commands

```bash
# View PR details
gh pr view <PR_NUMBER> --json number,title,body,state,isDraft,headRefName,baseRefName

# Get PR diff
gh pr diff <PR_NUMBER>

# Check existing comments
gh pr view <PR_NUMBER> --comments

# Post review comment
gh pr comment <PR_NUMBER> --body "## Code Review\n\n..."

# Create inline comment (requires GitHub API)
gh api repos/{owner}/{repo}/pulls/{pull_number}/comments \
  -f body="Issue description" \
  -f commit_id="<sha>" \
  -f path="<file_path>" \
  -f line=<line_number>
```

### Link Format

```
https://github.com/{owner}/{repo}/blob/{full_sha}/{path}#L{start}-L{end}
```

Requirements:
- Full SHA (40 characters, not abbreviated)
- `#L` notation for line numbers
- Range format: `L10-L15`

### Skip Conditions

```bash
# Check if should skip
gh pr view <PR_NUMBER> --json state,isDraft,labels

# Skip if:
# - state == "CLOSED" or state == "MERGED"
# - isDraft == true
# - labels contains "automated" or "trivial"
```

## GitLab

### Commands

```bash
# View MR details
glab mr view <MR_NUMBER>

# Get MR diff
glab mr diff <MR_NUMBER>

# Post comment
glab mr comment <MR_NUMBER> --message "## Code Review\n\n..."

# Create discussion on specific line
glab api projects/:id/merge_requests/:mr_iid/discussions \
  -f body="Issue description" \
  -f position[base_sha]="<base>" \
  -f position[head_sha]="<head>" \
  -f position[start_sha]="<start>" \
  -f position[new_path]="<file>" \
  -f position[new_line]=<line> \
  -f position[position_type]="text"
```

### Link Format

```
https://gitlab.com/{namespace}/{project}/-/blob/{sha}/{path}#L{line}
```

## Local Git

### Commands

```bash
# View changes
git diff                    # Unstaged changes
git diff --cached           # Staged changes
git diff main...HEAD        # Branch changes vs main
git diff HEAD~1             # Last commit

# Get file at specific commit
git show <sha>:<path>

# Get blame for context
git blame -L <start>,<end> <file>

# Get commit history for file
git log --oneline -n 10 -- <file>
```

### Output Format (Terminal)

```markdown
## Code Review

Found 2 issues:

1. Missing null check before accessing property (Bug)
   
   File: src/utils.ts
   Lines: 45-48
   
   ```typescript
   // Current code
   const value = obj.property.nested;
   
   // Suggested fix
   const value = obj?.property?.nested;
   ```

2. Function exceeds max line limit (CONTRIBUTING.md: "Functions should be < 50 lines")
   
   File: src/handlers.ts
   Lines: 120-195
```
