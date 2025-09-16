
<#
.SYNOPSIS
    Test Whether a setting is set, enabled or not found

.DESCRIPTION
    Some settings might not be available in your version or SKU.
    This command allows you to test the values of a named setting.

.PARAMETER Name
    Name of the Setting to verify

.PARAMETER Value
    Test if the Setting value provided matches with the one set on the config file.

.PARAMETER Unset
    Test if the Setting is disabled, the default is to test if the feature is enabled.

.EXAMPLE
    Test-ChocolateySetting -Name SettingName -value ''

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsConfig
#>
function Test-ChocolateySetting
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding(DefaultParameterSetName = 'Set')]
    [OutputType([Bool])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Setting')]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String]
        $Value,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Unset')]
        [switch]
        $Unset
    )

    begin
    {
        $chocoCmd = Get-ChocolateyCommand
    }

    process
    {
        if (-not ($setting = Get-ChocolateySetting -Name $Name))
        {
            Write-Warning -Message "Chocolatey Setting $Name cannot be found."
            return $false
        }

        Write-Verbose -Message ('Setting ''{0}'' set to ''{1}''.' -f $setting.Name, $setting.Value)

        if ($Unset)
        {
            $value = ''
        }
        else
        {
            $value = $ExecutionContext.InvokeCommand.ExpandString($value).TrimEnd(@('/', '\'))
        }

        if ([string]$Setting.value -eq $Value)
        {
            Write-Verbose -Message ("The Chocolatey Setting {0} is set to '{1}' as expected." -f $Name, $value)
            return $true
        }
        else
        {
            Write-Verbose -Message ("The Chocolatey Setting {0} is NOT set to '{1}' as expected:{2}" -f $Name, $Setting.value, $value)
            return $false
        }
    }
}
