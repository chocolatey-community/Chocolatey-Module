# Changelog for chocolatey

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Fixing the documentation upload step in the build pipeline.
- Added missing RequiredModules entry for platyPS.
- Fixed [#99](https://github.com/chocolatey-community/Chocolatey-Module/issues/99)
  where Update-ChocolateyPackage would not handle 'latest' version correctly.

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
