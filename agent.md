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

## Credential and Password Management Architecture

### Overview

mRemoteNG has a sophisticated credential management system with support for external password manager integrations.

### Core Architecture

#### 1. Credential Records (`ICredentialRecord`)

**Location**: `mRemoteNG\Credential\`

Core credential object containing:
- `Guid Id` - Unique identifier
- `string Title` - Display name  
- `string Username`
- `SecureString Password` - In-memory security
- `string Domain`

#### 2. Credential Repositories (`ICredentialRepository`)

**Location**: `mRemoteNG\Credential\Repositories\`

- Manages collections of credentials
- XML-based storage (`XmlCredentialRepository`)
- Encrypted with user-provided master key
- Multiple repositories supported
- Each repository has: ID, Title, TypeName, Source path, Encryption key

**Key Classes**:
- `CredentialRepositoryList` - Central catalog of all repositories
- `CredentialServiceFacade` - High-level API for credential operations
- `XmlCredentialRepositoryFactory` - Creates repository instances

#### 3. Encryption System

**Location**: `mRemoteNG\Security\`

**Modern Encryption** (`AeadCryptographyProvider`):
- Uses BouncyCastle library
- Supports: AES, Twofish, Serpent engines
- Cipher modes: GCM, CCM, EAX
- PBKDF2 key derivation with configurable iterations
- 256-bit keys, 128-bit nonces, 128-bit MACs

**Legacy Encryption** (`LegacyRijndaelCryptographyProvider`):
- .NET AES with MD5 key derivation
- Maintained for backward compatibility

**Encryption Decorators**:
- `XmlCredentialPasswordEncryptorDecorator` - Encrypts before XML save
- `XmlCredentialPasswordDecryptorDecorator` - Decrypts after XML load

#### 4. Connection Integration

**Location**: `mRemoteNG\Connection\`

Connections (`ConnectionInfo`) store credentials as:
- `string Username`
- `string Password`
- `string Domain`
- **`string UserViaAPI`** - External credential reference (e.g., "SSAPI:1234")

### External Password Manager Integration

#### Current Integration: Thycotic Secret Server

**Location**: `ExternalConnectors\TSS\`

**Implementation**:
- `SecretServerInterface` - Main interface class
- OAuth2 and Windows SSO authentication
- REST API client (auto-generated from NSwag)
- `SecretServerRestClient` - HTTP communication

**Usage Pattern**:
1. Set connection's `UserViaAPI` field to `"SSAPI:xxxx"` (xxxx = secret ID)
2. At connection time, protocol fetches credentials from API
3. Retrieved credentials populate Username/Password/Domain
4. Used in: `RdpProtocol6.cs`, `PuttyBase.cs` (SSH/Telnet)

**Integration Points**:
```csharp
// In protocol implementations (e.g., RDP, SSH)
if (!string.IsNullOrEmpty(connectionInfo.UserViaAPI))
{
    if (connectionInfo.UserViaAPI.StartsWith("SSAPI:"))
    {
        string secretId = connectionInfo.UserViaAPI.Substring(6);
        SecretServerInterface.FetchSecretFromServer(
            secretId, 
            out username, 
            out password, 
            out domain
        );
    }
}
```

#### Placeholder: 1Password Integration

**Location**: `ExternalConnectors\OP\` (directory exists but empty)

### Key Extension Points for 1Password

#### Option 1: External Connector Pattern (Recommended)

**Steps**:
1. Create `ExternalConnectors\OnePassword\` directory
2. Implement `OnePasswordInterface` class similar to `SecretServerInterface`
3. Add methods:
   - `FetchSecretFromVault(string itemId, out string username, out string password, out string domain)`
   - `Authenticate()` - Handle 1Password CLI or Connect Server authentication
4. Modify protocol implementations to check for `"OP:"` prefix in `UserViaAPI`
5. Call 1Password API/CLI to retrieve credentials at connection time

**Files to Modify**:
- `mRemoteNG\Protocol\RDP\RdpProtocol6.cs` - Add OP check
- `mRemoteNG\Protocol\PuTTY\PuttyBase.cs` - Add OP check
- Create new project: `ExternalConnectors\OnePassword\OnePassword.csproj`

**UserViaAPI Format**: `"OP:vault/item"` or `"OP:itemId"`

#### Option 2: Custom Credential Repository

**Steps**:
1. Implement `ICredentialRepository` interface
2. Create `OnePasswordCredentialRepository` class
3. Override `LoadCredentials()` to fetch from 1Password
4. Register repository type in `CredentialRepositoryList`

**Benefits**: 
- Credentials visible in credential manager UI
- Centralized management
- No per-connection configuration

**Drawbacks**:
- More complex implementation
- Requires 1Password API/CLI polling or sync

#### Option 3: Hybrid Approach

Combine both:
- Custom repository for credential listing/browsing
- External connector for runtime retrieval
- Best user experience but most complex

### 1Password Integration Options

#### A. 1Password CLI (Recommended)

**Overview**:
- Official command-line tool (`op.exe`)
- Cross-platform support (Windows, Mac, Linux)
- Integrates with 1Password Desktop App for authentication
- Uses biometric unlock (Touch ID, Windows Hello, system auth)

**Installation**:
- Windows: `winget install AgileBits.1PasswordCLI` or manual download
- Requires 1Password Desktop App for seamless integration
- Enable "Integrate with 1Password CLI" in app settings

**Authentication Flow**:
1. User installs 1Password CLI and Desktop App
2. Enables app integration in Settings → Developer
3. First CLI command prompts for biometric authentication
4. Session persists while desktop app is unlocked
5. No password needed after initial setup

**Key Commands**:
```bash
# Check authentication status
op whoami

