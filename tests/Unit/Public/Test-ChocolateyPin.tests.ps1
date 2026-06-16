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

Describe Test-ChocolateyPin {
    BeforeAll {
        Mock Get-ChocolateyCommand -MockWith {}
    }

    It 'Should return false when the package pin cannot be found' {
        Mock Get-ChocolateyPin -MockWith { $null } -ParameterFilter { $Name -eq 'git' }

        Test-ChocolateyPin -Name 'git' -Version '2.47.0' | Should -BeFalse
    }

    It 'Should return true when the pin version matches' {
        Mock Get-ChocolateyPin -MockWith {
            [PSCustomObject]@{
                Name    = 'git'
                Version = '2.47.0'
            }
        } -ParameterFilter { $Name -eq 'git' }

        Test-ChocolateyPin -Name 'git' -Version '2.47.0' | Should -BeTrue
    }

    It 'Should return false when the pin version does not match' {
        Mock Get-ChocolateyPin -MockWith {
            [PSCustomObject]@{
                Name    = 'git'
                Version = '2.46.0'
            }
        } -ParameterFilter { $Name -eq 'git' }

        Test-ChocolateyPin -Name 'git' -Version '2.47.0' | Should -BeFalse
    }
}