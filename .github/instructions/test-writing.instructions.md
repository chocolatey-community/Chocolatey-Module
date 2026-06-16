---
description: 'Pester test authoring instructions'
applyTo: 'tests/**/*.tests.ps1'
---

# Pester Tests Development Guidelines

## Baseline structure

- Start unit test files with the repository pattern:

```powershell
BeforeAll {
    $script:moduleName = 'Chocolatey'

    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}
```

- Match existing repository style before adding an `AfterAll` block to older tests that currently omit it.
- Use `BeforeDiscovery` for data-driven test cases.
- Put test-specific mocks in the relevant `Describe` or `Context` scope.

## Naming and assertions

- Start `It` descriptions with `Should` when creating or modernizing tests.
- Prefer the most specific assertion form available:
  - `Should -Be`
  - `Should -BeTrue` / `Should -BeFalse`
  - `Should -Throw` / `Should -Not -Throw`
  - `Should -BeNullOrEmpty` / `Should -Not -BeNullOrEmpty`
- Scope mock assertions to the smallest practical test scope.

## Repository-specific rules

- Keep tests consistent with the existing `tests\Unit\Public` and `tests\Unit\Private` patterns in this repository.
- When validating class or type-accelerator behavior, import the module before invoking code paths that reference exported accelerators.
- Use PowerShell-version or platform guards only when the behavior truly differs between Windows PowerShell 5.1 and PowerShell 7.
- This repository is Windows-only, but tests must still work on both supported PowerShell versions.
- For commands that mutate system state and use the hidden `RunNonElevated` parameter defaulted from `Assert-ChocolateyIsElevated`, unit tests should normally pass `-RunNonElevated` unless the elevation check itself is the subject of the test.
- Mock the command-discovery helper that the implementation actually uses. In this repository that is usually `Get-ChocolateyCommand`, not `Get-Command`.

## Windows PowerShell 5.1 compatibility

- Always wrap pipeline expressions in `@()` before calling `.Count` on them. On Windows PowerShell 5.1, a pipeline that produces exactly one object returns a scalar, and scalars without a `Count` property return `$null` instead of `1`. PowerShell 7 adds a synthetic `Count` member to all objects, masking the bug.

  ```powershell
  # Wrong — returns $null on WinPS 5.1 when exactly one item matches
  ($collection | Where-Object { ... }).Count | Should -Be 1

  # Correct — @() ensures a true array on both 5.1 and 7
  @($collection | Where-Object { ... }).Count | Should -Be 1
  ```

- The same rule applies to any pipeline result where you call `.Count`, `.Length`, or index into the result (`[0]`): wrap in `@()` first.

## Validation commands

```powershell
./build.ps1 -Tasks test -PesterPath 'tests/Unit/Public/<FunctionName>.tests.ps1' -CodeCoverageThreshold 0
./build.ps1 -Tasks test -PesterPath 'tests/Unit/Private/<FunctionName>.tests.ps1' -CodeCoverageThreshold 0
./build.ps1 -Tasks test
```
