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

Describe Sync-ChocolateyPackage {
    Context 'When no Chocolatey license is installed' {
        BeforeAll {
            Mock Get-ChocolateyCommand -MockWith { 'choco' }
            Mock Get-ChocolateyInstallPath -MockWith { 'C:\ProgramData\chocolatey' }
            Mock Test-ChocolateyLicenseInstalled -MockWith { $false }
        }

        It 'Should throw a license error' {
            {
                Sync-ChocolateyPackage -RunNonElevated -Confirm:$false
            } | Should -Throw '*requires a Chocolatey for Business license file*'
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
                'Package Id|Display Name|Version|New Package'
                'globalprotect|GlobalProtect|6.2.8|True'
                'putty|Putty|0.76|False'
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

        It 'Should return parsed sync results as objects' {
            $result = @(Sync-ChocolateyPackage -RunNonElevated -Confirm:$false)

            $result.Count | Should -Be 2
            $result[0].PackageId   | Should -Be 'globalprotect'
            $result[0].DisplayName | Should -Be 'GlobalProtect'
            $result[0].Version     | Should -Be '6.2.8'
            $result[0].NewPackage  | Should -BeTrue
            $result[1].PackageId   | Should -Be 'putty'
            $result[1].NewPackage  | Should -BeFalse
        }

        It 'Should pass sync as the first choco argument' {
            $null = Sync-ChocolateyPackage -RunNonElevated -Confirm:$false

            $script:capturedArguments[0] | Should -Be 'sync'
        }

        It 'Should pass -y when confirmed' {
            $null = Sync-ChocolateyPackage -RunNonElevated -Confirm:$false

            $script:capturedArguments | Should -Contain '-y'
        }

        It 'Should pass --id when Id is specified' {
            $null = Sync-ChocolateyPackage -Id 'Putty' -RunNonElevated -Confirm:$false

            $script:capturedArguments | Should -Contain '--id="Putty"'
        }

        It 'Should not pass --id when Id is not specified' {
            $null = Sync-ChocolateyPackage -RunNonElevated -Confirm:$false

            @($script:capturedArguments | Where-Object -FilterScript { $_ -like '--id*' }).Count | Should -Be 0
        }

        It 'Should pass --package-id when PackageId is specified' {
            $null = Sync-ChocolateyPackage -Id 'Putty' -PackageId 'putty.portable' -RunNonElevated -Confirm:$false

            $script:capturedArguments | Should -Contain '--package-id="putty.portable"'
        }

        It 'Should not pass --package-id when PackageId is not specified' {
            $null = Sync-ChocolateyPackage -RunNonElevated -Confirm:$false

            @($script:capturedArguments | Where-Object -FilterScript { $_ -like '--package-id*' }).Count | Should -Be 0
        }

        It 'Should not execute when WhatIf is specified' {
            $null = Sync-ChocolateyPackage -RunNonElevated -WhatIf

            $script:capturedArguments | Should -BeNullOrEmpty
        }
    }
}
