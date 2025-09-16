
<#
.SYNOPSIS
    Enable a Source set in the Chocolatey Config

.DESCRIPTION
    Lets you Enable an existing source from the Chocolatey Config.
    The equivalent Choco command is Choco source enable -n=sourcename

.PARAMETER Name
    Name of the Chocolatey source to Disable

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.

.EXAMPLE
    Enable-ChocolateySource -Name 'chocolatey'

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Enable-ChocolateySource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name,

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    process
    {
        $chocoCmd = Get-ChocolateyCommand

        if (-not (Get-ChocolateySource -id $Name))
        {
            throw "Chocolatey Source $Name cannot be found. You can Register it using Register-ChocolateySource."
        }

        $ChocoArguments = @('source', 'enable')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        &$chocoCmd $ChocoArguments | ForEach-Object -Process {
            Write-Verbose -Message ('{0}' -f $_)
        }
    }
}
