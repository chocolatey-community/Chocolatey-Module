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

Describe Get-ChocolateySource {
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
        $null = Set-Content -Path $script:configPath -Value '<chocolatey><sources><source id="Chocolatey" value="https://community.chocolatey.org/api/v2/" disabled="false" bypassProxy="true" selfService="false" priority="0" user="" password="" /><source id="Internal" value="https://proget/nuget/choco" disabled="true" bypassProxy="false" selfService="true" priority="10" user="svc" password="secret" /></sources></chocolatey>'
    }

    It 'Should return all configured sources' {
        $result = @(Get-ChocolateySource)

        $result.Count | Should -Be 2
        $result[0].PSTypeNames[0] | Should -Be 'Chocolatey.Source'
        $result[0].Name | Should -Be 'Chocolatey'
        $result[0].Source | Should -Be 'https://community.chocolatey.org/api/v2/'
        $result[0].disabled | Should -BeFalse
        $result[0].bypassProxy | Should -BeTrue
    }

    It 'Should return the requested source by name' {
        $result = @(Get-ChocolateySource -Name 'internal')

        $result.Count | Should -Be 1
        $result[0].Name | Should -Be 'Internal'
        $result[0].disabled | Should -BeTrue
        $result[0].selfService | Should -BeTrue
        $result[0].priority | Should -Be 10
    }
}