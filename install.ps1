# ==============================================================================
#  TRACE FORGE — Windows Installer (PowerShell 5.1 & 7+ Compatible)
#  Installs the native engine & registers Chrome Native Messaging host.
#
#  Usage:
#    irm https://raw.githubusercontent.com/tracedevtools/Forge-release/main/install.ps1 | iex
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Force TLS 1.2 for secure downloads from GitHub
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
} catch {
    try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072 } catch {}
}

# ANSI Colors
$ESC = [char]27
$BOLD = "$ESC[1m"
$DIM = "$ESC[2m"
$CYAN = "$ESC[36m"
$BLUE = "$ESC[34m"
$GREEN = "$ESC[32m"
$YELLOW = "$ESC[33m"
$RED = "$ESC[31m"
$RESET = "$ESC[0m"

$HostName = "dev.gettrace.rust.host"
$Repo = "tracedevtools/Forge-release"
$BinaryName = "trace-http-bridge.exe"

$LocalAppData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $env:USERPROFILE "AppData\Local" }
$InstallDir = Join-Path $LocalAppData "trace-rust\native-host"
$FinalBinaryPath = Join-Path $InstallDir $BinaryName
$WorkspaceDir = Join-Path $env:USERPROFILE "Documents\Trace\greenfield"

$AllowedExtensionIds = @(
    "akabcpcfdkapeompkabhpdaofmmfjcdh",
    "adiiaelmeohkajiddjedcgjmkkhjnfcm",
    "hmlngfjlohkgbhkkhomipdbgkdgogolc",
    "jbndfblonpaiajoilmcfjnilbfidnikg",
    "nihkoalbpdeldlfkbpadfjidaampnobn",
    "ijempdjhomdhgjbjekbmdhlknmgmiahe",
    "picocfmhmdhpefnlajhbgmindmnikpip",
    "edapgfkgaeajkhhpchfhljppbpbffggg"
)

function Show-Banner {
    Write-Host ""
    Write-Host "$CYAN$BOLD"
    Write-Host "  ______                     ______                    "
    Write-Host " /_  __/________ _________   / ____/___  _________ ____ "
    Write-Host "  / / / ___/ __ `/ ___/ _ \ / /_  / __ \/ ___/ __ `/ _ \"
    Write-Host " / / / /  / /_/ / /__/  __// __/ / /_/ / /  / /_/ /  __/"
    Write-Host "/_/ /_/   \__,_/\___/\___//_/    \____/_/   \__, /\___/ "
    Write-Host "                                           /____/       "
    Write-Host "$RESET"
    Write-Host "        $BLUE⚡ BROWSER-NATIVE AI CODING ENGINE$RESET"
    Write-Host "$DIM──────────────────────────────────────────────────────────────────$RESET`n"
}

function Show-Step($num, $title, $desc) {
    Write-Host "  $BLUE$BOLD[$num/4]$RESET $title $DIM→$RESET $desc"
}

function Show-Success($msg) {
    Write-Host "      $GREEN✓$RESET $msg"
}

function Show-Warn($msg) {
    Write-Host "      $YELLOW⚠$RESET $msg"
}

function Show-Error($msg) {
    Write-Host "`n  $RED${BOLD}✗ Installation failed:$RESET $msg`n" -ForegroundColor Red
    exit 1
}

# 1. Platform Detection (works on every Windows PC)
function Detect-Platform {
    $is64 = [Environment]::Is64BitOperatingSystem
    $arch = $env:PROCESSOR_ARCHITEW6432
    if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
    if (-not $arch) { $arch = "AMD64" }

    if ($arch -eq "ARM64") {
        $platformLabel = "Windows (ARM64)"
    } elseif ($is64 -or $arch -eq "AMD64") {
        $platformLabel = "Windows (x86_64)"
    } else {
        $platformLabel = "Windows ($arch)"
    }

    Show-Step "1" "Platform detected" "$CYAN$platformLabel$RESET"
}

# 2. Resolve Engine Version
function Resolve-Release {
    Show-Step "2" "Release repository" "$CYAN github.com/$Repo (v0.1.0) $RESET"
}

