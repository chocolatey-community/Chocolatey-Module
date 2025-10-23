
<#
.SYNOPSIS
Gets environment variable ChocolateyInstall from Machine scope.

.DESCRIPTION
This command gets the machine-scoped environment variable 'ChocolateyInstall',
and make sure it's set if the folder is present but variable is not.
If the variable is not set and the chocolatey folder can't be found,
the command will write to the error stream.

.EXAMPLE
Get-ChocolateyInstallPath -ErrorAction 'Stop'

#>
function Get-ChocolateyInstallPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        #
    )

    # Update path from registry if not set in process
    Repair-ProcessEnvPath

    # Get ChocolateyInstall path from HKLM
    $chocolateyInstall = [System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine')

    # Test if current user is admin
    # $isAdmin = Assert-ChocolateyIsElevated
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Guess Chocolatey install executable path
    $chocoInstallFolder = Join-Path -Path $env:ProgramData -ChildPath 'chocolatey'
    $chocoExe = Join-Path -Path $chocoInstallFolder -ChildPath 'choco.exe'

    $chocoCmd = Get-ChocolateyCommand -InstallDir $chocoInstallFolder -ErrorAction SilentlyContinue -Force
    if ($chocoCmd.path -eq $chocoExe)
    {
        Write-Debug -Message ('choco.exe found at {0}.' -f $chocoExe)
    }

    # todo: elseif ()

    if ([string]::IsNullOrEmpty($chocolateyInstall) -and (Test-Path -Path $chocolateyInstall))
    {
        # Choco install is set to the correct location
        $chocolateyInstall = $chocoInstallFolder
        # only if you're admin, fix the ChocolateyInstall folder
        if ($true -eq $isAdmin)
        {
            [Environment]::SetEnvironmentVariable('ChocolateyInstall', $chocolateyInstall, 'Machine')
        }
    }
    elseif (-not [string]::IsNullOrEmpty($chocolateyInstall))
    {
        Write-Debug -Message ('ChocolateyInstall path Machine environment variable already set to ''{0}''.' -f $chocolateyInstall)
    }
    else
    {
        Write-Error -Message 'The chocolatey install Machine environment variable couldn''t be found.'
    }

    return $chocolateyInstall
}
