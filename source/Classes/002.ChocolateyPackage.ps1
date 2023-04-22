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
class ChocolateyPackage
{
    [DscProperty(Mandatory)]
    [Ensure] $Ensure = 'Present'

    [DscProperty(Key)]
    [String] $Name

    [DscProperty()]
    [String] $Version

    [DscProperty()]
    [hashtable] $ChocolateyOptions

    [DscProperty()]
    [PSCredential] $Credential

    [DscProperty(NotConfigurable)]
    [bool] $UpdateOnly

    [DscProperty(NotConfigurable)]
    [ChocolateyReason[]] $Reasons

    [ChocolateyPackage] Get()
    {
        $currentState = [ChocolateyPackage]::new()
        $currentState.Name = $this.Name

        if ($false -eq (Test-ChocolateyInstall))
        {
            Write-Debug -Message 'Chocolatey is not installed.'
            $currentState.Ensure = 'Absent'

            $currentState.Reasons += @{
                code = 'ChocolateyPackage:ChocolateyPackage:ChocolateyNotInstalled'
                phrase = 'The Chocolatey software is not installed. We cannot check if a package is present using choco.'
            }

            return $currentState
        }

        try
        {
            $localPackage = Get-ChocolateyPackage -LocalOnly -Name $this.Name -Exact
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

        if ($null -eq $localPackage)
        {
            Write-Debug -Message ('Local Package ''{0}'' not found.' -f $this.Name)
            $currentState.Ensure = [Ensure]::Absent
        }
        else
        {
            Write-Debug -Message ('Local Package found: {0}' -f ($localPackage | ConvertTo-Json))
            $currentState.Ensure = [ensure]::Present
            $currentState.Version = $localPackage.Version
        }

        if ($this.Ensure -eq 'Absent' -and $currentState.Ensure -eq $this.Ensure)
        {
            Write-Debug -Message ('The package named ''{0}'' is absent as expected.' -f $this.Name)
            $currentState.Reasons += @{
                Code   = ('ChocolateyPackage:ChocolateyPackage:Compliant')
                Phrase = ('The Package ''{0}'' is not installed as desired.' -f $currentState.Name)
            }
        }
        elseif ([string]::IsNullOrEmpty($this.Version) -and $currentState.Ensure -eq $this.Ensure)
        {
            Write-Debug -Message ('The package named ''{0}'' is present as expected. No version required.' -f $this.Name)
            $currentState.Reasons += @{
                Code   = ('ChocolateyPackage:ChocolateyPackage:Compliant')
                Phrase = ('The Package ''{0}'' is installed (with version ''{1}'').' -f $currentState.Name, $currentState.Version)
            }
        }
        elseif (-not [string]::IsNullOrEmpty($this.Version) -and $this.Version -eq $localPackage.Version -and $currentState.Ensure -eq $this.Ensure)
        {
            Write-Debug -Message ('The package named ''{0}'' is present with expected version.' -f $this.Name)
            $currentState.Reasons += @{
                Code   = ('ChocolateyPackage:ChocolateyPackage:Compliant')
                Phrase = ('The Package ''{0}'' is installed with expected version ''{1}''.' -f $currentState.Name, $currentState.Version)
            }
        }
        elseif ($currentState.Ensure -ne $this.Ensure)
        {
            if ($this.Ensure -eq 'Absent')
            {
                $currentState.Reasons += @{
                    Code   = ('ChocolateyPackage:ChocolateyPackage:ShouldNotBeInstalled')
                    Phrase = ('The Package ''{0}'' is installed with version ''{1}'' but is NOT expected to be present.' -f $currentState.Name, $currentState.Version)
                }
            }
            else
            {
                $currentState.Reasons += @{
                    Code   = ('ChocolateyPackage:ChocolateyPackage:ShouldBeInstalled')
                    Phrase = ('The Package ''{0}'' is not installed but is expected to be present.' -f $currentState.Name)
                }
            }
        }
        else
        {
            Write-Debug -Message ('The package named ''{0}'' is ''Present'' with version ''{1}'' while we expect version ''{2}''.' -f $this.Name, $currentState.Version,$this.Version)
            if ('latest' -eq $this.Version)
            {
                Write-Debug -Message ('  Grabbing the latest version of ''{0}'' from source.' -f $this.Name)
                $searchVersionParam = @{
                    Exact = $true
                    Name  = $this.Name
                }

                if ($this.ChocolateyOptions -and $this.ChocolateyOptions.ContainsKey('source'))
                {
                    Write-Debug -Message ('  Searching in specified source ''{0}''.' -f $this.ChocolateyOptions['source'])
                    $searchVersionParam['source'] = $this.ChocolateyOptions['source']
                }

                Write-Debug -Message ('  Searching with ''Get-ChocolateyPackage'' and parameters {0}' -f ($searchVersionParam | ConvertTo-Json -Depth 3))
                $refVersionPackage = Find-ChocolateyPackage @searchVersionParam

                if ($null -eq $refVersionPackage)
                {
                    Write-Debug -Message ('The package ''{0}'' could not be found on the source repository.' -f $this.Name)
                    $refVersion = $null
                    $currentState.Reasons += @{
                        Code   = ('ChocolateyPackage:ChocolateyPackage:LatestPackageNotFound')
                        Phrase = ('The Package ''{0}'' is installed with version ''{1}'' but couldn''t be found on the source.' -f $currentState.Name, $currentState.Version, $this.Version)
                    }
                }
                else
                {
                    $refVersion = $refVersionPackage.Version
                    Write-Debug -Message ('Latest version for ''{0}'' found in source is ''{1}''.' -f $this.Name, $refVersion)
                }
            }
            else
            {
                $refVersion = $this.Version
            }

            if ([string]::IsNullOrEmpty($refVersion))
            {
                # No need to check for version because the 'LatestPackageNotFound' on source...
            }
            elseif ((Compare-SemVerVersion -ReferenceVersion $refVersion -DifferenceVersion $currentState.version) -in @('=', '<'))
            {
                $currentState.Reasons += @{
                    Code   = ('ChocolateyPackage:ChocolateyPackage:Compliant')
                    Phrase = ('The Package ''{0}'' is installed with version ''{1}'' higher or equal than the expected ''{2}'' (''{3}'').' -f $currentState.Name, $currentState.Version, $this.Version, $refVersion)
                }
            }
            else
            {
                $currentState.Reasons += @{
                    Code   = ('ChocolateyPackage:ChocolateyPackage:BelowExpectedVersion')
                    Phrase = ('The Package ''{0}'' is installed with version ''{1}'' Lower than the expected ''{2}''.' -f $currentState.Name, $currentState.Version, $this.Version)
                }
            }
        }

        return $currentState
    }

    [bool] Test()
    {
        $currentState = $this.Get()

        if ($currentState.Reasons.Code.Where({$_ -in @('BelowExpectedVersion','ShouldBeInstalled','ShouldNotBeInstalled')}))
        {
            return $false
        }
        else
        {
            return $true
        }
    }

    [void] Set()
    {
        [ChocolateyPackage] $currentState = $this.Get()
        $chocoCommand = Get-Command -Name 'Install-ChocolateyPackage'
        [hashtable] $chocoCommandParams = @{
            Name        = $this.Name
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        switch -Regex ($currentState.Reasons.Code)
        {
            'BelowExpectedVersion$'
            {
                Write-Debug -Message ('Upgrading package ''{0}'' to version ''{1}''.' -f $this.Name, $this.Version)
                $chocoCommand =  Get-Command -Name 'Update-ChocolateyPackage' -Module 'Chocolatey'
            }

            'ShouldBeInstalled$'
            {
                $chocoCommand = Get-Command -Name 'Install-ChocolateyPackage' -Module 'Chocolatey'

                if ('latest' -eq $this.Version -or [string]::IsNullOrEmpty($this.Version))
                {
                    Write-Debug -Message ('Installing the ''latest'' version of ''{0}'' from the configured or specified source.' -f $this.Name)
                }
                else
                {
                    Write-Debug -Message ('Installing package ''{0}'' to version ''{1}''.' -f $this.Name, $this.Version)
                    $chocoCommandParams['Version'] = $this.Version
                }
            }

            'ShouldNotBeInstalled$'
            {
                $chocoCommand = Get-Command -Name 'Uninstall-ChocolateyPackage' -Module 'Chocolatey'
            }
        }

        if ($this.UpdateOnly -and $chocoCommand.Name -eq 'Install-ChocolateyPackage')
        {
            Write-Verbose -Message ('Skipping install of ''{0}'' because ''UpdateOnly'' is set.' -f $this.Name)
            return
        }

        if ($this.Credential)
        {
            $chocoCommandParams['Credential'] = $this.Credential
        }

        $this.ChocolateyOptions.keys.Where{$_ -notin $chocoCommandParams.Keys}.Foreach{
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

        Write-Verbose -Message ('  Calling ''{0}'' with parameters {1}.' -f $chocoCommand.Name,($chocoCommandParams | ConvertTo-Json -Depth 3))
        &$($chocoCommand.Name) @ChocoCommandParams
    }
}
