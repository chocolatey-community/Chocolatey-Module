<#
.SYNOPSIS
    Creates completion results for Chocolatey feature names.

.DESCRIPTION
    Gets configured Chocolatey feature names and turns them into PowerShell
    completion results.

.PARAMETER WordToComplete
    Current token text that should be matched against feature names.

.EXAMPLE
    New-ChocolateyCompletionResultForFeatureName -WordToComplete 'show'
#>
function New-ChocolateyCompletionResultForFeatureName
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
        $featureNames = Get-ChocolateyFeature | Select-Object -ExpandProperty 'Name'
        New-ChocolateyCompletionResult -Value $featureNames -WordToComplete $WordToComplete
    }
    catch [System.Management.Automation.CommandNotFoundException], [System.Management.Automation.ItemNotFoundException]
    {
        return
    }
}
