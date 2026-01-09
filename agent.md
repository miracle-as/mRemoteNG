# mRemoteNG - Agent Build Guide

## Project Overview

**mRemoteNG** is an open source, multi-protocol, tabbed remote connections manager for Windows.

- **Repository**: https://github.com/mRemoteNG/mRemoteNG
- **Documentation**: https://mremoteng.readthedocs.io/
- **Current Framework**: .NET 6.0 (net6.0-windows7.0)
- **Solution File**: `mRemoteNG.sln`

## Supported Protocols

- RDP (Remote Desktop Protocol)
- VNC (Virtual Network Computing)
- SSH (Secure Shell)
- Telnet
- HTTP/HTTPS
- rlogin
- Raw Socket Connections
- PowerShell remoting

## Build Requirements

### Prerequisites

1. **Visual Studio 2022** (Professional or Community)
   - Required for .NET Framework MSBuild with COM reference support
   - Located at: `C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe`

2. **Microsoft .NET 6.0 SDK**
   - Target framework: `net6.0-windows7.0`

3. **Windows SDK**
   - Required for COM references (mstscax.dll - Remote Desktop ActiveX Control)

### Key Dependencies

- COM Reference: `MSTSCLib` (Windows Terminal Service Client)
- NuGet packages include:
  - System.Data.SqlClient 4.8.3 (has known vulnerabilities - consider updating)
  - ConsoleControl 1.3.0
  - ObjectListView packages
  - Many others (see .csproj files)

## Building the Project

### ⚠️ CRITICAL: Use Visual Studio MSBuild, NOT dotnet CLI

The project **MUST** be built with Visual Studio's MSBuild, not `dotnet build`, due to COM reference dependencies.

### Successful Build Command

```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" mRemoteNG.sln -p:Configuration=Release -p:Platform=x64
```

### Alternative Build Configurations

```powershell
# Debug build
& "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" mRemoteNG.sln -p:Configuration=Debug -p:Platform=x64

# Clean and rebuild
& "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" mRemoteNG.sln -p:Configuration=Release -p:Platform=x64 -t:Clean,Build
```

### Why NOT dotnet CLI?

Running `dotnet build` will fail with:
```
error MSB4803: The task "ResolveComReference" is not supported on the .NET Core version of MSBuild.
Please use the .NET Framework version of MSBuild.
```

This is because the project references Windows COM components (Remote Desktop ActiveX Control) which require .NET Framework MSBuild.

## Project Structure

### Solution Projects

1. **mRemoteNG** - Main application project
2. **ExternalConnectors** - External connector interfaces
3. **mRemoteNGTests** - Unit tests
4. **CustomActions** - Installer custom actions
5. **Installer** - WiX installer project
6. **mRemoteNGSpecs** - Specifications/tests
7. **ObjectListView.NetCore** - Custom ObjectListView implementation

### Build Configurations

- `Debug|x64` - Debug build for x64
- `Release|x64` - Release build for x64
- `Release Installer and Portable|x64` - Special config for distribution builds

## Common Build Issues

### Issue 1: Pre-build TextTransform Error

**Error**: `*Undefined*TextTransform.exe' is not recognized`

**Cause**: The pre-build event tries to run TextTransform.exe from Visual Studio's devenv.exe directory, which may not be found.

**Impact**: This is part of the T4 template transformation for AssemblyInfo. In non-AppVeyor builds, the script continues despite this error.

**Workaround**: This error can generally be ignored for local builds as the AssemblyInfo is already generated.

### Issue 2: COM Reference Warnings

**Warning**: Multiple MSB3305 warnings about COM marshaling for `MSTSCLib`

**Cause**: COM interop with Remote Desktop ActiveX Control has some methods that cannot be marshaled safely.

**Impact**: These are warnings only and don't prevent successful compilation. The affected methods use pointers and may require unsafe code.

### Issue 3: Package Vulnerability Warnings

**Warnings**:
- NU1902: System.Data.SqlClient 4.8.3 - moderate severity vulnerability
- NU1903: System.Data.SqlClient 4.8.3 - high severity vulnerability

**Recommendation**: Consider upgrading to Microsoft.Data.SqlClient for better security.

