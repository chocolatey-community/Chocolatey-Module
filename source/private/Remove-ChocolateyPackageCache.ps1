function Remove-ChocolateyPackageCache
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $ChocoInstallPath = (Get-ChocolateyInstallPath -ErrorAction 'Stop')
    )

    $cacheFolder = Join-Path -Path $ChocoInstallPath -ChildPath 'cache'
    $cachePath = Join-Path -Path $cacheFolder -ChildPath 'GetChocolateyPackageCache.xml'
    if ((Test-Path -Path $cachePath))
    {
        try
        {
            Write-Debug -Message ('Attempting to remove the cached list at ''{0}''.' -f $cachePath)
            $null = Remove-Item -Path $cachePath -ErrorAction SilentlyContinue -Force -Confirm:$false
            Write-Debug -Message 'Cached list removed'
        }
        catch
        {
            # Potentially a lack of permissions (running non-elevated)
            Write-Debug -Message ('Unable to remove cache list {0}' -f $cachePath)
        }
    }
}
