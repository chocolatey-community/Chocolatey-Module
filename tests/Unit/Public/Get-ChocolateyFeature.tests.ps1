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

Describe Get-ChocolateyFeature {
    BeforeAll {
        Mock Get-ChocolateyCommand -MockWith { [PSCustomObject]@{ Path = $script:fakeChocoPath } }
    }

    BeforeEach {
        $script:installRoot = Join-Path -Path $TestDrive -ChildPath 'choco'
        $script:fakeChocoPath = Join-Path -Path $script:installRoot -ChildPath 'bin\choco.exe'
        $script:configPath = Join-Path -Path $script:installRoot -ChildPath 'config\chocolatey.config'

        $null = New-Item -Path (Split-Path -Path $script:fakeChocoPath -Parent) -ItemType Directory -Force
        $null = New-Item -Path (Split-Path -Path $script:configPath -Parent) -ItemType Directory -Force
        $null = Set-Content -Path $script:fakeChocoPath -Value ''
        $null = Set-Content -Path $script:configPath -Value '<chocolatey><features><feature name="checksumFiles" enabled="true" /><feature name="showNonElevatedWarnings" enabled="false" /></features></chocolatey>'
    }

    It 'Should return all features from the Chocolatey configuration' {
        $result = @(Get-ChocolateyFeature)

        $result.Count | Should -Be 2
        $result[0].PSTypeNames[0] | Should -Be 'Chocolatey.Feature'
        $result[0].name | Should -Be 'checksumFiles'
        $result[0].enabled | Should -Be 'true'
    }

    It 'Should return the requested feature by name' {
        $result = @(Get-ChocolateyFeature -Name 'shownonelevatedwarnings')

        $result.Count | Should -Be 1
        $result[0].name | Should -Be 'showNonElevatedWarnings'
        $result[0].enabled | Should -Be 'false'
    }
}