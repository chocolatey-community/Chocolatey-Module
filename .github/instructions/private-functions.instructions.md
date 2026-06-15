---
description: 'Private function authoring instructions'
applyTo: 'source/private/**/*.ps1'
---

# Private Function Development Guidelines

## Baseline structure

- Follow the same comment-based help baseline as public functions, including at least one `.EXAMPLE`.
- Use `[CmdletBinding()]`.
- Include `[OutputType(...)]` when output shape is stable and meaningful to document.
- Use explicit parameter types where the helper contract is stable.

## Private helper rules

- Keep helpers focused and composable.
- Avoid embedding user interaction in private helpers unless explicitly required by design.
- If a private helper drives public behavior, treat its compatibility and tests with the same rigor as a public function.
- Reuse enums, classes, and existing helpers rather than duplicating logic.

## Testing expectations

- Add or update matching tests under `tests/Unit/Private/<FunctionName>.tests.ps1`.
- Cover happy path and validation or failure behavior.
- Keep help examples current when adding or changing private helpers; repository QA checks fail when a function has no `.EXAMPLE`.
- Prefer focused validation first:

```powershell
./build.ps1 -Tasks test -PesterPath 'tests/Unit/Private/<FunctionName>.tests.ps1' -CodeCoverageThreshold 0
```
