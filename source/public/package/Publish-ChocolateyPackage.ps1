<#
.SYNOPSIS
    Pushes a Chocolatey package file to a source feed.

.DESCRIPTION
    Wraps `choco push` to publish one or more `.nupkg` files to a Chocolatey-compatible
    package feed. Requires a source URL and, for authenticated feeds such as the
    Chocolatey Community Repository, an API key.

.PARAMETER Path
    Path to the `.nupkg` file to publish. Accepts pipeline input and multiple values.

.PARAMETER Source
    Source feed URL to push the package to. Required for the Chocolatey Community
    Repository (https://push.chocolatey.org/).

.PARAMETER ApiKey
    API key for the target source feed.

.PARAMETER Force
    Force the push behavior.

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
    Publish-ChocolateyPackage -Path '.\mypackage.1.0.0.nupkg' -Source 'https://push.chocolatey.org/' -ApiKey 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

    Pushes mypackage 1.0.0 to the Chocolatey Community Repository.

.EXAMPLE
    Publish-ChocolateyPackage -Path '.\mypackage.1.0.0.nupkg' -Source 'https://proget.example.com/nuget/choco/'

    Pushes the package to an internal ProGet feed (no API key needed if the feed allows anonymous push).

.EXAMPLE
    Get-ChildItem -Path '.\output\' -Filter '*.nupkg' | Select-Object -ExpandProperty FullName | Publish-ChocolateyPackage -Source 'https://internalrepo/nuget/choco/'

    Publishes every nupkg in the output folder via pipeline.

.NOTES
    https://docs.chocolatey.org/en-us/choco/commands/push/
#>
function Publish-ChocolateyPackage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        $Path,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Source,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $ApiKey,

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
    }

    process
    {
        $defaultArgParameters = @{}
        foreach ($key in $PSBoundParameters.Keys)
        {
            if ($key -notin 'Path', 'ApiKey')
            {
                $defaultArgParameters[$key] = $PSBoundParameters[$key]
            }
        }

        foreach ($nupkg in $Path)
        {
            [System.Collections.Generic.List[string]] $chocoArguments = [System.Collections.Generic.List[string]]::new()
            $chocoArguments.Add('push')
            $chocoArguments.Add($nupkg)

            foreach ($argument in (Get-ChocolateyDefaultArgument @defaultArgParameters))
            {
                $chocoArguments.Add($argument)
            }

            if ($PSBoundParameters.ContainsKey('ApiKey'))
            {
                $chocoArguments.Add("--api-key=`"$ApiKey`"")
            }

            if ($PSCmdlet.ShouldProcess($nupkg, 'Publish Chocolatey package'))
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
