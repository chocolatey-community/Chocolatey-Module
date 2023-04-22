
<#
.SYNOPSIS
    List the packages from a source.

.DESCRIPTION
    This command can list the packages available on the configured source or a specified one.
    You can also use this command to search for a specific package, and specific version.

.PARAMETER Name
    Name or part of the name of the Package to search on the source(s).

.PARAMETER Version
    Version of the package you're looking for.

.PARAMETER IdOnly
    Id Only - Only return Package Ids in the list results. Available in 0.1-0.6+.

.PARAMETER Prerelease
    Prerelease - Include Prereleases? Defaults to false

.PARAMETER ApprovedOnly
    ApprovedOnly - Only return approved packages - this option will filter
    out results not from the community repository (https://chocolatey.org/packages). Available in 0.9.10+

.PARAMETER ByIdOnly
    ByIdOnly - Only return packages where the id contains the search filter.
    Available in 0.9.10+.

.PARAMETER IdStartsWith
    IdStartsWith - Only return packages where the id starts with the search
    filter. Available in 0.9.10+.

.PARAMETER NoProgress
    Do Not Show Progress - Do not show download progress percentages.

.PARAMETER Exact
    Exact - Only return packages with this exact name. Available in 0.9.10+.

.PARAMETER Source
    Source - Source location for install. Can use special 'webpi' or 'windowsfeatures' sources. Defaults to sources.

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.PARAMETER CacheLocation
    CacheLocation - Location for download cache, defaults to %TEMP% or value in chocolatey.config file.

.EXAMPLE
    Get-ChocolateyPackage -LocalOnly chocolatey

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsList
#>
function Find-ChocolateyPackage
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
        $IdOnly,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Prerelease,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $ApprovedOnly,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $ByIdOnly,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $IdStartsWith,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $NoProgress,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Exact,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $Source,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $CacheLocation
    )

    process
    {
        if (-not ($chocoCmd = @(Get-Command 'choco.exe' -CommandType 'Application' -ErrorAction 'SilentlyContinue')[0]))
        {
            throw "Chocolatey Software not found."
        }

        $ChocoArguments = @('search', '-r')
        $paramKeys = [Array]::CreateInstance([string], $PSboundparameters.Keys.count)
        $PSboundparameters.Keys.CopyTo($paramKeys, 0)
        switch ($paramKeys)
        {
            'verbose'
            {
                $null = $PSBoundParameters.remove('Verbose')
            }
            'debug'
            {
                $null = $PSBoundParameters.remove('debug')
            }
            'Name'
            {
                $null = $PSBoundParameters.remove('Name')
            }
            'Exact'
            {
                $null = $PSBoundParameters.remove('Exact')
            }
        }

        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        if ($ChocoArguments -contains '--verbose')
        {
            $ChocoArguments = [System.Collections.ArrayList]$ChocoArguments
            $ChocoArguments.remove('--verbose')
        }

        Write-Debug -Message "Running from command without caching."
        $ChocoListOutput = &$chocoCmd $ChocoArguments $Name $( if ($Exact)
            {
                '--exact'
            } )

        $ChocoListOutput | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
    }
}
