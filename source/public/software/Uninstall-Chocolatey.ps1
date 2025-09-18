
<#
.SYNOPSIS
    Attempts to remove the Chocolatey Software form the system.

.DESCRIPTION
    This command attempts to clean the system from the Chocolatey Software files.
    It first look into the provided $InstallDir, or in the $Env:ChocolateyInstall if not provided.
    If the $InstallDir provided is $null or empty, it will attempts to find the Chocolatey folder
    from the choco.exe command path.
    If no choco.exe is found under the $InstallDir, it will fail to uninstall.
    This command also remove the $InstallDir from the Path.

.PARAMETER InstallDir
    Installation Directory to remove Chocolatey from. Default looks up in $Env:ChocolateyInstall
    Or, if specified with an empty/$null value, tries to find from the choco.exe path.

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.

.EXAMPLE
    Uninstall-Chocolatey -InstallDir ''
    Will uninstall Chocolatey from the location of Choco.exe if found from $Env:PATH
#>
function Uninstall-Chocolatey
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter()]
        [System.String]
        $InstallDir = $(Get-ChocolateyInstallPath -ErrorAction 'SilentlyContinue'),

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    process
    {
        #If InstallDir is empty or null, select from the choco.exe if available
        if (-not $InstallDir)
        {
            Write-Debug -Message "Attempting to find the choco.exe command."
            $chocoCmd = Get-ChocolateyCommand
            #Install dir is where choco.exe is found minus \bin subfolder
            if (-not ($chocoCmd -and ($chocoBin = Split-Path -Parent $chocoCmd.Path -ErrorAction SilentlyContinue)))
            {
                Write-Warning -Message "Could not find Chocolatey Software Install Folder."
                return
            }
            else
            {
                Write-Debug -Message ('Resolving {0}\..' -f $chocoBin)
                $InstallDir = Join-Path -Path $chocoBin -ChildPath '..' -Resolve
            }
        }

        Write-Verbose -Message "Chocolatey Installation Folder is $InstallDir"
        $chocoFiles = @('choco.exe', 'chocolatey.exe', 'cinst.exe', 'cuninst.exe', 'clist.exe', 'cpack.exe', 'cpush.exe',
            'cver.exe', 'cup.exe').Foreach{ $_; "$_.old" } #ensure the .old are also removed

        #If Install dir does not have a choco.exe, do nothing as it could delete unwanted files
        if
        (
            [string]::IsNullOrEmpty($InstallDir) -or
            -not ((Test-Path -Path $InstallDir) -and (Test-Path -Path "$InstallDir\choco.exe"))
        )
        {
            Write-Warning -Message 'Chocolatey Installation Folder Not found.'
            return
        }

        $script:ChocoCmd = $null #clear the cached choco command

        #all files under $InstallDir
        # Except those in $InstallDir\lib unless $_.Basename -in $chocoFiles
        # Except those in $installDir\bin unless $_.Basename -in $chocoFiles
        $FilesToRemove = Get-ChildItem $InstallDir -Recurse | Where-Object {
            -not (
                (
                    $_.FullName -match [regex]::escape((Join-Path -path $InstallDir -ChildPath 'lib')) -or
                    $_.FullName -match [regex]::escape((Join-Path -path $InstallDir -ChildPath 'bin'))
                ) -and
                $_.Name -notin $chocoFiles
            )
        }

        Write-Debug -Message ($FilesToRemove -join "`r`n>>  ")

        if ($Pscmdlet.ShouldProcess('chocoFiles'))
        {
            $FilesToRemove | Sort-Object -Descending FullName | remove-item -Force -recurse -ErrorAction 'SilentlyContinue' -Confirm:$false
        }

        Write-Verbose -Message "Removing $InstallDir from the Path and the ChocolateyInstall Environment variable."
        [Environment]::SetEnvironmentVariable('ChocolateyInstall', $null, 'Machine')
        [Environment]::SetEnvironmentVariable('ChocolateyInstall', $null, 'Process')
        $AllPaths = [Environment]::GetEnvironmentVariable('Path', 'machine').split(';').where{
            -not [string]::IsNullOrEmpty($_) -and
            $_ -notmatch ('^{0}\\bin$' -f ([regex]::escape($InstallDir)))
        } | Select-Object -unique

        Write-Debug -Message 'Reset the machine Path without choco (and dedupe/no null).'
        Write-Debug -Message ($AllPaths | Format-Table -AutoSize | Out-String)
        [Environment]::SetEnvironmentVariable('Path', ($AllPaths -Join [io.path]::PathSeparator), 'Machine')

        #refresh after uninstall
        $envPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        [Environment]::SetEnvironmentVariable($envPath, 'process')
        Write-Verbose -Message 'Uninstallation complete'
    }
}
