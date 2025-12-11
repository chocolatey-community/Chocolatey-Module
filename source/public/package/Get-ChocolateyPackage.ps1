
<#
.SYNOPSIS
    List the packages installed on the local machine.

.DESCRIPTION
    Retrieve the list of packages installed locally or to search for a specific package
    installed, with a specific version.

.PARAMETER Name
    Name or part of the name of the Package to search for.

.PARAMETER Version
    Version of the package you're looking for.

.PARAMETER ByIdOnly
    ByIdOnly - Only return packages where the id contains the search filter.
    Available in 0.9.10+.

.PARAMETER IdStartsWith
    IdStartsWith - Only return packages where the id starts with the search
    filter. Available in 0.9.10+.

.PARAMETER Exact
    Exact - Only return packages with this exact name. Available in 0.9.10+.

.PARAMETER ByPassCache
    ByPassCache - Bypass the local cache of packages and get the latest list from

.EXAMPLE
    Get-ChocolateyPackage -Name chocolatey

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsList
#>
function Get-ChocolateyPackage
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $ByIdOnly,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $IdStartsWith,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Exact,

        [Parameter()]
        [switch]
        $ByPassCache
    )

    begin
    {
        # Validate choco is installed or die. Will load the exe path from module cache.
        # Should you want to specify an installation directory,
        # you have to call Get-ChocolateyCommand -InstallDir <path> -Force to set the cache.
        $chocoCmd = Get-ChocolateyCommand

        # This command is PowerShell only (avoiding expensive choco list when validating many packages)
        if ($PSBoundParameters.ContainsKey('ByPassCache'))
        {
            $null = $PSBoundParameters.Remove('ByPassCache')
        }
    }

    process
    {
        $chocoArguments = @('list')
        if (-not [string]::IsNullOrEmpty($Name))
        {
            $chocoArguments += @($Name)
            # looks like choco search --name="chocolatey" does not work anymore
        }

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $null = $PSBoundParameters.Remove('Name')
        }

        $chocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters

        if ($ByPassCache.IsPresent -or -not $Exact.IsPresent)
        {
            # bypass caching when requested, or when not searching for an exact match
            # (when not doing exact match choco is looking through description)
            Write-Debug -Message ('{0} {1}' -f $chocoCmd, $($ChocoArguments -join ' '))
            &$chocoCmd $chocoArguments | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
        }
        else
        {
            try
            {
                $cachedPackages = Get-ChocolateyPackageCache -ErrorAction Stop
                if (-not [string]::IsNullOrEmpty($name))
                {
                    $cachedPackages = $cachedPackages.Where({$_.Name -eq $Name})
                }

                if (-not [string]::IsNullOrEmpty($Version))
                {
                    $cachedPackages = $cachedPackages.Where({$_.Version -like $Version})
                }

                $cachedPackages
            }
            catch
            {
                Write-Debug -Message ('Failed to use cache...{0}' -f $_.Exception.Message)
                Write-Debug -Message ('{0} {1}' -f $chocoCmd, $($ChocoArguments -join ' '))
                $outputString = &$chocoCmd $chocoArguments
                if ([string]::isNullOrEmpty($outputString))
                {
                    Write-Warning -Message ('No output returned from choco command: {0}' -f $chocoCmd)
                }
                else
                {
                    ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version' -InputObject $outputString
                }
            }
        }
    }
}
