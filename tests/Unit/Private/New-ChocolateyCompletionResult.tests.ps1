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

Describe New-ChocolateyCompletionResult {
    Context 'When matching candidate values' {
        BeforeAll {
            $script:results = InModuleScope -ScriptBlock {
                New-ChocolateyCompletionResult -Value @(
                    'google chrome',
                    'git',
                    'git'
                ) -WordToComplete 'g'
            }
        }

        It 'Should return unique completion results' {
            $script:results.Count | Should -Be 2
            $script:results.ListItemText | Should -Be @('git', 'google chrome')
        }

        It 'Should quote completion text for values with spaces' {
            ($script:results | Where-Object -FilterScript { $_.ListItemText -eq 'google chrome' }).CompletionText |
                Should -Be "'google chrome'"
        }
    }

    Context 'When filtering by the current word' {
        It 'Should only return prefix matches' {
            $result = InModuleScope -ScriptBlock {
                New-ChocolateyCompletionResult -Value @(
                    'git',
                    'python'
                ) -WordToComplete 'py'
            }

            $result.Count | Should -Be 1
            $result[0].ListItemText | Should -Be 'python'
        }
    }
}
