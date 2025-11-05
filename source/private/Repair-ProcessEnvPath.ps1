
<#
.SYNOPSIS
Repair $Env:Path from what's missing from Machine path.

.DESCRIPTION
This function reads what's currently set in the $Env:Path variable and
adds what's missing from the Machine path.
The function can also exclude some paths from being in the Process level Path variable.

.PARAMETER PathVarAtLoadTime
The Path variable as it was at module load time. By default, it's the current $Env:Path split into an array.

.PARAMETER ExcludedPaths
Paths to exclude from the Process level Path variable.

.EXAMPLE
Repair-ProcessEnvPath -ExcludedPaths @('C:\Some\Path\To\Exclude','D:\Another\Path\To\Exclude')
Repairs the Process level Path variable by adding any missing entries from Machine level Path,
excluding the specified paths.

.NOTES
    This is a private function used by the module.
#>
function Repair-ProcessEnvPath
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', $null, Scope='Function', Justification = 'Used within the function.')]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string[]]
        $PathVarAtLoadTime = ($Env:Path -split [IO.Path]::PathSeparator),

        [Parameter()]
        [string[]]
        $ExcludedPaths = @()
    )

    [bool]$pathMissing = $false
    # Store the current $Env:Path
    [string[]]$currentEnvPaths = ($Env:Path -split [IO.Path]::PathSeparator).ForEach{ $_.ToLower().TrimEnd('\') }
    # Add any missing entries from Machine level Path variable
    [string[]]$machinePaths = [Environment]::GetEnvironmentVariable('Path', 'Machine') -split [IO.Path]::PathSeparator
    $machinePaths.Where{
        # remove empty paths
        -not [string]::IsNullOrEmpty($_) -and
        # remove paths already in current $Env:Path
        -not $currentEnvPaths.Contains($_.ToLower().TrimEnd('\'))
    }.ForEach({
        # Add missing paths to $PathVarAtLoadTime
        Write-Debug -Message ("Adding missing Path entry from Machine level: {0}" -f $_)
        $PathVarAtLoadTime += $_
        $pathMissing = $true
    })

    # excluding any in $ExcludedPaths
    $ExcludedPaths = $ExcludedPaths.ForEach{ $_.ToLower().TrimEnd('\') }
    $PathVarAtLoadTime = $PathVarAtLoadTime.Where{
        -not $ExcludedPaths.Contains($_.ToLower().TrimEnd('\'))
    }

    # Finally, set the Process level Path variable if needed
    if ($PathVarAtLoadTime.count -eq $currentEnvPaths.count -and -not $pathMissing)
    {
        Write-Debug -Message 'No changes made to Process level Path variable ($Env:Path)'
    }
    else
    {
        Write-Debug -Message ('Setting Process level Path variable: {0}{1}' -f "`r`n",($PathVarAtLoadTime -join "`r`n"))
        $Env:Path = $PathVarAtLoadTime -join [IO.Path]::PathSeparator
        [Environment]::SetEnvironmentVariable('Path', $Env:Path, 'Process')
    }
}
