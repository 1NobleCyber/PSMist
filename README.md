# PSMist

PSMist is a PowerShell module for interacting with the Juniper Mist Cloud API. This module allows you to authenticate, retrieve information about your organizations and sites, and manage elements within your Mist environment.

## Installation

You can install the module locally by importing the module manifest:

```powershell
Import-Module ./src/PSMist.psd1 -Force
```

## Usage

Before running most commands, you must establish a session by authenticating with Mist.

### Authentication

If your account has Two-Factor Authentication (2FA) enabled, you can provide your TOTP code along with your credentials:

```powershell
$cred = Get-Credential
Connect-Mist -Credential $cred -TOTP "123456"
```

If 2FA is not required, simply omit the `-TOTP` parameter.

### Read Operations

Once authenticated, you can read data from your Mist environment:

- **Get the current user's details:**
  ```powershell
  Get-MistSelf
  ```

- **Get a list of your organizations:**
  ```powershell
  Get-MistOrg
  ```

- **Get sites within an organization:**
  ```powershell
  Get-MistSite -OrgId "your-org-id"
  ```

### Write Operations

The module includes commands to make changes to your environment:

- **Create a new site:**
  ```powershell
  New-MistSite -OrgId "your-org-id" -Name "Branch Office" -Timezone "America/New_York"
  ```

- **Delete a site:**
  ```powershell
  Remove-MistSite -SiteId "your-site-id"
  ```

## Structure

This module follows a standard PowerShell module structure:
- `src/PSMist.psd1`: Module manifest
- `src/PSMist.psm1`: Module script which loads the public and private functions
- `src/Public/`: Contains all exported, user-facing cmdlets
- `src/Private/`: Contains internal helper scripts (e.g., `Invoke-MistRequest.ps1`)
