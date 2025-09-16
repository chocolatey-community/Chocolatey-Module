
<#
.SYNOPSIS
    Disable a Chocolatey Feature

.DESCRIPTION
    Allows you to enable a Chocolatey Feature usually accessed by choco feature enable -n=bob

.PARAMETER Name
    Name of the Chocolatey Feature to disable

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.

.EXAMPLE
    Enable-ChocolateyFeature -Name 'MyChocoFeatureName'

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsFeature
#>
function Enable-ChocolateyFeature
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Feature')]
        [System.String]
        $Name,

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    process
    {
        $chocoCmd = Get-ChocolateyCommand

        if (-not (Get-ChocolateyFeature -Name $Name))
        {
            throw ('Chocolatey Feature {0} cannot be found.' -f $Name)
        }

        $chocoArguments = @('feature', 'enable')
        $chocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose -Message ('{0} {1}' -f $chocoCmd, ($chocoArguments -join ' '))

        if ($PSCmdlet.ShouldProcess($Env:COMPUTERNAME, "$chocoCmd $($chocoArguments -join ' ')"))
        {
            &$chocoCmd $chocoArguments | ForEach-Object -Process {
                Write-Verbose -Message ('{0}' -f $_)
            }
        }
    }
}
