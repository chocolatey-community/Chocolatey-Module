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

Describe Save-ChocolateyPackage {
    Context 'Default' {
        BeforeAll {
            function global:Invoke-FakeChoco {
                param (
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [object[]]
                    $Arguments
                )

                $script:capturedArguments = $Arguments
                'saved package'
            }

            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
        }

        BeforeEach {
            $script:capturedArguments = @()
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should call Get-ChocolateyCommand' {
            $null = Save-ChocolateyPackage -Name 'sysinternals'
            { Assert-MockCalled Get-ChocolateyCommand } | Should -Not -Throw
        }

        It 'Should not return value' {
            $return = Save-ChocolateyPackage -Name 'sysinternals'

            $return | Should -BeNullOrEmpty
        }
    }

    Context 'When using licensed-only download parameters' {
        BeforeAll {
            function global:Invoke-FakeChoco {
                param (
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [object[]]
                    $Arguments
                )

                $script:capturedArguments = $Arguments
                'saved package'
            }

            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
            Mock Get-ChocolateyInstallPath -MockWith { 'C:\ProgramData\chocolatey' }
        }

        BeforeEach {
            $script:capturedArguments = @()
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should throw when no Chocolatey license is installed' {
            Mock Test-ChocolateyLicenseInstalled -MockWith { $false }

            {
                Save-ChocolateyPackage -Name 'notepadplusplus.install' -Internalize
            } | Should -Throw '*license-specific parameters require an installed license file*'
        }

        It 'Should include licensed download arguments when internalizing a package' {
            Mock Test-ChocolateyLicenseInstalled -MockWith { $true }

            $null = Save-ChocolateyPackage -Name 'notepadplusplus.install' -Source 'https://community.chocolatey.org/api/v2/' -OutputDirectory 'C:\packages' -Internalize -ResourcesLocation '\\server\share' -DownloadLocation 'C:\staging' -InternalizeAllUrls -AppendUseOriginalLocation -UseDownloadCache -SkipVirusCheck -IgnoreDependenciesFromSource 'InternalRepo'

            $script:capturedArguments | Should -Contain 'download'
            $script:capturedArguments | Should -Contain 'notepadplusplus.install'
            $script:capturedArguments | Should -Contain '-s"https://community.chocolatey.org/api/v2/"'
            $script:capturedArguments | Should -Contain '--output-directory="C:\packages"'
            $script:capturedArguments | Should -Contain '--internalize'
            $script:capturedArguments | Should -Contain '--resources-location="\\server\share"'
            $script:capturedArguments | Should -Contain '--download-location="C:\staging"'
            $script:capturedArguments | Should -Contain '--internalize-all-urls'
            $script:capturedArguments | Should -Contain '--append-use-original-location'
            $script:capturedArguments | Should -Contain '--use-download-cache'
            $script:capturedArguments | Should -Contain '--skip-virus-check'
            $script:capturedArguments | Should -Contain '--ignore-dependencies-from-source="InternalRepo"'
            $script:capturedArguments | Should -Contain '-y'
        }

        It 'Should support downloading installed packages' {
            Mock Test-ChocolateyLicenseInstalled -MockWith { $true }

            $null = Save-ChocolateyPackage -InstalledPackages

            $script:capturedArguments | Should -Contain 'download'
            $script:capturedArguments | Should -Contain '--installed-packages'
        }
    }
}
