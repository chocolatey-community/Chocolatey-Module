<#
.SYNOPSIS
    Registers Chocolatey argument completers for PowerShell commands.

.DESCRIPTION
    Adds PowerShell-native argument completers for Chocolatey wrapper commands
    by registering scriptblocks that defer to focused completion-result helpers.

.EXAMPLE
    Register-ChocolateyArgumentCompleter
#>
function Register-ChocolateyArgumentCompleter
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    ()

    $packageNameCompleter = {
        param
        (
            [Parameter()]
            [string]
            $CommandName,

            [Parameter()]
            [string]
            $ParameterName,

            [Parameter()]
            [string]
            $WordToComplete,

            [Parameter()]
            [System.Management.Automation.Language.CommandAst]
            $CommandAst,

            [Parameter()]
            [System.Collections.IDictionary]
            $FakeBoundParameters
        )

        New-ChocolateyCompletionResultForPackageName -WordToComplete $WordToComplete
    }

    $pinNameCompleter = {
        param
        (
            [Parameter()]
            [string]
            $CommandName,

            [Parameter()]
            [string]
            $ParameterName,

            [Parameter()]
            [string]
            $WordToComplete,

            [Parameter()]
            [System.Management.Automation.Language.CommandAst]
            $CommandAst,

            [Parameter()]
            [System.Collections.IDictionary]
            $FakeBoundParameters
        )

        New-ChocolateyCompletionResultForPinName -WordToComplete $WordToComplete
    }

    $sourceNameCompleter = {
        param
        (
            [Parameter()]
            [string]
            $CommandName,

            [Parameter()]
            [string]
            $ParameterName,

            [Parameter()]
            [string]
            $WordToComplete,

            [Parameter()]
            [System.Management.Automation.Language.CommandAst]
            $CommandAst,

            [Parameter()]
            [System.Collections.IDictionary]
            $FakeBoundParameters
        )

        New-ChocolateyCompletionResultForSourceName -WordToComplete $WordToComplete
    }

    $featureNameCompleter = {
        param
        (
            [Parameter()]
            [string]
            $CommandName,

            [Parameter()]
            [string]
            $ParameterName,

            [Parameter()]
            [string]
            $WordToComplete,

            [Parameter()]
            [System.Management.Automation.Language.CommandAst]
            $CommandAst,

            [Parameter()]
            [System.Collections.IDictionary]
            $FakeBoundParameters
        )

        New-ChocolateyCompletionResultForFeatureName -WordToComplete $WordToComplete
    }

    $settingNameCompleter = {
        param
        (
            [Parameter()]
            [string]
            $CommandName,

            [Parameter()]
            [string]
            $ParameterName,

            [Parameter()]
            [string]
            $WordToComplete,

            [Parameter()]
            [System.Management.Automation.Language.CommandAst]
            $CommandAst,

            [Parameter()]
            [System.Collections.IDictionary]
            $FakeBoundParameters
        )

        New-ChocolateyCompletionResultForSettingName -WordToComplete $WordToComplete
    }

    Register-ArgumentCompleter -CommandName @(
        'Compare-ChocolateyPackage',
        'Get-ChocolateyPackage',
        'Optimize-ChocolateyPackage',
        'Uninstall-ChocolateyPackage',
        'Update-ChocolateyPackage',
        'Add-ChocolateyPin'
    ) -ParameterName 'Name' -ScriptBlock $packageNameCompleter

    Register-ArgumentCompleter -CommandName @(
        'Compare-ChocolateyPackage',
        'Find-ChocolateyPackage',
        'Install-ChocolateyPackage',
        'Publish-ChocolateyPackage',
        'Save-ChocolateyPackage',
        'Uninstall-ChocolateyPackage',
        'Update-ChocolateyPackage'
    ) -ParameterName 'Source' -ScriptBlock $sourceNameCompleter

    Register-ArgumentCompleter -CommandName @(
        'Get-ChocolateyPin',
        'Remove-ChocolateyPin',
        'Test-ChocolateyPin'
    ) -ParameterName 'Name' -ScriptBlock $pinNameCompleter

    Register-ArgumentCompleter -CommandName @(
        'Get-ChocolateySource',
        'Test-ChocolateySource',
        'Enable-ChocolateySource',
        'Disable-ChocolateySource',
        'Unregister-ChocolateySource'
    ) -ParameterName 'Name' -ScriptBlock $sourceNameCompleter

    Register-ArgumentCompleter -CommandName 'Get-ChocolateyFeature' -ParameterName 'Feature' -ScriptBlock $featureNameCompleter
    Register-ArgumentCompleter -CommandName @(
        'Test-ChocolateyFeature',
        'Enable-ChocolateyFeature',
        'Disable-ChocolateyFeature'
    ) -ParameterName 'Name' -ScriptBlock $featureNameCompleter

    Register-ArgumentCompleter -CommandName 'Get-ChocolateySetting' -ParameterName 'Setting' -ScriptBlock $settingNameCompleter
    Register-ArgumentCompleter -CommandName @(
        'Test-ChocolateySetting',
        'Set-ChocolateySetting'
    ) -ParameterName 'Name' -ScriptBlock $settingNameCompleter
}
