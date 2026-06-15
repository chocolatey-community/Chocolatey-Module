@{
    <#
        This is only required if you need to use the method PowerShellGet & PSDepend.
        It is not required for PSResourceGet or ModuleFast (and will be ignored).
        See Resolve-Dependency.psd1 on how to enable methods.
    #>
    #PSDependOptions             = @{
    #    AddToPath  = $true
    #    Target     = 'output\RequiredModules'
    #    Parameters = @{
    #        Repository = 'PSGallery'
    #    }
    #}

    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = 'latest'
    Pester                      = 'latest'
    Plaster                     = 'latest'
    ModuleBuilder               = 'latest'
    Configuration               = 'latest'
    ChangelogManagement         = 'latest'
    Sampler                     = @{
        version = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }

    PSDesiredStateConfiguration = '2.0.6'
    'Sampler.GitHubTasks'       = 'latest'
    MarkdownLinkCheck           = 'latest'
    'DscResource.Common'        = 'latest'
    'DscResource.Test'          = 'latest'
    'DscResource.AnalyzerRules' = 'latest'
    'DscResource.Authoring' = @{
        Version    = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
    xDscResourceDesigner        = 'latest'
    'DscResource.DocGenerator'  = 'latest'
    platyPS                     = 'latest'
    'Microsoft.PowerShell.PSResourceGet' = 'latest'

    'GuestConfiguration'        = @{
        version = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
}
