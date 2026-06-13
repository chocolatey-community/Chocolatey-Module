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

Describe Remove-ChocolateyLicense {
    BeforeAll {
        $script:installRoot = Join-Path -Path $TestDrive -ChildPath 'ChocolateyInstall'
        $script:licenseDirectory = Join-Path -Path $script:installRoot -ChildPath 'license'
        $script:licensePath = Join-Path -Path $script:licenseDirectory -ChildPath 'chocolatey.license.xml'

        $null = New-Item -Path $script:licenseDirectory -ItemType 'Directory' -Force
    }

    Context 'When the license file exists' {
        BeforeEach {
            [System.IO.File]::WriteAllText($script:licensePath, '<license><id>test-license</id></license>', [System.Text.UTF8Encoding]::new($false))
        }

        It 'Should remove the existing license file' {
            Remove-ChocolateyLicense -InstallDir $script:installRoot -RunNonElevated -Confirm:$false

            Test-Path -Path $script:licensePath | Should -BeFalse
        }
    }

    Context 'When the license file does not exist' {
        BeforeAll {
            Mock Write-Warning -MockWith {}
        }

        It 'Should write a warning and not throw' {
            Remove-ChocolateyLicense -InstallDir $script:installRoot -RunNonElevated -Confirm:$false

            Should -Invoke Write-Warning -Times 1
        }
    }
}
