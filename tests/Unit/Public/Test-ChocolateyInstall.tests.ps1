BeforeAll {
    $script:moduleName = 'Chocolatey'
    $script:repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..')).Path
    $script:builtManifest = Get-ChildItem -Path (Join-Path -Path $script:repoRoot -ChildPath 'output\module\chocolatey') -Filter 'chocolatey.psd1' -Recurse -ErrorAction 'SilentlyContinue' |
        Sort-Object -Property FullName -Descending |
        Select-Object -First 1 -ExpandProperty FullName

    if (-not $script:builtManifest)
    {
        & (Join-Path -Path $script:repoRoot -ChildPath 'build.ps1') -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null

        $script:builtManifest = Get-ChildItem -Path (Join-Path -Path $script:repoRoot -ChildPath 'output\module\chocolatey') -Filter 'chocolatey.psd1' -Recurse -ErrorAction 'Stop' |
            Sort-Object -Property FullName -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }

    Import-Module -Name $script:builtManifest -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

Describe Test-ChocolateyInstall {
    BeforeAll {
        Mock Repair-ProcessEnvPath -MockWith {}
    }

    It 'Should return true when choco.exe is available on PATH' {
        Mock Get-Command -MockWith {
            param ($Name)

            if ($Name -eq 'choco.exe')
            {
                [PSCustomObject]@{
                    Path    = 'C:\ProgramData\chocolatey\bin\choco.exe'
                    Version = '2.4.3'
                }
            }
        }

        Test-ChocolateyInstall | Should -BeTrue
        { Assert-MockCalled Repair-ProcessEnvPath } | Should -Not -Throw
    }

    It 'Should return true when choco.exe is found under the specified install directory' {
        $installDir = Join-Path -Path $TestDrive -ChildPath 'Chocolatey'
        $chocoPath = Join-Path -Path $installDir -ChildPath 'choco.exe'

        $null = New-Item -Path $installDir -ItemType Directory -Force
        $null = Set-Content -Path $chocoPath -Value ''

        Mock Get-Command -MockWith {
            param ($Name)

            if ($Name -eq $chocoPath -or $Name -eq 'choco.exe')
            {
                [PSCustomObject]@{
                    Path    = $chocoPath
                    Version = '2.4.3'
                }
            }
        }

        Test-ChocolateyInstall -InstallDir $installDir | Should -BeTrue
    }

    It 'Should return false when choco.exe cannot be found' {
        Mock Get-Command -MockWith { $null }

        Test-ChocolateyInstall | Should -BeFalse
    }
}