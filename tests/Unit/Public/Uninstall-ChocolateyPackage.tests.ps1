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

Describe Uninstall-ChocolateyPackage {
    Context 'Default' {
        BeforeAll {
            function global:Invoke-FakeChoco
            {
                param
                (
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [object[]]
                    $Arguments
                )

                $script:capturedArguments = $Arguments
                'uninstalled'
            }

            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
            Mock Remove-ChocolateyPackageCache -MockWith {}
        }

        BeforeEach {
            $script:capturedArguments = @()
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should call Remove-ChocolateyPackageCache before invoking choco' {
            $null = Uninstall-ChocolateyPackage -Name 'git' -RunNonElevated -Confirm:$false

            { Assert-MockCalled Remove-ChocolateyPackageCache } | Should -Not -Throw
        }

        It 'Should not return a value' {
            $result = Uninstall-ChocolateyPackage -Name 'git' -RunNonElevated -Confirm:$false

            $result | Should -BeNullOrEmpty
        }

        It 'Should pass uninstall as the first choco argument' {
            $null = Uninstall-ChocolateyPackage -Name 'git' -RunNonElevated -Confirm:$false

            $script:capturedArguments[0] | Should -Be 'uninstall'
            $script:capturedArguments[1] | Should -Be 'git'
        }

        It 'Should pass -y when confirmed' {
            $null = Uninstall-ChocolateyPackage -Name 'git' -RunNonElevated -Confirm:$false

            $script:capturedArguments | Should -Contain '-y'
        }

        It 'Should pass version and source arguments when specified' {
            $null = Uninstall-ChocolateyPackage -Name 'git' -Version '2.47.0' -Source 'https://community.chocolatey.org/api/v2/' -RunNonElevated -Confirm:$false

            $script:capturedArguments | Should -Contain '--version="2.47.0"'
            $script:capturedArguments | Should -Contain '-s"https://community.chocolatey.org/api/v2/"'
        }

        It 'Should not execute when WhatIf is specified' {
            $null = Uninstall-ChocolateyPackage -Name 'git' -RunNonElevated -WhatIf

            $script:capturedArguments | Should -BeNullOrEmpty
        }
    }
}