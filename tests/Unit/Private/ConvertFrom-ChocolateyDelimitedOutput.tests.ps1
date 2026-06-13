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

Describe ConvertFrom-ChocolateyDelimitedOutput {
    Context 'When command output contains compatibility warnings before valid package data' {
        BeforeAll {
            Mock Write-Warning -MockWith {}
        }

        It 'Should ignore non-delimited lines and return only valid package entries' {
            $result = @(InModuleScope -ScriptBlock {
                @(
                    'A valid Chocolatey license was found, but the chocolatey.licensed.dll assembly could not be loaded:'
                    '  Unable to load licensed assembly.'
                    'To resolve this, install the Chocolatey Licensed Extension package with'
                    'chocolatey.extension|7.0.0'
                ) | ConvertFrom-ChocolateyDelimitedOutput
            })

            $result.Count | Should -Be 1
            $result[0].Name | Should -Be 'chocolatey.extension'
            $result[0].Version | Should -Be '7.0.0'
        }

        It 'Should write the license compatibility line to the warning stream' {
            InModuleScope -ScriptBlock {
                @(
                    'A valid Chocolatey license was found, but the chocolatey.licensed.dll assembly could not be loaded:'
                    '  Unable to load licensed assembly.'
                    'To resolve this, install the Chocolatey Licensed Extension package with'
                ) | ConvertFrom-ChocolateyDelimitedOutput
            }

            Should -Invoke Write-Warning -Times 1 -ParameterFilter {
                $Message -match 'A valid Chocolatey license was found, but' -and
                $Message -match 'Unable to load licensed assembly\.' -and
                $Message -match 'To resolve this, install the Chocolatey Licensed Extension package with'
            }
        }
    }

    Context 'When command output contains only unexpected lines' {
        It 'Should return no package entries' {
            $result = InModuleScope -ScriptBlock {
                @(
                    'A valid Chocolatey license was found, but the chocolatey.licensed.dll assembly could not be loaded:'
                    'Ensure that the chocolatey.licensed.dll exists at the following path:'
                ) | ConvertFrom-ChocolateyDelimitedOutput
            }

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When command output contains an error line' {
        It 'Should write to the error stream when ErrorAction is Stop' {
            {
                InModuleScope -ScriptBlock {
                    @(
                        'ERROR: Chocolatey command failed.'
                    ) | ConvertFrom-ChocolateyDelimitedOutput -ErrorAction Stop
                }
            } | Should -Throw "*Chocolatey command output reported an error*"
        }
    }
}
