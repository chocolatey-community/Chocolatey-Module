---
description: 'Public function authoring instructions'
applyTo: 'source/public/**/*.ps1'
---

# Public Function Development Guidelines

## Baseline structure

- Use comment-based help with:
  - `.SYNOPSIS`
  - `.DESCRIPTION`
  - at least one `.EXAMPLE`
  - `.PARAMETER` help for every parameter.
- Use `[CmdletBinding()]`.
- Include `[OutputType(...)]` when the command returns a defined type or stable output shape.
- Use explicit parameter types where the command contract is stable.
- Keep parameter names and defaults stable unless intentionally making a breaking change.

## Public command rules

- Public functions are compatibility-sensitive.
- Preserve backward compatibility by default.
- Reuse existing private helpers instead of duplicating command-line argument construction or parsing logic.
- Keep user-facing messages aligned with localization files in `source\en-US\` when applicable.
- If behavior, parameters, or output change, update help and the matching unit tests.

## Testing expectations

- Add or update matching tests under `tests/Unit/Public/<FunctionName>.tests.ps1`.
- Cover happy path and validation or failure behavior.
- Prefer focused validation first:

```powershell
./build.ps1 -Tasks test -PesterPath 'tests/Unit/Public/<FunctionName>.tests.ps1' -CodeCoverageThreshold 0
```

- User-visible behavior changes require an `Unreleased` changelog entry.
