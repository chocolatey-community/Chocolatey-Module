
<#
.SYNOPSIS
    Test if the Chocolatey Software is installed.

.DESCRIPTION
    To test whether the Chocolatey Software is installed, it first look for the Command choco.exe.
    It then check if it's installed in the InstallDir path, if provided.

.PARAMETER InstallDir
    To ensure the software is installed in the given directory. If not specified,
    it will only test if the command choco.exe is available.

.EXAMPLE
    Test-ChocolateyInstall #Test whether the Chocolatey Software is installed

.NOTES
General notes
#>
function Test-ChocolateyInstall
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstallDir
    )

    Write-Verbose -Message 'Loading machine Path Environment variable into session.'
    # This is to reload Path written to registry but not yet loaded into the process.
    $envPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    [Environment]::SetEnvironmentVariable($envPath, 'Process')

    if (-not [string]::IsNullOrEmpty($InstallDir))
    {
        # Resolve the InstallDir path if specified
        $InstallDir = (Resolve-Path -Path $InstallDir -ErrorAction Stop).Path
        $chocoPath = Join-Path -Path $InstallDir -ChildPath 'choco.exe' -Resolve -ErrorAction SilentlyContinue
        Write-Verbose -Message ('Resolved choco path to {0}' -f $chocoPath)
        $chocoCmd = @(Get-Command $chocoPath -CommandType 'Application' -ErrorAction 'SilentlyContinue')[0]
    }
    else
    {
        # Lookup for the choco.exe command in Path
        $chocoCmd = @(Get-Command 'choco.exe' -CommandType 'Application' -ErrorAction 'SilentlyContinue')[0]
    }


    if (-not [string]::isNullOrEmpty($chocoCmd.Path))
    {
        Write-Verbose -Message ('Chocolatey Software found in {0} with version {1}' -f $chocoCmd.Path, $chocoCmd.Version)
        $chocoInPath = @(Get-Command 'choco.exe' -CommandType 'Application' -ErrorAction 'SilentlyContinue')[0]
        if ($null -eq $chocoInPath)
        {
            Write-Verbose -Message ('Chocolatey Software not found in Path environment variable.')
        }
        elseif ($chocoInPath.Path -ne $chocoCmd.Path)
        {
            # One of them might be the shim
            Write-Verbose -Message ('Chocolatey Software version {0} found in Path environment variable at {1}' -f $chocoInPath.Version, $chocoInPath.Path)
        }
        else
        {
            Write-Debug -Message ('Chocolatey Software in InstallDir corresponds to the first one found in $Env:Path')
        }

        return $true
    }
    else
    {
        Write-Verbose -Message 'Chocolatey Software not found.'
        return $false
    }
}
