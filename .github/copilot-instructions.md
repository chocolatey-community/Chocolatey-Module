# Copilot instructions for Chocolatey

## Build entrypoint

- Use `./build.ps1` for all dependency restore, build, test, and validation work.
- Bootstrap with `./build.ps1 -ResolveDependency -Tasks noop`.
- Build with `./build.ps1 -Tasks build`.
- Test with `./build.ps1 -Tasks test` or another named workflow from `build.yaml`.
- Do not call `Invoke-Pester`, `Build-Module`, or other build helpers directly from a fresh shell.
- Do not manually prepend `output/RequiredModules` or `output/module` to `PSModulePath`.

## Repository constraints

- This module is Windows-only.
- This module must support Windows PowerShell 5.1 and PowerShell 7.
- The built module is imported as `Chocolatey`.
- Add an `Unreleased` changelog entry in `CHANGELOG.md` for behavior or workflow changes.

## Instruction files

- Follow the targeted rules in `.github/instructions/*.instructions.md`.
- Use `.github/skills/validate-changes/SKILL.md` for validation scope selection.
