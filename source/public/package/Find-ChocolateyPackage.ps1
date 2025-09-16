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
