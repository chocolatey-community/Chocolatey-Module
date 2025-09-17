
<#PSScriptInfo

.VERSION 0.0.2

.GUID 142e2049-194b-4d66-9892-2b3141a92027

.AUTHOR Gael Colas

.COMPANYNAME SynEdgy Limited

.COPYRIGHT (c) 2021 Gael Colas. All rights reserved.

.TAGS

.LICENSEURI https://github.com/chocolatey-community/Chocolatey/blob/master/LICENSE

.PROJECTURI https://github.com/chocolatey-community/Chocolatey/

.ICONURI https://blog.chocolatey.org/assets/images/chocolatey-icon.png

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Updated author, copyright notice, and URLs.

.PRIVATEDATA

#>

<#

.DESCRIPTION
 This is an unofficial module with DSC resource to Install and configure Chocolatey.

#>

param ()


configuration Example {
    Import-DscResource -ModuleName Chocolatey

    Node localhost {
        ChocolateySoftware ChocoInst {
            Ensure = 'Present'
        }

        ChocolateySource ChocolateyOrg {
            DependsOn = '[ChocolateySoftware]ChocoInst'
            Ensure    = 'Present'
            Name      = 'Chocolatey'
            Source    = 'https://chocolatey.org/api/v2'
            Priority  = 0
            Disabled  = $false
        }

        ChocolateyFeature NoVIrusCheck {
            Ensure = 'Absent'
            Name   = 'viruscheck'
        }

        ChocolateyPackage Putty {
            DependsOn          = '[ChocolateySoftware]ChocoInst'
            Ensure            = 'Present'
            Name              = 'Putty'
            Version           = 'Latest'
            ChocolateyOptions = @(
            @{
                source = 'https://chocolatey.org/api/v2/'
            }
        )
        }
    }
}
