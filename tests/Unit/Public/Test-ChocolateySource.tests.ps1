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

Describe Test-ChocolateySource {
    BeforeAll {
        Mock Get-ChocolateyCommand -MockWith {}
    }

    It 'Should return false when the source cannot be found' {
        Mock Get-ChocolateySource -MockWith { $null } -ParameterFilter { $Name -eq 'Internal' }

        Test-ChocolateySource -Name 'Internal' | Should -BeFalse
    }

    It 'Should return no differences when the source matches the provided properties' {
        Mock Get-ChocolateySource -MockWith {
            [PSCustomObject]@{
                Name        = 'Internal'
                Source      = 'https://proget/nuget/choco'
                disabled    = $false
                bypassProxy = $true
                selfService = $false
                priority    = 10
                username    = ''
                password    = ''
            }
        } -ParameterFilter { $Name -eq 'Internal' }

        $result = Test-ChocolateySource -Name 'Internal' -Source 'https://proget/nuget/choco' -BypassProxy -Priority 10

        $result | Should -BeNullOrEmpty
    }

    It 'Should return differences when the source does not match the provided properties' {
        Mock Get-ChocolateySource -MockWith {
            [PSCustomObject]@{
                Name        = 'Internal'
                Source      = 'https://proget/nuget/choco'
                disabled    = $false
                bypassProxy = $true
                selfService = $false
                priority    = 5
                username    = ''
                password    = ''
            }
        } -ParameterFilter { $Name -eq 'Internal' }

        $result = @(Test-ChocolateySource -Name 'Internal' -Source 'https://proget/nuget/choco' -BypassProxy -Priority 10)

        $result.Count | Should -Be 2
        @($result | Where-Object -FilterScript { $_.SideIndicator -eq '=>' }).Count | Should -Be 1
        @($result | Where-Object -FilterScript { $_.SideIndicator -eq '<=' }).Count | Should -Be 1
    }
}