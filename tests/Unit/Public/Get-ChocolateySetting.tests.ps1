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

Describe Get-ChocolateySetting {
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
        $null = Set-Content -Path $script:configPath -Value '<chocolatey><config><add key="cacheLocation" value="C:\cache" /><add key="commandExecutionTimeoutSeconds" value="2700" /></config></chocolatey>'
    }

    It 'Should return all settings from the Chocolatey configuration' {
        $result = @(Get-ChocolateySetting)

        $result.Count | Should -Be 2
        $result[0].PSTypeNames[0] | Should -Be 'Chocolatey.Setting'
        $result[0].key | Should -Be 'cacheLocation'
        $result[0].value | Should -Be 'C:\cache'
    }

    It 'Should return the requested setting by name' {
        $result = @(Get-ChocolateySetting -Name 'cacheLocation')

        $result.Count | Should -Be 1
        $result[0].key | Should -Be 'cacheLocation'
        $result[0].value | Should -Be 'C:\cache'
    }
}