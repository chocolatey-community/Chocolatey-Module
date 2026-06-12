---
applyTo: "{.github/instructions/*.md,.github/prompts/*.md,.github/skills/*.md,**/AGENTS.md,.github/copilot-instructions.md}"
---

# AI Instruction Authoring

- AI-only files. No human-facing tutorials or rationale.
- Write short imperative directives.
- Prefer bullets over prose.
- Remove filler, repetition, and duplicated context.
- Omit reasons unless the reason changes behavior.
- Update existing rules on conflict; do not duplicate them across files.
- Use the narrowest `applyTo` glob possible.
- `applyTo` must be a string, never an array.
- Start each instruction file, except `.github/copilot-instructions.md` and `**/AGENTS.md`, with YAML frontmatter.
- Use `##`/`###` headings, `-` bullets, backticks for code tokens, and fenced blocks for multi-line examples.
- No bold/italic emphasis or conversational tone.

