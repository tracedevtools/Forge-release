# Trace Rust Agent — Windows One-line Installer
$ErrorActionPreference = "Stop"

$Repo = "tracedevtools/Forge-release"
$Version = "v0.1.0"
$BinaryName = "trace-http-bridge.exe"
$HostName = "dev.gettrace.rust.host"

$ExtensionIds = @(
  "akabcpcfdkapeompkabhpdaofmmfjcdh",
  "adiiaelmeohkajiddjedcgjmkkhjnfcm",
  "hmlngfjlohkgbhkkhomipdbgkdgogolc",
  "nihkoalbpdeldlfkbpadfjidaampnobn",
  "jbndfblonpaiajoilmcfjnilbfidnikg"
)

if ($env:TRACE_EXTENSION_ID) {
  $ExtensionIds += $env:TRACE_EXTENSION_ID
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "   ⚡ Installing Trace Rust Native Agent Host      " -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# 1. Target directory: %LOCALAPPDATA%\trace-rust\native-host
$InstallDir = Join-Path $env:LOCALAPPDATA "trace-rust\native-host"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$TargetBin = Join-Path $InstallDir $BinaryName
$DownloadUrl = "https://github.com/$Repo/releases/download/$Version/$BinaryName"

# 2. Download binary
Write-Host "• Downloading $BinaryName from GitHub..." -ForegroundColor Gray
try {
  Invoke-WebRequest -Uri $DownloadUrl -OutFile $TargetBin -UseBasicParsing
  Write-Host "✓ Binary installed at: $TargetBin" -ForegroundColor Green
} catch {
  Write-Warning "Could not download from $DownloadUrl. Make sure $BinaryName is attached to release $Version."
}

# 3. Create Manifest JSON
$ManifestPath = Join-Path $InstallDir "$HostName.json"
$EscapedTargetBin = $TargetBin.Replace('\', '\\')

$OriginsList = ($ExtensionIds | ForEach-Object { "    `"chrome-extension://$_/`"" }) -join ",`n"

$ManifestContent = @"
{
  "name": "$HostName",
  "description": "Trace Rust Agent Native Messaging Host",
  "path": "$EscapedTargetBin",
  "type": "stdio",
  "allowed_origins": [
$OriginsList
  ]
}
"@

[System.IO.File]::WriteAllText($ManifestPath, $ManifestContent)
Write-Host "✓ Manifest created at: $ManifestPath" -ForegroundColor Green

# 4. Register in Windows Registry
$RegPaths = @(
  "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName",
  "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$HostName",
  "HKCU:\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\$HostName"
)

foreach ($regPath in $RegPaths) {
  try {
    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name "(default)" -Value $ManifestPath
  } catch {
    # Best-effort across multiple browsers
  }
}
Write-Host "✓ Registered in Windows Registry for Chrome / Edge / Brave" -ForegroundColor Green

# 5. Default greenfield workspace
$Greenfield = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Trace\greenfield"
New-Item -ItemType Directory -Force -Path $Greenfield | Out-Null

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Trace Native Host installation complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "  1. Reload your Trace extension in Chrome (chrome://extensions)"
Write-Host "  2. Click 'Connect' inside the extension"
Write-Host "  3. Chrome will automatically launch the Rust agent binary`n"
