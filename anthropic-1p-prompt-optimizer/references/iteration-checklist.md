# Iteration & Evaluation Checklist (prompt optimization)

Use this to turn “改好了” into an iterative, testable prompt update.

## Define success (before rewriting)

- 1–3 primary success criteria (objective if possible).
- 3–10 “must not do” constraints (tone, safety, banned content, privacy, etc.).
- Output-format compliance rules (strict JSON/XML, or best-effort).

## Build a mini test set

Include 3–5 cases:
- 1 typical happy path
- 1 edge case (missing fields / ambiguous input)
- 1 adversarial or confusing case
- 1 formatting stress test (long text / unusual punctuation)
- (optional) 1 hallucination trap (distractor info)

For each case: input + expected output shape + pass/fail rule.

## Apply prompt chaining (Appendix 10.1 pattern)

After a first draft answer:
- Ask for a self-check / revision:
  - “Double-check your answer for factuality and format.”
  - “Only change the answer if you find a real issue; otherwise repeat it exactly.”

## Prefer minimal diffs when already near-correct

If the prompt mostly works:
- do small edits first (clarify constraints, add tags/examples)
- avoid broad rewrites that may regress behavior

## Post-change review

- Does the new prompt introduce new ambiguity?
- Are inputs clearly delimited (XML tags)?
- Is output format enforceable (tags/prefill/stop sequence)?
- Are “outs” present for unknown/insufficient info?
