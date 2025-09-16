
<#
.SYNOPSIS
    Verify the source settings matches the given parameters.

.DESCRIPTION
    This command compares the properties of the source found by name, with the parameters given.

.PARAMETER Name
    Name - the name of the source to find for comparison.

.PARAMETER Source
    Source - The source. This can be a folder/file share or an http location.
    If it is a url, it will be a location you can go to in a browser and
    it returns OData with something that says Packages in the browser,
    similar to what you see when you go to https://chocolatey.org/api/v2/.
    Defaults to empty.

.PARAMETER Disabled
    Test whether the source to is registered but disabled.
    By default it checks if enabled.

.PARAMETER BypassProxy
    Bypass Proxy - Is this source explicitly bypass any explicitly or
    system configured proxies? Defaults to false. Available in 0.10.4+.

.PARAMETER SelfService
    Is Self-Service ? - Is this source be allowed to be used with self-
    service? Requires business edition (v1.10.0+) with feature
    'useBackgroundServiceWithSelfServiceSourcesOnly' turned on. Defaults to
    false. Available in 0.10.4+.

.PARAMETER Priority
    Priority - The priority order of this source as compared to other
    sources, lower is better. Defaults to 0 (no priority). All priorities
    above 0 will be evaluated first, then zero-based values will be
    evaluated in config file order. Available in 0.9.9.9+.

.PARAMETER Credential
    Validate Credential used with authenticated feeds.

.PARAMETER KeyUser
    API Key User for the registered source.

.PARAMETER Key
    API Key for the registered source (used instead of credential when password length > 240 char).

.EXAMPLE
    Test-ChocolateySource -source https://chocolatey.org/api/v2 -priority 0

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Test-ChocolateySource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $Source,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Disabled,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $BypassProxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $SelfService,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]
        $Priority = 0,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter()]
        #To be used when Password is too long (>240 char) like a key
        $KeyUser,
        [Parameter()]
        $Key
    )

    process
    {
        $chocoCmd = Get-ChocolateyCommand
        $sourceObj = Get-ChocolateySource -Name $Name

        if ($null -eq $sourceObj)
        {
            Write-Verbose -Message ('Chocolatey Source {0} cannot be found.' -f $Name)
            return $false
        }

        $referenceSource = [ordered]@{}
        foreach ($Property in $PSBoundParameters.keys | Where-Object {$_ -notin ([System.Management.Automation.Cmdlet]::CommonParameters + [System.Management.Automation.Cmdlet]::OptionalCommonParameters) })
        {
            if ($Property -notin @('Credential', 'Key', 'KeyUser'))
            {
                if ($PSBoundParameters[$Property] -is [switch])
                {
                    $referenceSource[$Property] = $PSBoundParameters[$Property].IsPresent
                }
                else
                {
                    $referenceSource[$Property] = $PSBoundParameters[$Property]
                }
            }
            else
            {
                if ($Credential)
                {
                    $Username = $Credential.UserName
                }
                else
                {
                    $Username = $KeyUser
                }

                $referenceSource['password'] = 'Reference Object Password'
                $referenceSource['username'] = $UserName

                $securePasswordStr = $sourceObj.Password
                $SecureStr = [System.Convert]::FromBase64String($SecurePasswordStr)
                $salt = [System.Text.Encoding]::UTF8.GetBytes("Chocolatey")
                $PasswordBytes = [Security.Cryptography.ProtectedData]::Unprotect($SecureStr, $salt, [Security.Cryptography.DataProtectionScope]::LocalMachine)
                $PasswordInFile = [system.text.encoding]::UTF8.GetString($PasswordBytes)

                if ($Credential)
                {
                    $PasswordParameter = $Credential.GetNetworkCredential().Password
                }
                else
                {
                    $PasswordParameter = $Key
                }

                if ($PasswordInFile -eq $PasswordParameter)
                {
                    Write-Verbose -Message "The Passwords Match."
                    $sourceObj.Password = 'Reference Object Password'
                }
                else
                {
                    Write-Verbose -Message "The Password Do not Match."
                    $sourceObj.Password = 'Source Object Password'
                }
            }
        }

        $refSource = [PSCustomObject]$referenceSource
        Write-Debug -Message ('Reference Source: {0}' -f ($refSource | ConvertTo-Json -Depth 5))
        Write-Debug -Message ('Source from Config: {0}' -f ($sourceObj | ConvertTo-Json -Depth 5))

        Compare-Object -ReferenceObject $refSource -DifferenceObject $sourceObj -Property $refSource.PSObject.Properties.Name
    }
}
