<#
.SYNOPSIS
    Saves Chocolatey packages locally and can internalize them when licensed features are available.

.DESCRIPTION
    Wraps `choco download` to download one or more packages to a local directory.
    When the Chocolatey Licensed Extension is installed, this command can also use
    licensed download features such as private CDN download cache, virus scan
    switches, and package internalization. Licensed-only parameters throw when
    no Chocolatey license file is installed.

.PARAMETER Name
    Package name to save from the configured source or a specified source.

.PARAMETER InstalledPackages
    Save all currently installed Chocolatey packages instead of specifying package names.

.PARAMETER Version
    Specific version to download. Defaults to the latest available version.

.PARAMETER Source
    Source to find the package(s) to download. Defaults to configured sources.

.PARAMETER Credential
    Credential used with authenticated feeds.

.PARAMETER Prerelease
    Include prerelease packages when resolving a package to download.

.PARAMETER OutputDirectory
    Directory where downloaded package files should be saved. Defaults to the current directory.

.PARAMETER Force
    Force the download behavior when Chocolatey supports it.

.PARAMETER CacheLocation
    Location for Chocolatey's download cache.

.PARAMETER NoProgress
    Do not show download progress percentages.

.PARAMETER AcceptLicense
    Accept license dialogs automatically. Reserved for future use.

.PARAMETER Timeout
    Command execution timeout in seconds. Use `0` for infinite timeout.

.PARAMETER ProxyLocation
    Explicit proxy location to use for the Chocolatey command.

.PARAMETER ProxyCredential
    Credential to authenticate to the proxy.

.PARAMETER ProxyBypassList
    Regular-expression list of hosts that should bypass the proxy.

.PARAMETER ProxyBypassOnLocal
    Bypass the proxy for local connections.

.PARAMETER AllowUnofficialBuild
    Allow the command to run when using an unofficial Chocolatey build.

.PARAMETER FailOnStandardError
    Fail if Chocolatey writes to the standard error stream.

.PARAMETER UseSystemPowerShell
    Run PowerShell in an external process instead of the embedded host.

.PARAMETER SkipCompatibilityChecks
    Skip Chocolatey and licensed extension compatibility warnings.

.PARAMETER IgnoreHttpCache
    Ignore cached HTTP responses when querying sources.

.PARAMETER IgnoreDependencies
    Ignore package dependencies while downloading packages.

.PARAMETER IgnoreUnfound
    Continue downloading remaining packages when one package cannot be found.

.PARAMETER DisablePackageRepositoryOptimizations
    Disable Chocolatey's package repository query optimizations.

.PARAMETER IgnoreChecksum
    Ignore checksums provided by the package.

.PARAMETER AllowEmptyChecksum
    Allow empty or missing checksums for downloaded resources from non-secure locations.

.PARAMETER AllowEmptyChecksumSecure
    Allow empty checksums for downloaded resources from secure locations.

.PARAMETER RequireChecksum
    Require packages to provide checksums for downloaded resources.

.PARAMETER IgnoreDependenciesFromSource
    Ignore dependencies that are already present on the named configured source.

.PARAMETER Internalize
    Internalize the package by downloading external resources and recompiling it.

.PARAMETER ResourcesLocation
    Resources location to use during internalization.

.PARAMETER DownloadLocation
    Local download location to use during internalization.

.PARAMETER InternalizeAllUrls
    Internalize all discovered URLs, not only known helper-based downloads.

.PARAMETER AppendUseOriginalLocation
    Append `-UseOriginalLocation` to internalized helper calls.

.PARAMETER SkipCache
    Bypass Chocolatey's private CDN download cache.

.PARAMETER UseDownloadCache
    Use Chocolatey's private CDN download cache when available.

.PARAMETER SkipVirusCheck
    Skip the licensed virus check for downloaded files.

.PARAMETER VirusCheck
    Enable the licensed virus check for downloaded files.

.PARAMETER VirusPositive
    Minimum number of positive virus scan results required to flag a package.

.PARAMETER ForceSelfService
    Force handling through Chocolatey self-service when available.

.EXAMPLE
    Save-ChocolateyPackage -Name 'sysinternals' -OutputDirectory 'C:\packages'

    Downloads the latest sysinternals package into `C:\packages`.

