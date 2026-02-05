# Tool Use XML Formats (Appendix 10.2 condensed)

The 1P tutorial describes “tool use” (function calling) as prompt chaining + substitution:
1) Model emits a tool call (name + args) in a known structure.
2) You stop generation, execute the tool.
3) You append tool results to the conversation and ask the model to continue.

## Function calls (model → orchestrator)

The tutorial recommends an XML wrapper trained for this purpose:

```text
<function_calls>
  <call>
    <tool_name>calculator</tool_name>
    <parameters>
      <operand1>2</operand1>
      <operator>*</operator>
      <operand2>21</operand2>
    </parameters>
  </call>
</function_calls>
```

Orchestrator pattern:
- Set `stop_sequences` to the closing tag (e.g., `</function_calls>`) so you can reliably parse the call.
- Parse parameters, run tool, then send back results as below.

## Function results (orchestrator → model)

The tutorial provides a trained result envelope:

```text
<function_results>
  <result>
    <tool_name>{TOOL_NAME}</tool_name>
    <stdout>
{TOOL_OUTPUT}
    </stdout>
  </result>
</function_results>
```

Then you append `<function_results>...</function_results>` as a new message (or appended content) and ask the model to produce the final answer.

## Prompting tips

- In the system prompt, describe:
  - what tool use is,
  - when to call a tool vs answer directly,
  - each tool’s name + description + parameters (name/type/meaning).
- Add a rule: “If no tool is needed, answer normally and do not emit `<function_calls>`.”
