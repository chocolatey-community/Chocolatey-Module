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

Describe Unregister-ChocolateySource {
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
                'source removed'
            }

            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
            Mock Get-ChocolateySource -MockWith {
                [PSCustomObject]@{
                    Name = 'Internal'
                }
            }
        }

        BeforeEach {
            $script:capturedArguments = @()
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should call Get-ChocolateySource before unregistering the source' {
            $null = Unregister-ChocolateySource -Name 'Internal' -RunNonElevated

            { Assert-MockCalled Get-ChocolateySource } | Should -Not -Throw
        }

        It 'Should not return a value' {
            $result = Unregister-ChocolateySource -Name 'Internal' -RunNonElevated

            $result | Should -BeNullOrEmpty
        }

        It 'Should pass source remove as the choco subcommand' {
            $null = Unregister-ChocolateySource -Name 'Internal' -RunNonElevated

            $script:capturedArguments[0] | Should -Be 'source'
            $script:capturedArguments[1] | Should -Be 'remove'
        }

        It 'Should pass the source name when specified' {
            $null = Unregister-ChocolateySource -Name 'Internal' -RunNonElevated

            $script:capturedArguments | Should -Contain '--name="Internal"'
        }

        It 'Should throw when the source cannot be found' {
            Mock Get-ChocolateySource -MockWith { $null } -ParameterFilter { $Name -eq 'Missing' }

            {
                Unregister-ChocolateySource -Name 'Missing' -RunNonElevated
            } | Should -Throw 'Chocolatey Source Missing cannot be found. You can Register it using Register-ChocolateySource.'
        }
    }
}