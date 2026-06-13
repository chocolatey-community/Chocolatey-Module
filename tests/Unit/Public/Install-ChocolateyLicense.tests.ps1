BeforeAll {
    $script:moduleName = 'Chocolatey'

    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

Describe Install-ChocolateyLicense {
    BeforeAll {
        $script:licenseXmlContent = '<license><id>test-license</id></license>'
        $script:replacementLicenseXmlContent = '<license><id>replacement-license</id></license>'
        $script:installRoot = Join-Path -Path $TestDrive -ChildPath 'ChocolateyInstall'
        $script:licenseSourcePath = Join-Path -Path $TestDrive -ChildPath 'chocolatey.license.xml'

        $null = New-Item -Path $script:installRoot -ItemType 'Directory' -Force
        [System.IO.File]::WriteAllText($script:licenseSourcePath, $script:licenseXmlContent, [System.Text.UTF8Encoding]::new($false))
    }

    Context 'When installing from a file path' {
        It 'Should write the license file to the standard Chocolatey license path' {
            $result = Install-ChocolateyLicense -Path $script:licenseSourcePath -InstallDir $script:installRoot -RunNonElevated -Confirm:$false
            $expectedPath = Join-Path -Path $script:installRoot -ChildPath 'license\chocolatey.license.xml'

            $result.FullName | Should -Be $expectedPath
            (Get-Content -Path $expectedPath -Raw) | Should -Be $script:licenseXmlContent
        }
    }

    Context 'When a license file already exists' {
        It 'Should overwrite the existing license file content' {
            $expectedPath = Join-Path -Path $script:installRoot -ChildPath 'license\chocolatey.license.xml'
            $null = New-Item -Path (Split-Path -Path $expectedPath -Parent) -ItemType 'Directory' -Force
            [System.IO.File]::WriteAllText($expectedPath, '<license><id>old-license</id></license>', [System.Text.UTF8Encoding]::new($false))

            $result = Install-ChocolateyLicense -Content $script:replacementLicenseXmlContent -InstallDir $script:installRoot -RunNonElevated -Confirm:$false

            $result.FullName | Should -Be $expectedPath
            (Get-Content -Path $expectedPath -Raw) | Should -Be $script:replacementLicenseXmlContent
        }
    }

    Context 'When installing from raw XML content' {
        It 'Should create the license file from the provided content' {
            $result = Install-ChocolateyLicense -Content $script:licenseXmlContent -InstallDir $script:installRoot -RunNonElevated -Confirm:$false
            $expectedPath = Join-Path -Path $script:installRoot -ChildPath 'license\chocolatey.license.xml'

            $result.FullName | Should -Be $expectedPath
            (Get-Content -Path $expectedPath -Raw) | Should -Be $script:licenseXmlContent
        }
    }
}
