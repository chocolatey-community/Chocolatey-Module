
<#
.SYNOPSIS
    Updates the Chocolatey package to the latest version.

.DESCRIPTION
    Upgrades a package or a list of packages to the latest version available on the source(s).
    If you do not have a package installed, upgrade will install it.

.PARAMETER Name
    Package Name to install, either from a configured source, a specified one such as a folder,
    or the current directory '.'

.PARAMETER Version
    Version - A specific version to install. Defaults to unspecified.

.PARAMETER Source
    Source - The source to find the package(s) to install. Special sources
    include: ruby, webpi, cygwin, windowsfeatures, and python. To specify
    more than one source, pass it with a semi-colon separating the values (-
    e.g. "'source1;source2'"). Defaults to default feeds.

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

.PARAMETER AcceptLicense
    AcceptLicense - Accept license dialogs automatically. Reserved for future use.

.PARAMETER Timeout
    CommandExecutionTimeout (in seconds) - The time to allow a command to
    finish before timing out. Overrides the default execution timeout in the
    configuration of 2700 seconds. '0' for infinite starting in 0.10.4.

.PARAMETER x86
    ForceX86 - Force x86 (32bit) installation on 64 bit systems. Defaults to false.

.PARAMETER InstallArguments
    InstallArguments - Install Arguments to pass to the native installer in
    the package. Defaults to unspecified.

.PARAMETER InstallArgumentsSensitive
    InstallArgumentsSensitive - Install Arguments to pass to the native
    installer in the package that are sensitive and you do not want logged.
    Defaults to unspecified.
    Available in 0.10.1+. [Licensed editions](https://chocolatey.org/compare) only.

.PARAMETER PackageParameters
    PackageParameters - Parameters to pass to the package,
    that should be handled by the ChocolateyInstall.ps1

.PARAMETER PackageParametersSensitive
    PackageParametersSensitive - Package Parameters to pass the package that
    are sensitive and you do not want logged. Defaults to unspecified.
    Available in 0.10.1+. [Licensed editions](https://chocolatey.org/compare) only.

.PARAMETER OverrideArguments
    OverrideArguments - Should install arguments be used exclusively without
    appending to current package passed arguments? Defaults to false.

.PARAMETER NotSilent
    NotSilent - Do not install this silently. Defaults to false.

.PARAMETER ApplyArgsToDependencies
    Apply Install Arguments To Dependencies  - Should install arguments be
    applied to dependent packages? Defaults to false.

.PARAMETER AllowDowngrade
    AllowDowngrade - Should an attempt at downgrading be allowed? Defaults to false.

.PARAMETER IgnoreDependencies
    IgnoreDependencies - Ignore dependencies when installing package(s).
    Defaults to false.

.PARAMETER ForceDependencies
    ForceDependencies - Force dependencies to be reinstalled when force
    installing package(s). Must be used in conjunction with --force.
    Defaults to false.

.PARAMETER SkipPowerShell
    Skip Powershell - Do not run chocolateyInstall.ps1. Defaults to false.

.PARAMETER IgnoreChecksum
    IgnoreChecksums - Ignore checksums provided by the package. Overrides
    the default feature 'checksumFiles' set to 'True'. Available in 0.9.9.9+.

.PARAMETER AllowEmptyChecksum
    Allow Empty Checksums - Allow packages to have empty/missing checksums
    for downloaded resources from non-secure locations (HTTP, FTP). Use this
    switch is not recommended if using sources that download resources from
    the internet. Overrides the default feature 'allowEmptyChecksums' set to
    'False'. Available in 0.10.0+.

.PARAMETER ignorePackageCodes
    IgnorePackageExitCodes - Exit with a 0 for success and 1 for non-success,
    no matter what package scripts provide for exit codes. Overrides the
    default feature 'usePackageExitCodes' set to 'True'. Available in 0.-9.10+.

.PARAMETER UsePackageCodes
    UsePackageExitCodes - Package scripts can provide exit codes. Use those
    for choco's exit code when non-zero (this value can come from a
    dependency package). Chocolatey defines valid exit codes as 0, 1605,
    1614, 1641, 3010.  Overrides the default feature 'usePackageExitCodes'
    set to 'True'. Available in 0.9.10+.

.PARAMETER StopOnFirstFailure
    Stop On First Package Failure - stop running install, upgrade or
    uninstall on first package failure instead of continuing with others.
    Overrides the default feature 'stopOnFirstPackageFailure' set to 'False'.
    Available in 0.10.4+.

.PARAMETER UseRememberedArguments
    Use Remembered Options for Upgrade - use the arguments and options used
    during install for upgrade. Does not override arguments being passed at
    runtime. Overrides the default feature
    'useRememberedArgumentsForUpgrades' set to 'False'. Available in 0.10.4+.

.PARAMETER IgnoreRememberedArguments
    Ignore Remembered Options for Upgrade - ignore the arguments and options
    used during install for upgrade. Overrides the default feature
    'useRememberedArgumentsForUpgrades' set to 'False'. Available in 0.10.4+.

.PARAMETER ExcludePrerelease
    Exclude Prerelease - Should prerelease be ignored for upgrades? Will be
    ignored if you pass `--pre`. Available in 0.10.4+.

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.

.EXAMPLE
    Update-ChocolateyPackage -Name All

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsUpgrade
#>
function Update-ChocolateyPackage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $Source,

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

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $AcceptLicense,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]
        $Timeout,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $x86,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $InstallArguments,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $InstallArgumentsSensitive,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $PackageParameters,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $PackageParametersSensitive,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $OverrideArguments,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $NotSilent,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $ApplyArgsToDependencies,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $AllowDowngrade,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $IgnoreDependencies,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $ForceDependencies,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $SkipPowerShell,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $IgnoreChecksum,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $AllowEmptyChecksum,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $ignorePackageCodes,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $UsePackageCodes,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $StopOnFirstFailure,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $UseRememberedArguments,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $IgnoreRememberedArguments,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $ExcludePrerelease,

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    begin
    {
        # Validate choco is installed or die. Will load the exe path from module cache.
        # Should you want to specify an installation directory,
        # you have to call Get-ChocolateyCommand -InstallDir <path> -Force to set the cache.
        $chocoCmd = Get-ChocolateyCommand
        # Removing the cache because it will be obsolete when uninstalling packages
        Remove-ChocolateyPackageCache
    }

    process
    {
        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $null = $PSBoundParameters.Remove('Name')
        }

        foreach ($PackageName in $Name)
        {
            $ChocoArguments = @('upgrade', $PackageName)
            $ChocoArguments += @(Get-ChocolateyDefaultArgument @PSBoundParameters)

            if ($PSCmdlet.ShouldProcess($PackageName, "Upgrade"))
            {
                #Impact confirmed, go choco go!
                $ChocoArguments += @('-y')
                Write-Debug -Message ('{0} {1}' -f $chocoCmd, $($ChocoArguments -join ' '))
                &$chocoCmd $ChocoArguments | Foreach-Object -Process {
                    if (-not [string]::IsNullOrEmpty($_))
                    {
                        Write-Verbose -Message $_
                    }
                }
            }
        }
    }
}
