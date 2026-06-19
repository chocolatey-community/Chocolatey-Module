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

Describe Get-ChocolateyPin {
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
                $script:chocoOutput
            }

            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
            Mock Get-ChocolateyPackage -MockWith {
                [PSCustomObject]@{
                    Name    = $Name
                    Version = '2.47.0'
                }
            }
        }

        BeforeEach {
            $script:capturedArguments = @()
            $script:chocoOutput = @(
                'git|2.47.0'
                '7zip|24.09'
            )
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should return parsed pin results as objects' {
            $result = @(Get-ChocolateyPin)

            $result.Count | Should -Be 2
            $result[0].Name | Should -Be 'git'
            $result[0].Version | Should -Be '2.47.0'
            $result[1].Name | Should -Be '7zip'
        }

        It 'Should pass pin list as the choco subcommand' {
            $null = @(Get-ChocolateyPin)

            $script:capturedArguments[0] | Should -Be 'pin'
            $script:capturedArguments[1] | Should -Be 'list'
            $script:capturedArguments | Should -Contain '--limit-output'
        }

        It 'Should filter the results when Name is specified' {
            $result = @(Get-ChocolateyPin -Name 'git')

            $result.Count | Should -Be 1
            $result[0].Name | Should -Be 'git'
        }

        It 'Should throw when the requested package cannot be found' {
            Mock Get-ChocolateyPackage -MockWith { $null } -ParameterFilter { $Name -eq 'missing' -and $Exact }

            {
                Get-ChocolateyPin -Name 'missing'
            } | Should -Throw 'Chocolatey Package missing cannot be found.'
        }
    }
}