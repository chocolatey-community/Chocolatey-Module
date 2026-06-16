<#
.SYNOPSIS
    Creates completion results for Chocolatey source names.

.DESCRIPTION
    Gets configured Chocolatey source names and turns them into PowerShell
    completion results.

.PARAMETER WordToComplete
    Current token text that should be matched against source names.

.EXAMPLE
    New-ChocolateyCompletionResultForSourceName -WordToComplete 'int'
#>
function New-ChocolateyCompletionResultForSourceName
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
        $sourceNames = Get-ChocolateySource | Select-Object -ExpandProperty 'Name'
        New-ChocolateyCompletionResult -Value $sourceNames -WordToComplete $WordToComplete
    }
    catch [System.Management.Automation.CommandNotFoundException], [System.Management.Automation.ItemNotFoundException]
    {
        return
    }
}
