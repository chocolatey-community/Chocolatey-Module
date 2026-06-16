<#
.SYNOPSIS
    Optimizes installed Chocolatey packages to reduce disk space usage.

.DESCRIPTION
    Wraps `choco optimize` to reduce the on-disk footprint of installed packages.
    With Package Optimizer:

    - Each `.nupkg` file is reduced to 5 KB or less.
    - Zip and installer files are automatically removed from the package directory.
    - Zip and installer files are removed from the TEMP cache.

    This command requires Chocolatey Licensed Edition.

.PARAMETER Name
    Package id to optimize. When omitted, all installed packages are optimized.

.PARAMETER ReduceNupkgOnly
    Reduce only the size of the `.nupkg` file; leave downloaded installers in place.

.PARAMETER ForceSelfService
    Force the command to be handled through Chocolatey self-service when the feature
    is enabled.

.PARAMETER Force
    Force the optimization behavior.

.PARAMETER CacheLocation
    Location for Chocolatey's download cache.

.PARAMETER NoProgress
    Do not show progress percentages.

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
    Ignore cached HTTP responses.

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. Use `-RunNonElevated` if you
    really want to run even if the current shell is not elevated.

.EXAMPLE
    Optimize-ChocolateyPackage

    Optimizes all installed packages, removing redundant installers and reducing
    nupkg file sizes.

.EXAMPLE
    Optimize-ChocolateyPackage -Name 'googlechrome'

    Optimizes only the googlechrome package.

.EXAMPLE
    Optimize-ChocolateyPackage -ReduceNupkgOnly

    Reduces nupkg file sizes without removing downloaded installers.

.NOTES
    https://docs.chocolatey.org/en-us/choco/commands/optimize/
#>
function Optimize-ChocolateyPackage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]
    param
    (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $ReduceNupkgOnly,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $ForceSelfService,

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

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    begin
    {
        $chocoCmd = Get-ChocolateyCommand

        $installDir = Get-ChocolateyInstallPath -ErrorAction 'Stop'
        if (-not (Test-ChocolateyLicenseInstalled -InstallDir $installDir))
        {
            $licensePath = Join-Path -Path $installDir -ChildPath 'license\chocolatey.license.xml'
            throw ("Optimize-ChocolateyPackage requires a Chocolatey Licensed Edition license file at '{0}'." -f $licensePath)
        }
    }

    process
    {
        $defaultArgParameters = @{}
        foreach ($key in $PSBoundParameters.Keys)
        {
            if ($key -notin 'Name', 'ReduceNupkgOnly')
            {
                $defaultArgParameters[$key] = $PSBoundParameters[$key]
            }
        }

        [System.Collections.Generic.List[string]] $baseArguments = [System.Collections.Generic.List[string]]::new()
        $baseArguments.Add('optimize')

        if ($ReduceNupkgOnly)
        {
            $baseArguments.Add('--reduce-nupkg-only')
        }

        foreach ($argument in (Get-ChocolateyDefaultArgument @defaultArgParameters))
        {
            $baseArguments.Add($argument)
        }

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            foreach ($packageName in $Name)
            {
                [System.Collections.Generic.List[string]] $chocoArguments = [System.Collections.Generic.List[string]]::new()
                foreach ($arg in $baseArguments) { $chocoArguments.Add($arg) }
                $chocoArguments.Add("--id=`"$packageName`"")

                if ($PSCmdlet.ShouldProcess($packageName, 'Optimize Chocolatey package'))
                {
                    $chocoArguments.Add('-y')
                    Write-Debug -Message ('{0} {1}' -f $chocoCmd, ($chocoArguments -join ' '))
                    &$chocoCmd @chocoArguments | ForEach-Object -Process {
                        Write-Verbose -Message ('{0}' -f $_)
                    }
                }
            }
        }
        else
        {
            [System.Collections.Generic.List[string]] $chocoArguments = [System.Collections.Generic.List[string]]::new()
            foreach ($arg in $baseArguments) { $chocoArguments.Add($arg) }

            if ($PSCmdlet.ShouldProcess('all installed packages', 'Optimize Chocolatey package'))
            {
                $chocoArguments.Add('-y')
                Write-Debug -Message ('{0} {1}' -f $chocoCmd, ($chocoArguments -join ' '))
                &$chocoCmd @chocoArguments | ForEach-Object -Process {
                    Write-Verbose -Message ('{0}' -f $_)
                }
            }
        }
    }
}