# List all vaults
op vault list

# List login items
op item list --categories Login --format json

# Get specific item
op item get "Production Server" --fields username,password --format json

# Get password only
op item get "db-server" --fields password

# Use secret references (alternative syntax)
op read "op://Private/Production Server/password"
```

**Command Output Example**:
```json
{
  "id": "abc123def456",
  "title": "Production Server",
  "category": "LOGIN",
  "fields": [
    {"label": "username", "value": "admin"},
    {"label": "password", "value": "secretpass123"}
  ]
}
```

**Process Integration Pattern**:
```csharp
// Execute 1Password CLI from C#
Process process = new Process();
process.StartInfo.FileName = "op.exe";
process.StartInfo.Arguments = "item get \"itemId\" --fields username,password --format json";
process.StartInfo.UseShellExecute = false;
process.StartInfo.RedirectStandardOutput = true;
process.StartInfo.CreateNoWindow = true;
process.Start();

string output = process.StandardOutput.ReadToEnd();
process.WaitForExit();

// Parse JSON output to extract credentials
```

**Pros**:
- No additional infrastructure needed
- Leverages existing 1Password security (biometric unlock)
- Works with any 1Password account type (Individual, Family, Business)
- Official tool with active support
- Session management handled by desktop app
- User-friendly - same credentials available in app and CLI

**Cons**:
- Requires 1Password CLI and Desktop App installation
- Process execution overhead (~100-300ms per call)
- User must be signed into 1Password
- Windows/Mac/Linux only (desktop OS requirement)

**Performance Considerations**:
- Cache credentials in memory during mRemoteNG session
- Only call CLI once per connection establishment
- Implement timeout handling for unresponsive CLI

#### B. 1Password Connect Server

**Overview**:
- Server-based REST API for automation and integrations
- Designed for headless/server environments
- Requires dedicated Connect Server deployment
- Uses service account tokens for authentication

**Requirements**:
- 1Password Business or Teams plan
- Docker or Kubernetes for Connect Server
- Service account token from 1Password

**API Pattern**:
```http
GET /v1/vaults/{vault_id}/items/{item_id}
Authorization: Bearer <service_account_token>
```

**Pros**:
- No desktop app required
- Designed for API integrations
- Centralized for enterprise deployments
- Better for server/headless scenarios

**Cons**:
- Requires additional infrastructure (Connect Server)
- Only available with Business/Teams plans
- More complex setup
- Service account token management

**Use Case**: Enterprise/team deployments with centralized credential management

#### C. 1Password SDK

**Status**: .NET SDK in development, not yet available

**Future Option**:
- Official .NET library for direct integration
- Would provide native API access
- Most seamless integration possible

**Current Status**: Monitor 1Password developer documentation for SDK releases

### Recommended Implementation: 1Password CLI Integration

#### Architecture

```
mRemoteNG Connection
    └── UserViaAPI: "OP:item-id" or "OP:vault/item-name"
        └── OnePasswordInterface.FetchCredentials()
            └── Execute: op item get <item> --fields username,password --format json
                └── 1Password CLI (op.exe)
                    └── 1Password Desktop App
                        └── Biometric Authentication
                            └── 1Password Vaults
