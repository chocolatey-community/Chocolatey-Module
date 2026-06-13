<#
.SYNOPSIS
    Converts Chocolatey delimited output into objects.

.DESCRIPTION
    Filters command output to only include lines matching the expected delimited
    shape before converting them into objects.

.PARAMETER InputObject
    Raw output lines to parse.

.PARAMETER Delimiter
    Delimiter used by the Chocolatey command output.

.PARAMETER Header
    Property names to assign to the parsed output.
#>
function ConvertFrom-ChocolateyDelimitedOutput
{
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string[]]
        $InputObject,

        [Parameter()]
        [char]
        $Delimiter = '|',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Header = @('Name', 'Version')
    )

    begin
    {
        $validLines = [System.Collections.Generic.List[string]]::new()
        $warningBlockLines = [System.Collections.Generic.List[string]]::new()
        $escapedDelimiter = [regex]::Escape([string] $Delimiter)
        $expectedDelimiterCount = $Header.Count - 1
        $flushWarningBlock = {
            if ($warningBlockLines.Count -gt 0)
            {
                Write-Warning -Message ("Chocolatey command output warning:`n{0}" -f ($warningBlockLines -join [Environment]::NewLine))
                $warningBlockLines.Clear()
            }
        }

        $writeIgnoredLine = {
            param (
                [Parameter(Mandatory = $true)]
                [string] $Message,

                [Parameter(Mandatory = $true)]
                [string] $Line
            )

            if ($Line -match '^(?i:ERROR)(?:\b|:)')
            {
                Write-Error -Message ("Chocolatey command output reported an error: '{0}'" -f $Line)
            }
            else
            {
                Write-Verbose -Message ($Message -f $Line)
            }
        }
    }

    process
    {
        foreach ($line in $InputObject)
        {
            if ([string]::IsNullOrWhiteSpace($line))
            {
                & $flushWarningBlock
                continue
            }

            $displayLine = $line.TrimEnd()
            $trimmedLine = $line.Trim()
            $delimiterCount = [regex]::Matches($trimmedLine, $escapedDelimiter).Count
            $isDelimitedLine = $delimiterCount -eq $expectedDelimiterCount

            if ($warningBlockLines.Count -gt 0)
            {
                if ($isDelimitedLine)
                {
                    & $flushWarningBlock
                }
                else
                {
                    $warningBlockLines.Add($displayLine)
                    continue
                }
            }

            if ($trimmedLine -like 'A valid Chocolatey license was found, but*')
            {
                $warningBlockLines.Add($displayLine)
                continue
            }

            if (-not $isDelimitedLine)
            {
                & $writeIgnoredLine "Ignoring unexpected Chocolatey output line: '{0}'" $trimmedLine
                continue
            }

            $columns = $trimmedLine -split $escapedDelimiter, $Header.Count

            if (
                $columns.Count -ne $Header.Count -or
                ($columns | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0
            )
            {
                & $writeIgnoredLine "Ignoring invalid Chocolatey output line: '{0}'" $trimmedLine
                continue
            }

            $validLines.Add($trimmedLine)
        }
    }

    end
    {
        & $flushWarningBlock

        if ($validLines.Count -gt 0)
        {
            $validLines | ConvertFrom-Csv -Delimiter $Delimiter -Header $Header
        }
    }
}
