
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

    $resolveChocolateyInstallPath = {
        param
        (
            [Parameter()]
            [System.String]
            $Path
        )

        if ([string]::IsNullOrEmpty($Path))
        {
            return $null
        }

        try
        {
            $resolvedPath = (Resolve-Path -Path $Path -ErrorAction 'Stop').Path
        }
        catch
        {
            return $null
        }

        $rootChocoExe = Join-Path -Path $resolvedPath -ChildPath 'choco.exe'
        $binChocoExe = Join-Path -Path $resolvedPath -ChildPath 'bin\choco.exe'

        if ((Test-Path -Path $rootChocoExe) -or (Test-Path -Path $binChocoExe))
        {
            return $resolvedPath
        }

        return $null
    }

    $processChocolateyInstall = [System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Process')
    $machineChocolateyInstall = [System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine')
    $chocolateyInstall = & $resolveChocolateyInstallPath $processChocolateyInstall

    if (-not [string]::IsNullOrEmpty($chocolateyInstall))
    {
        Write-Debug -Message ('ChocolateyInstall path Process environment variable already set to ''{0}''.' -f $chocolateyInstall)
        return $chocolateyInstall
    }

    $chocolateyInstall = & $resolveChocolateyInstallPath $machineChocolateyInstall

    if (-not [string]::IsNullOrEmpty($chocolateyInstall))
    {
        Write-Debug -Message ('ChocolateyInstall path Machine environment variable already set to ''{0}''.' -f $chocolateyInstall)
        return $chocolateyInstall
    }

    # Test if current user is admin
    # $isAdmin = Assert-ChocolateyIsElevated
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $chocoCmd = Get-ChocolateyCommand -ErrorAction 'Ignore' -Force
    if ($null -ne $chocoCmd -and -not [string]::IsNullOrEmpty($chocoCmd.Path))
    {
        $chocoBin = Split-Path -Path $chocoCmd.Path -Parent -ErrorAction 'Ignore'
        if (-not [string]::IsNullOrEmpty($chocoBin))
        {
            if ((Split-Path -Path $chocoBin -Leaf -ErrorAction 'Ignore') -ieq 'bin')
            {
                $chocolateyInstall = Split-Path -Path $chocoBin -Parent -ErrorAction 'Ignore'
            }
            else
            {
                $chocolateyInstall = $chocoBin
            }

            $chocolateyInstall = & $resolveChocolateyInstallPath $chocolateyInstall
            if (-not [string]::IsNullOrEmpty($chocolateyInstall))
            {
                Write-Debug -Message ('Resolved Chocolatey install path from command discovery to ''{0}''.' -f $chocolateyInstall)
                return $chocolateyInstall
            }
        }
    }

    # Guess Chocolatey install path from the standard location.
    $chocoInstallFolder = Join-Path -Path $env:ProgramData -ChildPath 'chocolatey'
    # take the standard Chocolatey location, validate that it really looks like a Chocolatey install, and only keep it if it is valid.
    $chocolateyInstall = & $resolveChocolateyInstallPath $chocoInstallFolder

    if (-not [string]::IsNullOrEmpty($chocolateyInstall))
    {
        Write-Debug -Message ('Resolved Chocolatey install path from standard location ''{0}''.' -f $chocolateyInstall)

        # Only if you're admin, fix the ChocolateyInstall folder when it was missing.
        if ($true -eq $isAdmin)
        {
            [Environment]::SetEnvironmentVariable('ChocolateyInstall', $chocolateyInstall, 'Machine')
        }

        return $chocolateyInstall
    }

    Write-Error -Message 'The chocolatey install Machine environment variable couldn''t be found.'
}
