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

Describe Get-ChocolateyPackage {
    Context 'When checking whether a package is installed with Exact' {
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
        }

        BeforeEach {
            $script:capturedArguments = @()
            $script:chocoOutput = @('chocolatey|2.4.3')
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should pass list as the first choco argument' {
            $null = @(Get-ChocolateyPackage -Name 'chocolatey' -Exact)

            $script:capturedArguments[0] | Should -Be 'list'
        }

        It 'Should pass --exact when checking a specific package' {
            $null = @(Get-ChocolateyPackage -Name 'chocolatey' -Exact)

            $script:capturedArguments | Should -Contain '--exact'
        }

        It 'Should return the installed package entry when the package is present' {
            $result = @(Get-ChocolateyPackage -Name 'chocolatey' -Exact)

            $result.Count | Should -Be 1
            $result[0].Name | Should -Be 'chocolatey'
            $result[0].Version | Should -Be '2.4.3'
        }

        It 'Should return no package when the exact package is not installed' {
            $script:chocoOutput = @()

            $result = Get-ChocolateyPackage -Name 'chocolatey' -Exact

            $result | Should -BeNullOrEmpty
        }
    }
}