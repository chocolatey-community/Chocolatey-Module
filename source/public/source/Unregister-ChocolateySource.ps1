
<#
.SYNOPSIS
    Unregister a Chocolatey source from the Chocolatey Configuration.

.DESCRIPTION
    Chocolatey will allow you to interact with sources.
    You can unregister an existing source.

.PARAMETER Name
    Name - the name of the source to be delete.

.PARAMETER Source
    Source - The source. This can be a folder/file share or an http location.
    If it is a url, it will be a location you can go to in a browser and
    it returns OData with something that says Packages in the browser,
    similar to what you see when you go to https://chocolatey.org/api/v2/.

.PARAMETER Disabled
    The source to be unregistered is disabled.

.PARAMETER BypassProxy
    Bypass Proxy - Should this source explicitly bypass any explicitly or
    system configured proxies? Defaults to false. Available in 0.10.4+.

.PARAMETER SelfService
    Allow Self-Service - The source to be delete is allowed to be used with self-
    service. Requires business edition (v1.10.0+) with feature
    'useBackgroundServiceWithSelfServiceSourcesOnly' turned on.
    Available in 0.10.4+.

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

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.

.EXAMPLE
    Unregister-ChocolateySource -Name MyProgetFeed

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Unregister-ChocolateySource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $Source,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $Disabled,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $BypassProxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $SelfService,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]
        $Priority = 0,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $Force,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $CacheLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $NoProgress,

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
        if (-not (Get-ChocolateySource -Name $Name))
        {
            throw "Chocolatey Source $Name cannot be found. You can Register it using Register-ChocolateySource."
        }

        $ChocoArguments = @('source', 'remove')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose -Message ('{0}' -f ($ChocoArguments -join ' '))

        &$chocoCmd $ChocoArguments | Foreach-Object -Process {
            Write-Verbose -Message ('{0}' -f $_)
        }
    }
}
