
<#
.SYNOPSIS
    Compare the Chocolatey Package installed with a version or the latest available version.

.DESCRIPTION
    Search and compare the Installed PackageName locally, and compare the provided property.
    The command return an object with the detailed properties, and a comparison between the installed version
    and the expected version.

.PARAMETER Name
    Exact name of the package to be testing against.

.PARAMETER Version
    Version expected of the package, or latest to compare against the latest version from a source.

.PARAMETER Source
    Source to compare the latest version against. It will retrieve the

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.EXAMPLE
    Compare-ChocolateyPackage -Name Chocolatey -Source https://chocolatey.org/api/v2

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsList
#>
function Compare-ChocolateyPackage
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        # Version to compare the installed package with.
        # Specifying the version means we won't check against a source feed.
        $Version,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        # Chocolatey source to check for latest version available and compare
        # with installed version.
        $Source,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential
    )

    begin
    {
        # Validate choco is installed or die. Will load the exe path from module cache.
        # Should you want to specify an installation directory,
        # you have to call Get-ChocolateyCommand -InstallDir <path> -Force to set the cache.
        $chocoCmd = Get-ChocolateyCommand
    }

    process
    {
        #if version latest verify against sources
        $InstalledPackages = @(Get-ChocolateyPackage -Name $Name -Exact)

        $findPackageParams = $PSBoundParameters
        $null = $findPackageParams.Remove('version')

        if ($Version -eq 'latest')
        {
            $comparedObject = Find-ChocolateyPackage @findPackageParams -Exact
            if ($null -eq $comparedObject)
            {
                throw "Latest version of Package $name not found. Verify that the sources are reachable and package exists."
            }
        }
        else
        {
            $comparedObject = @{
                Name = $Name
            }

            if (-not [string]::IsNullOrEmpty($Version))
            {
                $comparedObject['Version'] = $Version
            }
        }

        if ($InstalledPackages.count -gt 0)
        {
            Write-Verbose -Message ('Processing {0} Packages.' -f $InstalledPackages.count)
            $InstalledPackages.ForEach{
                if ([string]::IsNullOrEmpty($Version))
                {
                    $sideIndicator = '='
                }
                else
                {
                    $SideIndicator = Compare-SemVerVersion -DifferenceVersion $comparedObject.Version -ReferenceVersion $_.Version
                }

                [PSCustomObject]@{
                    Name                = $Name
                    InstalledVersion    = $_.Version
                    SideIndicator       = $SideIndicator # if = or > it means the package is installed and meets the version requirement
                    ExpectedVersion     = $comparedObject.Version
                }
            }
        }
        else
        {
            Write-Verbose -Message ('Package {0} is not installed.' -f $Name)
            [PSCustomObject]@{
                Name                = $Name
                InstalledVersion    = ''
                SideIndicator       = '!' # ! means the package is not installed
                ExpectedVersion     = $comparedObject.Version
            }
        }
    }
}
