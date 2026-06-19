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

Describe Test-ChocolateyFeature {
    BeforeAll {
        Mock Get-ChocolateyCommand -MockWith {}
    }

    It 'Should return false when the feature cannot be found' {
        Mock Get-ChocolateyFeature -MockWith { $null } -ParameterFilter { $Name -eq 'checksumFiles' }

        Test-ChocolateyFeature -Name 'checksumFiles' | Should -BeFalse
    }

    It 'Should return true when the feature is enabled as expected' {
        Mock Get-ChocolateyFeature -MockWith {
            [PSCustomObject]@{
                Name    = 'checksumFiles'
                Enabled = $true
            }
        } -ParameterFilter { $Name -eq 'checksumFiles' }

        Test-ChocolateyFeature -Name 'checksumFiles' | Should -BeTrue
    }

    It 'Should return true when the feature is disabled as expected' {
        Mock Get-ChocolateyFeature -MockWith {
            [PSCustomObject]@{
                Name    = 'checksumFiles'
                Enabled = $false
            }
        } -ParameterFilter { $Name -eq 'checksumFiles' }

        Test-ChocolateyFeature -Name 'checksumFiles' -Disabled | Should -BeTrue
    }

    It 'Should return false when the feature state does not match' {
        Mock Get-ChocolateyFeature -MockWith {
            [PSCustomObject]@{
                Name    = 'checksumFiles'
                Enabled = $false
            }
        } -ParameterFilter { $Name -eq 'checksumFiles' }

        Test-ChocolateyFeature -Name 'checksumFiles' | Should -BeFalse
    }
}