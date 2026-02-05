# Guardrails to Reduce Hallucinations (1P patterns)

## 1) Give an “out” (允许不知道)

Add an explicit instruction such as:
- “If you don’t know / the input doesn’t contain the answer, say so clearly and do not guess.”
- “If information is insufficient, ask 1–3 clarifying questions.”

This trades off “helpfulness-at-all-costs” for correctness.

## 2) Evidence-first (先找证据，再回答)

For long documents or search results, use a two-phase response:
1) Extract relevant quotes/snippets with identifiers.
2) Answer using only the extracted evidence.

Template:

```text
Step 1: Extract 3–8 short quotes from <doc> that are relevant to <question>. If none exist, say “no supporting evidence found”.
Step 2: Answer the question using only those quotes. If evidence is missing, say what is missing.
```

## 3) Put the question at the bottom

For long contexts, place:
`<doc> ... </doc>` first, and the actual `<question> ... </question>` after it.

## 4) Lower temperature (when supported)

If you control sampling:
- Lower `temperature` for more consistent, less creative answers when accuracy matters.

## 5) Tighten scope + definitions

Common hallucination triggers:
- undefined terms (“largest”, “best”, “most important”)
- implicit assumptions (“use common sense”, “you know what I mean”)

Mitigation:
- define terms and allowed sources (“use only <doc>”)
- define output expectations (citations, quotes, or “unknown”)
