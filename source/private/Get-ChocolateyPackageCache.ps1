
<#
.SYNOPSIS
    Retrieve the cached list of installed packages.

.DESCRIPTION
    This command retrieves the cached list of installed packages. If the cache is older than 60 seconds,
    it will refresh the cache by calling Get-ChocolateyPackage and updating the cache file.

.PARAMETER ChocoInstallPath
    The path where Chocolatey is installed. If not provided, it will attempt to resolve it automatically.

.EXAMPLE
    Get-ChocolateyPackageCache

.NOTES
    This function is intended for internal use only.
#>
function Get-ChocolateyPackageCache
{
    [CmdletBinding()]
    [OutputType([Object[]])]
    param
    (
        [Parameter()]
        [string]
        $ChocoInstallPath = (Get-ChocolateyInstallPath -ErrorAction 'Stop')
    )

    $chocoCmd = Get-ChocolateyCommand

    if ([string]::IsNullOrEmpty($ChocoInstallPath))
    {
        Write-Debug -Message 'Chocolatey install path is not set.'
        if (-not [string]::IsNullOrEmpty($chocoCmd.Path))
        {
            $ChocoInstallPath = Split-Path -Path $chocoCmd.Path -Parent -ErrorAction 'Stop'
            Write-Debug -Message ('Resolved Chocolatey install path to {0}' -f $ChocoInstallPath)
        }
        else
        {
            Write-Error -Message 'Could not resolve Chocolatey install path.'
            return
        }
    }

    $cacheFolder = Join-Path -Path $ChocoInstallPath -ChildPath 'cache'
    $cachePath = Join-Path -Path $cacheFolder -ChildPath 'GetChocolateyPackageCache.xml'
    $cacheAvailable = $false

    try
    {
        if (-not (Test-Path -Path $cacheFolder))
        {
            # if we fail to create cache folder, we won't be able to cache results.
            $null = New-Item -Type Directory -Path $cacheFolder -Force -ErrorAction Stop
        }
        else
        {
            Write-Debug -Message ('Cache folder {0} already exists.' -f $cacheFolder)
            if (Test-Path -Path $cachePath)
            {
                Write-Debug -Message ('Cache file {0} already exists.' -f $cachePath)
                $cachedFile = Get-Item -Path $cachePath
            }
            else
            {
                Write-Debug -Message ('Cache file {0} does not exist.' -f $cachePath)
                $cachedFile = $null
            }
        }

        # touch the file to make sure we can write to file
        $null = [io.file]::OpenWrite($cachePath).close()
        $cacheAvailable = $true
    }
    catch
    {
        Write-Error -Message ('Failed to touch cache file at ''{0}''. {1}' -f $cachePath, $_.Exception.Message)
        return
    }

    if ($cacheAvailable -and $cachedFile.LastWriteTime -gt ([datetime]::Now.AddSeconds(-60)))
    {
        # if the cache is still valid, use it
        Write-Debug -Message "Retrieving from cache at $cachePath."
        $cachedResults = @(Import-Clixml -Path $cachePath)
        Write-Debug -Message ('Loaded {0} from cache.' -f $cachedResults.count)
        return $cachedResults
    }
    elseif ($cacheAvailable)
    {
        # cache is stale or not present, get a fresh list and update the cache
        Write-Debug -Message ('Cache is not available or is stale at {0}.' -f $cachePath)
        $unfilteredPackages = Get-ChocolateyPackage -ByPassCache
        $null = $unfilteredPackages | Export-Clixml -Path $cachePath -Force -ErrorAction 'Stop'
        Write-Debug -Message ('Unfiltered list cached at {0}.' -f $cachePath)
        return $unfilteredPackages
    }
}