```

#### Implementation Steps

**Phase 1: Core Integration**
- [ ] Create `ExternalConnectors\OnePassword\OnePassword.csproj`
- [ ] Implement `OnePasswordInterface.cs`:
  - [ ] `CheckCLIAvailable()` - Verify op.exe in PATH
  - [ ] `IsAuthenticated()` - Execute `op whoami`, check exit code
  - [ ] `FetchCredentials(string itemRef, out username, out password, out domain)`
  - [ ] `ExecuteCLI(string args)` - Process execution wrapper
  - [ ] `ParseJSONResponse(string json)` - Extract credentials from JSON
- [ ] Add error handling:
  - [ ] CLI not found → Show setup instructions
  - [ ] Not authenticated → Prompt user to sign in with desktop app
  - [ ] Item not found → Show helpful error message
  - [ ] Parse failures → Log and graceful fallback

**Phase 2: Protocol Integration**
- [ ] Modify `mRemoteNG\Protocol\RDP\RdpProtocol6.cs`:
  ```csharp
  if (connectionInfo.UserViaAPI?.StartsWith("OP:") == true)
  {
      string itemRef = connectionInfo.UserViaAPI.Substring(3);
      OnePasswordInterface.FetchCredentials(itemRef, out username, out password, out domain);
  }
  ```
- [ ] Modify `mRemoteNG\Protocol\PuTTY\PuttyBase.cs` (SSH/Telnet)
- [ ] Modify other protocols as needed (VNC, HTTP/HTTPS)

**Phase 3: User Interface**
- [ ] Create `ExternalConnectors\OnePassword\OPConnectionForm.cs`:
  - [ ] Browse 1Password vaults
  - [ ] Search items by name
  - [ ] Select item → populate `UserViaAPI` field
  - [ ] Test connection button
- [ ] Add settings page for 1Password:
  - [ ] Custom CLI path (default: search PATH)
  - [ ] Default vault selection
  - [ ] Enable/disable caching
  - [ ] Cache timeout configuration

**Phase 4: Optimization**
- [ ] Implement in-memory credential caching:
  - [ ] Cache credentials for session duration
  - [ ] Cache key: `UserViaAPI` value
  - [ ] Invalidate on timeout or manual refresh
- [ ] Add background credential refresh
- [ ] Optimize CLI calls (reuse process if possible)

**Phase 5: Testing & Documentation**
- [ ] Unit tests for `OnePasswordInterface`
- [ ] Integration tests with actual 1Password CLI
- [ ] Test with RDP, SSH, VNC, Telnet connections
- [ ] Test error scenarios (CLI missing, not authenticated, etc.)
- [ ] Write user documentation:
  - [ ] Installation guide (1Password app + CLI)
  - [ ] Configuration steps
  - [ ] How to link connections to 1Password items
- [ ] Write developer documentation

#### UserViaAPI Format

**Recommended Formats**:
1. `OP:<item-id>` - Direct item ID (fastest, most reliable)
   - Example: `OP:abc123def456ghi789`
   
2. `OP:<vault>/<item-title>` - Human-readable reference
   - Example: `OP:Private/Production Server`
   - Example: `OP:Work/Database Credentials`

**Parsing Logic**:
```csharp
string itemRef = connectionInfo.UserViaAPI.Substring(3); // Remove "OP:" prefix

if (Guid.TryParse(itemRef, out _) || itemRef.Length == 26)
{
    // Direct item ID
    command = $"item get {itemRef}";
}
else
{
    // Vault/Title format - requires escaping
    command = $"item get \"{itemRef}\"";
}
```

### Code Examples

#### OnePasswordInterface.cs (Skeleton)

```csharp
using System;
using System.Diagnostics;
using System.Text.Json;
using mRemoteNG.Messages;

namespace ExternalConnectors.OnePassword
{
    public static class OnePasswordInterface
    {
        private static readonly string DefaultCLIPath = "op"; // Will search PATH
        
        /// <summary>
        /// Checks if 1Password CLI is available
        /// </summary>
        public static bool IsCLIAvailable()
        {
            try
            {
                var (exitCode, _) = ExecuteCLI("--version");
                return exitCode == 0;
            }
            catch
            {
                return false;
            }
        }
        
        /// <summary>
        /// Checks if user is authenticated with 1Password
        /// </summary>
        public static bool IsAuthenticated()
        {
            try
            {
                var (exitCode, output) = ExecuteCLI("whoami");
                return exitCode == 0;
            }
            catch
            {
                return false;
            }
        }
        
