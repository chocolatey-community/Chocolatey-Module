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

Describe Register-ChocolateyArgumentCompleter {
    Context 'When registering completers' {
        BeforeEach {
            $script:registrations = @()

            Mock Register-ArgumentCompleter -MockWith {
                param
                (
                    [Parameter()]
                    [string[]]
                    $CommandName,

                    [Parameter()]
                    [string]
                    $ParameterName,

                    [Parameter()]
                    [scriptblock]
                    $ScriptBlock
                )

                $script:registrations += [PSCustomObject]@{
                    CommandName   = $CommandName
                    ParameterName = $ParameterName
                    ScriptBlock   = $ScriptBlock
                }
            }

            InModuleScope -ScriptBlock {
                Register-ChocolateyArgumentCompleter
            }
        }

        It 'Should register the expected command and parameter combinations' {
            $script:registrations.Count | Should -Be 7

            ($script:registrations | Where-Object -FilterScript {
                $_.ParameterName -eq 'Name' -and $_.CommandName -contains 'Update-ChocolateyPackage'
            }).Count | Should -Be 1

            ($script:registrations | Where-Object -FilterScript {
                $_.ParameterName -eq 'Name' -and $_.CommandName -contains 'Remove-ChocolateyPin'
            }).Count | Should -Be 1

            ($script:registrations | Where-Object -FilterScript {
                $_.ParameterName -eq 'Name' -and $_.CommandName -contains 'Unregister-ChocolateySource'
            }).Count | Should -Be 1

            ($script:registrations | Where-Object -FilterScript {
                $_.ParameterName -eq 'Feature' -and $_.CommandName -contains 'Get-ChocolateyFeature'
            }).Count | Should -Be 1

            ($script:registrations | Where-Object -FilterScript {
                $_.ParameterName -eq 'Setting' -and $_.CommandName -contains 'Get-ChocolateySetting'
            }).Count | Should -Be 1
        }

        It 'Should use the package completion helper for package commands' {
            Mock New-ChocolateyCompletionResultForPackageName -MockWith { 'package-result' }

            $registration = $script:registrations | Where-Object -FilterScript {
                $_.ParameterName -eq 'Name' -and $_.CommandName -contains 'Get-ChocolateyPackage'
            } | Select-Object -First 1

            $result = InModuleScope -ScriptBlock {
                param
                (
                    [Parameter()]
                    [scriptblock]
                    $ScriptBlock
                )

                & $ScriptBlock 'Get-ChocolateyPackage' 'Name' 'go' $null @{}
            } -Parameters @{ ScriptBlock = $registration.ScriptBlock }

            $result | Should -Be 'package-result'
            Should -Invoke New-ChocolateyCompletionResultForPackageName -Times 1 -Exactly -ParameterFilter {
                $WordToComplete -eq 'go'
            }
        }

        It 'Should use the feature completion helper for feature commands' {
            Mock New-ChocolateyCompletionResultForFeatureName -MockWith { 'feature-result' }

            $registration = $script:registrations | Where-Object -FilterScript {
                $_.ParameterName -eq 'Feature'
            } | Select-Object -First 1

            $result = InModuleScope -ScriptBlock {
                param
                (
                    [Parameter()]
                    [scriptblock]
                    $ScriptBlock
                )

                & $ScriptBlock 'Get-ChocolateyFeature' 'Feature' 'show' $null @{}
            } -Parameters @{ ScriptBlock = $registration.ScriptBlock }

            $result | Should -Be 'feature-result'
            Should -Invoke New-ChocolateyCompletionResultForFeatureName -Times 1 -Exactly -ParameterFilter {
                $WordToComplete -eq 'show'
            }
        }
    }
}
