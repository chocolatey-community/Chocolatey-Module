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

Describe Test-ChocolateyLicenseInstalled {
    Context 'When the license file exists' {
        BeforeAll {
            Mock Test-Path -MockWith { $true }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Test-ChocolateyLicenseInstalled -InstallDir 'C:\ProgramData\chocolatey'
            } | Should -BeTrue
        }
    }

    Context 'When the license file does not exist' {
        BeforeAll {
            Mock Test-Path -MockWith { $false }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Test-ChocolateyLicenseInstalled -InstallDir 'C:\ProgramData\chocolatey'
            } | Should -BeFalse
        }
    }
}
