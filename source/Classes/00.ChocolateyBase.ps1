class ChocolateyBase
{
    static [string] GetInstanceJsonSchema([type] $ResourceType)
    {
        $schema = [ChocolateyBase]::NewClassSchema(
            $ResourceType,
            $true
        )

        return ($schema | ConvertTo-Json -Depth 20 -Compress)
    }

    hidden static [object] NewClassSchema(
        [type] $Type,
        [bool] $IsRoot
    )
    {
        $isDscResource = $Type.GetCustomAttributes($false).Where{
            $_ -is [System.Management.Automation.DscResourceAttribute]
        }.Count -gt 0

        $schema = if ($IsRoot)
        {
            [ordered]@{
                '$schema'   = 'https://json-schema.org/draft/2020-12/schema'
                type        = 'object'
                properties  = [ordered]@{}
            }
        }
        else
        {
            [ordered]@{
                type       = 'object'
                properties = [ordered]@{}
            }
        }

        $requiredProperties = [System.Collections.Generic.List[string]]::new()
        $defaultInstance = $null

        if ($isDscResource)
        {
            $defaultInstance = $Type::new()
        }

        $properties = $Type.GetProperties(
            [System.Reflection.BindingFlags]::Instance -bor
            [System.Reflection.BindingFlags]::Public -bor
            [System.Reflection.BindingFlags]::DeclaredOnly
        ) | Sort-Object -Property MetadataToken

        foreach ($property in $properties)
        {
            $dscPropertyAttribute = $property.GetCustomAttributes($false).Where{
                $_ -is [System.Management.Automation.DscPropertyAttribute]
            } | Select-Object -First 1

            $isRequired = [ChocolateyBase]::IsRequiredSchemaProperty(
                $property,
                $dscPropertyAttribute,
                $isDscResource,
                $defaultInstance
            )

            $propertySchema = [ChocolateyBase]::NewPropertySchema(
                $property.PropertyType,
                $isRequired
            )

            if ($null -eq $dscPropertyAttribute)
            {
                $propertySchema['readOnly'] = $true
            }

            $schema.properties[$property.Name] = $propertySchema

            if ($isRequired)
            {
                $null = $requiredProperties.Add($property.Name)
            }
        }

        if ($requiredProperties.Count -gt 0)
        {
            $schema['required'] = @($requiredProperties)
        }

        return $schema
    }

    hidden static [bool] IsRequiredSchemaProperty(
        [System.Reflection.PropertyInfo] $Property,
        [System.Management.Automation.DscPropertyAttribute] $DscPropertyAttribute,
        [bool] $IsDscResource,
        [object] $DefaultInstance
    )
    {
        if (-not $IsDscResource)
        {
            return $true
        }

        if ($null -eq $DscPropertyAttribute)
        {
            return $false
        }

        if ($DscPropertyAttribute.Key)
        {
            return $true
        }

        if (-not $DscPropertyAttribute.Mandatory)
        {
            return $false
        }

        if ($null -eq $DefaultInstance)
        {
            return $true
        }

        if ($Property.PropertyType.IsValueType -and
            $null -eq [System.Nullable]::GetUnderlyingType($Property.PropertyType))
        {
            return $false
        }

        return $null -eq $Property.GetValue($DefaultInstance)
    }

    hidden static [object] NewPropertySchema(
        [type] $PropertyType,
        [bool] $IsRequired
    )
    {
        $nullableType = [System.Nullable]::GetUnderlyingType($PropertyType)

        if ($null -ne $nullableType)
        {
            $schema = [ChocolateyBase]::NewPropertySchema(
                $nullableType,
                $true
            )

            return [ChocolateyBase]::AddNullType($schema)
        }

        if ($PropertyType.IsArray)
        {
            $schema = [ordered]@{
                type  = 'array'
                items = [ChocolateyBase]::NewPropertySchema(
                    $PropertyType.GetElementType(),
                    $true
                )
            }

            if (-not $IsRequired)
            {
                $schema = [ChocolateyBase]::AddNullType($schema)
            }

            return $schema
        }

        if ($PropertyType.IsEnum)
        {
            return [ordered]@{
                type = 'string'
                enum = [System.Enum]::GetNames($PropertyType)
            }
        }

        switch ($PropertyType.FullName)
        {
            'System.String'
            {
                $schema = [ordered]@{
                    type = 'string'
                }

                if (-not $IsRequired)
                {
                    $schema = [ChocolateyBase]::AddNullType($schema)
                }

                return $schema
            }

            'System.Boolean'
            {
                return [ordered]@{
                    type = 'boolean'
                }
            }

            'System.Int32'
            {
                return [ordered]@{
                    type = 'integer'
                }
            }

            'System.Int64'
            {
                return [ordered]@{
                    type = 'integer'
                }
            }

            'System.Collections.Hashtable'
            {
                $schema = [ordered]@{
                    type                 = 'object'
                    additionalProperties = $true
                }

                if (-not $IsRequired)
                {
                    $schema = [ChocolateyBase]::AddNullType($schema)
                }

                return $schema
            }

            'System.Management.Automation.PSCredential'
            {
                $schema = [ordered]@{
                    type = 'object'
                }

                if (-not $IsRequired)
                {
                    $schema = [ChocolateyBase]::AddNullType($schema)
                }

                return $schema
            }
        }

        if ($PropertyType.IsClass)
        {
            $schema = [ChocolateyBase]::NewClassSchema(
                $PropertyType,
                $false
            )

            if (-not $IsRequired)
            {
                $schema = [ChocolateyBase]::AddNullType($schema)
            }

            return $schema
        }

        $schema = [ordered]@{
            type = 'object'
        }

        if (-not $IsRequired)
        {
            $schema = [ChocolateyBase]::AddNullType($schema)
        }

        return $schema
    }

    hidden static [object] AddNullType([object] $Schema)
    {
        if ($Schema.type -is [System.Array])
        {
            if ('null' -notin $Schema.type)
            {
                $Schema.type = @($Schema.type + 'null')
            }
        }
        else
        {
            $Schema.type = @($Schema.type, 'null')
        }

        return $Schema
    }
}
