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
- Put `[Parameter()]` on every parameter, even when no explicit metadata is needed.
- Format each parameter with the attribute, type, and variable name on separate lines, with a blank line between comma-separated parameter declarations.
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
- If the command uses the hidden `RunNonElevated` guard pattern (`$RunNonElevated = $(Assert-ChocolateyIsElevated)`), update tests to either pass `-RunNonElevated` or explicitly mock the elevation check so unit tests exercise the intended behavior instead of failing at parameter binding time.
- When command resolution behavior is under test, mock `Get-ChocolateyCommand` rather than older `Get-Command -Name 'choco.exe'` call paths unless the implementation still uses `Get-Command` directly.
- Prefer focused validation first:

```powershell
./build.ps1 -Tasks test -PesterPath 'tests/Unit/Public/<FunctionName>.tests.ps1' -CodeCoverageThreshold 0
```

- User-visible behavior changes require an `Unreleased` changelog entry.
