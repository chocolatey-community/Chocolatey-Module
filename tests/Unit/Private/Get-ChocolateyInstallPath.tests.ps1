BeforeAll {
    $script:moduleName = 'Chocolatey'
    $script:originalChocolateyInstall = [System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Process')

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    [System.Environment]::SetEnvironmentVariable('ChocolateyInstall', $script:originalChocolateyInstall, 'Process')
}

Describe Get-ChocolateyInstallPath {

    Context 'When process ChocolateyInstall points to a valid non-standard install root' {
        BeforeAll {
            $script:nonStandardInstallRoot = Join-Path -Path $TestDrive -ChildPath 'ChocolateyCustom'
            $script:nonStandardInstallBin = Join-Path -Path $script:nonStandardInstallRoot -ChildPath 'bin'
            $script:nonStandardChocoExe = Join-Path -Path $script:nonStandardInstallBin -ChildPath 'choco.exe'

            $null = New-Item -Path $script:nonStandardInstallBin -ItemType 'Directory' -Force
            $null = New-Item -Path $script:nonStandardChocoExe -ItemType 'File' -Force

            [System.Environment]::SetEnvironmentVariable('ChocolateyInstall', $script:nonStandardInstallRoot, 'Process')

            Mock Repair-ProcessEnvPath -MockWith {}
            Mock Get-ChocolateyCommand -MockWith {
                throw 'Get-ChocolateyCommand should not be called when ChocolateyInstall is already valid.'
            }

            $script:resolvedInstallPath = InModuleScope -ScriptBlock {
                Get-ChocolateyInstallPath
            }
        }

        It 'Should return the process ChocolateyInstall path unchanged' {
            $script:resolvedInstallPath | Should -Be $script:nonStandardInstallRoot
        }
    }

    Context 'When process ChocolateyInstall is invalid and machine ChocolateyInstall is valid' -Skip:((
        [string]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine')) -or
        -not (
            (Test-Path -Path (Join-Path -Path ([System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine')) -ChildPath 'choco.exe')) -or
            (Test-Path -Path (Join-Path -Path ([System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine')) -ChildPath 'bin\choco.exe'))
        )
    )) {
        BeforeAll {
            $script:machineChocolateyInstall = [System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine')
            [System.Environment]::SetEnvironmentVariable('ChocolateyInstall', 'C:\This\Path\Does\Not\Exist', 'Process')

            Mock Repair-ProcessEnvPath -MockWith {}
            Mock Get-ChocolateyCommand -MockWith {
                throw 'Get-ChocolateyCommand should not be called when Machine ChocolateyInstall is valid.'
            }

            $script:resolvedInstallPath = InModuleScope -ScriptBlock {
                Get-ChocolateyInstallPath
            }
        }

        It 'Should fall back to the machine ChocolateyInstall path' {
            $script:resolvedInstallPath | Should -Be $script:machineChocolateyInstall
        }
    }
}
