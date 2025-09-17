BeforeAll {
    $script:moduleName = 'Chocolatey'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

Describe Install-ChocolateySoftware {

    Context 'Default' {
        BeforeAll {
            Mock Get-RemoteFile -MockWith {}
            Mock Get-RemoteString -MockWith {
                "<result><feed><entry><content><src>https://chocolatey.org/api/v2/packages/chocolatey/0.10.8/</src></content></entry></feed></result>"
            }
            Mock Copy-Item -MockWith {}
            Mock Expand-Archive -MockWith {}
            Mock New-Item -MockWith {}
            Mock Join-Path -ParameterFilter {$ChildPath -eq 'chocolateyInstall.ps1'} -MockWith { {$true} }
        }

        #Need to be first before Get-RemoteString has been called
        It 'Ensure Get-RemoteString is NOT called when install from Package URL' {
            $null = Install-ChocolateySoftware -ChocolateyPackageUrl 'https://chocolatey.org/api/v2/package/chocolatey/0.10.8/'
            { Assert-MockCalled Get-RemoteString } | Should -Throw
        }

        It 'Ensure Get-RemoteString is called when install from Feed without version' {
            $null = Install-ChocolateySoftware
            { Assert-MockCalled Get-RemoteString } | Should -Not -Throw
        }

        It 'Ensure Get-RemoteFile is called' {
            $null = Install-ChocolateySoftware
            { Assert-MockCalled Get-RemoteFile } | Should -Not -Throw
        }

        if ($PSVersionTable.PSVersion.Major -ge 5)
        {
            It 'Ensure Expand-Archive is called' {
                $null = Install-ChocolateySoftware
                { Assert-MockCalled Expand-Archive } | Should -Not -Throw
            }
        }
    }
}
