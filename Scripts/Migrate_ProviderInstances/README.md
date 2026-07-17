# Provider Instance Migration (Azure Monitor for SAP solutions)

`Migrate-ProviderInstances.ps1` copies every provider configuration
(`Microsoft.Workloads/monitors/providerInstances`) from a **source** AMS monitor to a
**target** AMS monitor.

## Prerequisites

- Az PowerShell module (`Az.Accounts`). Run `Connect-AzAccount` first.
- Permission to read the source monitor and write to the target monitor.

## Usage

Run the following steps

1. Open the PowerShell console in Administrator mode
2. Navigate to the folder containing `Migrate-ProviderInstances.ps1`
3. Login to Azure with the following command:

   ```powershell
    Connect-AzAccount
    ```

4. If Az module is not installed, run the following command to install it:

   ```powershell
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    ```

5. Run the following skip to bypass the execution policy for the current session:

   ```powershell
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
    ```

6. Run the following command to perform a dry run first, which lists what would be created without making any changes.

    ```powershell
    # 1. Dry run first — lists what would be created, makes no changes
    ./Migrate-ProviderInstances.ps1 `
        -SourceMonitorResourceId "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Workloads/monitors/<source_monitor>" `
        -TargetMonitorResourceId "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Workloads/monitors/<target_monitor>" `
        -WhatIf
    ```

7. The above command generates a `secrets.template.json` file with any missing passwords. Fill in the passwords in that file and save it.
8. Now, run the following command to perform the actual migration:

    ```powershell
    ./Migrate-ProviderInstances.ps1 `
        -SourceMonitorResourceId "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Workloads/monitors/<source_monitor>" `
        -TargetMonitorResourceId "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Workloads/monitors/<target_monitor>" `
        -SecretsMapPath ./secrets.template.json
    ```

The script is safe to re-run: providers already created are left as-is and only
failed/missing ones are retried. Each provider can take **10–20 minutes** to
provision.

### Parameters

| Parameter | Required | Description |
| --------- | -------- | ----------- |
| `-SourceMonitorResourceId` | yes | ARM id of the existing monitor. |
| `-TargetMonitorResourceId` | yes | ARM id of the new monitor. |
| `-SecretsMapPath` | no | JSON file re-supplying plaintext passwords (see below). |
| `-ApiVersion` | no | Defaults to `2024-02-01-preview`. |
| `-NamePrefix` / `-NameSuffix` | no | Rename target providers (avoid collisions when both monitors share a resource group). |
| `-SkipExisting` | no | Skip providers that already exist on the target. |
| `-SecretsTemplatePath` | no | Path for the auto-generated secrets template. Defaults to `./secrets.template.json`. |
| `-WhatIf` | no | Preview without making changes. |

## Passwords

Passwords are **never returned** by Azure, so they can't be read from the source
monitor. How each provider is handled:

- **Key Vault based providers** — the secret URI (`dbPasswordUri` / `sapPasswordUri`)
  is copied automatically. You don't enter anything, but the target monitor's
  identity must be able to read that Key Vault (see below).
- **Plaintext-password providers** — supply the password again with `-SecretsMapPath`.
  Providers needing a password but with none supplied are reported and skipped.

### Secrets file format

Keys are the **source** provider instance names. The password field depends on the
provider type:

| Provider type | Field to use |
| ------------- | ------------ |
| SapHana, Db2, Oracle, MsSqlServer | `dbPassword` |
| SapNetWeaver | `sapPassword` |

You don't need to memorize this — run with `-WhatIf` first and the script prints the
exact field and provider name for anything missing a password, **and automatically
writes a `secrets.template.json` file** you can fill in straight away, for example:

```
WARNING: [hana-e2e] Missing 'dbPassword'. Provide it via -SecretsMapPath ...
WARNING: [netweaver-e2e] Missing 'sapPassword'. Provide it via -SecretsMapPath ...
Secrets template written to './secrets.template.json' with 2 entries.
Fill in the empty password values and re-run with: -SecretsMapPath './secrets.template.json'
```

The generated file already has the right structure — just fill in the values:

```json
{
  "hana-e2e":      { "dbPassword": "" },
  "netweaver-e2e": { "sapPassword": "" }
}
```

Supplying a plaintext password here also **overrides** a Key Vault URI — the easiest
way to avoid Key Vault access setup. Delete the file after migrating; it holds
plaintext credentials.

## Fixing `KeyVaultAccessDenied`

If a Key Vault based provider fails with `KeyVaultAccessDenied`, grant the **new
monitor's** managed identity access to the Key Vault:

1. **Identity:** the new monitor has its own identity `sapmon-msi-<id>` in its managed
   resource group `sapmonrg-<id>`. Grant access to that one (not the old monitor's).
2. **Permission model** (Key Vault → *Access configuration*):
   - *Azure RBAC* → assign role **Key Vault Secrets User** to the MSI.
   - *Vault access policy* → grant the MSI **Get** + **List** on secrets.
3. **Networking** (Key Vault → *Networking*): if restricted, allow the new monitor's
   subnet or the `AzureMonitorForSAPsolutions` service tag
   (<https://aka.ms/AmsServiceTags>).

RBAC changes can take 5–10 minutes to take effect. Then re-run the script.

Quickest alternative: skip Key Vault entirely by putting the plaintext password in
`secrets.json` and re-running.

## Result statuses

| Status | Meaning |
| ------ | ------- |
| `Succeeded` | Provider created on the target. |
| `Skipped` | No settings, missing required password, or already exists. |
| `WhatIf` | Would be created (dry run). |
| `Failed` / `Timeout` | Did not complete — see the printed error / check the portal. |
