<#
.SYNOPSIS
    Creates completion results for Chocolatey argument completers.

.DESCRIPTION
    Filters candidate values using the current word being completed and returns
    PowerShell completion results for matching entries.

.PARAMETER Value
    Candidate values that can be completed.

.PARAMETER WordToComplete
    Current token text that should be matched against the candidate values.

.EXAMPLE
    New-ChocolateyCompletionResult -Value @('git', 'googlechrome') -WordToComplete 'g'
#>
function New-ChocolateyCompletionResult
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.CompletionResult[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [string[]]
        $Value,

        [Parameter()]
        [AllowEmptyString()]
        [string]
        $WordToComplete = ''
    )

    $candidateValues = $Value |
        Where-Object -FilterScript { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique

    foreach ($item in $candidateValues)
    {
        if ($item -notlike "$WordToComplete*")
        {
            continue
        }

        if ($item -match '\s')
        {
            $completionText = "'{0}'" -f ($item -replace "'", "''")
        }
        else
        {
            $completionText = $item
        }

        [System.Management.Automation.CompletionResult]::new(
            $completionText,
            $item,
            [System.Management.Automation.CompletionResultType]::ParameterValue,
            $item
        )
    }
}
