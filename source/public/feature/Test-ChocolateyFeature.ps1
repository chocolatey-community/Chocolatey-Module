
<#
.SYNOPSIS
    Test Whether a feature is disabled, enabled or not found

.DESCRIPTION
    Some feature might not be available in your version or SKU.
    This command allows you to test the state of that feature.

.PARAMETER Name
    Name of the feature to verify

.PARAMETER Disabled
    Test if the feature is disabled, the default is to test if the feature is enabled.

.EXAMPLE
    Test-ChocolateyFeature -Name FeatureName -Disabled

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsFeature
#>
function Test-ChocolateyFeature
{
    [CmdletBinding()]
    [outputType([Bool])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Feature')]
        [System.String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $Disabled
    )

    process
    {
        # Test if choco is installed before doing anything
        $null = Get-ChocolateyCommand
        $feature = Get-ChocolateyFeature -Name $Name

        if (-not $feature)
        {
            Write-Verbose -Message ('Chocolatey Feature {0} cannot be found.' -f $Name)
            return $false
        }
        else
        {
            Write-Verbose -Message ('Chocolatey Feature {0} found.' -f $Name)
        }

        if ($feature.enabled -eq -not $Disabled.IsPresent)
        {
            Write-Verbose -Message ("The Chocolatey Feature {0} is set to {1} as expected." -f $Name, (@('Disabled', 'Enabled')[([int]$Disabled.ToBool())]))
            return $true
        }
        else
        {
            Write-Verbose -Message ('The Chocolatey Feature {0} is NOT set to {1} as expected.' -f $Name, (@('Disabled', 'Enabled')[([int]$Disabled.ToBool())]))
            return $False
        }
    }
}
