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

Describe New-ChocolateyCompletionResultForSourceName {
    It 'Should build completion results from source names' {
        $script:capturedValue = $null
        $script:capturedWordToComplete = $null

        Mock Get-ChocolateySource -MockWith {
            @(
                [PSCustomObject]@{ Name = 'Chocolatey' },
                [PSCustomObject]@{ Name = 'Internal' }
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

            'source-completion'
        }

        $result = InModuleScope -ScriptBlock {
            New-ChocolateyCompletionResultForSourceName -WordToComplete 'Int'
        }
        $result | Should -Be 'source-completion'
        $result | Should -Be 'source-completion'
        $script:capturedValue | Should -Be @('Chocolatey', 'Internal')
        $script:capturedWordToComplete | Should -Be 'Int'
    }
}
