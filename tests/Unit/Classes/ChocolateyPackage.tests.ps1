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

Describe ChocolateyPackage {
    Context 'When licensed compatibility warnings are emitted before an exact package query' {
        BeforeAll {
            function global:Invoke-FakeChoco {
                param (
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [object[]]
                    $Arguments
                )

                @(
                    'A valid Chocolatey license was found, but the chocolatey.licensed.dll assembly could not be loaded:'
                    '  Unable to load licensed assembly.'
                    'Ensure that the chocolatey.licensed.dll exists at the following path:'
                    ' ''C:\ProgramData\chocolatey\extensions\chocolatey\chocolatey.licensed.dll'''
                    'To resolve this, install the Chocolatey Licensed Extension package with'
                    ' `choco install chocolatey.extension`'
                )
            }

            Mock Test-ChocolateyInstall -MockWith { $true }
            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
            Mock Get-ChocolateyDefaultArgument -MockWith { @('--limit-output', '--exact') }
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should treat the package as absent instead of throwing' {
            $desiredState = [ChocolateyPackage]::new()
            $desiredState.Name = 'chocolatey.extension'
            $desiredState.Version = '7.0.0'
            $desiredState.Source = 'Chocolatey-Source'
            $desiredState.Ensure = 'Present'

            $result = [ChocolateyPackage]::Get($desiredState)

            $result.Ensure | Should -Be 'Absent'
            $result.Version | Should -BeNullOrEmpty
            $result.Reasons.Code | Should -Contain 'ChocolateyPackage:ChocolateyPackage:ShouldBeInstalled'
        }
    }

    Context 'When evaluating DSCv3 static methods' {
        BeforeEach {
            Mock Test-ChocolateyInstall -MockWith { $true }
        }

        It 'Should return a tuple from Test with differing properties for version drift' {
            Mock Compare-ChocolateyPackage -MockWith {
                [PSCustomObject]@{
                    InstalledVersion = '1.0.0'
                    ExpectedVersion  = '2.0.0'
                    SideIndicator    = '<'
                }
            }

            $desiredState = [ChocolateyPackage]::new()
            $desiredState.Name = 'git'
            $desiredState.Version = '2.0.0'
            $desiredState.Ensure = 'Present'

            $result = [ChocolateyPackage]::Test($desiredState)

            $result.Item1 | Should -BeFalse
            $result.Item2.Version | Should -Be '1.0.0'
            $result.Item3 | Should -Be @('Version')
            $desiredState.Version | Should -Be '2.0.0'
        }

        It 'Should treat UpdateOnly as compliant when the package is absent' {
            Mock Compare-ChocolateyPackage -MockWith {
                [PSCustomObject]@{
                    InstalledVersion = $null
                    ExpectedVersion  = '2.0.0'
                    SideIndicator    = '!'
                }
            }

            $desiredState = [ChocolateyPackage]::new()
            $desiredState.Name = 'git'
            $desiredState.Version = '2.0.0'
            $desiredState.Ensure = 'Present'
            $desiredState.UpdateOnly = $true

            $result = [ChocolateyPackage]::Test($desiredState)

            $result.Item1 | Should -BeTrue
            $result.Item3 | Should -BeNullOrEmpty
        }

        It 'Should return the final state and changed properties from Set' {
            function global:Invoke-FakeUpdateChocolateyPackage {
                [CmdletBinding()]
                param (
                    [Parameter()]
                    [string]
                    $Name,

                    [Parameter()]
                    [string]
                    $Version,

                    [Parameter()]
                    [bool]
                    $Force,

                    [Parameter()]
                    [switch]
                    $Confirm
                )

                $script:capturedSetParameters = $PSBoundParameters
                'updated'
            }

            $script:comparePackageCallCount = 0
            Mock Compare-ChocolateyPackage -MockWith {
                $script:comparePackageCallCount++

                if ($script:comparePackageCallCount -eq 1)
                {
                    return [PSCustomObject]@{
                        InstalledVersion = '1.0.0'
                        ExpectedVersion  = '2.0.0'
                        SideIndicator    = '<'
                    }
                }

                return [PSCustomObject]@{
                    InstalledVersion = '2.0.0'
                    ExpectedVersion  = '2.0.0'
                    SideIndicator    = '='
                }
            }

            Mock Get-Command -MockWith { Get-Command -Name 'Invoke-FakeUpdateChocolateyPackage' } -ParameterFilter {
                $Name -eq 'Update-ChocolateyPackage'
            }

            $desiredState = [ChocolateyPackage]::new()
            $desiredState.Name = 'git'
            $desiredState.Version = '2.0.0'
            $desiredState.Ensure = 'Present'
            $desiredState.ChocolateyOptions = @{
                Force = 'True'
            }

            $result = [ChocolateyPackage]::Set($desiredState)

            $result.Item1.Version | Should -Be '2.0.0'
            $result.Item1.Ensure | Should -Be 'Present'
            $result.Item2 | Should -Be @('Version')
            $script:capturedSetParameters.Force | Should -BeTrue
        }

        It 'Should pass version-aware parameters to Delete' {
            Mock Compare-ChocolateyPackage -MockWith {
                [PSCustomObject]@{
                    InstalledVersion = '1.0.0'
                    ExpectedVersion  = '1.0.0'
                    SideIndicator    = '='
                }
            }

            Mock Uninstall-ChocolateyPackage -MockWith {}

            $desiredState = [ChocolateyPackage]::new()
            $desiredState.Name = 'git'
            $desiredState.Version = '1.0.0'
            $desiredState.Ensure = 'Absent'

            [ChocolateyPackage]::Delete($desiredState)

            Should -Invoke Compare-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
                $Version -eq '1.0.0'
            }

            Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
                $Version -eq '1.0.0'
            }
        }

        It 'Should return an instance schema that includes UpdateOnly' {
            $schema = [ChocolateyPackage]::InstanceJsonSchema() | ConvertFrom-Json -Depth 10

            $schema.required | Should -Contain 'Name'
            $schema.required | Should -Not -Contain 'Ensure'
            $schema.properties.Ensure.enum | Should -Contain 'Present'
            $schema.properties._name.readOnly | Should -BeTrue
            $schema.properties.UpdateOnly.type | Should -Be 'boolean'
            $schema.properties.Reasons.items.properties.Code.type | Should -Be 'string'
        }
    }
}