# 3. Fast & Reliable Download
function Download-Binary {
    Show-Step "3" "Downloading binary" "$DIM fetching trace-http-bridge.exe (~46 MB)...$RESET"
    
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    $tempFile = Join-Path $InstallDir "$BinaryName.tmp"
    $downloadSuccess = $false

    $urls = @(
        "https://github.com/$Repo/releases/download/v0.1.0/$BinaryName",
        "https://github.com/$Repo/releases/latest/download/$BinaryName"
    )

    foreach ($url in $urls) {
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }

        # Attempt 1: WebClient (Fastest, handles redirects)
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Trace-Windows-Installer")
            $webClient.DownloadFile($url, $tempFile)
            
            if ((Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 1000000)) {
                $downloadSuccess = $true
                break
            }
        } catch {}

        # Attempt 2: Invoke-WebRequest fallback
        try {
            Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing -TimeoutSec 120
            if ((Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 1000000)) {
                $downloadSuccess = $true
                break
            }
        } catch {}
    }

    if ($downloadSuccess -and (Test-Path $tempFile)) {
        Move-Item -Path $tempFile -Destination $FinalBinaryPath -Force
        Show-Success "Binary installed to $CYAN$FinalBinaryPath$RESET"
    } else {
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path $FinalBinaryPath) {
            Show-Warn "Remote release unreachable; using existing binary at $CYAN$FinalBinaryPath$RESET"
        } else {
            Show-Error "Could not download binary from https://github.com/$Repo. Please verify release assets on GitHub."
        }
    }
}

# 4. Register Manifest & Windows Registry
function Register-Manifests {
    Show-Step "4" "Registering native host" "$CYAN$HostName$RESET"

    $escapedPath = $FinalBinaryPath.Replace('\', '\\')
    $allowedOriginsJson = ($AllowedExtensionIds | ForEach-Object { "    `"chrome-extension://$_/`"" }) -join ",`n"

    $manifestContent = @"
{
  "name": "$HostName",
  "description": "Trace Forge Native Messaging Host",
  "path": "$escapedPath",
  "type": "stdio",
  "allowed_origins": [
$allowedOriginsJson
  ]
}
"@

    $manifestPath = Join-Path $InstallDir "$HostName.json"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($manifestPath, $manifestContent, $utf8NoBom)

    # Register in Windows Registry for Chrome, Edge, Brave using reg.exe (bulletproof default key handling)
    $regKeys = @(
        "HKCU\Software\Google\Chrome\NativeMessagingHosts\$HostName",
        "HKCU\Software\Microsoft\Edge\NativeMessagingHosts\$HostName",
        "HKCU\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\$HostName"
    )

    $registeredCount = 0
    foreach ($regKey in $regKeys) {
        try {
            $process = Start-Process -FilePath "reg.exe" -ArgumentList "add `"$regKey`" /ve /t REG_SZ /d `"$manifestPath`" /f" -NoNewWindow -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                $registeredCount++
            }
        } catch {}
    }

    Show-Success "Native messaging registered in Windows Registry ($registeredCount browser profiles)"

    # Greenfield workspace
    if (-not (Test-Path $WorkspaceDir)) {
        New-Item -ItemType Directory -Path $WorkspaceDir -Force | Out-Null
    }
    $readmePath = Join-Path $WorkspaceDir "README.md"
    if (-not (Test-Path $readmePath)) {
        @"
# Trace Greenfield
This is your default Trace workspace for building new web applications.
Trace creates new projects here when you click Connect in the Trace extension.
"@ | Out-File -FilePath $readmePath -Encoding utf8
    }

    Show-Success "Workspace ready at $DIM$WorkspaceDir$RESET"
}

# Summary Screen
function Show-Summary {
    Write-Host "`n$DIM──────────────────────────────────────────────────────────────────$RESET"
    Write-Host "  $GREEN${BOLD}✅ Trace Forge installed successfully!$RESET`n"
    Write-Host "  ${BOLD}Binary:$RESET    $CYAN$FinalBinaryPath$RESET"
    Write-Host "  ${BOLD}Host ID:$RESET   $DIM$HostName$RESET"
    Write-Host "  ${BOLD}Workspace:$RESET $DIM$WorkspaceDir$RESET`n"
    Write-Host "  $BLUE${BOLD}🚀 Next Step:$RESET Open Chrome and click ${BOLD}Connect$RESET in the Trace panel."
    Write-Host "$DIM──────────────────────────────────────────────────────────────────$RESET`n"
}

function Main {
    Show-Banner
    Detect-Platform
    Resolve-Release
    Download-Binary
    Register-Manifests
    Show-Summary
}

Main
