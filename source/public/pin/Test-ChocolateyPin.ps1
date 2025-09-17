
<#
.SYNOPSIS
    Test whether a package is set, enabled or not found

.DESCRIPTION
    This command allows you to test the values of a pinned package.

.PARAMETER Name
    Name of the Package to verify

.PARAMETER Version
    Test if the Package version provided matches with the one set on the config file.

.EXAMPLE
    Test-ChocolateyPin -Name PackageName -Version ''

.NOTES
    https://chocolatey.org/docs/commands-pin
#>
function Test-ChocolateyPin
{
    [CmdletBinding()]
    [OutputType([Bool])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $Version
    )

    begin
    {
        # Validate choco is installed or die. Will load the exe path from module cache.
        # Should you want to specify an installation directory,
        # you have to call Get-ChocolateyCommand -InstallDir <path> -Force to set the cache.
        $null = Get-ChocolateyCommand
    }

    process
    {
        $pin = Get-ChocolateyPin -Name $Name
        if ($null -eq $pin)
        {
            Write-Verbose -Message ('The Pin for the Chocolatey Package ''{0}'' cannot be found.' -f $Name)
            return $false
        }

        if ([string]$pin.Version -eq $Version)
        {
            Write-Verbose -Message ('The Pin for the Chocolatey Package ''{0}'' is set to ''{1}'' as expected.' -f $Name, $pin.Version)
            return $true
        }
        else
        {
            Write-Verbose ('The Pin for the Chocolatey Package ''{0}'' is NOT set to ''{1}'' but to ''{2}''.' -f $Name, $Version, $pin.Version)
            return $false
        }
    }
}
