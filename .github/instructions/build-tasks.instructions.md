---
description: 'Build and workflow authoring instructions'
applyTo: '{build.ps1,build.yaml,.build/tasks/*.build.ps1,.pipelines/*.yml,.pipelines/*.yaml,.github/workflows/*.yml,.github/workflows/*.yaml}'
---

# Build and Workflow Development Guidelines

## Entry points

- Use `build.ps1` as the only bootstrap, build, and test entrypoint.
- Keep `build.ps1` focused on bootstrap/runtime parameters.
- Prefer changing `build.yaml` when altering workflow composition, copied assets, default test paths, or coverage behavior.
- If new local InvokeBuild task files are added later, place them under `.build/tasks/` and wire them through `build.yaml`.

## Dependency and environment rules

- Restore dependencies with `./build.ps1 -ResolveDependency -Tasks noop`.
- Do not manually edit `PSModulePath`; let `build.ps1` handle it.
- Keep required modules resolving into `output\RequiredModules`.
- When validating long builds or tests, pipe `./build.ps1 ...` output through `Tee-Object` to a log outside `output\*`.

## Logging pattern

```powershell
$logPath = Join-Path -Path $env:TEMP -ChildPath 'Chocolatey.validate-build.log'

if (Test-Path $logPath)
{
    Remove-Item $logPath -Force
}

./build.ps1 -Tasks build 2>&1 |
    Tee-Object -FilePath $logPath
```

- Do not wrap `./build.ps1` invocations in `| Select-Object -Last <N>` or other buffering filters.
- Read logs separately with `Get-Content -Tail` or `Select-String`.

## Task and pipeline safety

- Keep artifact context explicit when a workflow is packaging something other than the default module output.
- Reuse existing Sampler-driven patterns instead of re-deriving build paths or version information independently.
- Treat changes to `build.ps1`, `build.yaml`, `.pipelines`, or Copilot setup workflows as validation-impacting changes.
- Run at least `./build.ps1 -Tasks test` after workflow wiring changes.
