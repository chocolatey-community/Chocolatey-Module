The cChoco project will be archived and made read-only by June 30, 2026.

Instead of using cChoco, we recommend transitioning to [Chocolatey Module](https://github.com/chocolatey-community/Chocolatey-Module).

Below are a number of common tasks done using **cChoco** resources and their **Chocolatey** Module equivalents.

## cChoco to Chocolatey Module Migration Examples

### Installing Chocolatey CLI

When using **cChoco** to install Chocolatey CLI, you used the `cChocoInstaller` resource and must specify a path into which Chocolatey should be installed:

```powershell
cChocoInstaller InstallChoco {
    InstallDir = 'C:\choco'
}
```

When using the **Chocolatey** Module, you install Chocolatey CLI using the `ChocolateySoftware` resource and the default install location is respected so you do not need to specify an installation directory.

```powershell
ChocolateySoftware InstallChoco {
    Ensure = 'Present'
}
```

If required, you can still provide an installation directory as you previously did when using **cChoco**.

```powershell
ChocolateySoftware InstallChoco {
    Ensure = 'Present'
    InstallationDirectory = 'C:\choco'
}
```

### Installing a Package

To install a package using **cChoco**, you use the `cChocoPackageInstaller` resource.

```powershell
cChocoPackageInstaller InstallGit {
    Ensure = 'Present'
    Name   = 'git'
}
```

The **Chocolatey** Module equivalent of this resource is `ChocolateyPackage`.

```powershell
ChocolateyPackage InstallGit {
    Ensure = 'Present'
    Name   = 'git'
}
```

### Uninstalling a Package

To uninstall a package using **cChoco**, you also use the `cChocoPackageInstaller` resource, just like during an install.

```powershell
cChocoPackageInstaller UninstallGit {
    Ensure = 'Absent'
    Name   = 'git'
}
```

The **Chocolatey** Module equivalent of this resource is also `ChocolateyPackage`.

```powershell
ChocolateyPackage UninstallGit {
    Ensure = 'Absent'
    Name   = 'git'
}
```

### Installing Multiple Packages

To install multiple packages with one task using **cChoco**, you use the `cChocoPackageInstallerSet` resource.

```powershell
cChocoPackageInstallerSet InstallMultiplePackages {
    Ensure = 'Present'
    Name = @(
        "git"
        "skype"
        "7zip"
    )
}
```

There is no direct equivalent of this in **Chocolatey** Module. Instead, you use the `ChocolateyPackage` resource inside a `foreach` loop.

```powershell
$Packages = @(
    "git"
    "skype"
    "7zip"
)

foreach ($Pkg in $Packages) {
    ChocolateyPackage "Install_$Pkg" {
        Ensure = 'Present'
        Name   = $Pkg
    }
}
```

### Adding a Custom Package Source

To manage sources using **cChoco**, you use the `cChocoSource` resource.

```powershell
cChocoSource AddInternalRepo {
    Ensure = 'Present'
    Name   = 'InternalRepo'
    Source = 'https://internal-repo.local/api/v2/'
    Priority  = 1
}
```

The equivalent resource in **Chocolatey** Module is `ChocolateySource`.

```powershell
ChocolateySource AddInternalRepo {
    Ensure    = 'Present'
    Name      = 'InternalRepo'
    Source    = 'https://internal-repo.local/api/v2/'
    Priority  = 1
}
```

### Enabling a Chocolatey Feature

To manage Chocolatey Features with **cChoco**, you use the `cChocoFeature` resource.

```powershell
cChocoFeature EnableGlobalConfirm {
    Ensure      = 'Present'
    FeatureName = 'allowGlobalConfirmation'
}
```

The equivalent resource in the **Chocolatey** Module is `ChocolateyFeature`.

```powershell
ChocolateyFeature EnableGlobalConfirm {
    Ensure = 'Present'
    Name   = 'allowGlobalConfirmation'
}
```

### Configuring a Chocolatey Setting

To configure Chocolatey Settings with **cChoco**, you use the `cChocoConfig` resource.

```powershell
cChocoConfig SetCacheLocation {
    Ensure     = 'Present'
    ConfigName = 'cacheLocation'
    Value      = 'C:\Temp\Choco'
}
```

The equivalent resource in the **Chocolatey** Module is `ChocolateySetting`.

```powershell
ChocolateySetting SetCacheLocation {
    Ensure = 'Present'
    Name   = 'cacheLocation'
    Value  = 'C:\Temp\Choco'
}
```
