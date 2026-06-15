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

Describe New-ChocolateyCompletionResultForSettingName {
    It 'Should build completion results from setting names' {
        $script:capturedValue = $null
        $script:capturedWordToComplete = $null

        Mock Get-ChocolateySetting -MockWith {
            @(
                [PSCustomObject]@{ key = 'cacheLocation' },
                [PSCustomObject]@{ key = 'commandExecutionTimeoutSeconds' }
            )
        }
        Mock New-ChocolateyCompletionResult -MockWith {
            param
            (
                [Parameter()]
                [string[]]
                $Value,

                [Parameter()]
                [string]
                $WordToComplete
            )

            $script:capturedValue = $Value
            $script:capturedWordToComplete = $WordToComplete

            'setting-completion'
        }

        $result = InModuleScope -ScriptBlock {
            New-ChocolateyCompletionResultForSettingName -WordToComplete 'cache'
        }
        $result | Should -Be 'setting-completion'
        $result | Should -Be 'setting-completion'
        $script:capturedValue | Should -Be @('cacheLocation', 'commandExecutionTimeoutSeconds')
        $script:capturedWordToComplete | Should -Be 'cache'
    }
}
