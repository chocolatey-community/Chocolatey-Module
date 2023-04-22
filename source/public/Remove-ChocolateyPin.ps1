
<#
.SYNOPSIS
    Remove a Pin from a Chocolatey Package

.DESCRIPTION
    Allows you to remove a pinned Chocolatey Package like choco pin remove -n=packagename

.PARAMETER Name
    Name of the Chocolatey Package to remove the pin.

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.

.EXAMPLE
    Remove-ChocolateyPin -Name 'PackageName'

.NOTES
    https://chocolatey.org/docs/commands-pin
#>
function Remove-ChocolateyPin
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Package')]
        [System.String]
        $Name,

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    process
    {
        if (-not ($chocoCmd = @(Get-Command 'choco.exe' -CommandType 'Application' -ErrorAction 'SilentlyContinue')[0]))
        {
            throw "Chocolatey Software not found."
        }

        if (-not (Get-ChocolateyPackage -LocalOnly -Name $Name))
        {
            throw "The Pin for Chocolatey Package $Name cannot be found."
        }

        $chocoArguments = @('pin', 'remove', '-r')
        $chocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose -Message "choco $($chocoArguments -join ' ')"

        if ($PSCmdlet.ShouldProcess("$Name", "Remove Pin"))
        {
            $output = &$chocoCmd $chocoArguments

            # LASTEXITCODE is always 0 unless point an existing version (0 when remove but already removed)
            if ($LASTEXITCODE -ne 0)
            {
                throw ("Error when trying to remove Pin for {0}.`r`n {1}" -f "$Name", ($output -join "`r`n"))
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
