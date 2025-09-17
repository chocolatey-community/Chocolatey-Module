
<#
    .SYNOPSIS
        The `ChocolateySource` DSC resource is used to configure or remove source feeds for chocolatey.

    .DESCRIPTION
        Chocolatey will allow you to interact with sources.
        You can register a new source, whether internal or external with some source
        specific settings such as proxy.

    .PARAMETER Ensure
        Indicate whether the Chocolatey source should be installed or removed from the system.

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

    .EXAMPLE
        Invoke-DscResource -ModuleName Chocolatey -Name ChocolateySource -Method Get -Property @{
            Ensure  = 'Present'
            Name    = 'Chocolatey'
            Disable = $true
        }

        # This example shows how to call the resource using Invoke-DscResource.
#>
[DscResource()]
class ChocolateySource : ChocolateyBase
{
    [DscProperty()]
    [Ensure] $Ensure = 'Present'

    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    # If we want to make sure a source is disabled, we don't need to provide its
    # source location
    [string] $Source

    [DscProperty()]
    [Nullable[bool]] $Disabled

    [DscProperty()]
    [Nullable[bool]] $ByPassProxy

    [DscProperty()]
    [Nullable[bool]] $SelfService

    [DscProperty()]
    [Nullable[int]] $Priority

    [DscProperty()]
    [String] $Username

    [DscProperty()]
    [String] $Password

    [DscProperty()] # WriteOnly
    [pscredential] $Credential

    [DscProperty(NotConfigurable)]
    [ChocolateyReason[]] $Reasons


