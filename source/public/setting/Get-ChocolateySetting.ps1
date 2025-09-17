
<#
.SYNOPSIS
    Gets the Settings set in the Configuration file.

.DESCRIPTION
    This command looks up in the Chocolatey Config file, and returns
    the Settings available from there.

.PARAMETER Setting
    Name of the Setting when retrieving a single one or a specific list.
    It defaults to returning all Settings available in the config file.

.EXAMPLE
    Get-ChocolateySetting -Name CacheLocation

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsConfig
#>
function Get-ChocolateySetting
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Setting = '*'
    )

    begin
    {
        $chocoCmd = Get-ChocolateyCommand

        $ChocoConfigPath = Join-Path -Path $chocoCmd.Path -ChildPath '..\..\config\chocolatey.config' -Resolve
        $chocoXml = [xml]::new()
        $chocoXml.Load($ChocoConfigPath)
    }

    process
    {
        if (-not $chocoXml)
        {
            throw "Error with Chocolatey config."
        }

        foreach ($Name in $Setting)
        {
            if ($Name -ne '*')
            {
                Write-Verbose -Message ("Searching for Setting named {0}" -f [Security.SecurityElement]::Escape($Name))
                $SettingNodes = $chocoXml.SelectNodes("//add[translate(@key,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='$([Security.SecurityElement]::Escape($Name.ToLower()))']")
            }
            else
            {
                Write-Verbose -Message 'Returning all Sources configured.'
                $SettingNodes = $chocoXml.chocolatey.config.childNodes
            }

            foreach ($SettingNode in $SettingNodes)
            {
                $SettingObject = [ordered]@{
                    PSTypeName = 'Chocolatey.Setting'
                }

                foreach ($property in $SettingNode.Attributes.name)
                {
                    $settingObject[$property] = '{0}' -f $SettingNode.($property)
                }

                [PSCustomObject]$SettingObject
            }
        }
    }
}
