[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string] $SourceMonitorResourceId,

    [Parameter(Mandatory = $true)]
    [string] $TargetMonitorResourceId,

    [Parameter(Mandatory = $false)]
    [string] $ApiVersion = "2024-02-01-preview",

    [Parameter(Mandatory = $false)]
    [string] $SecretsMapPath,

    [Parameter(Mandatory = $false)]
    [string] $NamePrefix = "",

    [Parameter(Mandatory = $false)]
    [string] $NameSuffix = "",

    [Parameter(Mandatory = $false)]
    [switch] $SkipExisting,

    [Parameter(Mandatory = $false)]
    [string] $SecretsTemplatePath = "./secrets.template.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Read-only / server-generated fields that must not be echoed back on a create call.
$ReadOnlySettingFields = @("errors", "provisioningState", "health")

# Map of providerType -> plaintext password field and its Key Vault URI counterpart.
# Used only to detect missing secrets and give the operator a clear message.
$PasswordFieldMap = @{
    "SapHana"     = @{ Password = "dbPassword";  Uri = "dbPasswordUri" }
    "Db2"         = @{ Password = "dbPassword";  Uri = "dbPasswordUri" }
    "Oracle"      = @{ Password = "dbPassword";  Uri = "dbPasswordUri" }
    "MsSqlServer" = @{ Password = "dbPassword";  Uri = "dbPasswordUri" }
    "SapNetWeaver" = @{ Password = "sapPassword"; Uri = "sapPasswordUri" }
}

function Assert-AzContext {
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        throw "No Azure context found. Run 'Connect-AzAccount' before executing this script."
    }
    Write-Host "Using Azure account: $($context.Account.Id) (tenant $($context.Tenant.Id))" -ForegroundColor DarkGray
}

function Invoke-Arm {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("GET", "PUT")] [string] $Method,
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $false)][string] $Body
    )

    $params = @{ Path = $Path; Method = $Method }
    if ($Body) { $params["Payload"] = $Body }

    # Retry transient failures (network blips, socket resets, throttling).
    $maxRetries = 5
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            $response = Invoke-AzRestMethod @params

            # Retry on transient HTTP status codes.
            if ($response.StatusCode -in @(429, 500, 502, 503, 504) -and $attempt -lt $maxRetries) {
                $delay = [Math]::Min(30, [Math]::Pow(2, $attempt))
                Write-Host "    (transient HTTP $($response.StatusCode); retry $attempt/$maxRetries in ${delay}s)" -ForegroundColor DarkGray
                Start-Sleep -Seconds $delay
                continue
            }

            return $response
        }
        catch {
            if ($attempt -ge $maxRetries) { throw }
            $delay = [Math]::Min(30, [Math]::Pow(2, $attempt))
            Write-Host "    (transient error: $($_.Exception.Message); retry $attempt/$maxRetries in ${delay}s)" -ForegroundColor DarkGray
            Start-Sleep -Seconds $delay
        }
    }
}

function Get-ProviderInstances {
    param([string] $MonitorId)

    $providers = @()
    $path = "$MonitorId/providerInstances?api-version=$ApiVersion"

    do {
        $response = Invoke-Arm -Method GET -Path $path
        if ($response.StatusCode -ge 400) {
            throw "Failed to list provider instances ($($response.StatusCode)): $($response.Content)"
        }

        $parsed = $response.Content | ConvertFrom-Json
        if ($parsed.PSObject.Properties.Name -contains "value" -and $parsed.value) {
            $providers += $parsed.value
        }

        $nextLink = $null
        if ($parsed.PSObject.Properties.Name -contains "nextLink") {
            $nextLink = $parsed.nextLink
        }

        # nextLink is an absolute URL; Invoke-AzRestMethod -Path accepts the path+query.
        if ($nextLink) {
            $path = ([Uri]$nextLink).PathAndQuery
        }
    } while ($nextLink)

    return $providers
}

function Get-AsyncOperationUrl {
    # Extracts the long-running-operation polling URL from a PUT response. Header
    # values come back as string arrays, so select the first non-empty element.
    param([Parameter(Mandatory = $true)] $Response)

    foreach ($headerName in @("Azure-AsyncOperation", "Location")) {
        $header = $Response.Headers | Where-Object { $_.Key -eq $headerName } | Select-Object -First 1
        if ($header) {
            $url = @($header.Value)[0]
            if (-not [string]::IsNullOrWhiteSpace($url)) { return $url }
        }
    }
    return $null
}

