# Licensed Chocolatey

This module now includes public commands to install and remove a Chocolatey license file:

- `Install-ChocolateyLicense`
- `Remove-ChocolateyLicense`
- `Save-ChocolateyPackage`

## Installing a license

You can install a license either from a file path or from raw XML content.

### From a file

```powershell
Install-ChocolateyLicense -Path 'C:\secure\chocolatey.license.xml'
```

### From XML content

```powershell
$licenseXml = Get-Content -Path 'C:\secure\chocolatey.license.xml' -Raw
Install-ChocolateyLicense -Content $licenseXml
```

The command writes the license to Chocolatey's standard machine-wide location:

```text
<ChocolateyInstall>\license\chocolatey.license.xml
```

If a license file already exists, `Install-ChocolateyLicense` overwrites it.

## Removing a license

To revert a machine back to unlicensed Chocolatey behavior:

```powershell
Remove-ChocolateyLicense
```

This removes:

```text
<ChocolateyInstall>\license\chocolatey.license.xml
```

## Licensed extension compatibility warning

If the license file exists but `chocolatey.extension` is not installed yet, Chocolatey can emit a compatibility warning similar to:

```text
A valid Chocolatey license was found, but the chocolatey.licensed.dll assembly could not be loaded:
```

The module now surfaces that message on the **warning stream** and ignores it when parsing package list output, so it is no longer misinterpreted as installed package data.

You should still install the licensed extension promptly after installing the license:

```powershell
Install-ChocolateyPackage -Name 'chocolatey.extension'
```

## Downloading or internalizing packages

With the licensed extension installed, you can save packages locally and use
internalization features through:

```powershell
Save-ChocolateyPackage -Name 'notepadplusplus.install' -Internalize
```

If you use licensed-only `Save-ChocolateyPackage` parameters such as
`-Internalize`, `-UseDownloadCache`, or `-SkipVirusCheck` without first
installing a Chocolatey license, the command throws before invoking Chocolatey.

## Recommended sequence

1. Install Chocolatey CLI.
2. Install the Chocolatey license.
3. Install `chocolatey.extension`.
4. Continue with the rest of your licensed configuration.