.EXAMPLE
    Save-ChocolateyPackage -Name 'notepadplusplus.install' -Internalize -ResourcesLocation '\\server\packages'

    Downloads and internalizes the package using licensed Chocolatey features.

.NOTES
    https://docs.chocolatey.org/en-us/choco/commands/download/
#>
function Save-ChocolateyPackage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'ByName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'InstalledPackages')]
        [switch]
        $InstalledPackages,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $Source,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Prerelease,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $OutputDirectory,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Force,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $CacheLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $NoProgress,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $AcceptLicense,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]
        $Timeout,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $ProxyLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $ProxyBypassList,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $ProxyBypassOnLocal,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $AllowUnofficialBuild,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $FailOnStandardError,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $UseSystemPowerShell,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $SkipCompatibilityChecks,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $IgnoreHttpCache,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $IgnoreDependencies,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $IgnoreUnfound,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $DisablePackageRepositoryOptimizations,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $IgnoreChecksum,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $AllowEmptyChecksum,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $AllowEmptyChecksumSecure,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $RequireChecksum,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $IgnoreDependenciesFromSource,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Internalize,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $ResourcesLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $DownloadLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $InternalizeAllUrls,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $AppendUseOriginalLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $SkipCache,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $UseDownloadCache,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $SkipVirusCheck,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $VirusCheck,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VirusPositive,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $ForceSelfService
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
        $licensedParameterNames = @(
            'InstalledPackages',
            'IgnoreDependencies',
            'IgnoreUnfound',
            'IgnoreChecksum',
            'AllowEmptyChecksum',
            'AllowEmptyChecksumSecure',
            'RequireChecksum',
            'IgnoreDependenciesFromSource',
            'Internalize',
            'ResourcesLocation',
            'DownloadLocation',
            'InternalizeAllUrls',
            'AppendUseOriginalLocation',
            'SkipCache',
            'UseDownloadCache',
            'SkipVirusCheck',
            'VirusCheck',
            'VirusPositive',
            'ForceSelfService'
        )

        $requestedLicensedParameters = @(
            $PSBoundParameters.Keys.Where({ $_ -in $licensedParameterNames })
        )

        if ($requestedLicensedParameters.Count -gt 0)
        {
            $installDir = Get-ChocolateyInstallPath -ErrorAction 'Stop'
            $licensePath = Join-Path -Path $installDir -ChildPath 'license\chocolatey.license.xml'

            if (-not (Test-ChocolateyLicenseInstalled -InstallDir $installDir))
            {
                $parameterList = $requestedLicensedParameters |
                    Sort-Object |
                    ForEach-Object { "-$_" }

                throw ("Chocolatey license-specific parameters require an installed license file at '{0}'. Remove the following parameters or install a license first: {1}" -f $licensePath, ($parameterList -join ', '))
            }
        }

        $downloadArgumentParameters = @{}
        foreach ($key in $PSBoundParameters.Keys)
        {
            if ($key -ne 'Name')
            {
                $downloadArgumentParameters[$key] = $PSBoundParameters[$key]
            }
        }

        [System.Collections.Generic.List[string]] $chocoArguments = [System.Collections.Generic.List[string]]::new()
        $chocoArguments.Add('download')

        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            foreach ($packageName in $Name)
            {
                $chocoArguments.Add($packageName)
            }
        }

        foreach ($argument in (Get-ChocolateyDefaultArgument @downloadArgumentParameters))
        {
            $chocoArguments.Add($argument)
        }

        $target = if ($PSCmdlet.ParameterSetName -eq 'InstalledPackages')
        {
            'installed Chocolatey packages'
        }
        else
        {
            $Name -join ', '
        }

        if ($PSCmdlet.ShouldProcess($target, 'Save Chocolatey package'))
        {
            $chocoArguments.Add('-y')
            Write-Debug -Message ('{0} {1}' -f $chocoCmd, ($chocoArguments -join ' '))
            &$chocoCmd @chocoArguments | ForEach-Object -Process {
                Write-Verbose -Message ('{0}' -f $_)
            }
        }
    }
}
