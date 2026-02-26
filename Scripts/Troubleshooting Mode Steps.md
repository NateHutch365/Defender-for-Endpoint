# MDE Troubleshooting Mode Scripts

A set of PowerShell scripts to assist with troubleshooting performance issues on endpoints running Microsoft Defender for Endpoint (MDE). The scripts are designed to be run in a staged approach, allowing administrators to incrementally disable settings and isolate the cause of performance issues without immediately stripping all protection.

---

## Prerequisites

- The endpoint must be onboarded to Microsoft Defender for Endpoint
- **Troubleshooting Mode must be active** on the endpoint before running either script. This is initiated from the MDE portal (Security.microsoft.com) on a per-device basis
- Scripts must be run in an elevated PowerShell session (Run as Administrator)
- Troubleshooting Mode automatically expires after **4 hours**, reverting any changes made during the session

---

## How to Initiate Troubleshooting Mode

1. Navigate to [Microsoft Defender XDR](https://security.microsoft.com)
2. Go to **Assets > Devices** and locate the target device
3. Select the device and click **... > Turn on troubleshooting mode**
4. Confirm the action — the device will show **Troubleshooting mode: On** in the device page once active
5. On the device in elevated PowerShell terminal run `Set-MPPreference -DisableTamperProtection $true` to ensure you can change TP protected settings
5. You can now run the scripts on the endpoint

---

## Scripts

### Step 1 — Performance Tuning (`Step1-PerformanceTuning.ps1`)

Reduces the performance impact of Defender without disabling core protection components. Real-time monitoring, behaviour monitoring, and network protection remain active.

**Run this first.** If the performance issue resolves after Step 1, no further action is needed and you can identify the offending setting by reviewing what was changed.

| Setting | Value Applied | Reason |
|---|---|---|
| CloudBlockLevel | 0 (Default) | Removes aggressive cloud blocking overhead |
| CloudExtendedTimeout | 10 (Default) | Reduces cloud lookup timeout to minimum |
| ScanAvgCPULoadFactor | 20 | Caps CPU usage during scans |
| DisableScanningNetworkFiles | True | Reduces overhead on network share activity |
| EnableFileHashComputation | False | Eliminates disk I/O overhead from hash computation |
| PUAProtection | Disabled | Removes PUA scanning overhead |

```powershell
# ============================================================
# MDE Troubleshooting - Step 1: Performance Tuning
# Reduces resource impact while maintaining core protection
# Run within an active Troubleshooting Mode session
# ============================================================

# Integer-based settings
$intSettings = @{
    CloudBlockLevel             = 0
    CloudExtendedTimeout        = 10
    ScanAvgCPULoadFactor        = 20
}

# Boolean-based settings
$boolSettings = @{
    DisableScanningNetworkFiles = $true
    EnableFileHashComputation   = $false
}

# Enumeration-based settings
$enumSettings = @{
    PUAProtection               = "Disabled"
}

foreach ($setting in $intSettings.GetEnumerator()) {
    try {
        $splat = @{ $setting.Key = $setting.Value }
        Set-MpPreference @splat -ErrorAction Stop
        Write-Host "[OK] $($setting.Key) set to $($setting.Value)" -ForegroundColor Green
    } catch {
        Write-Warning "[FAILED] $($setting.Key): $_"
    }
}

foreach ($setting in $boolSettings.GetEnumerator()) {
    try {
        $splat = @{ $setting.Key = $setting.Value }
        Set-MpPreference @splat -ErrorAction Stop
        Write-Host "[OK] $($setting.Key) set to $($setting.Value)" -ForegroundColor Green
    } catch {
        Write-Warning "[FAILED] $($setting.Key): $_"
    }
}

foreach ($setting in $enumSettings.GetEnumerator()) {
    try {
        $splat = @{ $setting.Key = $setting.Value }
        Set-MpPreference @splat -ErrorAction Stop
        Write-Host "[OK] $($setting.Key) set to $($setting.Value)" -ForegroundColor Green
    } catch {
        Write-Warning "[FAILED] $($setting.Key): $_"
    }
}

Write-Host "`nStep 1 complete. Test performance now." -ForegroundColor Cyan
Write-Host "Core protection (Real-Time, Behaviour Monitoring, NP) remains ACTIVE." -ForegroundColor Yellow
```

---

### Step 2 — Full Protection Disable (`Step2-FullProtectionDisable.ps1`)

Disables all active protection components. Only run this if Step 1 does not resolve the issue and further isolation is required.

> ⚠️ **Warning:** This script disables core Defender protection. Do not leave endpoints in this state. Troubleshooting Mode will revert all changes automatically after 4 hours, or you can end the session manually from the MDE portal.

| Setting | Value Applied | Reason |
|---|---|---|
| DisableRealtimeMonitoring | True | Disables real-time file scanning |
| DisableBehaviorMonitoring | True | Disables behavioural analysis |
| DisableBlockAtFirstSeen | True | Disables cloud-based first-seen blocking |
| DisableIOAVProtection | True | Disables scanning of downloaded files and attachments |
| EnableNetworkProtection | 0 (Disabled) | Disables network protection |

```powershell
# ============================================================
# MDE Troubleshooting - Step 2: Full Protection Disable
# Disables all active protection components
# Run within an active Troubleshooting Mode session
# WARNING: Do not leave in this state. Re-enable or end
# Troubleshooting Mode when testing is complete.
# ============================================================

$step2Settings = @{
    DisableRealtimeMonitoring = $true
    DisableBehaviorMonitoring = $true
    DisableBlockAtFirstSeen   = $true
    DisableIOAVProtection     = $true
    EnableNetworkProtection   = 0
}

foreach ($setting in $step2Settings.GetEnumerator()) {
    try {
        $splat = @{ $setting.Key = $setting.Value }
        Set-MpPreference @splat -ErrorAction Stop
        Write-Host "[OK] $($setting.Key) set to $($setting.Value)" -ForegroundColor Green
    } catch {
        Write-Warning "[FAILED] $($setting.Key): $_"
    }
}

Write-Host "`nStep 2 complete. Full protection is now disabled." -ForegroundColor Red
Write-Host "Remember: Troubleshooting Mode auto-expires after 4 hours." -ForegroundColor Yellow
```

---

## Verification

Use the following one-liner to check the current effective state of all relevant settings before and after running either script:

```powershell
Get-MpPreference | Select-Object CloudBlockLevel, CloudExtendedTimeout, ScanAvgCPULoadFactor, DisableScanningNetworkFiles, EnableFileHashComputation, PUAProtection, DisableRealtimeMonitoring, DisableBehaviorMonitoring, DisableBlockAtFirstSeen, DisableIOAVProtection, EnableNetworkProtection | Format-List
```

It is recommended to capture a baseline **before** running any script so you have a reference point:

```powershell
Get-MpPreference | Select-Object CloudBlockLevel, CloudExtendedTimeout, ScanAvgCPULoadFactor, DisableScanningNetworkFiles, EnableFileHashComputation, PUAProtection, DisableRealtimeMonitoring, DisableBehaviorMonitoring, DisableBlockAtFirstSeen, DisableIOAVProtection, EnableNetworkProtection | Format-List | Out-File "C:\Temp\MDE_Baseline.txt"
```

---

## Recommended Workflow

```
1. Capture baseline with Get-MpPreference
        ↓
2. Initiate Troubleshooting Mode from MDE portal
        ↓
3. Run Step 1 - Performance Tuning
        ↓
4. Test and monitor performance
        ↓
5. Issue resolved? → Document findings, end Troubleshooting Mode
   Issue persists? → Run Step 2 - Full Protection Disable
        ↓
6. Test and monitor performance
        ↓
7. End Troubleshooting Mode or allow 4-hour auto-expiry
```

---

## Known Limitations

- If enforcing the `HideExclusionsFromLocalAdmins` on the device, even if troubleshooting mode is enabled you are unable to query exclusions added. In my testing these exclusions still apply despite not being able to query them using `Get-MpPreference | Select-Object -ExpandProperty ExclusionPath` options (also applies to `ExclusionProcess` etc.)

---

## References

- [Microsoft Docs — Troubleshooting Mode](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/enable-troubleshooting-mode)
- [Microsoft Docs — Set-MpPreference](https://learn.microsoft.com/en-us/powershell/module/defender/set-mppreference)
- [Microsoft Docs — Get-MpPreference](https://learn.microsoft.com/en-us/powershell/module/defender/get-mppreference)