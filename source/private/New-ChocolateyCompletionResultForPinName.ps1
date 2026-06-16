<#
.SYNOPSIS
    Creates completion results for Chocolatey pin names.

.DESCRIPTION
    Gets Chocolatey pin names and turns them into PowerShell completion
    results.

.PARAMETER WordToComplete
    Current token text that should be matched against pin names.

.EXAMPLE
    New-ChocolateyCompletionResultForPinName -WordToComplete 'git'
#>
function New-ChocolateyCompletionResultForPinName
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
        $pinNames = Get-ChocolateyPin | Select-Object -ExpandProperty 'Name'
        New-ChocolateyCompletionResult -Value $pinNames -WordToComplete $WordToComplete
    }
    catch [System.Management.Automation.CommandNotFoundException], [System.Management.Automation.ItemNotFoundException]
    {
        return
    }
}
