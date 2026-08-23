# ==============================================================================
#  TRACE FORGE — Autonomous Installer (Windows PowerShell)
#  Installs the native engine & registers Chrome Native Messaging host.
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ANSI Colors
$ESC = [char]27
$BOLD = "$ESC[1m"
$DIM = "$ESC[2m"
$CYAN = "$ESC[38;2;6;182;212m"
$BLUE = "$ESC[38;2;99;102;241m"
$GREEN = "$ESC[38;2;34;197;94m"
$YELLOW = "$ESC[38;2;234;179;8m"
$RED = "$ESC[38;2;239;68;68m"
$RESET = "$ESC[0m"

$HostName = "dev.gettrace.rust.host"
$Repo = "tracedevtools/Forge-release"
$BinaryName = "trace-http-bridge.exe"

$AssetCandidates = @(
    "trace-http-bridge.exe",
    "trace-http-bridge-x86_64-pc-windows-msvc.exe"
)

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
    "picocfmhmdhpefnlajhbgmindmnikpip"
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

# 1. Platform Detection
function Detect-Platform {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    Show-Step "1" "Platform detected" "$CYAN Windows x86_64 ($arch) $RESET"
}

# 2. Resolve Engine Version
function Resolve-Release {
    Show-Step "2" "Release repository" "$CYAN github.com/$Repo (v0.1.0) $RESET"
}

# 3. Realtime Download with Animated Block Progress Bar
function Download-Binary {
    Show-Step "3" "Downloading binary" "$DIM fetching engine from $Repo...$RESET"
    
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    $tempFile = Join-Path $InstallDir "$BinaryName.tmp"
    $downloadSuccess = $false

    foreach ($asset in $AssetCandidates) {
        $urls = @(
            "https://github.com/$Repo/releases/download/v0.1.0/$asset",
            "https://github.com/$Repo/releases/latest/download/$asset"
        )

        foreach ($url in $urls) {
            try {
                $webClient = New-Object System.Net.WebClient
                
                Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
                    $percent = $EventArgs.ProgressPercentage
                    $bytesIn = [math]::Round($EventArgs.BytesReceived / 1MB, 1)
                    $totalBytes = [math]::Round($EventArgs.TotalBytesToReceive / 1MB, 1)
                    
                    if ($totalBytes -gt 0) {
                        $barLength = 26
                        $completed = [math]::Floor(($percent / 100) * $barLength)
                        $remaining = $barLength - $completed
                        $bar = ("█" * $completed) + ("░" * $remaining)
                        Write-Host -NoNewline "`r      $script:CYAN[$bar]$script:RESET $script:BOLD$percent%$script:RESET  $script:DIM($bytesIn MB / $totalBytes MB)$script:RESET  "
                    }
                } | Out-Null

                $downloadTask = $webClient.DownloadFileTaskAsync($url, $tempFile)
                while (-not $downloadTask.IsCompleted -and -not $downloadTask.IsFaulted) {
                    Start-Sleep -Milliseconds 80
                }
                if ($downloadTask.IsCompleted -and (Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 1000000)) {
                    $downloadSuccess = $true
                    $finalBytes = [math]::Round((Get-Item $tempFile).Length / 1MB, 1)
                    $fullBar = "█" * 26
                    Write-Host "`r      $script:GREEN[$fullBar]$script:RESET $script:BOLD 100%$script:RESET  $script:DIM($finalBytes MB / $finalBytes MB)$script:RESET  "
                    Show-Success "Binary installed to $CYAN$FinalBinaryPath$RESET"
                    break
                }
            } catch {
                # Fallback to Invoke-WebRequest
                try {
                    Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
                    if ((Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 1000000)) {
                        $downloadSuccess = $true
                        Show-Success "Binary installed to $CYAN$FinalBinaryPath$RESET"
                        break
                    }
                } catch {}
            }
        }
        if ($downloadSuccess) { break }
    }

    if ($downloadSuccess -and (Test-Path $tempFile)) {
        Move-Item -Path $tempFile -Destination $FinalBinaryPath -Force
    } else {
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
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
    [System.IO.File]::WriteAllText($manifestPath, $manifestContent, [System.Text.Encoding]::UTF8)

    # Register in Windows Registry for Chrome, Edge, Brave
    $regPaths = @(
        "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName",
        "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$HostName",
        "HKCU:\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\$HostName"
    )

    $registeredCount = 0
    foreach ($regPath in $regPaths) {
        try {
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            Set-ItemProperty -Path $regPath -Name "(default)" -Value $manifestPath -Force | Out-Null
            $registeredCount++
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
