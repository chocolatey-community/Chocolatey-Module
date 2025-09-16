
<#
.SYNOPSIS
    Add a Pin to a Chocolatey Package

.DESCRIPTION
    Allows you to pin a Chocolatey Package like choco pin add -n=packagename

.PARAMETER Name
    Name of the Chocolatey Package to pin.
    The Package must be installed beforehand.

.PARAMETER Version
    This allows to pin a specific Version of a Chocolatey Package.
    The Package with the Version to pin must be installed beforehand.

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.

.EXAMPLE
    Add-ChocolateyPin -Name 'PackageName'

.EXAMPLE
    Add-ChocolateyPin -Name 'PackageName' -Version '1.0.0'

.NOTES
    https://chocolatey.org/docs/commands-pin
#>
function Add-ChocolateyPin
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Package')]
        [System.String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Version,

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    begin
    {
        # Validate choco is installed or die. Will load the exe path from module cache.
        # Should you want to specify an installation directory,
        # you have to call Get-ChocolateyCommand -InstallDir <path> -Force to set the cache.
        $chocoCmd = Get-ChocolateyCommand
    }

    process
    {
        if (-not (Get-ChocolateyPackage -Name $Name -Exact))
        {
            throw ('Chocolatey Package ''{0}'' cannot be found.' -f $Name)
        }

        $ChocoArguments = @('pin', 'add')
        $ChocoArguments += @(Get-ChocolateyDefaultArgument @PSBoundParameters)
        Write-Verbose -Message ('{0} {1}' -f $chocoCmd, ($ChocoArguments -join ' '))

        if ($PSCmdlet.ShouldProcess($Env:COMPUTERNAME, ('{0} {1}' -f $chocoCmd, ($ChocoArguments -join ' '))))
        {
            $output = &$chocoCmd $ChocoArguments

            # LASTEXITCODE is always 0 unless point an existing version (0 when remove but already removed)
            if ($LASTEXITCODE -ne 0)
            {
                throw ("Error when trying to add Pin for Package '{0}'.`r`n {1}" -f "$Name $Version", ($output -join "`r`n"))
            }
            else
            {
                $output | ForEach-Object -Process {
                    Write-Verbose -Message ('{0}' -f $_)
                }
            }
        }
    }
}
