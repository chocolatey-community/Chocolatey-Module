<#
.SYNOPSIS
    Creates completion results for Chocolatey package names.

.DESCRIPTION
    Gets local Chocolatey package names and turns them into PowerShell
    completion results.

.PARAMETER WordToComplete
    Current token text that should be matched against local package names.

.EXAMPLE
    New-ChocolateyCompletionResultForPackageName -WordToComplete 'git'
#>
function New-ChocolateyCompletionResultForPackageName
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.CompletionResult[]])]
    param
    (
        [Parameter()]
        [AllowEmptyString()]
        [string]
        $WordToComplete = ''
    )

    try
    {
        $packageNames = Get-ChocolateyPackage | Select-Object -ExpandProperty 'Name'
        New-ChocolateyCompletionResult -Value $packageNames -WordToComplete $WordToComplete
    }
    catch [System.Management.Automation.CommandNotFoundException], [System.Management.Automation.ItemNotFoundException]
    {
        return
    }
}