function Get-TargetProviderNames {
    param([string] $MonitorId)
    $existing = @{}
    try {
        $providers = Get-ProviderInstances -MonitorId $MonitorId
        foreach ($p in $providers) { $existing[$p.name] = $true }
    }
    catch {
        Write-Warning "Could not enumerate existing target providers: $($_.Exception.Message)"
    }
    return $existing
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Assert-AzContext

$SourceMonitorResourceId = $SourceMonitorResourceId.TrimEnd('/')
$TargetMonitorResourceId = $TargetMonitorResourceId.TrimEnd('/')

# Load secrets map, if provided.
$secretsMap = @{}
if ($SecretsMapPath) {
    if (-not (Test-Path $SecretsMapPath)) {
        throw "SecretsMapPath '$SecretsMapPath' does not exist."
    }
    $rawSecrets = Get-Content -Raw -Path $SecretsMapPath | ConvertFrom-Json
    foreach ($prop in $rawSecrets.PSObject.Properties) {
        $secretsMap[$prop.Name] = $prop.Value
    }
    Write-Host "Loaded secrets for $($secretsMap.Keys.Count) provider(s)." -ForegroundColor DarkGray
}

Write-Host "Reading provider configurations from source monitor..." -ForegroundColor Cyan
$sourceProviders = Get-ProviderInstances -MonitorId $SourceMonitorResourceId
Write-Host "Found $($sourceProviders.Count) provider instance(s) on the source monitor." -ForegroundColor Cyan

if ($sourceProviders.Count -eq 0) {
    Write-Host "Nothing to migrate." -ForegroundColor Yellow
    return
}

$existingTargets = @{}
if ($SkipExisting) {
    $existingTargets = Get-TargetProviderNames -MonitorId $TargetMonitorResourceId
}

$summary = [System.Collections.Generic.List[object]]::new()

# Tracks providers that need a plaintext password but none was supplied.
# Populated during Phase 1; written to $SecretsTemplatePath after the loop.
$missingSecrets = [ordered]@{}

# Jobs that have been submitted and still need polling to reach a terminal state.
$pending = [System.Collections.Generic.List[object]]::new()

# ---------------------------------------------------------------------------
# Phase 1: prepare + submit every provider create (do NOT wait yet). Submitting
# all creates up front lets Azure provision them in parallel instead of forcing
# each ~10-20 min provider deployment to run one after another.
# ---------------------------------------------------------------------------
foreach ($provider in $sourceProviders) {
    $sourceName = $provider.name
    $targetName = "$NamePrefix$sourceName$NameSuffix"

    $result = [ordered]@{
        Source = $sourceName
        Target = $targetName
        Type   = $null
        Status = $null
        Detail = ""
    }

    try {
        if (-not $provider.properties -or -not $provider.properties.providerSettings) {
            $result.Status = "Skipped"
            $result.Detail = "No providerSettings found."
            $summary.Add([pscustomobject]$result)
            Write-Warning "[$sourceName] has no providerSettings; skipping."
            continue
        }

        # Deep clone the providerSettings via round-trip serialization so we can mutate.
        $settings = $provider.properties.providerSettings | ConvertTo-Json -Depth 20 | ConvertFrom-Json
        $providerType = $settings.providerType
        $result.Type = $providerType

        # Strip read-only fields that must not be sent on create.
        foreach ($field in $ReadOnlySettingFields) {
            if ($settings.PSObject.Properties.Name -contains $field) {
                $settings.PSObject.Properties.Remove($field)
            }
        }

        # Remove SapNetWeaver fields that are present but empty — empty values cause the PUT to fail.
        if ($providerType -eq "SapNetWeaver") {
            $sapOptionalFields = @("SapPortNumber", "sapPortNumber", "sapUsername", "sapPasswordUri", "sapClientId", "sslCertificateUri")
            foreach ($field in $sapOptionalFields) {
                if ($settings.PSObject.Properties.Name -contains $field) {
                    $val = $settings.$field
                    # sapPortNumber is numeric: treat null, empty-string, and 0 as "not set".
                    # All other fields are strings: treat null/empty/whitespace as "not set".
                    $isEmpty = ($null -eq $val) -or
                               [string]::IsNullOrWhiteSpace([string]$val) -or
                               ($field -in @("SapPortNumber", "sapPortNumber") -and [string]$val -eq "0")
                    if ($isEmpty) {
                        # Write-Host "[$sourceName] removing empty '$field' ($val) to avoid PUT failure." -ForegroundColor DarkGray
                        $settings.PSObject.Properties.Remove($field)
                    }
                }
            }
        }

        # Write-Host $settings | ConvertTo-Json -Depth 10

        # Handle secrets.
        # SapNetWeaver providers without RFC credentials (no sapUsername/sapClientId) are
        # message-server-only and do not require a password — skip the password check for them.
        $isCredentialFreeNw = ($providerType -eq "SapNetWeaver") -and
                              (-not ($settings.PSObject.Properties.Name -contains "sapUsername")) -and
                              (-not ($settings.PSObject.Properties.Name -contains "sapClientId"))

        if ($PasswordFieldMap.ContainsKey($providerType) -and -not $isCredentialFreeNw) {
            $pwField = $PasswordFieldMap[$providerType].Password
            $uriField = $PasswordFieldMap[$providerType].Uri

            $hasUri = ($settings.PSObject.Properties.Name -contains $uriField) -and
                      (-not [string]::IsNullOrWhiteSpace($settings.$uriField))

            $suppliedSecret = $null
            if ($secretsMap.ContainsKey($sourceName)) {
                $secretEntry = $secretsMap[$sourceName]
                if ($secretEntry.PSObject.Properties.Name -contains $pwField) {
                    $suppliedSecret = $secretEntry.$pwField
                }
            }

            if ($suppliedSecret) {
                # Inject the re-supplied plaintext password.
                if ($settings.PSObject.Properties.Name -contains $pwField) {
                    $settings.$pwField = $suppliedSecret
                }
                else {
                    $settings | Add-Member -NotePropertyName $pwField -NotePropertyValue $suppliedSecret
                }
            }
            elseif (-not $hasUri) {
                # Neither a Key Vault URI nor a supplied secret: cannot create securely.
                $result.Status = "Skipped"
                $result.Detail = "Missing '$pwField'. Provide it via -SecretsMapPath (or configure '$uriField' on the source)."
                $summary.Add([pscustomobject]$result)
                Write-Warning "[$sourceName] $($result.Detail)"
                # Record for the secrets template that will be written after the loop.
                $missingSecrets[$sourceName] = [ordered]@{ $pwField = "" }
                continue
            }
        }

        if ($SkipExisting -and $existingTargets.ContainsKey($targetName)) {
            $result.Status = "Skipped"
            $result.Detail = "Already exists on target."
            $summary.Add([pscustomobject]$result)
            Write-Host "[$sourceName] already exists on target as '$targetName'; skipping." -ForegroundColor Yellow
            continue
        }

        $body = @{ properties = @{ providerSettings = $settings } } | ConvertTo-Json -Depth 20
        $targetPath = "$TargetMonitorResourceId/providerInstances/$targetName" + "?api-version=$ApiVersion"

        if (-not $PSCmdlet.ShouldProcess($targetName, "Create providerInstance ($providerType)")) {
            $result.Status = "WhatIf"
            $result.Detail = "Would create ($providerType)."
            $summary.Add([pscustomobject]$result)
            continue
        }

        Write-Host "[$sourceName] -> submitting create for '$targetName' ($providerType)..." -ForegroundColor Green
        $response = Invoke-Arm -Method PUT -Path $targetPath -Body $body

        # Determine how this one will be polled.
        $pollPath = $null
        $pollMode = "operation"   # poll the async-operation URL
        $immediateStatus = $null

        if ($response.StatusCode -eq 200) {
            $immediateStatus = "Succeeded"   # synchronous completion
        }
        elseif ($response.StatusCode -eq 409 -and $response.Content -match "being provisioned|InvalidResourceOperation") {
            # Already being provisioned by a prior run: poll the resource directly.
            $pollMode = "resource"
            $pollPath = $targetPath
            Write-Host "[$sourceName] -> '$targetName' already provisioning; will wait on it." -ForegroundColor Yellow
        }
        elseif ($response.StatusCode -in @(200, 201, 202)) {
            $asyncUrl = Get-AsyncOperationUrl -Response $response
            if ($asyncUrl) {
                $pollPath = ([Uri]$asyncUrl).PathAndQuery
            }
            else {
                # No async URL returned: fall back to polling the resource.
                $pollMode = "resource"
                $pollPath = $targetPath
            }
        }
        else {
            throw "Create of '$targetName' failed ($($response.StatusCode)): $($response.Content)"
        }

        if ($immediateStatus) {
            $result.Status = $immediateStatus
            $summary.Add([pscustomobject]$result)
            Write-Host "[$sourceName] -> '$targetName' $immediateStatus." -ForegroundColor Green
            continue
        }

        $pending.Add([pscustomobject]@{
            SourceName = $sourceName
            TargetName = $targetName
            PollMode   = $pollMode
            PollPath   = $pollPath
            Result     = $result
            LastStatus = $null
        })
    }
    catch {
        $result.Status = "Failed"
        $result.Detail = $_.Exception.Message
        $summary.Add([pscustomobject]$result)
        Write-Warning "[$sourceName] submission failed (continuing to next provider): $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Write secrets template whenever providers were skipped for missing passwords.
# ---------------------------------------------------------------------------
if ($missingSecrets.Count -gt 0) {
    # Use .NET directly so the write is NOT suppressed when -WhatIf is active.
    $templateJson = $missingSecrets | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText(
        ([System.IO.Path]::GetFullPath($SecretsTemplatePath)),
        $templateJson,
        [System.Text.Encoding]::UTF8
    )
    Write-Host ""
    Write-Host "Secrets template written to '$SecretsTemplatePath' with $($missingSecrets.Count) entr$(if ($missingSecrets.Count -eq 1) { 'y' } else { 'ies' })." -ForegroundColor Yellow
    Write-Host "Fill in the empty password values and re-run with: -SecretsMapPath '$SecretsTemplatePath'" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Phase 2: poll all in-flight creates together until each reaches a terminal
# state. A failure on one provider is recorded and never blocks the others.
# ---------------------------------------------------------------------------
if ($pending.Count -gt 0) {
    Write-Host ""
    Write-Host "Waiting for $($pending.Count) provider create(s) to finish (they provision in parallel; each can take 10-20m)..." -ForegroundColor Cyan

    $timeoutMinutes = 45
    $deadline = (Get-Date).AddMinutes($timeoutMinutes)
    $start = Get-Date

    while ($pending.Count -gt 0 -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 20
        $elapsed = [int]((Get-Date) - $start).TotalMinutes
        $stillPending = [System.Collections.Generic.List[object]]::new()

        foreach ($job in $pending) {
            try {
                $poll = Invoke-Arm -Method GET -Path $job.PollPath
                if ($poll.StatusCode -ge 400) {
                    throw "Polling failed ($($poll.StatusCode)): $($poll.Content)"
                }

                $parsed = $poll.Content | ConvertFrom-Json
                if ($job.PollMode -eq "resource") {
                    $status = $parsed.properties.provisioningState
                }
                else {
                    $status = $parsed.status
                }

                if ($status -ne $job.LastStatus) {
                    Write-Host "    [$($job.TargetName)] $status (${elapsed}m)" -ForegroundColor DarkGray
                    $job.LastStatus = $status
                }

                if ($status -in @("Succeeded", "Failed", "Canceled")) {
                    $job.Result.Status = $status
                    if ($status -ne "Succeeded") {
                        $job.Result.Detail = "Ended with status '$status'. $($poll.Content)"
                        Write-Warning "[$($job.SourceName)] -> '$($job.TargetName)' $status."
                    }
                    else {
                        Write-Host "[$($job.SourceName)] -> '$($job.TargetName)' Succeeded." -ForegroundColor Green
                    }
                    $summary.Add([pscustomobject]$job.Result)
                }
                else {
                    $stillPending.Add($job)   # not terminal yet
                }
            }
            catch {
                # A transient poll error shouldn't fail the provider outright; keep it
                # pending and try again on the next cycle (unless we're out of time).
                Write-Host "    [$($job.TargetName)] poll error (will retry): $($_.Exception.Message)" -ForegroundColor DarkGray
                $stillPending.Add($job)
            }
        }

        $pending = $stillPending
    }

    # Anything still pending after the deadline is timed out.
    foreach ($job in $pending) {
        $job.Result.Status = "Timeout"
        $job.Result.Detail = "Still '$($job.LastStatus)' after ${timeoutMinutes}m. Check the resource in the portal."
        $summary.Add([pscustomobject]$job.Result)
        Write-Warning "[$($job.SourceName)] -> '$($job.TargetName)' timed out after ${timeoutMinutes}m (last status '$($job.LastStatus)')."
    }
}

Write-Host ""
Write-Host "==================== Migration summary ====================" -ForegroundColor Cyan
$summary | Format-Table -AutoSize
Write-Host "===========================================================" -ForegroundColor Cyan

# Print the full (untruncated) error for anything that did not succeed.
$notOk = @($summary | Where-Object { $_.Status -in @("Failed", "Timeout") })
foreach ($item in $notOk) {
    Write-Host ""
    Write-Host "----- $($item.Target) ($($item.Type)) : $($item.Status) -----" -ForegroundColor Red
    Write-Host $item.Detail -ForegroundColor Red
}

$failed = @($notOk)
if ($failed.Count -gt 0) {
    Write-Warning "$($failed.Count) provider(s) did not migrate successfully. Review the details above."
    exit 1
}
