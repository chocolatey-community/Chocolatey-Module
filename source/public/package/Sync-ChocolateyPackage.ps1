<#
.SYNOPSIS
    Synchronizes Chocolatey with software installed outside of Chocolatey.

.DESCRIPTION
    Wraps `choco sync` to scan the system for software that has been installed
    outside Chocolatey, generates Chocolatey packages for those programs, and
    baselines them against the Chocolatey package list.

    Returns one `PSCustomObject` per synchronized entry with properties
    `PackageId`, `DisplayName`, `Version`, and `NewPackage` (`[bool]`).

    This command requires Chocolatey for Business.

.PARAMETER Id
    Display Name of the software entry in Programs and Features to synchronize.
    When omitted, all untracked software is synchronized.

.PARAMETER PackageId
    Custom Chocolatey package id to assign when synchronizing a specific program.
    Used together with `-Id`. Requires Chocolatey for Business.

.PARAMETER OutputDirectory
    Directory where generated Chocolatey package files should be saved.

.PARAMETER ForceSelfService
    Force the command to be handled through Chocolatey self-service when the feature
    is enabled.

.PARAMETER Force
    Force the sync behavior.

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
    Sync-ChocolateyPackage

    Synchronizes all software installed outside of Chocolatey.

.EXAMPLE
    Sync-ChocolateyPackage -Id 'Putty'

    Synchronizes the Putty entry from Programs and Features into Chocolatey.

.EXAMPLE
    Sync-ChocolateyPackage -Id 'Putty' -PackageId 'putty.portable'

    Synchronizes Putty and assigns it the custom package id 'putty.portable'.

.NOTES
    https://docs.chocolatey.org/en-us/choco/commands/sync/
#>
function Sync-ChocolateyPackage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Id,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $PackageId,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $OutputDirectory,

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
            throw ("Sync-ChocolateyPackage requires a Chocolatey for Business license file at '{0}'." -f $licensePath)
        }
    }

    process
    {
        $defaultArgParameters = @{}
        foreach ($key in $PSBoundParameters.Keys)
        {
            if ($key -notin 'Id', 'PackageId')
            {
                $defaultArgParameters[$key] = $PSBoundParameters[$key]
            }
        }

        [System.Collections.Generic.List[string]] $chocoArguments = [System.Collections.Generic.List[string]]::new()
        $chocoArguments.Add('sync')

        if ($PSBoundParameters.ContainsKey('Id'))
        {
            $chocoArguments.Add("--id=`"$Id`"")
        }

        if ($PSBoundParameters.ContainsKey('PackageId'))
        {
            $chocoArguments.Add("--package-id=`"$PackageId`"")
        }

        foreach ($argument in (Get-ChocolateyDefaultArgument @defaultArgParameters))
        {
            $chocoArguments.Add($argument)
        }

        $target = if ($PSBoundParameters.ContainsKey('Id')) { $Id } else { 'all untracked software' }

        if ($PSCmdlet.ShouldProcess($target, 'Sync Chocolatey package'))
        {
            $chocoArguments.Add('-y')
            Write-Debug -Message ('{0} {1}' -f $chocoCmd, ($chocoArguments -join ' '))

            $chocoOutput = &$chocoCmd @chocoArguments
            $headers = $null

            foreach ($line in $chocoOutput)
            {
                Write-Verbose -Message ('{0}' -f $line)

                if ($line -notmatch '\|')
                {
                    continue
                }

                if ($null -eq $headers)
                {
                    $headers = $line -split '\|'
                    continue
                }

                $values = $line -split '\|'
                [PSCustomObject]@{
                    PackageId   = $values[0]
                    DisplayName = $values[1]
                    Version     = $values[2]
                    NewPackage  = $values[3] -eq 'True'
                }
            }
        }
    }
}
