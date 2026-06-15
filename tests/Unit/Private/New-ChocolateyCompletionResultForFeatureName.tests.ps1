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

Describe New-ChocolateyCompletionResultForFeatureName {
    It 'Should build completion results from feature names' {
        $script:capturedValue = $null
        $script:capturedWordToComplete = $null

        Mock Get-ChocolateyFeature -MockWith {
            @(
                [PSCustomObject]@{ Name = 'checksumFiles' },
                [PSCustomObject]@{ Name = 'showDownloadProgress' }
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

            'feature-completion'
        }

        $result = InModuleScope -ScriptBlock {
            New-ChocolateyCompletionResultForFeatureName -WordToComplete 'show'
        }
        $result | Should -Be 'feature-completion'
        $result | Should -Be 'feature-completion'
        $script:capturedValue | Should -Be @('checksumFiles', 'showDownloadProgress')
        $script:capturedWordToComplete | Should -Be 'show'
    }
}
