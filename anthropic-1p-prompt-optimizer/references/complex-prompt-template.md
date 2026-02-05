# 1P Complex Prompt Template (elements + skeleton)

This is a reusable “complex prompt” scaffold distilled from Chapter 9’s recommended structure.

## Elements (recommended order)

1) **Task context**: who the model is + overarching goal + environment constraints.
2) **Tone context** (optional): voice, audience, style.
3) **Detailed task rules**: step definitions, constraints, refusal / “out” rules, definitions.
4) **Examples (few-shot)** (optional but powerful): wrap each in `<example>...</example>`.
5) **Input data**: wrap each variable in its own XML tag (`<doc>`, `<question>`, `<emails>`, etc.).
6) **Immediate task**: the exact thing to do right now (prefer near the bottom).
7) **Precognition** (optional): ask to think step-by-step before answering.
8) **Output formatting**: required structure (XML tags / JSON schema / exact token constraints).
9) **Prefill** (optional): start the assistant response (e.g., `<response>` or `{`).

Notes:
- The tutorial suggests it’s usually best to place the user’s question near the bottom after any long inputs.
- Some tasks are sensitive to ordering; keep this order unless you have evidence to change it.

## Skeleton (copy/paste and fill)

Use meaningful XML tag names; keep variable content strictly inside tags.

```text
TASK CONTEXT:
You are ...
Your goal is ...
You operate in/for ...

TONE (optional):
Use a ... tone for ...

RULES / DETAILED TASK:
- Do ...
- Do not ...
- If information is insufficient, say: "...", and ask 1–3 clarifying questions.
- If unsure, do not guess; explain what’s missing.

EXAMPLES (optional):
Here is an example of an ideal response:
<example>
User: ...
Assistant: ...
</example>

INPUT DATA:
Here is the input you must use:
<input>
{INPUT}
</input>

Here is the question:
<question>
{QUESTION}
</question>

IMMEDIATE TASK:
Respond to the user’s question using the input above.

PRECOGNITION (optional):
Before answering, think step by step about the rules and input.

OUTPUT FORMAT:
Put your final answer in <response></response> tags.
```

## Prefill (“speaking for Claude”)

If you can prefill an `assistant` message, start it with something like:

```text
<response>
```

Or for JSON:

```text
{
```

Then (optionally) stop on the closing tag / `}` in your API layer.
