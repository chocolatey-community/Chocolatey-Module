using namespace System.Management.Automation

<#
    .SYNOPSIS
        The `ChocolateyPackage` DSC resource is used to install or remove chocolatey
        packages.
    .DESCRIPTION
        The ChocolateyPackage DSC Resource helps with chocolatey package management.
    .PARAMETER Name
        The name of the ChocolateyPackage to set in the desired state.
    .PARAMETER Version
        The version of the package to install. If not set, it will only ensure the package
        is present/absent.
        If set to latest, it will always make sure the latest version available on the source is
        the one installed.
        If set to a version it will try to compare and make sure the installed version is greater
        or equal than the one desired.
    .PARAMETER ChocolateyOptions
        Chocolatey parameters as per the Install or Update chocolateyPackage commands.
    .PARAMETER UpdateOnly
        Only update the package if present.
        When absent do not attempt to install.
    .PARAMETER Reasons
        Reason for compliance or non-compliance returned by the Get method.
    .EXAMPLE
        Invoke-DscResource -ModuleName Chocolatey -Name ChocolateyPackage -Method Get -Property @{
            Ensure         = 'present'
            Name           = 'localhost'
            UpdateOnly     = $true
        }

        This example shows how to call the resource using Invoke-DscResource.
#>
[DscResource(RunAsCredential = 'Optional')]
class ChocolateyPackage : ChocolateyBase
{
    [DscProperty(Mandatory)]
    [Ensure] $Ensure = 'Present'

    [DscProperty(Key)]
    [String] $Name

    [DscProperty()]
    [String] $Version

    [DscProperty()] # WriteOnly
    [hashtable] $ChocolateyOptions

    [DscProperty()] # WriteOnly
    [String] $Source

    [DscProperty()] # WriteOnly
    [PSCredential] $Credential

    [DscProperty(NotConfigurable)]
    [bool] $UpdateOnly

    [DscProperty(NotConfigurable)]
    [ChocolateyReason[]] $Reasons

