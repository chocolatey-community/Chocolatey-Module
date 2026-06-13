<#
.SYNOPSIS
    Tests whether a Chocolatey license file is installed.

.DESCRIPTION
    Returns `$true` when the standard Chocolatey license file exists under the
    resolved Chocolatey installation directory; otherwise returns `$false`.

.PARAMETER InstallDir
    Path where Chocolatey is installed. Defaults to the resolved
    ChocolateyInstall path.

.EXAMPLE
    Test-ChocolateyLicenseInstalled

    Returns whether a Chocolatey license file is currently installed.
#>
function Test-ChocolateyLicenseInstalled
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir = (Get-ChocolateyInstallPath -ErrorAction 'Stop')
    )

    $licensePath = Join-Path -Path $InstallDir -ChildPath 'license\chocolatey.license.xml'
    return (Test-Path -Path $licensePath -PathType 'Leaf')
}
