
<#
.SYNOPSIS
    Gets the pinned Chocolatey Packages.

.DESCRIPTION
    This command gets the pinned Chocolatey Packages, and returns
    the Settings available from there.

.PARAMETER Name
    Name of the Packages when retrieving a single one or a specific list.
    It defaults to returning all Packages available in the config file.

.EXAMPLE
    Get-ChocolateyPin -Name packageName

.NOTES
    https://chocolatey.org/docs/commands-pin
#>

function Get-ChocolateyPin
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name = '*'
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
        if ($Name -ne '*' -and -not (Get-ChocolateyPackage -Name $Name -Exact))
        {
            throw "Chocolatey Package $Name cannot be found."
        }

        # Prepare the arguments for `choco pin list -r`
        $ChocoArguments = @('pin', 'list', '--limit-output')

        Write-Debug -Message ('{0} {1}' -f $chocoCmd, $($ChocoArguments -join ' '))
        $chocoPinListOutput = &$chocoCmd $ChocoArguments

        # Stop here if the list is empty
        if ([string]::IsNullOrEmpty($chocoPinListOutput))
        {
            return
        }
        else
        {
            Write-Verbose ("Found {0} Packages" -f $chocoPinListOutput.count)
            # Convert the list to objects
            $chocoPinListOutput = $chocoPinListOutput | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
        }

        if ($Name -ne '*')
        {
            Write-Verbose -Message 'Filtering pinned Packages'
            $chocoPinListOutput = $chocoPinListOutput | Where-Object { $_.Name -like $Name }
        }
        else
        {
            Write-Verbose -Message ('Returning all {0} pinned packages' -f $chocoPinListOutput.count)
        }

        foreach ($pin in $chocoPinListOutput)
        {
            [PSCustomObject]@{
                PSTypeName = 'Chocolatey.Pin'
                Name       = $pin.Name
                Version    = $pin.Version
            }
        }
    }
}