    static [ChocolateyPackage] Get([ChocolateyPackage] $DesiredState)
    {
        $currentState = [ChocolateyPackage]::new()
        $currentState.Name = $DesiredState.Name

        if (-not (Test-ChocolateyInstall))
        {
            Write-Debug -Message 'Chocolatey is not installed.'
            $currentState.Ensure = 'Absent'

            $currentState.Reasons += @{
                code = 'ChocolateyPackage:ChocolateyPackage:ChocolateyNotInstalled'
                phrase = 'The Chocolatey software is not installed. We cannot check if a package is present using choco.'
            }
        }

        $comparePackageParams = @{
            Name = $DesiredState.Name
        }

        if ([string]::IsNullOrEmpty($DesiredState.Version) -eq $false)
        {
            $comparePackageParams['Version'] = $DesiredState.Version
        }

        if ([string]::IsNullOrEmpty($DesiredState.Source) -eq $false)
        {
            $comparePackageParams['Source'] = $DesiredState.Source
        }

        if ($null -ne $DesiredState.Credential)
        {
            $comparePackageParams['Credential'] = $DesiredState.Credential
        }

        $comparePackage = $null
        try
        {
            $comparePackage = Compare-ChocolateyPackage @comparePackageParams
        }
        catch
        {
            Write-Verbose -Message ('Exception Caught:' -f $_)
            $localPackage = $null
            $currentState.Reasons += @{
                code = 'ChocolateyPackage:ChocolateyPackage:ChocolateyError'
                phrase = ('Error: {0}.' -f $_)
            }
        }

        $currentState.Version = $comparePackage.InstalledVersion
        $DesiredState.Version = $comparePackage.ExpectedVersion

        if ($DesiredState.Ensure -eq 'Present')
        {
            # We expect the package to be present
            switch ($comparePackage.SideIndicator)
            {
                '='
                {
                    $currentState.Ensure = 'Present'
                    $currentState.Reasons += @{
                        Code   = ('ChocolateyPackage:ChocolateyPackage:Compliant')
                        Phrase = ('The Package ''{0}'' is installed with expected version ''{1}''.' -f $currentState.Name, $currentState.Version)
                    }
                }

                '>'
                {
                    $currentState.Ensure = 'Present'
                    $currentState.Reasons += @{
                        Code   = ('ChocolateyPackage:ChocolateyPackage:Compliant')
                        Phrase = ('The Package ''{0}'' is installed with version ''{1}'' higher or equal than the expected ''{2}''.' -f $currentState.Name, $currentState.Version, $DesiredState.Version)
                    }
                }

                '<'
                {
                    $currentState.Ensure = 'Present'
                    $currentState.Reasons += @{
                        Code   = ('ChocolateyPackage:ChocolateyPackage:BelowExpectedVersion')
                        Phrase = ('The Package ''{0}'' is installed with version ''{1}'' Lower than the expected ''{2}''.' -f $currentState.Name, $currentState.Version, $DesiredState.Version)
                    }
                }

                '!'
                {
                    if ($DesiredState.UpdateOnly -and $DesiredState.Ensure -eq 'Present')
                    {
                        Write-Verbose -Message ('Skipping install of ''{0}'' because ''UpdateOnly'' is set.' -f $DesiredState.Name)
                        $currentState.Ensure = 'Absent'
                        $currentState.Reasons += @{
                            Code   = ('ChocolateyPackage:ChocolateyPackage:Compliant')
                            Phrase = ('The Package ''{0}'' is not installed as desired (UpdateOnly set).' -f $currentState.Name)
                        }
                    }
                    else
                    {
                        $currentState.Ensure = 'Absent'
                        $currentState.Reasons += @{
                            Code   = ('ChocolateyPackage:ChocolateyPackage:ShouldBeInstalled')
                            Phrase = ('The Package ''{0}'' is not installed but is expected to be present.' -f $currentState.Name)
                        }
                    }
                }

                default
                {
                    Write-Debug -Message ('Unknown SideIndicator ''{0}'' returned by Compare-ChocolateyPackageInstalled.' -f $comparePackage.SideIndicator)
                    $localPackage = $null
                    $currentState.Reasons += @{
                        code = 'ChocolateyPackage:ChocolateyPackage:UnknownSideIndicator'
                        phrase = ('Unknown SideIndicator ''{0}'' returned by Compare-ChocolateyPackageInstalled.' -f $comparePackage.SideIndicator)
                    }
                }
            }
        }
        else
        {
            # We expect the package to be absent
            # if version is specified, we want that version to not be installed
            #  but another version installed is ok
            # if version is not specified, we don't want the package present at all

            switch ($comparePackage.SideIndicator)
            {
                '!'
                {
                    $currentState.Ensure = 'Absent'
                    $currentState.Reasons += @{
                        Code   = ('ChocolateyPackage:ChocolateyPackage:Compliant')
                        Phrase = ('The Package ''{0}'' is not installed as desired.' -f $currentState.Name)
                    }
                }

                '='
                {
                    if ([string]::IsNullOrEmpty($DesiredState.Version))
                    {
                        # Any version is not expected
                        $currentState.Ensure = 'Present'
                        $currentState.Reasons += @{
                            Code   = ('ChocolateyPackage:ChocolateyPackage:ShouldNotBeInstalled')
                            Phrase = ('The Package ''{0}'' is installed with version ''{1}'' but is NOT expected to be present.' -f $currentState.Name, $currentState.Version)
                        }
                    }
                    else
                    {
                        # A version is expected to be absent, and that version is present
                        $currentState.Ensure = 'Present'
                        $currentState.Reasons += @{
                            Code   = ('ChocolateyPackage:ChocolateyPackage:VersionShouldNotBeInstalled')
                            Phrase = ('The Package ''{0}'' is installed with version ''{1}'' which is the version expected absent: ''{2}''.' -f $currentState.Name, $currentState.Version, $DesiredState.Version)
                        }
                    }
                }

                '>'
                {
                    if ([string]::IsNullOrEmpty($DesiredState.Version))
                    {
                        # Any version is not expected
                        $currentState.Ensure = 'Present'
                        $currentState.Reasons += @{
                            Code   = ('ChocolateyPackage:ChocolateyPackage:ShouldNotBeInstalled')
                            Phrase = ('The Package ''{0}'' is installed with version ''{1}'' but is NOT expected to be present.' -f $currentState.Name, $currentState.Version)
                        }
                    }
                    else
                    {
                        # A version is expected to be absent, but a higher version is present
                        $currentState.Ensure = 'Present'
                        $currentState.Reasons += @{
                            Code   = ('ChocolateyPackage:ChocolateyPackage:Compliant')
                            Phrase = ('The Package ''{0}'' is installed with version ''{1}'' higher than the expected absent ''{2}''.' -f $currentState.Name, $currentState.Version, $DesiredState.Version)
                        }
                    }
                }

                '<'
                {
                    if ([string]::IsNullOrEmpty($DesiredState.Version))
                    {
                        # Any version is not expected
                        $currentState.Ensure = 'Present'
                        $currentState.Reasons += @{
                            Code   = ('ChocolateyPackage:ChocolateyPackage:ShouldNotBeInstalled')
                            Phrase = ('The Package ''{0}'' is installed with version ''{1}'' but is NOT expected to be present.' -f $currentState.Name, $currentState.Version)
                        }
                    }
                    else
                    {
                        # A version is expected to be absent, but a lower version is present
                        $currentState.Ensure = 'Present'
                        $currentState.Reasons += @{
                            Code   = ('ChocolateyPackage:ChocolateyPackage:BelowUnapprovedVersion')
                            Phrase = ('The Package ''{0}'' is installed with version ''{1}'' Lower than the version expected absent: ''{2}''.' -f $currentState.Name, $currentState.Version, $DesiredState.Version)
                        }
                    }
                }

                default
                {
                    Write-Debug -Message ('Unknown SideIndicator ''{0}'' returned by Compare-ChocolateyPackageInstalled.' -f $comparePackage.SideIndicator)
                    $localPackage = $null
                    $currentState.Reasons += @{
                        code = 'ChocolateyPackage:ChocolateyPackage:UnknownSideIndicator'
                        phrase = ('Unknown SideIndicator ''{0}'' returned by Compare-ChocolateyPackageInstalled.' -f $comparePackage.SideIndicator)
                    }
                }
            }
        }

        return $currentState
    }