        /// <summary>
        /// Fetches credentials from 1Password
        /// </summary>
        /// <param name="itemRef">Item ID or "vault/title" format</param>
        /// <param name="username">Retrieved username</param>
        /// <param name="password">Retrieved password</param>
        /// <param name="domain">Retrieved domain (if available)</param>
        /// <returns>True if successful</returns>
        public static bool FetchCredentials(
            string itemRef, 
            out string username, 
            out string password, 
            out string domain)
        {
            username = string.Empty;
            password = string.Empty;
            domain = string.Empty;
            
            try
            {
                // Check if CLI is available
                if (!IsCLIAvailable())
                {
                    Runtime.MessageCollector?.AddMessage(MessageClass.ErrorMsg, 
                        "1Password CLI not found. Please install from https://1password.com/downloads/command-line/");
                    return false;
                }
                
                // Check authentication
                if (!IsAuthenticated())
                {
                    Runtime.MessageCollector?.AddMessage(MessageClass.ErrorMsg,
                        "Not signed in to 1Password. Please open 1Password app and sign in.");
                    return false;
                }
                
                // Build command
                string command = $"item get \"{itemRef}\" --fields label=username,label=password --format json";
                
                // Execute CLI
                var (exitCode, output) = ExecuteCLI(command);
                
                if (exitCode != 0)
                {
                    Runtime.MessageCollector?.AddMessage(MessageClass.ErrorMsg,
                        $"Failed to retrieve item '{itemRef}' from 1Password: {output}");
                    return false;
                }
                
                // Parse JSON response
                return ParseCredentialsFromJSON(output, out username, out password, out domain);
            }
            catch (Exception ex)
            {
                Runtime.MessageCollector?.AddMessage(MessageClass.ErrorMsg,
                    $"1Password integration error: {ex.Message}");
                return false;
            }
        }
        
        /// <summary>
        /// Executes 1Password CLI command
        /// </summary>
        private static (int exitCode, string output) ExecuteCLI(string arguments)
        {
            Process process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = DefaultCLIPath,
                    Arguments = arguments,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Hidden
                }
            };
            
            process.Start();
            string output = process.StandardOutput.ReadToEnd();
            string error = process.StandardError.ReadToEnd();
            process.WaitForExit(5000); // 5 second timeout
            
            int exitCode = process.ExitCode;
            string result = !string.IsNullOrEmpty(output) ? output : error;
            
            return (exitCode, result);
        }
        
        /// <summary>
        /// Parses JSON output from 1Password CLI
        /// </summary>
        private static bool ParseCredentialsFromJSON(
            string json, 
            out string username, 
            out string password, 
            out string domain)
        {
            username = string.Empty;
            password = string.Empty;
            domain = string.Empty;
            
            try
            {
                using JsonDocument doc = JsonDocument.Parse(json);
                JsonElement root = doc.RootElement;
                
                // Parse fields array
                if (root.TryGetProperty("fields", out JsonElement fields))
                {
                    foreach (JsonElement field in fields.EnumerateArray())
                    {
                        if (field.TryGetProperty("label", out JsonElement label) &&
                            field.TryGetProperty("value", out JsonElement value))
                        {
                            string labelText = label.GetString()?.ToLower();
                            string valueText = value.GetString() ?? string.Empty;
                            
                            switch (labelText)
                            {
                                case "username":
                                    username = valueText;
                                    break;
                                case "password":
                                    password = valueText;
                                    break;
                                case "domain":
                                    domain = valueText;
                                    break;
                            }
                        }
                    }
                }
                
                return !string.IsNullOrEmpty(username) || !string.IsNullOrEmpty(password);
            }
            catch (Exception ex)
            {
                Runtime.MessageCollector?.AddMessage(MessageClass.ErrorMsg,
                    $"Failed to parse 1Password response: {ex.Message}");
                return false;
            }
        }
    }
}
```

#### Protocol Integration Example (RdpProtocol6.cs)

```csharp
// Add to existing credential resolution logic
private void SetCredentials()
{
    string username = _connectionInfo.Username;
    string password = _connectionInfo.Password;
    string domain = _connectionInfo.Domain;
    
    // Check for external API credential reference
    if (!string.IsNullOrEmpty(_connectionInfo.UserViaAPI))
    {
        // Existing: Thycotic Secret Server
        if (_connectionInfo.UserViaAPI.StartsWith("SSAPI:"))
        {
            string secretId = _connectionInfo.UserViaAPI.Substring(6);
            SecretServerInterface.FetchSecretFromServer(secretId, out username, out password, out domain);
        }
        // NEW: 1Password integration
        else if (_connectionInfo.UserViaAPI.StartsWith("OP:"))
        {
            string itemRef = _connectionInfo.UserViaAPI.Substring(3);
            ExternalConnectors.OnePassword.OnePasswordInterface.FetchCredentials(
                itemRef, 
                out username, 
                out password, 
                out domain
            );
        }
    }
    
    // Apply credentials to RDP connection
    if (!string.IsNullOrEmpty(domain))
        _client.AdvancedSettings9.Domain = domain;
        
    _client.UserName = username;
    _client.AdvancedSettings9.ClearTextPassword = password;
}
```

```
mRemoteNG\
├── Credential\
│   ├── ICredentialRecord.cs
│   ├── CredentialRecord.cs
│   ├── ICredentialRepository.cs
│   ├── CredentialServiceFacade.cs
│   └── Repositories\
│       ├── XmlCredentialRepository.cs
│       └── XmlCredentialRepositoryFactory.cs
├── Connection\
│   ├── ConnectionInfo.cs (has UserViaAPI field)
│   └── AbstractConnectionRecord.cs
├── Protocol\
│   ├── RDP\
│   │   └── RdpProtocol6.cs (needs modification)
│   └── PuTTY\
│       └── PuttyBase.cs (needs modification)
└── Security\
    ├── ICryptographyProvider.cs
    └── AeadCryptographyProvider.cs

