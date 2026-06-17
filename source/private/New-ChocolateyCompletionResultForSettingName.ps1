<#
.SYNOPSIS
    Creates completion results for Chocolatey setting names.

.DESCRIPTION
    Gets configured Chocolatey setting names and turns them into PowerShell
    completion results.

.PARAMETER WordToComplete
    Current token text that should be matched against setting names.

.EXAMPLE
    New-ChocolateyCompletionResultForSettingName -WordToComplete 'cache'
#>
function New-ChocolateyCompletionResultForSettingName
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
        $settingNames = Get-ChocolateySetting | Select-Object -ExpandProperty 'key'
        New-ChocolateyCompletionResult -Value $settingNames -WordToComplete $WordToComplete
    }
    catch [System.Management.Automation.CommandNotFoundException], [System.Management.Automation.ItemNotFoundException]
    {
        return
    }
}
