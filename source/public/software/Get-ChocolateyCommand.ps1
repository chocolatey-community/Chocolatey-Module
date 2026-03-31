
<#
.SYNOPSIS
    Get the Chocolatey command executable.

.DESCRIPTION
    This function retrieves the path to the Chocolatey command executable (choco.exe).

.PARAMETER InstallDir
    The installation directory of Chocolatey.

.PARAMETER Force
    Whether to force re-evaluation of the Chocolatey command path.

.PARAMETER Force
    Whether to force re-evaluation of the Chocolatey command path.

.EXAMPLE
    Get-ChocolateyCommand -InstallDir 'C:\ProgramData\chocolatey' -Force
#>
function Get-ChocolateyCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        [ValidateNotNullOrEmpty()]
        $InstallDir,

        [Parameter()]
        [switch]
        $Force
    )

    if ($null -ne $script:ChocoCmd -and -not $Force.IsPresent)
    {
        Write-Debug -Message ('Getting Choco.exe from cache')
        return $script:ChocoCmd
    }
    else
    {
        if (-not [string]::IsNullOrEmpty($InstallDir))
        {
            # Resolve the InstallDir path if specified
            $InstallDir = (Resolve-Path -Path $InstallDir -ErrorAction Stop).Path
            $chocoPath = Join-Path -Path $InstallDir -ChildPath 'choco.exe' -Resolve -ErrorAction SilentlyContinue
            Write-Verbose -Message ('Resolved choco path to {0}' -f $chocoPath)
            $script:ChocoCmd = @(Get-Command $chocoPath -CommandType 'Application' -ErrorAction 'Stop')[0]
        }
        else
        {
            Write-Debug -Message 'Loading machine Path Environment variable into session.'
            # This is to reload Path written to registry but not yet loaded into the process.
            Repair-ProcessEnvPath

            # Lookup for the choco.exe command in Path
            Write-Debug -Message ('Looking up chocolatey from Path.')
            $script:ChocoCmd = @(Get-Command 'choco.exe' -CommandType 'Application' -ErrorAction 'Stop')[0]
        }

        Write-Debug -Message ('Chocolatey Software found in {0} with file version {1}' -f $script:ChocoCmd.Path, $script:ChocoCmd.Version)

        return $script:ChocoCmd
    }
}