ExternalConnectors\
├── TSS\
│   ├── SecretServerInterface.cs (reference implementation)
│   ├── SecretServerRestClient.cs
│   └── SSConnectionForm.cs (UI)
└── OnePassword\ (to be created)
    ├── OnePasswordInterface.cs
    ├── OnePasswordClient.cs
    └── OPConnectionForm.cs (UI)
```

### Security Considerations

1. **No Local Storage**: Never store 1Password credentials in mRemoteNG files
   - Only store reference strings like "OP:item-id" in `UserViaAPI` field
   - No passwords cached to disk
   
2. **Session Management**: 
   - 1Password CLI relies on desktop app authentication
   - Session persists as long as desktop app is unlocked
   - No password prompts once app integration enabled
   
3. **Memory Security**:
   - Use `SecureString` for in-memory credential caching
   - Clear cached credentials on mRemoteNG exit
   - Implement cache timeout (default: 15 minutes)
   
4. **Error Handling**: 
   - Graceful fallback when 1Password unavailable
   - Never log sensitive credential values
   - Clear error messages for troubleshooting
   
5. **Audit Logging**: 
   - Log credential access events (which item accessed, when)
   - Don't log actual credential values
   - Respect 1Password's own audit logging
   
6. **User Context**: 
   - Respect 1Password user permissions and vault access
   - Each user's credentials isolated to their 1Password account
   - No shared credential exposure
   
7. **Process Security**:
   - CLI output piped directly to memory, not temp files
   - Process execution with hidden window
   - Timeout protection against hanging processes

### Alternative: Credential Repository Approach

Instead of (or in addition to) the `UserViaAPI` external connector pattern, you could implement a full `ICredentialRepository` for 1Password:

#### OnePasswordCredentialRepository.cs

```csharp
public class OnePasswordCredentialRepository : ICredentialRepository
{
    private readonly List<ICredentialRecord> _credentials = new();
    
    public IList<ICredentialRecord> CredentialRecords => _credentials.AsReadOnly();
    public bool IsLoaded { get; private set; }
    
    public void LoadCredentials(SecureString key)
    {
        // Execute: op item list --categories Login --format json
        // Parse JSON to populate _credentials list
        // Each 1Password item becomes a CredentialRecord
        
        _credentials.Clear();
        
        var (exitCode, output) = ExecuteCLI("item list --categories Login --format json");
        if (exitCode == 0)
        {
            var items = JsonSerializer.Deserialize<List<OnePasswordItem>>(output);
            foreach (var item in items)
            {
                _credentials.Add(new CredentialRecord
                {
                    Id = Guid.Parse(item.id),
                    Title = item.title,
                    // Username/Password loaded on-demand when accessed
                });
            }
            IsLoaded = true;
        }
    }
    
    public void SaveCredentials(SecureString key)
    {
        // Not supported - credentials managed in 1Password app
        throw new NotSupportedException("1Password credentials must be managed in the 1Password app");
    }
    
