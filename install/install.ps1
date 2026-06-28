#Requires -RunAsAdministrator
param([switch]$Uninstall)

$ErrorActionPreference = "Stop"
$installDir  = "C:\GIFCopier"
$logPath     = Join-Path $PSScriptRoot "install.log"
$exeName     = "ClipApp.exe"
$nativeName  = "com.syanth.gifcopier"

# Registry paths for Native Messaging hosts
$regPaths = @{
    Firefox = "HKCU:\SOFTWARE\Mozilla\NativeMessagingHosts\$nativeName"
    Chrome  = "HKCU:\SOFTWARE\Google\Chrome\NativeMessagingHosts\$nativeName"
    Edge    = "HKCU:\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\$nativeName"
}

Start-Transcript -Path $logPath -Force

# ── Uninstall ─────────────────────────────────────────────────────────────────
if ($Uninstall) {
    $ans = Read-Host "Uninstall GIFCopier? (y/n)"
    if ($ans -ne 'y') { Stop-Transcript; exit 2 }

    if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
    foreach ($k in $regPaths.Values) {
        if (Test-Path $k) { Remove-Item $k -Force }
    }
    Write-Host "GIFCopier uninstalled."
    Stop-Transcript
    exit 0
}

# ── Install ───────────────────────────────────────────────────────────────────
$ans = Read-Host "Install GIFCopier to $installDir? (y/n)"
if ($ans -ne 'y') { Stop-Transcript; exit 2 }

# Copy files
if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
New-Item -ItemType Directory -Path $installDir | Out-Null

$srcExe = Join-Path $PSScriptRoot $exeName
if (-not (Test-Path $srcExe)) {
    Write-Error "ClipApp.exe not found next to install.ps1 ($srcExe). Build it first."
    Stop-Transcript; exit 1
}
Copy-Item $srcExe $installDir

# ── Write Native Messaging manifests ─────────────────────────────────────────
$exePath = Join-Path $installDir $exeName

$ffManifest = @{
    name               = $nativeName
    description        = "GIFCopier clipboard helper"
    path               = $exePath
    type               = "stdio"
    allowed_extensions = @("gifcopier@syanth")
} | ConvertTo-Json -Depth 5

$crManifest = @{
    name            = $nativeName
    description     = "GIFCopier clipboard helper"
    path            = $exePath
    type            = "stdio"
    allowed_origins = @("chrome-extension://ncddcifdiglpdkflenjfceajajjmglji/")
} | ConvertTo-Json -Depth 5

$edManifest = @{
    name            = $nativeName
    description     = "GIFCopier clipboard helper"
    path            = $exePath
    type            = "stdio"
    allowed_origins = @("chrome-extension://ilkmmecafihenljghaofocefdofekafo/")
} | ConvertTo-Json -Depth 5

$ffJson  = Join-Path $installDir "com.syanth.gifcopier.firefox.json"
$crJson  = Join-Path $installDir "com.syanth.gifcopier.chrome.json"
$edJson  = Join-Path $installDir "com.syanth.gifcopier.edge.json"

$ffManifest  | Set-Content $ffJson  -Encoding UTF8
$crManifest  | Set-Content $crJson  -Encoding UTF8
$edManifest  | Set-Content $edJson  -Encoding UTF8

# ── Register manifests in the Windows Registry ────────────────────────────────
function Set-NativeMessagingKey($regPath, $jsonPath) {
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value $jsonPath
}

Set-NativeMessagingKey $regPaths.Firefox $ffJson
Set-NativeMessagingKey $regPaths.Chrome  $crJson
Set-NativeMessagingKey $regPaths.Edge    $edJson

# ── Chrome extension policy whitelist (needed for .crx sideloading) ───────────
$chromePolicyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallAllowlist"
if (-not (Test-Path $chromePolicyPath)) {
    New-Item -Path $chromePolicyPath -Force | Out-Null
}
New-ItemProperty -Path $chromePolicyPath -Name "1" -Value "ncddcifdiglpdkflenjfceajajjmglji" -Force | Out-Null

Write-Host ""
Write-Host "GIFCopier installed to $installDir"
Write-Host "Now install the browser extension:"
Write-Host "  Firefox : https://addons.mozilla.org/en-US/firefox/addon/gifcopier/"
Write-Host "  Edge    : https://microsoftedge.microsoft.com/addons/detail/gifcopier/ilkmmecafihenljghaofocefdofekafo"

Stop-Transcript
exit 0
