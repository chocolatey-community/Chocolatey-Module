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

Describe Register-ChocolateySource {
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
                $script:capturedInvocations.Add(@($Arguments))
                'source updated'
            }

            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
        }

        BeforeEach {
            $script:capturedArguments = @()
            $script:capturedInvocations = [System.Collections.Generic.List[object[]]]::new()
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should not return a value' {
            $result = Register-ChocolateySource -Name 'Internal' -Source 'https://proget/nuget/choco' -RunNonElevated -Confirm:$false

            $result | Should -BeNullOrEmpty
        }

        It 'Should pass source add as the choco subcommand' {
            $null = Register-ChocolateySource -Name 'Internal' -Source 'https://proget/nuget/choco' -RunNonElevated -Confirm:$false

            $script:capturedInvocations[0][0] | Should -Be 'source'
            $script:capturedInvocations[0][1] | Should -Be 'add'
        }

        It 'Should pass key source arguments when specified' {
            $null = Register-ChocolateySource -Name 'Internal' -Source 'https://proget/nuget/choco' -Priority 10 -BypassProxy -SelfService -RunNonElevated -Confirm:$false

            $script:capturedInvocations[0] | Should -Contain '--name="Internal"'
            $script:capturedInvocations[0] | Should -Contain '-s"https://proget/nuget/choco"'
            $script:capturedInvocations[0] | Should -Contain '--priority=10'
            $script:capturedInvocations[0] | Should -Contain '--bypass-proxy'
            $script:capturedInvocations[0] | Should -Contain '--allow-self-service'
        }

        It 'Should disable the source after registration when Disabled is specified' {
            $null = Register-ChocolateySource -Name 'Internal' -Source 'https://proget/nuget/choco' -Disabled -RunNonElevated -Confirm:$false

            $script:capturedInvocations.Count | Should -Be 2
            $script:capturedInvocations[1][0] | Should -Be 'source'
            $script:capturedInvocations[1][1] | Should -Be 'disable'
            $script:capturedInvocations[1] | Should -Contain '-n="Internal"'
        }

        It 'Should not execute when WhatIf is specified' {
            $null = Register-ChocolateySource -Name 'Internal' -Source 'https://proget/nuget/choco' -RunNonElevated -WhatIf

            $script:capturedInvocations.Count | Should -Be 0
        }
    }
}