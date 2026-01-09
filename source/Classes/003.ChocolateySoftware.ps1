using namespace System.Management.Automation

<#
    .SYNOPSIS
        The `ChocolateySoftware` DSC resource is used to install or remove choco.exe.
    .DESCRIPTION
        Install Chocolatey Software either from a fixed URL where the chocolatey nupkg is stored,
        or from the url of a NuGet feed containing the Chocolatey Package.
        A version can be specified to lookup the Package feed for a specific version, and install it.
        A proxy URL and credential can be specified to fetch the Chocolatey package, or the proxy configuration
        can be ignored.
    .PARAMETER Ensure
        Indicate whether the Chocolatey Software should be installed or not on the system.
    .PARAMETER Version
        Version to install if you want to be specific, this is the way to Install a pre-release version, as when not specified,
        the latest non-prerelease version is looked up from the feed defined in PackageFeedUrl.
    .PARAMETER ChocolateyPackageUrl
        Exact URL of the chocolatey package. This can be an HTTP server, a network or local path.
        This must be the .nupkg package as downloadable from here: https://chocolatey.org/packages/chocolatey
    .PARAMETER PackageFeedUrl
        Url of the NuGet Feed API to use for looking up the latest version of Chocolatey (available on that feed).
        This is also used when searching for a specific version, doing a lookup via an Odata filter.
    .PARAMETER ChocoTempDir
        The temporary folder to extract the Chocolatey Binaries during install. This does not set the Chocolatey Cache dir.
    .PARAMETER IgnoreProxy
        Ensure the proxy is bypassed when downloading the Chocolatey Package from the URL.
    .PARAMETER ProxyCredential
        Credential to authenticate to the proxy, if not specified but the ProxyLocation is set, an attempt
        to use the Cached credential will be made.
    .PARAMETER ProxyLocation
        Proxy url to use when downloading the Chocolatey Package for installation.
    .EXAMPLE
        Invoke-DscResource -ModuleName Chocolatey -Name ChocolateySoftware -Method Get -Property @{
            Ensure         = 'Present'
        }

        # This example shows how to call the resource using Invoke-DscResource.
#>
[DscResource()]
class ChocolateySoftware : ChocolateyBase
{
    [DscProperty(Key)]
    [Ensure] $Ensure = 'Present'

    [DscProperty()]
    [String] $InstallationDirectory

    [DscProperty()] #WriteOnly
    [String] $ChocolateyPackageUrl

    [DscProperty()] #WriteOnly
    [String] $PackageFeedUrl

    [DscProperty()] #WriteOnly
    [string] $Version

    [DscProperty()] #WriteOnly
    [String] $ChocoTempDir

    [DscProperty()] #WriteOnly
    [string] $ProxyLocation

    [DscProperty()] #WriteOnly
    [bool]   $IgnoreProxy

    [DscProperty()] #WriteOnly
    [PSCredential] $ProxyCredential

    [DscProperty(NotConfigurable)]
    [ChocolateyReason[]] $Reasons

    [ChocolateySoftware] Get()
    {
        $currentState = [ChocolateySoftware]::new()
        $chocoExe = @(Get-Command -Name 'choco.exe' -ErrorAction 'Ignore')[0]

        if ($null -eq $chocoExe)
        {
            Write-Verbose -Message ('Path: {0}' -f $ENV:Path)
            $currentState.Ensure = 'Absent'
        }
        else
        {
            $currentState.Ensure = 'Present'
            $chocoBin = Split-Path -Path $chocoExe.Path -Parent
            $chocoInstallPath = Split-Path -Path $chocoBin -Parent
            $currentState.InstallationDirectory = $chocoInstallPath
        }

        if ($this.Ensure -eq 'Present' -and $currentState.Ensure -eq 'Absent')
        {
            Write-Debug -Message 'Choco not found while it should be installed.'
            $currentState.Reasons += @{
                code = 'ChocolateySoftware:ChocolateySoftware:ChocoShouldBeInstalled'
                phrase = 'The Chocolatey software is not installed but is expected to be.'
            }
        }
        elseif ($this.Ensure -eq 'Absent' -and $currentState.Ensure -eq $this.Ensure)
        {
            Write-Debug -Message 'Choco not found as expected.'
            $currentState.Reasons += @{
                code = 'ChocolateySoftware:ChocolateySoftware:Compliant'
                phrase = 'Chocolatey software is absent as expected.'
            }
        }
        elseif ($this.Ensure -eq 'Absent' -and $currentState.Ensure -eq 'Present')
        {
            Write-Debug -Message 'Choco found while it should be ''Absent''.'
            $currentState.Reasons += @{
                code = 'ChocolateySoftware:ChocolateySoftware:ChocoShouldBeRemoved'
                phrase = 'Chocolatey software is unexpectedly present and should be uninstalled.'
            }
        }
        else
        {
            Write-Verbose -Message 'Choco.exe is found as expected, let''s retrieve its Install Directory.'
            # Present as it should
            if ([string]::IsNullOrEmpty($this.InstallationDirectory) -or $this.InstallationDirectory -eq $currentState.InstallationDirectory)
            {
                $currentState.Reasons += @{
                    code = 'ChocolateySoftware:ChocolateySoftware:Compliant'
                    phrase = ('Choco.exe is correctly installed at ''{0}''.' -f $currentState.InstallationDirectory)
                }
            }
            else
            {
                $currentState.Reasons += @{
                    code = 'ChocolateySoftware:ChocolateySoftware:ChocoInstalledInWrongDirectory'
                    phrase = ('Choco.exe is **incorrectly** installed at ''{0}''. Unable to remediate.' -f $currentState.InstallationDirectory)
                }
            }
        }

        return $currentState
    }

    [bool] Test()
    {
        $currentState = $this.Get()

        if ($currentState.Reasons.Code.Where{$_ -notmatch 'Compliant$'})
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

        if ($currentState.Reasons.code.Where{$_ -match 'ChocoShouldBeInstalled$'})
        {
            $properties = @(
                'ChocolateyPackageUrl'
                'PackageFeedUrl'
                'Version'
                'ChocoTempDir'
                'ProxyLocation'
                'InstallationDirectory'
                'IgnoreProxy'
                'InstallationDirectory'
                'ProxyCredential'
            )

            $installChocoSoftwareParam = @{}

            $properties.Where{-not [string]::IsNullOrEmpty($this.($_))}.Foreach{
                $installChocoSoftwareParam[$_] = $this.($_)
            }

            Write-Debug -Message ('Installing Chocolatey with parameters: {0}' -f ($installChocoSoftwareParam | ConvertTo-Json -Depth 2))
            Install-ChocolateySoftware @installChocoSoftwareParam
        }
        elseif ($currentState.Reasons.code.Where{$_ -match 'ChocoShouldBeRemoved$'})
        {
            if ( -not [string]::IsNullOrEmpty($this.InstallationDirectory))
            {
                Write-Debug -Message ('Uninstall-Chocolatey -InstallDir ''{0}''' -f $this.InstallationDirectory)
                $null = Uninstall-Chocolatey -InstallDir $this.InstallationDirectory -Confirm:$false
            }
            else
            {
                $null = Uninstall-Chocolatey -Confirm:$false
            }
        }
        else
        {
            Write-Verbose -Message 'No ChocolateySoftware action taken.'
        }
    }
}
