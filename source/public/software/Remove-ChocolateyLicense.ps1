<#
.SYNOPSIS
    Removes the Chocolatey license file.

.DESCRIPTION
    Removes the Chocolatey license file from the standard Chocolatey license
    folder so Chocolatey reverts to unlicensed operation.

.PARAMETER InstallDir
    Path where Chocolatey is installed. Defaults to the resolved
    ChocolateyInstall path.

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you
    really want to run even if the current shell is not elevated.

.EXAMPLE
    Remove-ChocolateyLicense
#>
function Remove-ChocolateyLicense
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir = (Get-ChocolateyInstallPath -ErrorAction 'Stop'),

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    process
    {
        if (-not (Test-Path -Path $InstallDir -PathType 'Container'))
        {
            throw "Chocolatey install directory '$InstallDir' does not exist."
        }

        $licensePath = Join-Path -Path $InstallDir -ChildPath 'license\chocolatey.license.xml'

        if (-not (Test-Path -Path $licensePath -PathType 'Leaf'))
        {
            Write-Warning -Message ("Chocolatey license file '{0}' was not found." -f $licensePath)
            return
        }

        if ($PSCmdlet.ShouldProcess($Env:COMPUTERNAME, ("Remove Chocolatey license from '{0}'" -f $licensePath)))
        {
            Remove-Item -Path $licensePath -Force -ErrorAction 'Stop'
        }
    }
}
