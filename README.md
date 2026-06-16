# Chocolatey Module

[![Build status](https://ci.appveyor.com/api/projects/status/ulul0agv7kgo8a7n?svg=true)](https://ci.appveyor.com/project/gaelcolas/chocolatey)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/chocolatey?label=chocolatey%20Preview)](https://www.powershellgallery.com/packages/chocolatey/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/chocolatey?label=chocolatey)](https://www.powershellgallery.com/packages/chocolatey/)

This module intend to wrap around the [Chocolatey Software](https://chocolatey.org) binary, to create a PowerShell interface and provide DSC resources.
The module let you install the chocolatey binary from a Nuget feed, optionally specifying a version, Proxy and Credentials to use.

This project has adopted the Microsoft Open Source Code of Conduct.
For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Command coverage

The table below tracks which `choco` CLI commands have a PowerShell wrapper.
Update this table whenever a new public function is added or removed.

| `choco` command | PowerShell wrapper | Edition |
|---|---|---|
| `list` / `search` | `Get-ChocolateyPackage` | OSS |
| `find` | `Find-ChocolateyPackage` | OSS |
| `info` | — | OSS |
| `install` | `Install-ChocolateyPackage` | OSS |
| `upgrade` | `Update-ChocolateyPackage` | OSS |
| `uninstall` | `Uninstall-ChocolateyPackage` | OSS |
| `outdated` | — | OSS |
| `pin add/remove/list` | `Add-`, `Remove-`, `Get-ChocolateyPin` | OSS |
| `pack` | — | OSS |
| `push` | `Publish-ChocolateyPackage` | OSS |
| `new` | — | OSS |
| `export` | — | OSS |
| `download` | `Save-ChocolateyPackage` | Licensed |
| `source add/remove/list/enable/disable` | `Register-`, `Unregister-`, `Get-`, `Enable-`, `Disable-ChocolateySource` | OSS |
| `config get/set/list` | `Get-`, `Set-ChocolateySetting` | OSS |
| `config unset` | — | OSS |
| `feature enable/disable/list` | `Enable-`, `Disable-`, `Get-ChocolateyFeature` | OSS |
| `apikey add/remove/list` | — | OSS |
| `template list/info` | — | OSS |
| `cache` | — | OSS |
| `sync` | `Sync-ChocolateyPackage` | C4B |
| `optimize` | `Optimize-ChocolateyPackage` | Licensed |
| `convert` | `Convert-ChocolateyPackage` | C4B |

**Not yet implemented (open for contribution):**

- `Get-ChocolateyPackageInfo` — wraps `choco info`; returns detailed metadata for a package from a source
- `Get-ChocolateyOutdatedPackage` — wraps `choco outdated`; lists installed packages that have newer versions available
- `New-ChocolateyPackage` — wraps `choco pack`; creates a `.nupkg` from a `.nuspec`
- `New-ChocolateyPackageScaffold` — wraps `choco new`; scaffolds a new package directory from a template
- `Export-ChocolateyPackage` — wraps `choco export`; exports installed packages to a `packages.config`
- `Set-ChocolateyApiKey` / `Get-ChocolateyApiKey` / `Remove-ChocolateyApiKey` — wraps `choco apikey`
- `Remove-ChocolateySetting` — wraps `choco config unset`
- `Get-ChocolateyPackageTemplate` / `Install-ChocolateyPackageTemplate` / `Uninstall-ChocolateyPackageTemplate` — wraps `choco template`
- `Clear-ChocolateyCache` — wraps `choco cache`

## PowerShell argument completers

Importing the module registers PowerShell argument completers for common
Chocolatey wrapper commands.

- Package name completion (installed packages) for `Get-ChocolateyPackage`,
  `Uninstall-ChocolateyPackage`, `Update-ChocolateyPackage`,
  `Compare-ChocolateyPackage`, `Optimize-ChocolateyPackage`, and `Add-ChocolateyPin`
- Pin name completion for `Get-ChocolateyPin`, `Remove-ChocolateyPin`, and
  `Test-ChocolateyPin`
- Source name completion for `Get-ChocolateySource`, `Test-ChocolateySource`,
  `Enable-ChocolateySource`, `Disable-ChocolateySource`,
  `Unregister-ChocolateySource`, `Install-ChocolateyPackage`,
  `Update-ChocolateyPackage`, `Uninstall-ChocolateyPackage`,
  `Save-ChocolateyPackage`, `Find-ChocolateyPackage`,
  `Compare-ChocolateyPackage`, and `Publish-ChocolateyPackage`
- Feature name completion for `Get-ChocolateyFeature`,
  `Test-ChocolateyFeature`, `Enable-ChocolateyFeature`, and
  `Disable-ChocolateyFeature`
- Setting name completion for `Get-ChocolateySetting`,
  `Test-ChocolateySetting`, and `Set-ChocolateySetting`

The completers are local-only and do not query remote package feeds. They use
the current local Chocolatey package, pin, source, feature, and setting data to
keep tab completion responsive.

## Contributing

Please check out common DSC Community [contributing guidelines](CONTRIBUTING.md).
