# Chocolatey PowerShell module
<sup>*chocolatey v#.#.#*</sup>

Welcome to the Chocolatey PowerShell Module wiki!

## Getting started

To get started either:

- Install from the PowerShell Gallery using PowerShellGet by running the
  following command:

```powershell
Install-Module -Name chocolatey -Repository PSGallery
```

- Download chocolatey from the [PowerShell Gallery](https://www.powershellgallery.com/packages/chocolatey)
  and then unzip it to one of your PowerShell modules folders (such as
  `$env:ProgramFiles\WindowsPowerShell\Modules`).

To confirm installation, run the below command and ensure you see the chocolatey
DSC resources available:

```powershell
Get-Command -Module chocolatey
```
