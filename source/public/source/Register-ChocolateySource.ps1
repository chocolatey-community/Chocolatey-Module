
<#
.SYNOPSIS
    Register a new Chocolatey source or edit an existing one.

.DESCRIPTION
    Chocolatey will allow you to interact with sources.
    You can register a new source, whether internal or external with some source
    specific settings such as proxy.

.PARAMETER Name
    Name - the name of the source. Required with some actions. Defaults to empty.

.PARAMETER Source
    Source - The source. This can be a folder/file share or an http location.
    If it is a url, it will be a location you can go to in a browser and
    it returns OData with something that says Packages in the browser,
    similar to what you see when you go to https://chocolatey.org/api/v2/.
    Defaults to empty.

.PARAMETER Disabled
    Allow the source to be registered but disabled.

.PARAMETER BypassProxy
    Bypass Proxy - Should this source explicitly bypass any explicitly or
    system configured proxies? Defaults to false. Available in 0.10.4+.

.PARAMETER SelfService
    Allow Self-Service - Should this source be allowed to be used with self-
    service? Requires business edition (v1.10.0+) with feature
    'useBackgroundServiceWithSelfServiceSourcesOnly' turned on. Defaults to
    false. Available in 0.10.4+.

.PARAMETER Priority
    Priority - The priority order of this source as compared to other
    sources, lower is better. Defaults to 0 (no priority). All priorities
    above 0 will be evaluated first, then zero-based values will be
    evaluated in config file order. Available in 0.9.9.9+.

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.PARAMETER Force
    Force - force the behavior. Do not use force during normal operation -
    it subverts some of the smart behavior for commands.

.PARAMETER CacheLocation
    CacheLocation - Location for download cache, defaults to %TEMP% or value
    in chocolatey.config file.

.PARAMETER NoProgress
    Do Not Show Progress - Do not show download progress percentages.
    Available in 0.10.4+.

.PARAMETER KeyUser
    API Key User for the source being registered.

.PARAMETER Key
    API key for the source (too long in C4B to be passed as credentials)

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.
    This parameter is hidden and serves as a protection against accidental non-elevated runs.

.EXAMPLE
    Register-ChocolateySource -Name MyNuget -Source https://proget/nuget/choco

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Register-ChocolateySource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        $Source,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Disabled = $false,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $BypassProxy = $false,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $SelfService = $false,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]
        $Priority = 0,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Force,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $CacheLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $NoProgress,

        [Parameter()]
        #To be used when Password is too long (>240 char) like a key
        $KeyUser,

        [Parameter()]
        $Key,

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    begin
    {
        $chocoCmd = Get-ChocolateyCommand
    }

    process
    {
        # if not provided set default values in PSBoundParameters
        if (-not $PSBoundParameters.containsKey('Disabled'))
        {
            $null = $PSBoundParameters.add('Disabled', $Disabled)
        }

        if (-not $PSBoundParameters.containsKey('SelfService'))
        {
            $null = $PSBoundParameters.add('SelfService', $SelfService)
        }

        if (-not $PSBoundParameters.containsKey('BypassProxy'))
        {
            $null = $PSBoundParameters.add('BypassProxy', $BypassProxy)
        }

        $ChocoArguments = @('source', 'add')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters

        if ($PSCmdlet.ShouldProcess($Env:COMPUTERNAME, ('{0} {1}' -f $chocoCmd, ($ChocoArguments -join ' '))))
        {
            &$chocoCmd $ChocoArguments | ForEach-Object -Process {
                Write-Verbose -Message ('{0}' -f $_)
            }

            if ($Disabled)
            {
                &$chocoCmd @('source', 'disable', "-n=`"$Name`"", '--limit-output') | ForEach-Object -Process {
                    Write-Verbose -Message ('{0}' -f $_)
                }
            }
        }
    }
}
