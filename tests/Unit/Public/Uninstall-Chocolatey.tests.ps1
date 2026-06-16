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

Describe Uninstall-Chocolatey {
    It 'Should warn and return nothing when the install directory does not contain choco.exe' {
        $installDir = Join-Path -Path $TestDrive -ChildPath 'Chocolatey'
        $null = New-Item -Path $installDir -ItemType Directory -Force

        $warningOutput = Uninstall-Chocolatey -InstallDir $installDir -RunNonElevated 3>&1

        @($warningOutput | Where-Object -FilterScript { $_.Message -eq 'Chocolatey Installation Folder Not found.' }).Count | Should -Be 1
    }

    It 'Should warn and return nothing when no install directory or choco command can be found' {
        Mock Get-ChocolateyCommand -MockWith { $null }

        $warningOutput = Uninstall-Chocolatey -InstallDir '' -RunNonElevated 3>&1

        @($warningOutput | Where-Object -FilterScript { $_.Message -eq 'Could not find Chocolatey Software Install Folder.' }).Count | Should -Be 1
    }
}