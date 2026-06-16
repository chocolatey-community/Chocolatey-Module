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

Describe Convert-ChocolateyPackage {
    Context 'When no Chocolatey license is installed' {
        BeforeAll {
            Mock Get-ChocolateyCommand -MockWith { 'choco' }
            Mock Get-ChocolateyInstallPath -MockWith { 'C:\ProgramData\chocolatey' }
            Mock Test-ChocolateyLicenseInstalled -MockWith { $false }
        }

        It 'Should throw a license error' {
            {
                Convert-ChocolateyPackage -Path 'sysinternals.nupkg' -ToFormat 'intune' -Confirm:$false
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
                'converted'
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
            $result = Convert-ChocolateyPackage -Path 'sysinternals.nupkg' -ToFormat 'intune' -Confirm:$false

            $result | Should -BeNullOrEmpty
        }

        It 'Should pass convert as the first choco argument' {
            $null = Convert-ChocolateyPackage -Path 'sysinternals.nupkg' -ToFormat 'intune' -Confirm:$false

            $script:capturedArguments[0] | Should -Be 'convert'
        }

        It 'Should pass the nupkg path as the second argument' {
            $null = Convert-ChocolateyPackage -Path 'sysinternals.nupkg' -ToFormat 'intune' -Confirm:$false

            $script:capturedArguments[1] | Should -Be 'sysinternals.nupkg'
        }

        It 'Should pass --to-format when converting by path' {
            $null = Convert-ChocolateyPackage -Path 'sysinternals.nupkg' -ToFormat 'intune' -Confirm:$false

            $script:capturedArguments | Should -Contain '--to-format="intune"'
        }

        It 'Should pass -y when confirmed' {
            $null = Convert-ChocolateyPackage -Path 'sysinternals.nupkg' -ToFormat 'intune' -Confirm:$false

            $script:capturedArguments | Should -Contain '-y'
        }

        It 'Should pass --include-all when IncludeAll is specified' {
            $null = Convert-ChocolateyPackage -IncludeAll -ToFormat 'intune' -Confirm:$false

            $script:capturedArguments | Should -Contain '--include-all'
        }

        It 'Should not pass a path argument when IncludeAll is specified' {
            $null = Convert-ChocolateyPackage -IncludeAll -ToFormat 'intune' -Confirm:$false

            @($script:capturedArguments | Where-Object -FilterScript { $_ -like '*.nupkg' }).Count | Should -Be 0
        }

        It 'Should not execute when WhatIf is specified' {
            $null = Convert-ChocolateyPackage -Path 'sysinternals.nupkg' -ToFormat 'intune' -WhatIf

            $script:capturedArguments | Should -BeNullOrEmpty
        }
    }
}