## Build Output

### Successful Build Indicators

```
Build SUCCEEDED.
    91 Warning(s)
    0 Error(s)
Time Elapsed 00:00:13.96
```

### Output Locations

- **Main executable**: `mRemoteNG\bin\x64\Release\net6.0-windows\mRemoteNG.exe`
- **ExternalConnectors**: `ExternalConnectors\bin\x64\Release\net6.0-windows\ExternalConnectors.dll`
- **Tests**: `mRemoteNGTests\bin\x64\Release\net6.0-windows\mRemoteNGTests.dll`

## Git Workflow Notes

### Current State (as of 2026-01-09)

- **Current HEAD**: `aee497de` - "nuget updates"
- **Branch**: Likely `develop` or `main`

### Recent History

Previous commits from 2026-01-09 were reverted:
- 09858f12 - Reapply "Complete .NET 8 upgrade: remove HTTP/HTTPS/SSH protocols, update all serializers"
- 11726843 - Revert "Complete .NET 8 upgrade: remove HTTP/HTTPS/SSH protocols, update all serializers"
- 8e14970b - Complete .NET 8 upgrade: remove HTTP/HTTPS/SSH protocols, update all serializers"
- deccd3b3 - Fix COM reference build error and add build script

These were reverted due to build issues.

## Testing

### Running Unit Tests

```powershell
# Run tests using Visual Studio Test Platform
dotnet test mRemoteNGTests\mRemoteNGTests.csproj --configuration Release
```

## Development Notes

### Code Quality

- Project uses C# with .NET 6.0
- Contains some legacy code patterns (Thread.Abort, obsolete APIs)
- Some areas use COM interop requiring unsafe code
- Uses Windows Forms for UI

### Known Technical Debt

1. **Thread.Abort usage** (SYSLIB0006) - Should be replaced with cancellation tokens
2. **BinaryFormatter usage** (SYSLIB0011) - Obsolete serialization, should migrate to JSON/XML
3. **COM reference marshaling** - Some unsafe pointer operations required
4. **Package vulnerabilities** - System.Data.SqlClient needs updating

## Troubleshooting

### Build Fails with MSB4803

**Solution**: Use Visual Studio MSBuild instead of dotnet CLI (see Build Commands above)

### Build Fails with Missing COM References

**Solution**: Ensure Windows SDK is installed and mstscax.dll is registered:
```powershell
regsvr32 C:\Windows\System32\mstscax.dll
```

### Pre-build Event Fails

**Solution**: If building locally (not on AppVeyor), this can usually be ignored. The error occurs because TextTransform.exe is not found, but AssemblyInfo.cs is already present.

## Continuous Integration

The project uses **AppVeyor** for CI/CD:
- Stable: ![Build status](https://ci.appveyor.com/api/projects/status/rqwxjxldail7btcf?svg=true)
- Preview: ![Build status](https://ci.appveyor.com/api/projects/status/rqwxjxldail7btcf/branch/preview?svg=true)
- Nightly: ![Build status](https://ci.appveyor.com/api/projects/status/rqwxjxldail7btcf/branch/develop?svg=true)

## Quick Reference Commands

```powershell
# Build Release
& "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" mRemoteNG.sln -p:Configuration=Release -p:Platform=x64

# Clean Solution
& "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" mRemoteNG.sln -t:Clean

# Restore NuGet Packages
dotnet restore mRemoteNG.sln

# Check Git Status
git status
git log --oneline -10

# Run Application (after build)
& "mRemoteNG\bin\x64\Release\net6.0-windows\mRemoteNG.exe"
```

## Additional Resources

- [Project Documentation](https://mremoteng.readthedocs.io/)
- [Contributing Guidelines](https://github.com/mRemoteNG/mRemoteNG/blob/develop/CONTRIBUTING.md)
- [Issue Tracker](https://github.com/mRemoteNG/mRemoteNG/issues)
- [Reddit Community](https://www.reddit.com/r/mRemoteNG/)

---

**Last Updated**: 2026-01-09  
**Build Status**: ✅ Building successfully with Visual Studio MSBuild  
**Platform**: Windows x64 only
