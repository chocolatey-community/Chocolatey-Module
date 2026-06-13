BeforeAll {
    $script:moduleName = 'Chocolatey'

    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

Describe Get-ChocolateyPackage {
    Context 'When choco list returns compatibility warnings before package output' {
        BeforeAll {
            function global:Invoke-FakeChoco {
                param (
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [object[]]
                    $Arguments
                )

                @(
                    'A valid Chocolatey license was found, but the chocolatey.licensed.dll assembly could not be loaded:'
                    'Ensure that the chocolatey.licensed.dll exists at the following path:'
                    'chocolatey.extension|7.0.0'
                )
            }

            Mock Get-ChocolateyCommand -MockWith { 'Invoke-FakeChoco' }
            Mock Get-ChocolateyDefaultArgument -MockWith { @('--limit-output', '--exact') }
        }

        AfterAll {
            Remove-Item -Path Function:\Invoke-FakeChoco -ErrorAction 'SilentlyContinue'
        }

        It 'Should return only the valid package entry' {
            $result = @(Get-ChocolateyPackage -Name 'chocolatey.extension' -Exact)

            $result.Count | Should -Be 1
            $result[0].Name | Should -Be 'chocolatey.extension'
            $result[0].Version | Should -Be '7.0.0'
        }
    }
}