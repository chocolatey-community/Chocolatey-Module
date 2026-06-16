<#
.SYNOPSIS
    Converts a Chocolatey package to another format.

.DESCRIPTION
    Wraps `choco convert` to convert a `.nupkg` file into a different package format.
    Currently supports converting to Microsoft Intune (`.intunewin`) format.

    This command requires Chocolatey for Business.

.PARAMETER Path
    Path to the `.nupkg` file to convert. Accepts pipeline input and multiple values.

.PARAMETER IncludeAll
    Convert all `.nupkg` files found in the current working directory.

.PARAMETER ToFormat
    Target format for the conversion. The only currently supported value is `intune`.

.PARAMETER IgnoreDependencies
    Ignore package dependencies during conversion.

.PARAMETER ForceSelfService
    Force the command to be handled through Chocolatey self-service when the feature
    is enabled.

.PARAMETER Force
    Force the conversion behavior.

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

.EXAMPLE
    Convert-ChocolateyPackage -Path 'sysinternals.2024.1.0.nupkg' -ToFormat intune

    Converts the sysinternals nupkg to a Microsoft Intune package.

.EXAMPLE
    Convert-ChocolateyPackage -IncludeAll -ToFormat intune

    Converts all `.nupkg` files in the current directory to Intune format.

.EXAMPLE
    Get-ChildItem -Filter '*.nupkg' | Select-Object -ExpandProperty FullName | Convert-ChocolateyPackage -ToFormat intune

    Converts each nupkg found by pipeline to Intune format.

.NOTES
    https://docs.chocolatey.org/en-us/create/commands/convert/
#>
function Convert-ChocolateyPackage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'ByPath', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        $Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'AllInDirectory')]
        [switch]
        $IncludeAll,

        [Parameter(Mandatory = $true)]
        [ValidateSet('intune')]
        [System.String]
        $ToFormat,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $IgnoreDependencies,

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
        $IgnoreHttpCache
    )

    begin
    {
        $chocoCmd = Get-ChocolateyCommand

        $installDir = Get-ChocolateyInstallPath -ErrorAction 'Stop'
        if (-not (Test-ChocolateyLicenseInstalled -InstallDir $installDir))
        {
            $licensePath = Join-Path -Path $installDir -ChildPath 'license\chocolatey.license.xml'
            throw ("Convert-ChocolateyPackage requires a Chocolatey for Business license file at '{0}'." -f $licensePath)
        }
    }

    process
    {
        $defaultArgParameters = @{}
        foreach ($key in $PSBoundParameters.Keys)
        {
            if ($key -notin 'Path', 'IncludeAll', 'ToFormat')
            {
                $defaultArgParameters[$key] = $PSBoundParameters[$key]
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'AllInDirectory')
        {
            [System.Collections.Generic.List[string]] $chocoArguments = [System.Collections.Generic.List[string]]::new()
            $chocoArguments.Add('convert')
            $chocoArguments.Add("--to-format=`"$ToFormat`"")
            $chocoArguments.Add('--include-all')

            foreach ($argument in (Get-ChocolateyDefaultArgument @defaultArgParameters))
            {
                $chocoArguments.Add($argument)
            }

            if ($PSCmdlet.ShouldProcess('all packages in current directory', ('Convert to {0}' -f $ToFormat)))
            {
                $chocoArguments.Add('-y')
                Write-Debug -Message ('{0} {1}' -f $chocoCmd, ($chocoArguments -join ' '))
                &$chocoCmd @chocoArguments | ForEach-Object -Process {
                    Write-Verbose -Message ('{0}' -f $_)
                }
            }
        }
        else
        {
            foreach ($nupkg in $Path)
            {
                [System.Collections.Generic.List[string]] $chocoArguments = [System.Collections.Generic.List[string]]::new()
                $chocoArguments.Add('convert')
                $chocoArguments.Add($nupkg)
                $chocoArguments.Add("--to-format=`"$ToFormat`"")

                foreach ($argument in (Get-ChocolateyDefaultArgument @defaultArgParameters))
                {
                    $chocoArguments.Add($argument)
                }

                if ($PSCmdlet.ShouldProcess($nupkg, ('Convert to {0}' -f $ToFormat)))
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
}
