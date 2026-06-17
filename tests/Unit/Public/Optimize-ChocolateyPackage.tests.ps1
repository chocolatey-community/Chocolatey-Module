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

Describe Optimize-ChocolateyPackage {
    Context 'When no Chocolatey license is installed' {
        BeforeAll {
            Mock Get-ChocolateyCommand -MockWith { 'choco' }
            Mock Get-ChocolateyInstallPath -MockWith { 'C:\ProgramData\chocolatey' }
            Mock Test-ChocolateyLicenseInstalled -MockWith { $false }
        }

        It 'Should throw a license error' {
            {
                Optimize-ChocolateyPackage -RunNonElevated -Confirm:$false
            } | Should -Throw '*requires a Chocolatey Licensed Edition license file*'
        }
    }

    Context 'When a Chocolatey license is installed' {
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
                'optimized'
            }

            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
            Mock Get-ChocolateyInstallPath -MockWith { 'C:\ProgramData\chocolatey' }
            Mock Test-ChocolateyLicenseInstalled -MockWith { $true }
        }

        BeforeEach {
            $script:capturedArguments = @()
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should not return a value' {
            $result = Optimize-ChocolateyPackage -RunNonElevated -Confirm:$false

            $result | Should -BeNullOrEmpty
        }

        It 'Should pass optimize as the first choco argument' {
            $null = Optimize-ChocolateyPackage -RunNonElevated -Confirm:$false

            $script:capturedArguments[0] | Should -Be 'optimize'
        }

        It 'Should pass -y when confirmed' {
            $null = Optimize-ChocolateyPackage -RunNonElevated -Confirm:$false

            $script:capturedArguments | Should -Contain '-y'
        }

        It 'Should pass --id when Name is specified' {
            $null = Optimize-ChocolateyPackage -Name 'googlechrome' -RunNonElevated -Confirm:$false

            $script:capturedArguments | Should -Contain '--id="googlechrome"'
        }

        It 'Should not pass --id when Name is not specified' {
            $null = Optimize-ChocolateyPackage -RunNonElevated -Confirm:$false

            @($script:capturedArguments | Where-Object -FilterScript { $_ -like '--id*' }).Count | Should -Be 0
        }

        It 'Should pass --reduce-nupkg-only when ReduceNupkgOnly is specified' {
            $null = Optimize-ChocolateyPackage -ReduceNupkgOnly -RunNonElevated -Confirm:$false

            $script:capturedArguments | Should -Contain '--reduce-nupkg-only'
        }

        It 'Should not execute when WhatIf is specified' {
            $null = Optimize-ChocolateyPackage -RunNonElevated -WhatIf

            $script:capturedArguments | Should -BeNullOrEmpty
        }
    }
}
