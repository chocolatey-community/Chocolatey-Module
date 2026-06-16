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

## PowerShell argument completers

Importing the module registers PowerShell argument completers for common
Chocolatey wrapper commands.

- Package name completion for `Get-ChocolateyPackage`,
  `Uninstall-ChocolateyPackage`, `Update-ChocolateyPackage`, and
  `Add-ChocolateyPin`
- Pin name completion for `Get-ChocolateyPin`, `Remove-ChocolateyPin`, and
  `Test-ChocolateyPin`
- Source name completion for `Get-ChocolateySource`, `Test-ChocolateySource`,
  `Enable-ChocolateySource`, `Disable-ChocolateySource`, and
  `Unregister-ChocolateySource`
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
