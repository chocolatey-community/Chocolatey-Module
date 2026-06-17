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

Describe Publish-ChocolateyPackage {
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
                'pushed package'
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
            $null = Publish-ChocolateyPackage -Path 'mypackage.1.0.0.nupkg' -Confirm:$false

            Should -Invoke Get-ChocolateyCommand -Times 1 -Exactly
        }

        It 'Should not return a value' {
            $result = Publish-ChocolateyPackage -Path 'mypackage.1.0.0.nupkg' -Confirm:$false

            $result | Should -BeNullOrEmpty
        }

        It 'Should pass push as the first choco argument' {
            $null = Publish-ChocolateyPackage -Path 'mypackage.1.0.0.nupkg' -Confirm:$false

            $script:capturedArguments[0] | Should -Be 'push'
        }

        It 'Should pass the nupkg path as the second choco argument' {
            $null = Publish-ChocolateyPackage -Path 'mypackage.1.0.0.nupkg' -Confirm:$false

            $script:capturedArguments[1] | Should -Be 'mypackage.1.0.0.nupkg'
        }

        It 'Should pass -y when confirmed' {
            $null = Publish-ChocolateyPackage -Path 'mypackage.1.0.0.nupkg' -Confirm:$false

            $script:capturedArguments | Should -Contain '-y'
        }

        It 'Should include the source argument when Source is specified' {
            $null = Publish-ChocolateyPackage -Path 'mypackage.1.0.0.nupkg' -Source 'https://push.chocolatey.org/' -Confirm:$false

            $script:capturedArguments | Should -Contain '-s"https://push.chocolatey.org/"'
        }

        It 'Should include the api-key argument when ApiKey is specified' {
            $null = Publish-ChocolateyPackage -Path 'mypackage.1.0.0.nupkg' -ApiKey 'my-api-key' -Confirm:$false

            $script:capturedArguments | Should -Contain '--api-key="my-api-key"'
        }

        It 'Should not include --api-key when ApiKey is not specified' {
            $null = Publish-ChocolateyPackage -Path 'mypackage.1.0.0.nupkg' -Confirm:$false

            $script:capturedArguments | Should -Not -Contain '--api-key'
            @($script:capturedArguments | Where-Object -FilterScript { $_ -like '--api-key*' }).Count | Should -Be 0
        }

        It 'Should publish each package when multiple paths are supplied' {
            $null = Publish-ChocolateyPackage -Path 'pkg1.nupkg', 'pkg2.nupkg' -Confirm:$false

            Should -Invoke Get-ChocolateyCommand -Times 1 -Exactly
        }

        It 'Should not execute when WhatIf is specified' {
            $null = Publish-ChocolateyPackage -Path 'mypackage.1.0.0.nupkg' -WhatIf

            $script:capturedArguments | Should -BeNullOrEmpty
        }
    }
}
