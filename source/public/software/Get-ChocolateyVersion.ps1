
<#
.SYNOPSIS
    Retrieve the version of the Chocolatey available in $Env:Path

.DESCRIPTION
    Get the version of the Chocolatey currently installed.

.EXAMPLE
    Get-ChocolateyVersion #This command does not accept parameter

.NOTES
    This does not specify the SKU (C4B or Community)
#>
function Get-ChocolateyVersion
{
    [CmdletBinding()]
    [OutputType([version])]
    param
    (
    )

    $chocoCmd = Get-ChocolateyCommand

    $ChocoArguments = @('-v')
    Write-Verbose -Message ('{0} {1}' -f $chocoCmd, ($ChocoArguments -join ' '))

    $CHOCO_OLD_MESSAGE = "Please run chocolatey /? or chocolatey help - chocolatey v"
    $versionOutput = (&$chocoCmd $ChocoArguments) -replace ([regex]::escape($CHOCO_OLD_MESSAGE))
    #remove other text to keep only the last line which should have the version
    $versionOutput = ($versionOutput -split '\r\n|\n|\r')[-1]
    Write-Verbose -Message $versionOutput
    [version]$versionOutput
}
