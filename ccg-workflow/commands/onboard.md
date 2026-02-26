# /ccg:onboard

Guided walkthrough of an end-to-end change. Interactive tutorial for new users.

## What It Does

Walk the user through a complete workflow cycle with explanations at each step:

```
/ccg:onboard

Welcome to CCG Workflow! Let's walk through a complete change together.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CCG Workflow orchestrates three AI models working together:

  🧠 Claude (Coordinator) — Orchestrates everything, writes code
  ⚙️ Codex (Backend Expert) — Advises on API, database, security
  🎨 Gemini (Frontend Expert) — Advises on UI/UX, components, design

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1/6: Tell me what you want to build.

  Quick path:  /ccg:propose <what-you-want>
  Explore:     /ccg:explore <question>
  Expanded:    /ccg:new <change-name>

  Example: /ccg:propose Add a dark mode toggle to the settings page

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 2/6: Review the plan.

  The AI will analyze your request using multiple models and
  present a plan. Review it and approve or request changes.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 3/6: Implementation.

  /ccg:apply — The Coordinator writes code based on the plan,
  consulting Codex and Gemini for domain-specific advice.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 4/6: Verify.

  /ccg:verify — Both models review the implementation against
  the plan. Issues are scored and filtered.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 5/6: Iterate if needed.

  If issues found: fix → /ccg:verify again
  If plan was wrong: edit plan → /ccg:apply → /ccg:verify

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 6/6: Archive.

  /ccg:archive — Generate commit, archive artifacts, done!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ready? Tell me what you want to build!
```

## Quick Reference Card (shown at end)

```
┌─────────────────────────────────────────────────────────┐
│                  CCG Workflow Commands                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Core:                                                  │
│    /ccg:propose <what>    Quick path: idea → plan       │
│    /ccg:explore <topic>   Think & research              │
│    /ccg:apply             Implement tasks               │
│    /ccg:archive           Done, commit & archive        │
│                                                         │
│  Expanded:                                              │
│    /ccg:new <name>        Start change scaffold         │
│    /ccg:continue          Next artifact (one at a time) │
│    /ccg:ff                Fast-forward all planning     │
│    /ccg:verify            Multi-model review            │
│    /ccg:status            Show current state            │
│                                                         │
│  Config:                                                │
│    /ccg:config show       View configuration            │
│    /ccg:config init       Create config file            │
│    /ccg:config profile    Switch command profiles       │
│    /ccg:config schema     Manage workflow schemas       │
│                                                         │
│  Tips:                                                  │
│    • /ccg:propose for quick tasks                       │
│    • /ccg:new + /ccg:ff for complex features            │
│    • /ccg:explore when unsure                           │
│    • Edit artifacts anytime, then /ccg:apply continues  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```
