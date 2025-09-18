
<#
    .SYNOPSIS
        The `ChocolateyPin` DSC resource is used to set or remove Pins.

    .DESCRIPTION
        Chocolatey lets you pin package versions so they don't get updated.
        This resources lets you set or remove a Pin.

    .PARAMETER Ensure
        Indicate whether the Chocolatey Pin should be enabled or disabled for this package.

    .PARAMETER Version
        Version of the Package to pin.

    .EXAMPLE
        Invoke-DscResource -ModuleName Chocolatey -Name ChocolateyPin -Method Get -Property @{
            Ensure  = 'Present'
            Name    = 'putty.portable'
            Version   = '0.78'
        }

        # This example shows how to set the Pin webRequestTimeoutSeconds using Invoke-DscResource.
#>
[DscResource()]
class ChocolateyPin : ChocolateyBase
{
    [DscProperty()]
    [Ensure] $Ensure = 'Present'

    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [string] $Version

    [DscProperty(NotConfigurable)]
    [ChocolateyReason[]] $Reasons

    [ChocolateyPin] Get()
    {
        $currentState = [ChocolateyPin]::new()
        $currentState.Name = $this.Name
        if (-not (Test-ChocolateyInstall))
        {
            Write-Debug -Message 'Chocolatey is not installed.'
            $currentState.Ensure = 'Absent'

            $currentState.Reasons += @{
                code = 'ChocolateyPin:ChocolateyPin:ChocolateyNotInstalled'
                phrase = 'The Chocolatey software is not installed. We cannot check if a pin is present.'
            }

            return $currentState
        }

        try
        {
            $pin = Get-ChocolateyPin -Name $this.Name
            $currentState.Version = $pin.Version
            if (-not [string]::IsNullOrEmpty($pin.Name))
            {
                $currentState.Ensure = 'Present'
            }
            else
            {
                $currentState.Ensure = 'Absent'
            }
        }
        catch
        {
            Write-Verbose -Message ('Exception Caught:' -f $_)
            $pin = $null
            $currentState.Ensure = 'Absent'
            $currentState.Reasons += @{
                code = 'ChocolateyPin:ChocolateyPin:ChocolateyError'
                phrase = ('Error: {0}.' -f $_)
            }
        }

        if ($null -eq $pin)
        {
            Write-Debug -Message ('No pin found for package {0}' -f $this.Name)

            if ($this.Ensure -eq 'Absent')
            {
                $currentState.Reasons += @{
                    code = 'ChocolateyPin:ChocolateyPin:PinAbsentCompliant'
                    phrase = ('The package ''{0}'' is not pinned, as expected.' -f $this.Name)
                }
            }
            else # expected Present
            {
                # Sould be set
                $currentState.Reasons += @{
                    code = 'ChocolateyPin:ChocolateyPin:PinShouldBeSet'
                    phrase = ('The package ''{0}'' wasn''t pinned but should be set. (To version ''{1}'').' -f $this.Name, $this.Version)
                }
            }
        }
        elseif ($this.Ensure -eq 'Absent')
        {
            Write-Debug -Message 'Present but expected Absent. Should be removed.'
            $currentState.Reasons += @{
                code = 'ChocolateyPin:ChocolateyPin:PinShouldBeRemoved'
                phrase = ('The package ''{0}'' is pinned to ''{1}'' but it souldn''t.' -f $this.Name, $pin.Version)
            }
        }
        elseif ($this.Ensure -eq 'Present' -and $pin.Version -ne $this.Version)
        {
            Write-Debug -Message ('The package is pinned, that''s expected, but version differs (Expected: {0}, Current: {1}).' -f $currentState.Version, $this.Version)
            if ([string]::IsNullOrEmpty($this.Version))  # Assumes $this.Version is NOT set (Package must be pinned, but to ANY version)
            {
                # Pin version not expected, so $pin.Version is whatever was pinned at the time
                $currentState.Reasons += @{
                    code = 'ChocolateyPin:ChocolateyPin:PinCompliant'
                    phrase = ('The package ''{0}'' is pinned to version ''{1}''. No desired version specified for the pin.' -f $this.Name, $pin.Version)
                }
            }
            else
            {
                # Pin version mismatch
                $currentState.Reasons += @{
                    code = 'ChocolateyPin:ChocolateyPin:PinVersionMismatch'
                    phrase = ('The package ''{0}'' should be pinned to ''{1}'' but is set to ''{2}''.' -f $this.Name, $this.Version, $pin.Version)
                }
            }
        }
        elseif ($this.Ensure -eq 'Present' -and $pin.Version -eq $this.Version)
        {
            Write-Debug -Message 'The Pin is set to the desired version (not null)'
            $currentState.Reasons += @{
                code = 'ChocolateyPin:ChocolateyPin:PinCompliant'
                phrase = ('The Pin ''{0}'' is enabled with value ''{1}'' as expected.' -f $this.Name, $pin.Version)
            }
        }

        return $currentState
    }

    [bool] Test()
    {
        $currentState = $this.Get()
        $currentState.Reasons.code.Where{
            $_ -notmatch 'Compliant$'
        }

        if ($currentState.count -eq 0)
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    [void] Set()
    {
        $currentState = $this.Get()
        if (-not (Test-ChocolateyInstall))
        {
            Write-Debug -Message 'Chocolatey is not installed.'
            throw $currentState.Reasons.Where{$_.Code -match 'ChocolateyNotInstalled$'}.phrase
        }

        switch -Regex ($currentState.Reasons.code)
        {
            'PinShouldBeRemoved'
            {
                Write-Verbose -Message ('Removing the pin on package ''{0}''.' -f $this.Name)
                Remove-ChocolateyPin -Name $this.Name -Confirm:$false
            }

            'PinVersionMismatch$|PinShouldBeSet$'
            {
                Write-Verbose -Message ('Setting pin on package ''{0}'' asking for version ''{0}''.' -f $this.Name, $this.Version)
                Add-ChocolateyPin -Name $this.Name -Version $this.Version -Confirm:$false
            }
        }
    }
}
