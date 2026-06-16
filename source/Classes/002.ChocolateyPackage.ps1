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

    # [DscProperty(NotConfigurable)]
    [String] $_name

    [DscProperty()]
    [String] $Version

    [DscProperty()] # WriteOnly
    [hashtable] $ChocolateyOptions

    [DscProperty()] # WriteOnly
    [String] $Source

    [DscProperty()] # WriteOnly
    [PSCredential] $Credential

    [DscProperty()]
    [bool] $UpdateOnly

    [DscProperty(NotConfigurable)]
    [ChocolateyReason[]] $Reasons

    static [bool] IsCompliant([ChocolateyPackage] $CurrentState)
    {
        return ([ChocolateyPackage]::GetDifferingProperties($CurrentState).Count -eq 0) -and
            (@($CurrentState.Reasons.Code).Where({ $_ -notmatch ':Compliant$' }).Count -eq 0)
    }

    static [string[]] GetDifferingProperties([ChocolateyPackage] $CurrentState)
    {
        $differingProperties = [System.Collections.Generic.List[string]]::new()

        foreach ($reasonCode in @($CurrentState.Reasons.Code))
        {
            switch -Regex ($reasonCode)
            {
                'ShouldBeInstalled$|ShouldNotBeInstalled$'
                {
                    if ('Ensure' -notin $differingProperties)
                    {
                        $null = $differingProperties.Add('Ensure')
                    }
                }

                'BelowExpectedVersion$|VersionShouldNotBeInstalled$|BelowUnapprovedVersion$'
                {
                    if ('Version' -notin $differingProperties)
                    {
                        $null = $differingProperties.Add('Version')
                    }
                }
            }
        }

        return @($differingProperties)
    }

    static [string[]] GetChangedProperties([ChocolateyPackage] $CurrentState, [ChocolateyPackage] $AfterState)
    {
        $changedProperties = [System.Collections.Generic.List[string]]::new()

        if ($CurrentState.Ensure -ne $AfterState.Ensure)
        {
            $null = $changedProperties.Add('Ensure')
        }

        if ($CurrentState.Version -ne $AfterState.Version)
        {
            $null = $changedProperties.Add('Version')
        }

        return @($changedProperties | Select-Object -Unique)
    }

    static [ChocolateyPackage] NewProjectedState(
        [ChocolateyPackage] $CurrentState,
        [ChocolateyPackage] $DesiredState,
        [string] $CommandName
    )
    {
        $projectedState = [ChocolateyPackage]::new()
        $projectedState.Name = $DesiredState.Name
        $projectedState.Source = $DesiredState.Source
        $projectedState.UpdateOnly = $DesiredState.UpdateOnly

        switch ($CommandName)
        {
            'Install-ChocolateyPackage'
            {
                $projectedState.Ensure = 'Present'
                $projectedState.Version = if ([string]::IsNullOrEmpty($DesiredState.Version) -or $DesiredState.Version -eq 'latest')
                {
                    $CurrentState.Version
                }
                else
                {
                    $DesiredState.Version
                }
            }

            'Update-ChocolateyPackage'
            {
                $projectedState.Ensure = 'Present'
                $projectedState.Version = if ([string]::IsNullOrEmpty($DesiredState.Version) -or $DesiredState.Version -eq 'latest')
                {
                    $CurrentState.Version
                }
                else
                {
                    $DesiredState.Version
                }
            }

            'Uninstall-ChocolateyPackage'
            {
                $projectedState.Ensure = 'Absent'
                $projectedState.Version = $null
            }

            default
            {
                $projectedState.Ensure = $CurrentState.Ensure
                $projectedState.Version = $CurrentState.Version
            }
        }

        if ([string]::IsNullOrEmpty($projectedState.Version))
        {
            $projectedState._name = $projectedState.Name
        }
        else
        {
            $projectedState._name = '{0}_{1}' -f $projectedState.Name, $projectedState.Version
        }

        return $projectedState
    }

    static [string] InstanceJsonSchema()
    {
        return [ChocolateyBase]::GetInstanceJsonSchema([ChocolateyPackage])
    }

    static [ChocolateyPackage] Get([ChocolateyPackage] $DesiredState)
    {
        $currentState = [ChocolateyPackage]::new()
        $currentState.Name = $DesiredState.Name
        $currentState.Source = $DesiredState.Source
        $currentState.UpdateOnly = $DesiredState.UpdateOnly

        if (-not (Test-ChocolateyInstall))
        {
            Write-Debug -Message 'Chocolatey is not installed.'
            $currentState.Ensure = 'Absent'
            $currentState._name = $currentState.Name

            $currentState.Reasons += @{
                code = 'ChocolateyPackage:ChocolateyPackage:ChocolateyNotInstalled'
                phrase = 'The Chocolatey software is not installed. We cannot check if a package is present using choco.'
            }

            return $currentState
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
            $currentState.Ensure = 'Absent'
            $currentState._name = $currentState.Name
            $currentState.Reasons += @{
                code = 'ChocolateyPackage:ChocolateyPackage:ChocolateyError'
                phrase = ('Error: {0}.' -f $_)
            }

            return $currentState
        }

        $currentState.Version = $comparePackage.InstalledVersion

        if ([string]::IsNullOrEmpty($currentState.Version))
        {
            $currentState._name = $currentState.Name
        }
        else
        {
            $currentState._name = '{0}_{1}' -f $currentState.Name, $currentState.Version
        }

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
                        Phrase = ('The Package ''{0}'' is installed with version ''{1}'' higher or equal than the expected ''{2}''.' -f $currentState.Name, $currentState.Version, $comparePackage.ExpectedVersion)
                    }
                }

                '<'
                {
                    $currentState.Ensure = 'Present'
                    $currentState.Reasons += @{
                        Code   = ('ChocolateyPackage:ChocolateyPackage:BelowExpectedVersion')
                        Phrase = ('The Package ''{0}'' is installed with version ''{1}'' Lower than the expected ''{2}''.' -f $currentState.Name, $currentState.Version, $comparePackage.ExpectedVersion)
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
                            Phrase = ('The Package ''{0}'' is installed with version ''{1}'' which is the version expected absent: ''{2}''.' -f $currentState.Name, $currentState.Version, $comparePackage.ExpectedVersion)
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
                            Phrase = ('The Package ''{0}'' is installed with version ''{1}'' higher than the expected absent ''{2}''.' -f $currentState.Name, $currentState.Version, $comparePackage.ExpectedVersion)
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
                            Phrase = ('The Package ''{0}'' is installed with version ''{1}'' Lower than the version expected absent: ''{2}''.' -f $currentState.Name, $currentState.Version, $comparePackage.ExpectedVersion)
                        }
                    }
                }

                default
                {
                    Write-Debug -Message ('Unknown SideIndicator ''{0}'' returned by Compare-ChocolateyPackageInstalled.' -f $comparePackage.SideIndicator)
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

    static [System.Tuple[bool, ChocolateyPackage, string[]]] Test([ChocolateyPackage] $DesiredState)
    {
        $currentState = [ChocolateyPackage]::Get($DesiredState)
        return [System.Tuple[bool, ChocolateyPackage, string[]]]::new(
            [ChocolateyPackage]::IsCompliant($currentState),
            $currentState,
            [ChocolateyPackage]::GetDifferingProperties($currentState)
        )
    }

    [bool] Test()
    {
        return [ChocolateyPackage]::Test($this).Item1
    }

    static [System.Tuple[ChocolateyPackage, string[]]] Set([ChocolateyPackage] $DesiredState)
    {
        return [ChocolateyPackage]::Set($DesiredState, $false)
    }

    static [System.Tuple[ChocolateyPackage, string[]]] Set([ChocolateyPackage] $DesiredState, [bool] $WhatIf)
    {
        $currentState = [ChocolateyPackage]::Get($DesiredState)
        return [ChocolateyPackage]::InvokeSet($currentState, $DesiredState, $WhatIf)
    }

    static [System.Tuple[ChocolateyPackage, string[]]] InvokeSet(
        [ChocolateyPackage] $CurrentState,
        [ChocolateyPackage] $DesiredState,
        [bool] $WhatIf
    )
    {
        $chocoCommand = $null

        if (-not (Test-ChocolateyInstall))
        {
            Write-Debug -Message 'Chocolatey is not installed.'
            throw $CurrentState.Reasons.Where{$_.Code -match 'ChocolateyNotInstalled'}.Phrase
        }

        if ([ChocolateyPackage]::IsCompliant($CurrentState))
        {
            return [System.Tuple[ChocolateyPackage, string[]]]::new(
                $CurrentState,
                @()
            )
        }

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
                if ($DesiredState.UpdateOnly)
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
                if ($DesiredState.UpdateOnly)
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
                throw ('Unsupported error occurred while processing {0}.' -f $DesiredState.Name)
            }

            default
            {
                throw ('Unsupported code path encountered while processing {0}.' -f $DesiredState.Name)
            }
        }

        if ($null -eq $chocoCommand)
        {
            throw ('Unable to resolve a Chocolatey command for package ''{0}''.' -f $DesiredState.Name)
        }

        $chocoCommandParams = @{
            Name        = $DesiredState.Name
            Confirm     = $false
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

        if ($null -ne $DesiredState.ChocolateyOptions)
        {
            $DesiredState.ChocolateyOptions.Keys.Where({ $_ -notin $chocoCommandParams.Keys }).ForEach({
                if ($chocoCommand.Parameters.Keys -contains $_)
                {
                    if ($DesiredState.ChocolateyOptions[$_] -in @('True', 'False'))
                    {
                        $chocoCommandParams[$_] = [bool]::Parse($DesiredState.ChocolateyOptions[$_])
                    }
                    else
                    {
                        $chocoCommandParams[$_] = $DesiredState.ChocolateyOptions[$_]
                    }
                }
                else
                {
                    Write-Verbose -Message ('  Ignoring parameter ''{0}''. Not suported by ''{1}''.' -f $_, $chocoCommand.Name)
                }
            })
        }

        if ($WhatIf)
        {
            $afterState = [ChocolateyPackage]::NewProjectedState($CurrentState, $DesiredState, $chocoCommand.Name)
            return [System.Tuple[ChocolateyPackage, string[]]]::new(
                $afterState,
                [ChocolateyPackage]::GetChangedProperties($CurrentState, $afterState)
            )
        }

        $null = &$chocoCommand @chocoCommandParams

        $afterState = [ChocolateyPackage]::Get($DesiredState)
        return [System.Tuple[ChocolateyPackage, string[]]]::new(
            $afterState,
            [ChocolateyPackage]::GetChangedProperties($CurrentState, $afterState)
        )
    }

    [void] Set()
    {
        $null = [ChocolateyPackage]::Set($this, $false)
    }

    static [void] Delete([ChocolateyPackage] $DesiredState)
    {
        $comparePackageParams = @{
            Name = $DesiredState.Name
        }

        if (-not [string]::IsNullOrEmpty($DesiredState.Version))
        {
            $comparePackageParams['Version'] = $DesiredState.Version
        }

        if (-not [string]::IsNullOrEmpty($DesiredState.Source))
        {
            $comparePackageParams['Source'] = $DesiredState.Source
        }

        if ($null -ne $DesiredState.Credential)
        {
            $comparePackageParams['Credential'] = $DesiredState.Credential
        }

        $comparedPackage = Compare-ChocolateyPackage @comparePackageParams
        if ($comparedPackage.SideIndicator -ne '!')
        {
            Write-Verbose -Message ('Removing package ''{0}''.' -f $DesiredState.Name)

            $uninstallParams = @{
                Name     = $DesiredState.Name
                Confirm  = $false
            }

            if (-not [string]::IsNullOrEmpty($DesiredState.Version) -and $DesiredState.Version -ne 'latest')
            {
                $uninstallParams['Version'] = $DesiredState.Version
            }

            if (-not [string]::IsNullOrEmpty($DesiredState.Source))
            {
                $uninstallParams['Source'] = $DesiredState.Source
            }

            if ($null -ne $DesiredState.Credential)
            {
                $uninstallParams['Credential'] = $DesiredState.Credential
            }

            Uninstall-ChocolateyPackage @uninstallParams
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
            [ChocolateyPackage[]] $result = $allPackages.ForEach({
                $package = [ChocolateyPackage]::new()
                $package.Ensure = 'Present'
                $package.Name = $_.Name
                $package.Version = $_.Version
                $package._name = '{0}_{1}' -f $_.Name, $_.Version
                $package
            })

            return $result
        }
        catch
        {
            Write-Verbose -Message ('Exception Caught:' -f $_)
            return @()
        }
    }
}
