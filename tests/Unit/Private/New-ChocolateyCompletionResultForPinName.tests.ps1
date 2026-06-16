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

Describe New-ChocolateyCompletionResultForPinName {
    It 'Should build completion results from pin names' {
        $script:capturedValue = $null
        $script:capturedWordToComplete = $null

        Mock Get-ChocolateyPin -MockWith {
            @(
                [PSCustomObject]@{ Name = 'git' },
                [PSCustomObject]@{ Name = 'googlechrome' }
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

            'pin-completion'
        }

        $result = InModuleScope -ScriptBlock {
            New-ChocolateyCompletionResultForPinName -WordToComplete 'g'
        }
        $result | Should -Be 'pin-completion'
        $result | Should -Be 'pin-completion'
        $script:capturedValue | Should -Be @('git', 'googlechrome')
        $script:capturedWordToComplete | Should -Be 'g'
    }
}
