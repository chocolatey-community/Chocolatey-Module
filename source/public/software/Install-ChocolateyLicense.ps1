<#
.SYNOPSIS
    Installs a Chocolatey license file.

.DESCRIPTION
    Installs a Chocolatey license file into the standard Chocolatey license
    folder from either a source file path or raw XML content.

.PARAMETER Path
    Path to a Chocolatey license XML file.

.PARAMETER Content
    Raw Chocolatey license XML content.

.PARAMETER InstallDir
    Path where Chocolatey is installed. Defaults to the resolved
    ChocolateyInstall path.

.PARAMETER RunNonElevated
    Throws if the process is not running elevated. use -RunNonElevated if you
    really want to run even if the current shell is not elevated.

.EXAMPLE
    Install-ChocolateyLicense -Path C:\secure\chocolatey.license.xml

.EXAMPLE
    Install-ChocolateyLicense -Content $licenseXml
#>
function Install-ChocolateyLicense
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Path', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'Content', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Content,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallDir = (Get-ChocolateyInstallPath -ErrorAction 'Stop'),

        [Parameter(DontShow)]
        [switch]
        $RunNonElevated = $(Assert-ChocolateyIsElevated)
    )

    process
    {
        if (-not (Test-Path -Path $InstallDir -PathType 'Container'))
        {
            throw "Chocolatey install directory '$InstallDir' does not exist."
        }

        $licenseContent = $Content

        if ($PSCmdlet.ParameterSetName -eq 'Path')
        {
            $resolvedLicensePath = (Resolve-Path -Path $Path -ErrorAction 'Stop').Path
            $licenseContent = Get-Content -Path $resolvedLicensePath -Raw -ErrorAction 'Stop'
        }

        try
        {
            $licenseXml = [xml] $licenseContent
        }
        catch
        {
            throw "License content is not valid XML. $($_.Exception.Message)"
        }

        if ($null -eq $licenseXml.DocumentElement)
        {
            throw 'License content is not valid XML.'
        }

        $licenseDirectory = Join-Path -Path $InstallDir -ChildPath 'license'
        $licensePath = Join-Path -Path $licenseDirectory -ChildPath 'chocolatey.license.xml'

        if ($PSCmdlet.ShouldProcess($Env:COMPUTERNAME, ("Install Chocolatey license to '{0}'" -f $licensePath)))
        {
            if (-not (Test-Path -Path $licenseDirectory -PathType 'Container'))
            {
                $null = New-Item -Path $licenseDirectory -ItemType 'Directory' -Force
            }

            [System.IO.File]::WriteAllText($licensePath, $licenseContent, [System.Text.UTF8Encoding]::new($false))

            Get-Item -Path $licensePath -ErrorAction 'Stop'
        }
    }
}
