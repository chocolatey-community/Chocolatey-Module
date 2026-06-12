@{
    <#
        Default parameter values to be loaded by the Resolve-Dependency.ps1 script (unless set in bound parameters
        when calling the script).

        NOTE: To revert to the method PowerShellGet & PSDepend either remove the properties 'UsePSResourceGet' and
        'UseModuleFast' or set them to $false. Also, in the file RequiredModules.psd1 uncomment the property
        'PSDependOptions' which is required for PSDepend.
    #>

    Gallery         = 'PSGallery'
    AllowPrerelease = $false
    WithYAML        = $true # Will also bootstrap PowerShell-Yaml to read other config files

    <#
        Enable ModuleFast to be the default method of resolving dependencies by setting
        UseModuleFast to the value $true. ModuleFast requires PowerShell 7.2 or higher.
        If UseModuleFast is not configured or set to $false then PowerShellGet (or
        PSResourceGet if enabled) will be used as the default method of resolving
        dependencies.
    #>
    UseModuleFast = $true
    #ModuleFastVersion = '0.1.2'
    #ModuleFastBleedingEdge = $true

    <#
        Enable PSResourceGet to be the default method of resolving dependencies by setting
        UsePSResourceGet to the value $true. If UsePSResourceGet is not configured or
        set to $false then PowerShellGet will be used to resolve dependencies.
    #>
    UsePSResourceGet = $true
    #PSResourceGetVersion = '1.2.0'

    # PowerShellGet compatibility module only works when using PSResourceGet or ModuleFast.
    # UsePowerShellGetCompatibilityModule = $true
    # UsePowerShellGetCompatibilityModuleVersion = '3.0.23-beta23'
}
