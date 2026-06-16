# PowerShell argument completers

The Chocolatey module registers PowerShell argument completers when you import
the module.

## Supported completions

- Package names for `Get-ChocolateyPackage`, `Uninstall-ChocolateyPackage`,
  `Update-ChocolateyPackage`, and `Add-ChocolateyPin`
- Pin names for `Get-ChocolateyPin`, `Remove-ChocolateyPin`, and
  `Test-ChocolateyPin`
- Source names for `Get-ChocolateySource`, `Test-ChocolateySource`,
  `Enable-ChocolateySource`, `Disable-ChocolateySource`, and
  `Unregister-ChocolateySource`
- Feature names for `Get-ChocolateyFeature`, `Test-ChocolateyFeature`,
  `Enable-ChocolateyFeature`, and `Disable-ChocolateyFeature`
- Setting names for `Get-ChocolateySetting`, `Test-ChocolateySetting`, and
  `Set-ChocolateySetting`

## Behavior

- Completers are registered during module import.
- Completion is based on local Chocolatey state.
- Remote package feeds are not queried during completion.
- Values containing spaces are quoted automatically in the inserted completion
  text.

## Example

```powershell
Import-Module Chocolatey

Update-ChocolateyPackage -Name <TAB>
Set-ChocolateySetting -Name <TAB>
Disable-ChocolateyFeature -Name <TAB>
```
