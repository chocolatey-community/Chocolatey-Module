
<#
.SYNOPSIS
    Find a Chocolatey package from local or remote sources.

.DESCRIPTION
    This function searches for a Chocolatey package by name and version, optionally filtering by other criteria.

.PARAMETER Name
The name of the package to find.

.PARAMETER Version
The version of the package to find.

.PARAMETER IdOnly
Whether to search the Name only in the package ID.

.PARAMETER Prerelease
Whether to include prerelease packages in the search.

.PARAMETER ApprovedOnly
Whether to only include approved packages in the search.

.PARAMETER ByIdOnly
Whether to only include packages that match the ID exactly.

.PARAMETER IdStartsWith
Whether to only include packages whose ID starts with the specified string.

.PARAMETER NoProgress
Whether to suppress progress output.

.PARAMETER Exact
Whether to only include packages that match the name and version exactly.

.PARAMETER Source
The source to search for the package.

.PARAMETER Credential
The credentials to use for the search.

.PARAMETER CacheLocation
The location of the cache to use for the search.

.PARAMETER IncludeConfiguredSources
Whether to include configured sources in the search.

.EXAMPLE
    Find-ChocolateyPackage -Name PackageName -Version 1.0.0

.NOTES
    This function requires Chocolatey to be installed and available in the system PATH.
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
        $CacheLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $IncludeConfiguredSources
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
        $chocoArguments = @('search')
        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $chocoArguments += @($Name)
            if ($PSBoundParameters.ContainsKey('Name'))
            {
                $null = $PSBoundParameters.Remove('Name')
            }
        }

        $chocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters

        Write-Debug -Message ('{0} {1}' -f $chocoCmd.Path, $($chocoArguments -join ' '))
        (&$chocoCmd $chocoArguments | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version')
    }
}
