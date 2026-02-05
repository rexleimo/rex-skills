# Anthropic 1P Prompt Engineering — Cheatsheet (condensed)

This file summarizes the “Anthropic 1P” interactive prompt-engineering tutorial notebooks into reusable patterns.

## Chapter 1 — Basic prompt structure

- Use a `system` prompt for global rules/identity/style/guardrails.
- Messages alternate `user` and `assistant`; you can “prefill” an `assistant` turn to steer output continuation.

## Chapter 2 — Clear and direct

- Claude performs best with explicit, concrete instructions.
- Golden rule: if a colleague can’t follow the prompt unambiguously, the model won’t either.
- If you want “no preamble / only X”, ask for it precisely (including whitespace/punctuation constraints when needed).

## Chapter 3 — Role prompting

- Assign a role (and optionally intended audience) to change tone, style, and sometimes reasoning quality.
- Role can live in `system` or in the `user` message.

## Chapter 4 — Separate data and instructions (XML tags)

- For prompt templates with variable user input, keep a fixed “skeleton” and substitute data at runtime.
- Always make boundaries explicit: wrap variable data in XML tags so the model knows where inputs start/end.
- Recommendation: prefer XML tags as separators (the tutorial notes Claude is trained to recognize them well).
- There are no “magic” XML tags outside function-calling; use meaningful tag names for readability.
- “Small details matter”: typos/formatting ambiguity can cause misreads; scrub prompts carefully.

## Chapter 5 — Output formatting + “speaking for Claude” (prefill)

- Ask for structured output explicitly (XML tags, JSON).
- Wrap only the target content in output tags to make extraction reliable.
- “Speaking for Claude”: prefill the `assistant` turn with the opening tag (or `{` for JSON) so the model continues in the desired structure.
- If using an API, set `stop_sequences` to the closing tag to stop generation once the output is complete.

## Chapter 6 — Precognition (thinking step-by-step)

- For multi-step tasks, let the model “think out loud” before answering.
- In Claude-style prompting, thinking “counts” only if it is produced in text; scaffold the steps you want it to follow.
- Ordering can matter; models may be sensitive to which option appears first vs second.

## Chapter 7 — Few-shot examples

- Examples are highly effective for tone + formatting compliance.
- Use 1–5 examples; include edge cases; keep examples close to the task.
- Combine with prefilling (e.g., start an output tag in the assistant turn).

## Chapter 8 — Avoiding hallucinations

- Give an “out”: explicitly allow “I don’t know / not enough info” instead of guessing.
- Evidence-first: ask the model to extract relevant quotes/snippets, then answer using only those.
- Placement: put long documents first and the question at the bottom to reduce distraction effects.
- Lower `temperature` to reduce variability when accuracy matters.

## Chapter 9 — Complex prompts from scratch

- Start broad (more structure), then slim once it works.
- Use the 1P complex prompt element ordering (see `complex-prompt-template.md`).

## Appendix 10.1 — Prompt chaining

- Ask the model to revise or double-check its prior output; “writing is rewriting”.
- To reduce unnecessary changes, give an out: “Only change if you find a real issue.”

## Appendix 10.2 — Tool use (function calling via chaining)

- Have the model output tool name + arguments in a trained XML structure, stop generation, run the tool, then reprompt with `<function_results>...`.
- See `tool-use-xml.md` for the exact format.

## Appendix 10.3 — Search & retrieval

- Use retrieval (RAG) to supplement knowledge and reduce hallucinations; summarize/synthesize from retrieved sources.
