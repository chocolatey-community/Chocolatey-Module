
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
        if (-not ($chocoCmd = @(Get-Command 'choco.exe' -CommandType 'Application' -ErrorAction 'SilentlyContinue')[0]))
        {
            throw "Chocolatey Software not found."
        }
    }

    process
    {
        if (-not (Get-ChocolateyPackage -LocalOnly -Name $Name -Exact))
        {
            throw ('Chocolatey Package ''{0}'' cannot be found.' -f $Name)
        }

        $ChocoArguments = @('pin', 'add')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose -Message ('choco {0}' -f ($ChocoArguments -join ' '))

        if ($PSCmdlet.ShouldProcess("$Name $Version", "Add Pin"))
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
