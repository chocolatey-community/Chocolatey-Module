# Changelog for chocolatey

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Added repository Copilot setup and instructions covering cloud-agent bootstrap,
  `build.ps1` validation patterns, Public/Private test coupling, and PowerShell
  coding conventions.
- Clarified the PowerShell coding conventions to prefer `$null = <expression>`
  over piping to `Out-Null`.
- Clarified in Copilot instructions that the module is Windows-only while still
  requiring compatibility with Windows PowerShell 5.1 and PowerShell 7.
- Split Copilot guidance into targeted instruction files and added a local
  `validate-changes` skill plus class-export/type-accelerator guidance for
  `source\suffix.ps1`.
- Updated the bootstrap scripts and dependency configuration to the newer
  Sampler pattern with PSResourceGet support while keeping repo-specific
  compatibility.
- Changed the bootstrap defaults to prefer ModuleFast on PowerShell 7.2+
  while retaining PSResourceGet as the fallback on older PowerShell hosts.
- Updated the Copilot setup workflow to resolve the built module artifact
  dynamically and run on Windows so the built module can be imported during
  environment validation.
- Hardened Chocolatey delimited output parsing so licensed-extension
  compatibility output is surfaced as warnings or errors and is no longer
  treated as installed package data.
- Added regression coverage for the `ChocolateyPackage` DSC/class `Get()`
  path so licensed-extension compatibility warnings still resolve to an
  absent package state instead of breaking package discovery.
- Added `Install-ChocolateyLicense` to install or overwrite a Chocolatey
  license file from a source path or XML content.
- Added `Remove-ChocolateyLicense` to remove the Chocolatey license file and
  revert to unlicensed Chocolatey behavior.
- Added `Save-ChocolateyPackage` to wrap `choco download`, including licensed
  download, virus-scan, and internalization switches.
- Added PowerShell argument completer registrations for local Chocolatey package, pin, source,
  feature, and setting names across the module's wrapper commands.
- Aligned the `ChocolateyPackage` DSC class more closely with the DSC v3 class
  resource contract by adding tuple-based static `Test` and `Set` methods,
  `InstanceJsonSchema()`, and improved export and delete handling.
- Generalized DSC instance JSON schema generation in `ChocolateyBase` so class
  resources can share the same schema builder.
- Aligned wiki generation with the explicit Sampler docs workflow so content
  from `source\WikiSource` is prepared and published to the GitHub wiki.
- Added a `Home.md` wiki landing page under `source\WikiSource`.
- Added a `LicensedChocolatey.md` wiki page covering license install, removal,
  and the licensed-extension compatibility warning.

### Fixed

- Fixed `Get-ChocolateyInstallPath` to honor a valid non-standard
  `ChocolateyInstall` path before falling back to the default install location.
- `Save-ChocolateyPackage` now throws when licensed-only download parameters are
  used without an installed Chocolatey license file.
- Fixing issue #105 where Uninstall-ChocolateySoftware fails.
- Making version parameter of `Update-ChocolateyPackage` not mandatory.
- Fixing issue #107 to allow for username field to be set on ChocolateySource

## [0.10.4] - 2025-12-05

### Fixed

- Fixing issue #101 where the property `$_name` break DSC v1 compilation.

## [0.10.3] - 2025-10-23

### Fixed

- Fixing the documentation upload step in the build pipeline.
- Added missing RequiredModules entry for platyPS.

## [0.10.2] - 2025-10-23

### Fixed

- Fixed issue where Test-ChocolateyInstall and Get-ChocolateyCommand would not
  refresh the process environment Path variable correctly.

- Fixed issue where Get-ChocolateyInstallPath was updating the path incorrectly.

## [0.10.1] - 2025-10-23

### Created

- Created `Repair-ProcessEnvPath` private function to refresh the process
  environment Path variable from the Machine environment Path variable,
  excluding specified paths.

### Fixed

- Updated how the process Path environment variable is refreshed to avoid
  removing current user or session paths.

### Changed

- Enforced lowercase module name.

## [0.10.0] - 2025-10-22

### Fixed

- Fixed a syntax error ([#85](https://github.com/chocolatey-community/Chocolatey-Module/issues/85)).

### Changed

- DSC Resource ChocolateyPackage: Added a property '_name' only during exports
for DSCv3 that combines Name and Version to uniquely identify package instances.
- Removed the invocation of .Get() for each returned package to speed up exports.

## [0.9.1] - 2025-10-22

### Fixed

- Fixed issue where Get-ChocolateySource would not correctly parse boolean values
  for disabled, bypassProxy, and selfService properties.

## [0.9.0] - 2025-10-14

### Changed

- Refactoring the codebase to improve quality and relevance to latest chocolatey versions.
- Modified project with new Sampler template.
- Invoking choco commands now always add `--no-progress` & `--limit-output`.
- Limiting Get-Command choco to the first result as per [#69](https://github.com/chocolatey-community/Chocolatey/issues/69) on all calls.
- Changed `ChocolateySoftware` to be class-based DSC Resource.
- Changed `ChocolateyPackage` to be class-based DSC Resource.
- Changed `ChocolateySource` to be a class-based DSC Resource.
- Changed `ChocolateyFeature` to be a class-based DSC Resource.

### Added

- Added the `ChocolateyIsInstalled` Azure Automanage Machine Configuration package that validates that Chocolatey is installed.
- Added the `DisableChocolateyCommunitySource` Azure Automanage Machine Configuration package that ensures the Chocolatey Community source is disabled.
- Added repository's Wiki.

### Removed

- Removed SideBySide option as per [#61](https://github.com/chocolatey-community/Chocolatey/issues/61).

### Fixed

- Fixed [#68](https://github.com/chocolatey-community/Chocolatey/issues/68) by
  making sure it's set to the correct Path.  
- Fixed the ChocolateySoftware installation and uninstallation
  (using latest community URL).
- Fixed [#78](https://github.com/chocolatey-community/Chocolatey/issues/78)
  cleanup the script:ChocoCmd cached module variable.
- Fixed issue where `Install-ChocolateyPackage` would output messages directly
  from choco commands.
