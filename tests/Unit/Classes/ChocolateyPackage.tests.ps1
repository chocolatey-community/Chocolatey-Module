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
}