    [ChocolateyPackage] Get()
    {
        return [ChocolateyPackage]::Get($this)
    }

    static [DscChocoTestResult] Test([ChocolateyPackage] $DesiredState)
    {
        $currentState = [ChocolateyPackage]::Get($DesiredState)
        [DscChocoTestResult] $result = [DscChocoTestResult]::new()

        if ($currentState.Reasons.Code.Where({$_ -notmatch ':Compliant$'}))
        {
            $result.Passed = $false
        }
        else
        {
            $result.Passed = $true
        }

        return $result
    }

    [bool] Test()
    {
        return [ChocolateyPackage]::Test($this).Passed
    }

    # static [bool] Validate([MyResource]$instance) {}
    # static [hashtable] Schema() {}

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCReturnCorrectTypesForDSCFunctions", "")]
    static [DscChocoSetResult] Set([ChocolateyPackage] $DesiredState)
    {
        $currentState = [ChocolateyPackage]::Get($DesiredState)
        return ([ChocolateyPackage]::Set($currentState, $DesiredState, $false))
    }

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCReturnCorrectTypesForDSCFunctions", "")]
    static [DscChocoSetResult] Set([ChocolateyPackage] $CurrentState, [ChocolateyPackage] $DesiredState)
    {
        return ([ChocolateyPackage]::Set($CurrentState, $DesiredState, $false))
    }

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCReturnCorrectTypesForDSCFunctions", "")]
    static [DscChocoSetResult] Set([ChocolateyPackage] $CurrentState, [ChocolateyPackage] $DesiredState, [bool] $WhatIf)
    {
        $result = [DscChocoSetResult]::new()
        $chocoCommand = $null

        switch ($CurrentState.Reasons.code)
        {

            'ChocolateyPackage:ChocolateyPackage:BelowExpectedVersion'
            {
                # upgrade
                Write-Debug -Message ('Upgrading {0}' -f $DesiredState.Name)
                $chocoCommand = Get-Command -Name 'Update-ChocolateyPackage'
            }

            'ChocolateyPackage:ChocolateyPackage:ShouldBeInstalled'
            {
                # Install
                Write-Debug -Message ('Installing {0}' -f $DesiredState.Name)
                $chocoCommand = Get-Command -Name 'Install-ChocolateyPackage'
            }

            'ChocolateyPackage:ChocolateyPackage:ShouldNotBeInstalled'
            {
                # Uninstall
                Write-Debug -Message ('Uninstalling {0} version {1}' -f $DesiredState.Name, $DesiredState.Version)
                $chocoCommand = Get-Command -Name 'Uninstall-ChocolateyPackage'
            }

            'ChocolateyPackage:ChocolateyPackage:VersionShouldNotBeInstalled'
            {
                if ($DesiredState.UpgradeOnly)
                {
                    # Upgrade
                    Write-Debug -Message ('Upgrading {0}' -f $DesiredState.Name)
                    $chocoCommand = Get-Command -Name 'Update-ChocolateyPackage'
                }
                else
                {
                    # Uninstall
                    Write-Debug -Message ('Uninstalling {0} version {1}' -f $DesiredState.Name, $DesiredState.Version)
                    $chocoCommand = Get-Command -Name 'Uninstall-ChocolateyPackage'
                }
            }

            'ChocolateyPackage:ChocolateyPackage:BelowUnapprovedVersion'
            {
                if ($DesiredState.UpgradeOnly)
                {
                    # Upgrade
                    Write-Debug -Message ('Upgrading {0}' -f $DesiredState.Name)
                    $chocoCommand = Get-Command -Name 'Update-ChocolateyPackage'
                }
                else
                {
                    # Uninstall
                    Write-Debug -Message ('Uninstalling {0} version {1}' -f $DesiredState.Name, $DesiredState.Version)
                    $chocoCommand = Get-Command -Name 'Uninstall-ChocolateyPackage'
                }
            }

            'ChocolateyPackage:ChocolateyPackage:UnknownSideIndicator'
            {
                # Unsupported error, surface message
                Write-Error -Message ('Unsupported error occurred while processing {0}.' -f $DesiredState.Name)
            }

            Default
            {
                # Unsupported Code Path
                Write-Error -Message ('Unsupported code path encountered while processing {0}.' -f $DesiredState.Name)
            }
        }

        $chocoCommandParams = @{
            Name    = $DesiredState.Name
            confirm = $false
            ErrorAction = 'Stop'
        }

        if (-not [string]::IsNullOrEmpty($DesiredState.Version) -and $DesiredState.Version -ne 'latest')
        {
            $chocoCommandParams['Version'] = $DesiredState.Version
        }

        if (-not [string]::IsNullOrEmpty($DesiredState.Source))
        {
            $chocoCommandParams['Source'] = $DesiredState.Source
        }

        $DesiredState.ChocolateyOptions.keys.Where{$_ -notin $chocoCommandParams.Keys}.Foreach{
            if ($chocoCommand.Parameters.Keys -contains $_)
            {
                if ($this.ChocolateyOptions[$_] -in @('True','False'))
                {
                    $chocoCommandParams[$_] = [bool]::Parse($this.ChocolateyOptions[$_])
                }
                else
                {
                    $chocoCommandParams[$_] = $this.ChocolateyOptions[$_]
                }
            }
            else
            {
                Write-Verbose -Message ('  Ignoring parameter ''{0}''. Not suported by ''{1}''.' -f $_, $chocoCommand.Name)
            }
        }

        try
        {
            if ($null -ne $chocoCommand)
            {
                Write-verbose -Message ('---> Executing command {0} with param <{1}>' -f $chocoCommand.Name, ($chocoCommandParams | ConvertTo-Json -Depth 4))
                $result.messages += &$chocoCommand @chocoCommandParams
            }
        }
        catch
        {
            Write-Verbose -Message ('Exception Caught:' -f $_)
            $result.messages += ('Error: {0}.' -f $_)
        }

        $result.After = [ChocolateyPackage]::Get($DesiredState)
        #TODO: not a big fan of always having to call Get() to populate After state
        # it's expensive after all.

        return $result
    }

