# /ccg:archive [change-name]

Archive a completed change. Generate commit, move artifacts to archive, clean up.

## What It Does

1. **Check completeness** — Verify all tasks are checked off in plan.md
2. **Generate commit** — Create conventional commit message from change artifacts
3. **Archive artifacts** — Move `.ccg/<change>/` to `.ccg/archive/<change>/`
4. **Report summary** — Final summary of what was done

## Orchestration

```
User: /ccg:archive add-oauth2

  ┌─────────────────────────────────────────────────────────┐
  │  Check: All tasks in plan.md completed?                 │
  │  [x] 1. Create OAuth2 provider config ✓                │
  │  [x] 2. Implement auth middleware ✓                    │
  │  [x] 3. Create login/callback routes ✓                 │
  │  [x] 4. Add OAuth2 login button ✓                     │
  │  [x] 5. Write integration tests ✓                     │
  │  → All done ✓                                          │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  Generate commit message:                               │
  │  ✨ feat(auth): add OAuth2 authentication with PKCE     │
  │                                                         │
  │  - Add OAuth2 provider configuration                    │
  │  - Implement auth middleware with token refresh          │
  │  - Create login/callback API routes                     │
  │  - Add OAuth2 login button component                    │
  │  - Add integration tests for auth flow                  │
  └──────────────────────┬──────────────────────────────────┘
                         │
  ┌──────────────────────▼──────────────────────────────────┐
  │  Archive:                                               │
  │  .ccg/add-oauth2/ → .ccg/archive/add-oauth2/           │
  │                                                         │
  │  Summary:                                               │
  │  Files modified: 12                                     │
  │  Lines added: 450                                       │
  │  Lines removed: 23                                      │
  │  Duration: 45 minutes                                   │
  └─────────────────────────────────────────────────────────┘
```

## Commit Convention

```
[emoji] <type>(<scope>): <subject>

<body>
```

| Type | Emoji | When |
|------|-------|------|
| feat | ✨ | New feature |
| fix | 🐛 | Bug fix |
| docs | 📝 | Documentation |
| refactor | ♻️ | Code refactoring |
| perf | ⚡ | Performance improvement |
| test | ✅ | Tests |
| chore | 🔧 | Maintenance |

## Incomplete Changes

If tasks are not all completed:

```
⚠️ Change 'add-oauth2' has incomplete tasks:
  [ ] 5. Write integration tests

Options:
  1. Archive anyway (mark as partial)
  2. Continue with /ccg:apply
  3. Cancel archive
```
