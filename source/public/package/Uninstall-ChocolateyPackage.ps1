
<#
.SYNOPSIS
    Uninstalls a Chocolatey package or a list of packages.

.DESCRIPTION
    Once the Chocolatey Software has been installed (see Install-ChocolateySoftware) this command
    allows you to uninstall Software installed by Chocolatey,
    or synced from Add-remove program (Business edition).

.PARAMETER Name
    Package Name to uninstall, either from a configured source, a specified one such as a folder,
    or the current directory '.'

.PARAMETER Version
    Version - A specific version to install.

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

.PARAMETER UninstallArguments
    UninstallArguments - Uninstall Arguments to pass to the native installer
    in the package. Defaults to unspecified.

.PARAMETER OverrideArguments
    OverrideArguments - Should uninstall arguments be used exclusively
    without appending to current package passed arguments? Defaults to false.

.PARAMETER NotSilent
    NotSilent - Do not uninstall this silently. Defaults to false.

.PARAMETER ApplyArgsToDependencies
    Apply Install Arguments To Dependencies  - Should install arguments be
    applied to dependent packages? Defaults to false.

.PARAMETER IgnoreDependencies
    IgnoreDependencies - Ignore dependencies when installing package(s).
    Defaults to false.

.PARAMETER ForceDependencies
    RemoveDependencies - Uninstall dependencies when uninstalling package(s).
    Defaults to false.

.PARAMETER SkipPowerShell
    Skip Powershell - Do not run chocolateyUninstall.ps1. Defaults to false.

.PARAMETER ignorePackageCodes
    IgnorePackageExitCodes - Exit with a 0 for success and 1 for non-succes-s,
    no matter what package scripts provide for exit codes. Overrides the
    default feature 'usePackageExitCodes' set to 'True'. Available in 0.9.10+.

.PARAMETER UsePackageCodes
    UsePackageExitCodes - Package scripts can provide exit codes. Use those
    for choco's exit code when non-zero (this value can come from a
    dependency package). Chocolatey defines valid exit codes as 0, 1605,
    1614, 1641, 3010. Overrides the default feature 'usePackageExitCodes'
    set to 'True'.
    Available in 0.9.10+.

.PARAMETER StopOnFirstFailure
    Stop On First Package Failure - stop running install, upgrade or
    uninstall on first package failure instead of continuing with others.
    Overrides the default feature 'stopOnFirstPackageFailure' set to 'False'.
    Available in 0.10.4+.

.PARAMETER AutoUninstaller
    UseAutoUninstaller - Use auto uninstaller service when uninstalling.
    Overrides the default feature 'autoUninstaller' set to 'True'.
    Available in 0.9.10+.

.PARAMETER SkipAutoUninstaller
    SkipAutoUninstaller - Skip auto uninstaller service when uninstalling.
    Overrides the default feature 'autoUninstaller' set to 'True'. Available
    in 0.9.10+.

.PARAMETER FailOnAutouninstaller
    FailOnAutoUninstaller - Fail the package uninstall if the auto
    uninstaller reports and error. Overrides the default feature
    'failOnAutoUninstaller' set to 'False'. Available in 0.9.10+.

.PARAMETER IgnoreAutoUninstallerFailure
    Ignore Auto Uninstaller Failure - Do not fail the package if auto
    uninstaller reports an error. Overrides the default feature
    'failOnAutoUninstaller' set to 'False'. Available in 0.9.10+.

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you really want to run
    even if the current shell is not elevated.

.EXAMPLE
    Uninstall-ChocolateyPackage -Name Putty

.NOTES
    https://github.com/chocolatey/choco/wiki/Commandsuninstall
#>
function Uninstall-ChocolateyPackage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $Source,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [pscredential]
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
        [System.String]
        $UninstallArguments,

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
        $IgnoreDependencies,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $ForceDependencies,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $SkipPowerShell,

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
        $AutoUninstaller,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $SkipAutoUninstaller,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $FailOnAutouninstaller,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $IgnoreAutoUninstallerFailure,

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
            $ChocoArguments = @('uninstall', $PackageName)
            $ChocoArguments += @(Get-ChocolateyDefaultArgument @PSBoundParameters)

            if ($PSCmdlet.ShouldProcess($PackageName, "Uninstall"))
            {
                #Impact confirmed, go choco go!
                $ChocoArguments += @('-y')
                Write-Debug -Message ('{0} {1}' -f $chocoCmd, $($ChocoArguments -join ' '))
                &$chocoCmd $ChocoArguments | Foreach-Object -Process {
                    Write-Verbose -Message ('{0}' -f $_)
                }
            }
        }
    }
}