    [void] Set()
    {
        [ChocolateyPackage] $currentState = $this.Get()
        $null = [ChocolateyPackage]::Set($currentState, $this, $false)
    }

    static [void] Delete([ChocolateyPackage] $DesiredState)
    {
        $comparePackageParams = @{
            Name = $DesiredState.Name
        }

        if ($DesiredState.Version)
        {
            $comparePackageParams['Version'] = $DesiredState.Version
        }

        $ComparedPackage = Compare-ChocolateyPackage -Name $DesiredState.Name
        if ($ComparedPackage.SideIndicator -ne '!')
        {
            Write-Verbose -Message ('Removing package ''{0}''.' -f $DesiredState.Name)
            Uninstall-ChocolateyPackage -Name $DesiredState.Name -Confirm:$false
        }
    }

    static [ChocolateyPackage[]] Export([ChocolateyPackage] $FilteringInstance)
    {
        return ([ChocolateyPackage]::Export().Where{
            if ([string]::IsNullOrEmpty($FilteringInstance.Name))
            {
                $true
            }
            else
            {
                $_.Name -eq $FilteringInstance.Name
            }
        })
    }

    static [ChocolateyPackage[]] Export()
    {
        try
        {
            $allPackages = Get-ChocolateyPackage
            [ChocolateyPackage[]]$result = $allPackages.Foreach{
                ([ChocolateyPackage]@{
                    Ensure  = 'Present'
                    Name    = $_.Name
                    Version = $_.Version
                }).Get() #TODO: is it necessary to call the Get() to populate the Reasons?
            }

            return $result
        }
        catch
        {
            Write-Verbose -Message ('Exception Caught:' -f $_)
            return @()
        }
    }
}
