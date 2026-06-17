# Chocolatey Module Wiki

The **Chocolatey Module** provides PowerShell commands and DSC resources for installing Chocolatey, managing packages, sources, features, settings, and related automation tasks.

## Start here

- Install Chocolatey CLI with the `ChocolateySoftware` DSC resource.
- Manage packages with the `ChocolateyPackage` DSC resource.
- Manage package sources with the `ChocolateySource` DSC resource.
- Manage Chocolatey settings with the `ChocolateySetting` DSC resource.
- Manage Chocolatey features with the `ChocolateyFeature` DSC resource.
- Install a Chocolatey license with the `Install-ChocolateyLicense` command.
- [PowerShell argument completers](ArgumentCompleters.md)
- [Licensed Chocolatey guidance](LicensedChocolatey.md)

## Migration

- [cChoco migration guide](cChocoMigrationWiki.md)

## Command reference

Generated command pages in the published wiki include:

- `Install-ChocolateySoftware`
- `Install-ChocolateyLicense`
- `Remove-ChocolateyLicense`
- `Save-ChocolateyPackage`
- `Install-ChocolateyPackage`
- `Update-ChocolateyPackage`
- `Uninstall-ChocolateyPackage`
- `Register-ChocolateySource`
- `Set-ChocolateySetting`
- `Enable-ChocolateyFeature`

## DSC resources

Generated DSC resource pages in the published wiki include:

- `ChocolateySoftware`
- `ChocolateyPackage`
- `ChocolateySource`
- `ChocolateySetting`
- `ChocolateyFeature`

## Notes

- The repository is Windows-only.
- The module supports Windows PowerShell 5.1 and PowerShell 7.
- Generated command pages and `_Sidebar.md` are rebuilt from `build.yaml`; keep custom wiki pages in `source\WikiSource`.
