Repair-ProcessEnvPath

#region TypeAccelerator export for classes

# If classes/types are specified here, they won't be fully qualified (careful with conflicts)
$typesToExportAsIs = @(
    'ChocolateyReason'
    'ChocolateyPackage'
    'ChocolateySoftware'
    'ChocolateySource'
    'ChocolateyFeature'
    'ChocolateySetting'
    'ChocolateyPin'
)

# The type accelerators created will be ModuleName.ClassName (to avoid conflicts with other modules until you use 'using moduleName'
$typesToExportWithNamespace = @(

)

# inspired from https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes?view=powershell-7.5

# Always clobber an existing type accelerator, but
# warn if a type accelerator with the same name exists.

# Get the internal TypeAccelerators class to use its static methods.
$typeAcceleratorsClass = [psobject].Assembly.GetType(
    'System.Management.Automation.TypeAccelerators'
)
$moduleName = (Get-CurrentModule).Name
$existingTypeAccelerators = $typeAcceleratorsClass::Get

foreach ($typeToExport in  @($typesToExportWithNamespace + $typesToExportAsIs))
{
    if ($typeToExport -in $typesToExportAsIs)
    {
        $fullTypeToExport = $TypeToExport
    }
    else
    {
        $fullTypeToExport = '{0}.{1}' -f $moduleName,$TypeToExport
    }

    $type = $TypeToExport -as [System.Type]
    if (-not $type)
    {
        $Message = @(
            "Unable to register type accelerator '$fullTypeToExport' for '$typeToExport'"
            "Type '$typeToExport' not found."
        ) -join ' - '

        throw [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new($Message),
                'TypeAcceleratorTypeNotFound',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $fullTypeToExport
            )
    }
    else
    {
        if ($fullTypeToExport -in $existingTypeAccelerators.Keys)
        {
            $Message = @(
                "Overriding type accelerator '$($fullTypeToExport)' with '$($Type.FullName)'"
                'Accelerator already exists.'
            ) -join ' - '

            Write-Warning -Message $Message
        }
        else
        {
            Write-Verbose -Message "Added type accelerator '$($fullTypeToExport)' for '$($Type.FullName)'."
        }

        $null = $TypeAcceleratorsClass::Add($fullTypeToExport, $Type)
    }
}

# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach ($TypeName in $typesToExportWithNamespace)
    {
        $fullTypeToExport = '{0}.{1}' -f $moduleName,$TypeName
        $null = $TypeAcceleratorsClass::Remove($fullTypeToExport)
    }
}.GetNewClosure()

#endregion