    public void UnloadCredentials()
    {
        _credentials.Clear();
        IsLoaded = false;
    }
}
```

**Benefits of Repository Approach**:
- Credentials appear in mRemoteNG's credential manager UI
- Users can browse and search 1Password items within mRemoteNG
- Centralized credential management
- No manual `UserViaAPI` field editing

**Drawbacks**:
- More complex implementation
- Requires periodic sync/refresh from 1Password
- May need to cache credential list
- Still need on-demand password retrieval (security best practice)

**Recommended**: Use both approaches
- Repository for browsing/discovery
- External connector for runtime retrieval
- Best of both worlds

### Relevant File Paths

```
mRemoteNG\
├── Credential\
│   ├── ICredentialRecord.cs
│   ├── CredentialRecord.cs
│   ├── ICredentialRepository.cs
│   ├── CredentialServiceFacade.cs
│   └── Repositories\
│       ├── XmlCredentialRepository.cs
│       └── XmlCredentialRepositoryFactory.cs
├── Connection\
│   ├── ConnectionInfo.cs (has UserViaAPI field)
│   └── AbstractConnectionRecord.cs
├── Protocol\
│   ├── RDP\
│   │   └── RdpProtocol6.cs (needs modification for OP: support)
│   └── PuTTY\
│       └── PuttyBase.cs (needs modification for OP: support)
└── Security\
    ├── ICryptographyProvider.cs
    └── AeadCryptographyProvider.cs

ExternalConnectors\
├── TSS\
│   ├── SecretServerInterface.cs (reference implementation)
│   ├── SecretServerRestClient.cs
│   └── SSConnectionForm.cs (UI example)
└── OnePassword\ (to be created)
    ├── OnePassword.csproj (new .NET 6 class library)
    ├── OnePasswordInterface.cs (main API - implement FetchCredentials)
    ├── OnePasswordCLI.cs (CLI execution wrapper)
    ├── OnePasswordClient.cs (JSON parsing, caching)
    ├── OnePasswordCredentialRepository.cs (optional: ICredentialRepository impl)
    ├── OPConnectionForm.cs (UI for browsing/selecting items)
    └── OPSettingsForm.cs (configuration page)
```

### Quick Start Guide for Users

**Prerequisites**:
1. 1Password subscription (Individual, Family, Business, or Teams)
2. 1Password Desktop App installed
3. 1Password CLI installed

**Installation Steps**:
1. Install 1Password Desktop App from https://1password.com/downloads
2. Sign in to your 1Password account in the desktop app
3. Install 1Password CLI:
   ```powershell
   winget install AgileBits.1PasswordCLI
   ```
4. Enable app integration:
   - Open 1Password app
   - Settings → Developer
   - Check "Integrate with 1Password CLI"
5. (Windows) Enable Windows Hello for biometric authentication

**Using with mRemoteNG** (once implemented):
1. Create connection in mRemoteNG (RDP, SSH, etc.)
2. In connection properties, set `UserViaAPI` to:
   - `OP:item-id` (using item's unique ID), or
   - `OP:vault-name/item-title` (human-readable reference)
3. Connect - mRemoteNG will retrieve credentials from 1Password
4. First connection may prompt for biometric authentication
5. Subsequent connections use cached session

**Example**:
- Create login item "Production Server" in 1Password Private vault
- In mRemoteNG, set connection's `UserViaAPI` to `OP:Private/Production Server`
- Connect - credentials retrieved automatically

### Development Resources

**1Password Documentation**:
- CLI Reference: https://developer.1password.com/docs/cli/reference/
- CLI Get Started: https://developer.1password.com/docs/cli/get-started/
- Secret References: https://developer.1password.com/docs/cli/secret-references/
- App Integration: https://developer.1password.com/docs/cli/app-integration/

**Existing mRemoteNG Reference**:
- Thycotic Secret Server integration: `ExternalConnectors\TSS\SecretServerInterface.cs`
- Shows complete pattern for external credential providers
- OAuth2 authentication, REST API calls, error handling

**Testing Commands**:
```bash
# Verify CLI installation
op --version

# Check authentication
op whoami

# List vaults
op vault list

# List login items
op item list --categories Login

# Get specific item (test data retrieval)
op item get "test-connection" --fields username,password --format json
```

---

**Last Updated**: 2026-01-09  
**Build Status**: ✅ Building successfully with Visual Studio MSBuild  
**Platform**: Windows x64 only
