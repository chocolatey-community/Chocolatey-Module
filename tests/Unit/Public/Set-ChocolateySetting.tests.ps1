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

Describe Set-ChocolateySetting {
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
                'setting updated'
            }

            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
        }

        BeforeEach {
            $script:capturedArguments = @()
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should not return a value' {
            $result = Set-ChocolateySetting -Name 'cacheLocation' -Value 'C:\cache' -RunNonElevated -Confirm:$false

            $result | Should -BeNullOrEmpty
        }

        It 'Should use config set when Value is specified' {
            $null = Set-ChocolateySetting -Name 'cacheLocation' -Value 'C:\cache' -RunNonElevated -Confirm:$false

            $script:capturedArguments[0] | Should -Be 'config'
            $script:capturedArguments[1] | Should -Be 'set'
        }

        It 'Should pass the name and expanded value arguments when setting a value' {
            $null = Set-ChocolateySetting -Name 'cacheLocation' -Value '$env:SystemDrive\ChocolateyCache\' -RunNonElevated -Confirm:$false

            $script:capturedArguments | Should -Contain '--name="cacheLocation"'
            $script:capturedArguments | Should -Contain ('--value="{0}\ChocolateyCache"' -f $env:SystemDrive)
        }

        It 'Should use config unset and omit --value when Unset is specified' {
            $null = Set-ChocolateySetting -Name 'cacheLocation' -Unset -RunNonElevated -Confirm:$false

            $script:capturedArguments[0] | Should -Be 'config'
            $script:capturedArguments[1] | Should -Be 'unset'
            @($script:capturedArguments | Where-Object -FilterScript { $_ -like '--value=*' }).Count | Should -Be 0
        }

        It 'Should not execute when WhatIf is specified' {
            $null = Set-ChocolateySetting -Name 'cacheLocation' -Value 'C:\cache' -RunNonElevated -WhatIf

            $script:capturedArguments | Should -BeNullOrEmpty
        }
    }
}