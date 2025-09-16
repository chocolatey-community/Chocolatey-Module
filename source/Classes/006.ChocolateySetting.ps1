
<#
    .SYNOPSIS
        The `ChocolateySetting` DSC resource is used to set or unset Settings.

    .DESCRIPTION
        Chocolatey lets you set or unset general Settings.
        This resources lets you set or unset a Setting.

    .PARAMETER Ensure
        Indicate whether the Chocolatey Setting should be enabled or disabled on the system.

    .PARAMETER Name
        Name - the name of the Setting.

    .PARAMETER Value
        Value - the value of the Setting, if ensure is set to present.
        When Ensure is absent, the setting's value is cleared.

    .EXAMPLE
        Invoke-DscResource -ModuleName Chocolatey -Name ChocolateySetting -Method Get -Property @{
            Ensure  = 'Present'
            Name    = 'webRequestTimeoutSeconds'
            Value   = '30'
        }

        # This example shows how to set the Setting webRequestTimeoutSeconds using Invoke-DscResource.
#>
[DscResource()]
class ChocolateySetting : ChocolateyBase
{
    [DscProperty()]
    [Ensure] $Ensure = 'Present'

    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [string] $Value

    [DscProperty(NotConfigurable)]
    [ChocolateyReason[]] $Reasons

    [ChocolateySetting] Get()
    {
        $currentState = [ChocolateySetting]::new()
        $currentState.Name = $this.Name

        try
        {
            $setting = Get-ChocolateySetting -Name $this.Name
            $currentState.Value = $setting.Value
            if (-not [string]::IsNullOrEmpty($setting.Value))
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
            $Setting = $null
            $currentState.Ensure = 'Absent'
            $currentState.Reasons += @{
                code = 'ChocolateySetting:ChocolateySetting:ChocolateyError'
                phrase = ('Error: {0}.' -f $_)
            }
        }

        if ($null -eq $Setting)
        {
            $currentState.Reasons += @{
                code = 'ChocolateySetting:ChocolateySetting:SettingNotFound'
                phrase = ('The Setting ''{0}'' was not found.' -f $this.Name)
            }
        }
        else
        {
            if ($this.Ensure -eq 'Present' -and $currentState.Value -eq $this.Value)
            {
                $currentState.Ensure = 'Present'
                $currentState.Reasons += @{
                    code = 'ChocolateySetting:ChocolateySetting:SettingCompliant'
                    phrase = ('The Setting ''{0}'' is enabled with value ''{1}'' as expected.' -f $this.Name, $setting.Value)
                }
            }
            elseif (-not [string]::isNullOrEmpty($Setting.value) -and $this.Ensure -eq 'Absent')
            {
                $currentState.Ensure = 'Present'
                $currentState.Reasons += @{
                    code = 'ChocolateySetting:ChocolateySetting:SettingShouldBeUnset'
                    phrase = ('The Setting ''{0}'' is Present while it''s expected to be unset (Absent). Currently set to ''{1}''.' -f $this.Name, $Setting.Value)
                }
            }
            elseif ([string]::isNullOrEmpty($Setting.value) -and $this.Ensure -eq 'Absent')
            {
                $currentState.Ensure = 'Absent'
                $currentState.Reasons += @{
                    code = 'ChocolateySetting:ChocolateySetting:SettingUnsetCompliant'
                    phrase = ('The Setting ''{0}'' is unset as expected.' -f $this.Name)
                }
            }
            elseif ([string]::isNullOrEmpty($Setting.value) -and $this.Ensure -eq 'Present')
            {
                $currentState.Ensure = 'Absent'
                $currentState.Reasons += @{
                    code = 'ChocolateySetting:ChocolateySetting:SettingShouldBeSet'
                    phrase = ('The Setting ''{0}'' should be set.' -f $this.Name)
                }
            }
            elseif ([string]::isNullOrEmpty($Setting.value) -and [string]::isNullOrEmpty($this.value) -and $this.Ensure -eq 'Present')
            {
                $currentState.Ensure = 'Absent'
                $currentState.Reasons += @{
                    code = 'ChocolateySetting:ChocolateySetting:SettingIncorrectlySet'
                    phrase = ('The Setting ''{0}'' should be set.' -f $this.Name)
                }
            }
            elseif ($this.Ensure -eq 'Present' -and $setting.Value -ne $this.Value)
            {
                $currentState.Ensure = 'Present'
                $currentState.Reasons += @{
                    code = 'ChocolateySetting:ChocolateySetting:SettingNotCorrect'
                    phrase = ('The Setting ''{0}'' should be set to ''{1}'' but is ''{2}''.' -f $this.Name, $this.Value, $setting.Value)
                }
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

        switch ($currentState.Reasons.code)
        {
            'SettingShouldBeUnset'
            {
                # Unset the Setting
                Set-ChocolateySetting -Name $this.Name -Unset -Confirm:$false
            }

            'SettingShouldBeSet$|SettingNotCorrect$'
            {
                # Configure the Setting
                Set-ChocolateySetting -Name $this.Name -Value $this.Value -Confirm:$false
            }
        }
    }
}
