
<#
.SYNOPSIS
    Disable a Source set in the Chocolatey Config

.DESCRIPTION
    Lets you disable an existing source.
    The equivalent Choco command is Choco source disable -n=sourcename

.PARAMETER Name
    Name of the Chocolatey source to Disable

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. Use -RunNonElevated if you really want to run
    even if the current shell is not elevated.
    This parameter is hidden and serves as a protection against accidental non-elevated runs.

.EXAMPLE
    Disable-ChocolateySource -Name chocolatey

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Disable-ChocolateySource
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

        if (-not (Get-ChocolateySource -Name $Name))
        {
            throw "Chocolatey Source $Name cannot be found. You can Register it using Register-ChocolateySource."
        }

        $ChocoArguments = @('source', 'disable')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose -Message ('{0} {1}' -f $chocoCmd, ($ChocoArguments -join ' '))

        &$chocoCmd $ChocoArguments | ForEach-Object -Process {
            Write-Verbose -Message ('{0}' -f $_)
        }
    }
}