    [ChocolateySource] Get()
    {
        $currentState = [ChocolateySource]::New()
        $currentState.Name = $this.Name

        try
        {
            $localSource = Get-ChocolateySource -Name $this.Name
        }
        catch
        {
            Write-Verbose -Message ('Exception Caught:' -f $_)
            $localSource = $null
            $currentState.Reasons += @{
                code = 'ChocolateySource:ChocolateySource:ChocolateyError'
                phrase = ('Error: {0}.' -f $_)
            }
        }

        if ($localSource.Name -eq $this.Name)
        {
            $currentState.Ensure = 'Present'
        }
        else
        {
            $currentState.Ensure = 'Absent'
        }

        if ($this.Ensure -ne $currentState.Ensure)
        {
            if ($this.Ensure -eq 'Absent')
            {
                $currentState.Reasons += @{
                    code = 'ChocolateySource:ChocolateySource:ShouldBeAbsent'
                    phrase = ('The source ''{0}'' is ''Present'' but should be ''Absent''.' -f $this.Name)
                }
            }
            else
            {
                $currentState.Reasons += @{
                    code = 'ChocolateySource:ChocolateySource:ShouldBePresent'
                    phrase = ('The source ''{0}'' is ''Absent'' but should be ''Present''.' -f $this.Name)
                }
            }
        }
        else
        {
            $currentState.Reasons += @{
                code = 'ChocolateySource:ChocolateySource:EnsureCompliant'
                phrase = ('The source ''{0}'' is ''{1}'' as expected.' -f $this.Name, $this.Ensure)
            }
        }

        $currentState.Source = $localSource.Source
        $currentState.Disabled = $localSource.Disabled
        $currentState.ByPassProxy = $localSource.ByPassProxy
        $currentState.SelfService = $localSource.SelfService
        $currentState.Priority = $localSource.Priority
        $currentState.Username = $localSource.user
        $currentState.Password = $localSource.password

        if (-not [string]::isNullOrEmpty($this.Source) -and $currentState.Source -ne $this.Source)
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:IncorrectSource'
                phrase = ('The ChocolateySource for source named ''{0}'' is expected to be ''{1}'' and was ''{2}''.' -f $this.Name, $this.Source, $currentState.Source)
            }
        }
        elseif (-not [string]::isNullOrEmpty($this.Source) )
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:SourceCompliant'
                phrase = ('The ChocolateySource for source named ''{0}'' is ''{1}'' as expected.' -f $this.Name, $currentState.Source)
            }
        }


        if (-not [string]::isNullOrEmpty($this.Disabled) -and $currentState.Disabled -ne $this.Disabled)
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:DisabledNotExpected'
                phrase = ('The Chocolatey Source named ''{0}'' is expected to have disabled as ''{1}'' and was ''{2}''.' -f $this.Name, $this.Disabled, $currentState.Disabled)
            }
        }
        elseif (-not [string]::isNullOrEmpty($this.Disabled))
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:DisabledCompliant'
                phrase = ('The Chocolatey Source named ''{0}'' has disabled set to ''{1}'' as expected.' -f $this.Name, $this.Disabled, $currentState.Disabled)
            }
        }

        if (-not [string]::isNullOrEmpty($this.ByPassProxy) -and $currentState.ByPassProxy -ne $this.ByPassProxy)
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:ByPassProxyNotExpected'
                phrase = ('The Chocolatey ByPassProxy for source name ''{0}'' is expected to be ''{1}'' and was ''{2}''.' -f $this.Name, $this.ByPassProxy, $currentState.ByPassProxy)
            }
        }
        elseif (-not [string]::isNullOrEmpty($this.ByPassProxy))
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:ByPassProxyCompliant'
                phrase = ('The Chocolatey ByPassProxy for source name ''{0}'' is ''{1}'' as expected.' -f $this.Name, $currentState.ByPassProxy)
            }
        }

        if (-not [string]::isNullOrEmpty($this.selfService) -and $currentState.selfService -ne $this.selfService)
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:SelfServiceNotExpected'
                phrase = ('The Chocolatey SelfService for source name ''{0}'' is expected to be ''{1}'' and was ''{2}''.' -f $this.Name, $this.SelfService, $currentState.SelfService)
            }
        }
        elseif (-not [string]::isNullOrEmpty($this.selfService))
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:SelfServiceCompliant'
                phrase = ('The Chocolatey SelfService for source name ''{0}'' is ''{1}'' as expected.' -f $this.Name, $currentState.SelfService)
            }
        }

        if (-not [string]::isNullOrEmpty($this.priority) -and $currentState.priority -ne $this.priority)
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:PriorityIncorrect'
                phrase = ('The priority for source name ''{0}'' is expected to be ''{1}'' and was ''{2}''.' -f $this.Name, $this.priority, $currentState.priority)
            }
        }
        elseif (-not [string]::isNullOrEmpty($this.priority))
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:PriorityCompliant'
                phrase = ('The priority for source name ''{0}'' is ''{1}'' as expected.' -f $this.Name, $currentState.priority)
            }
        }

        if (-not [string]::isNullOrEmpty($this.Username) -and $currentState.Username -ne $this.Username)
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:UsernameNotExpected'
                phrase = ('The ChocolateySource for source name ''{0}'' is expected to have the user ''{1}'' and was ''{2}''.' -f $this.Name, $this.Username, $currentState.Username)
            }
        }
        elseif (-not [string]::isNullOrEmpty($this.Username)) # Username compliant
        {
            $currentState.Reasons += [ChocolateyReason]@{
                code = 'ChocolateySource:ChocolateySource:UsernameCompliant'
                phrase = ('The ChocolateySource username for source name ''{0}'' is ''{1}'' as expected.' -f $this.Name, $currentState.Username)
            }
        }

        return $currentState
    }

    [bool] Test()
    {
        $currentState = $this.Get()

        if ($currentState.Reasons.code.Where({$_ -notmatch 'compliant$'}))
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
        $currentState = $this.Get()

        switch -Regex ($currentState.Reasons.Code)
        {
            'ShouldBeAbsent$'
            {
                Unregister-ChocolateySource -Name $this.Name -Force
            }

            'ShouldBePresent$|IncorrectSource$|ByPassProxyNotExpected$|PriorityIncorrect$|UsernameNotExpected$'
            {
                #Register-ChocolateySource -Name $this.Name -Force
                $registerChocolateySourceParams = @{
                    Name = $this.Name
                    Source = $this.Source
                    confirm = $false
                }

                if (-not [string]::isNullOrEmpty($this.Disabled))
                {
                    $registerChocolateySourceParams['Disabled'] = $this.Disabled
                }

                if (-not [string]::IsNullOrEmpty($this.ByPassProxy))
                {
                    $registerChocolateySourceParams['ByPassProxy'] = $this.ByPassProxy
                }

                if (-not [string]::IsNullOrEmpty($this.SelfService))
                {
                    $registerChocolateySourceParams['SelfService'] = $this.SelfService
                }

                if (-not [string]::IsNullOrEmpty($this.Priority))
                {
                    $registerChocolateySourceParams['Priority'] = $this.Priority
                }

                if (-not [string]::IsNullOrEmpty($this.Username))
                {
                    $registerChocolateySourceParams['KeyUser'] = $this.Username
                    throw 'NotImplementedYet'
                }

                if (-not [string]::isNullOrEmpty($this.Password))
                {
                    $registerChocolateySourceParams['Key'] = $this.Password
                }

                if (-not [string]::IsNullOrEmpty($this.Credential))
                {
                    $registerChocolateySourceParams['Credential'] = $this.Credential
                }

                Register-ChocolateySource @registerChocolateySourceParams
                return
            }

            'DisabledNotExpected$'
            {
                if ($currentState.Disabled)
                {
                    Enable-ChocolateySource -Name $this.Name
                }
                else
                {
                    Disable-ChocolateySource -Name $this.Name
                }
            }
        }
    }
}
