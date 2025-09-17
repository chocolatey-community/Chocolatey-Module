
<#
.SYNOPSIS
    Set or unset a Chocolatey Setting

.DESCRIPTION
    Allows you to set or unset the value of a Chocolatey setting usually accessed by choco config set -n=bob value

.PARAMETER Name
    Name (or setting) of the Chocolatey setting to modify

.PARAMETER Value
    Value to be given on the setting. This is not available when the switch -Unset is used.

.PARAMETER Unset
    Unset the setting, returning to the Chocolatey defaults.

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.

.EXAMPLE
    Set-ChocolateySetting -Name 'cacheLocation' -value 'C:\Temp\Choco'

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsConfig
#>
function Set-ChocolateySetting
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([Void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Setting')]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Set')]
        [AllowEmptyString()]
        [System.String]
        $Value,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Unset')]
        [switch]
        $Unset,

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    process
    {
        $chocoCmd = Get-ChocolateyCommand

        $ChocoArguments = @('config')

        if ($Unset -or [string]::IsNullOrEmpty($Value))
        {
            if ($PSBoundParameters.ContainsKey('Value'))
            {
                # value not needed when unsetting
                $null = $PSBoundParameters.Remove('Value')
            }

            $null = $PSBoundParameters.Remove('Unset')
            $ChocoArguments += @('unset')
        }
        else
        {
            # expand any environment variables in the value and trim trailing slashes
            $PSBoundParameters['Value'] = $ExecutionContext.InvokeCommand.ExpandString($Value).TrimEnd(@('/', '\'))
            $ChocoArguments += @('set')
        }

        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters

        if ($PSCmdlet.ShouldProcess($Env:COMPUTERNAME, ('{0} {1}' -f $chocoCmd, ($ChocoArguments -join ' '))))
        {
            &$chocoCmd $ChocoArguments | ForEach-Object -Process {
                Write-Verbose -Message ('{0}' -f $_)
            }
        }
    }
}
