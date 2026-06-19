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

Describe Test-ChocolateySetting {
    BeforeAll {
        Mock Get-ChocolateyCommand -MockWith {}
    }

    It 'Should return false when the setting cannot be found' {
        Mock Get-ChocolateySetting -MockWith { $null } -ParameterFilter { $Name -eq 'cacheLocation' }

        Test-ChocolateySetting -Name 'cacheLocation' -Value 'C:\cache' | Should -BeFalse
    }

    It 'Should return true when the setting value matches' {
        Mock Get-ChocolateySetting -MockWith {
            [PSCustomObject]@{
                Name  = 'cacheLocation'
                Value = ('{0}\ChocolateyCache' -f $env:SystemDrive)
            }
        } -ParameterFilter { $Name -eq 'cacheLocation' }

        Test-ChocolateySetting -Name 'cacheLocation' -Value '$env:SystemDrive\ChocolateyCache\' | Should -BeTrue
    }

    It 'Should return true when Unset is specified and the value is empty' {
        Mock Get-ChocolateySetting -MockWith {
            [PSCustomObject]@{
                Name  = 'cacheLocation'
                Value = ''
            }
        } -ParameterFilter { $Name -eq 'cacheLocation' }

        Test-ChocolateySetting -Name 'cacheLocation' -Unset | Should -BeTrue
    }

    It 'Should return false when the setting value does not match' {
        Mock Get-ChocolateySetting -MockWith {
            [PSCustomObject]@{
                Name  = 'cacheLocation'
                Value = 'C:\different'
            }
        } -ParameterFilter { $Name -eq 'cacheLocation' }

        Test-ChocolateySetting -Name 'cacheLocation' -Value 'C:\cache' | Should -BeFalse
    }
}