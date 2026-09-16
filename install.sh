#!/usr/bin/env bash
# ==============================================================================
# Trace Forge — One-Line Installer & Service Configurator
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/tracedevtools/Forge-release/main/install.sh | bash
# ==============================================================================

set -eo pipefail

# Visual styling
if [ -t 1 ]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  CYAN="\033[36m"
  BLUE="\033[34m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  RED="\033[31m"
  RESET="\033[0m"
else
  BOLD=""
  DIM=""
  CYAN=""
  BLUE=""
  GREEN=""
  YELLOW=""
  RED=""
  RESET=""
fi

HOST_NAME="dev.gettrace.rust.host"
REPO="tracedevtools/Forge-release"
DEFAULT_WORKSPACE="$HOME/Documents/Trace/greenfield"
INSTALL_DIR="$HOME/.local/share/trace-rust/native-host"
BINARY_NAME="trace-http-bridge"

ALLOWED_EXTENSION_IDS=(
  "akabcpcfdkapeompkabhpdaofmmfjcdh"
  "adiiaelmeohkajiddjedcgjmkkhjnfcm"
  "hmlngfjlohkgbhkkhomipdbgkdgogolc"
  "jbndfblonpaiajoilmcfjnilbfidnikg"
  "nihkoalbpdeldlfkbpadfjidaampnobn"
  "ijempdjhomdhgjbjekbmdhlknmgmiahe"
  "picocfmhmdhpefnlajhbgmindmnikpip"
  "edapgfkgaeajkhhpchfhljppbpbffggg"
)

# Banner
print_banner() {
  printf "\n"
  printf "${CYAN}${BOLD}"
  cat << "BANNER"
  ______                     ______                    
 /_  __/________ _________   / ____/___  _________ ____ 
  / / / ___/ __ `/ ___/ _ \ / /_  / __ \/ ___/ __ `/ _ \
 / / / /  / /_/ / /__/  __// __/ / /_/ / /  / /_/ /  __/
/_/ /_/   \__,_/\___/\___//_/    \____/_/   \__, /\___/ 
                                           /____/       
BANNER
  printf "${RESET}"
  printf "        ${BLUE}⚡ BROWSER-NATIVE AI CODING ENGINE${RESET}\n"
  printf "${DIM}──────────────────────────────────────────────────────────────────${RESET}\n\n"
}

info_step() {
  local num="$1"
  local title="$2"
  local desc="$3"
  printf "  ${BLUE}${BOLD}[${num}/5]${RESET} ${title} ${DIM}→${RESET} ${desc}\n"
}

success_step() {
  local msg="$1"
  printf "      ${GREEN}✓${RESET} ${msg}\n"
}

warn_step() {
  local msg="$1"
  printf "      ${YELLOW}⚠${RESET} ${msg}\n"
}

error_exit() {
  printf "\n  ${RED}${BOLD}✗ Installation failed:${RESET} %s\n\n" "$1" >&2
  exit 1
}

# 1. Platform Detection
detect_platform() {
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  
  case "$OS" in
    Darwin)
      case "$ARCH" in
        arm64)  PLATFORM_LABEL="macOS (Apple Silicon arm64)" ; ASSET_NAME="trace-http-bridge" ;;
        x86_64) PLATFORM_LABEL="macOS (Intel x86_64)" ; ASSET_NAME="trace-http-bridge" ;;
        *)      error_exit "Unsupported macOS architecture: $ARCH" ;;
      esac
      ;;
    Linux)
      case "$ARCH" in
        x86_64)        PLATFORM_LABEL="Linux (x86_64)" ; ASSET_NAME="trace-http-bridge" ;;
        aarch64|arm64) PLATFORM_LABEL="Linux (ARM64)" ; ASSET_NAME="trace-http-bridge" ;;
        *)             error_exit "Unsupported Linux architecture: $ARCH" ;;
      esac
      ;;
    *)
      error_exit "Unsupported OS: $OS. Trace Forge supports macOS, Linux, and Windows (via install.ps1)."
      ;;
  esac

  info_step "1" "Platform detected" "${CYAN}${PLATFORM_LABEL}${RESET}"
}

# 2. Resolve Release
resolve_release() {
  info_step "2" "Release repository" "${CYAN}github.com/${REPO} (v0.1.0)${RESET}"
}

# 3. Download Binary
download_binary() {
  info_step "3" "Downloading binary" "${DIM}fetching engine from ${REPO}...${RESET}"
  
  mkdir -p "$INSTALL_DIR"
  local temp_dest="$INSTALL_DIR/${BINARY_NAME}.tmp"
  local final_dest="$INSTALL_DIR/${BINARY_NAME}"
  local downloaded=false

  local urls=(
    "https://github.com/${REPO}/releases/download/v0.1.0/${ASSET_NAME}"
    "https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"
  )

  for url in "${urls[@]}"; do
    rm -f "$temp_dest"
    printf "      ${CYAN}⬇ Downloading trace-http-bridge (~38 MB):${RESET}\n"
    if curl --fail --location --progress-bar "$url" --output "$temp_dest"; then
      if [ -s "$temp_dest" ]; then
        mv -f "$temp_dest" "$final_dest"
        chmod +x "$final_dest"
        downloaded=true
        printf "\n"
        success_step "Binary installed to ${CYAN}${final_dest}${RESET}"
        break
      fi
    fi
    rm -f "$temp_dest"
  done

  if [ "$downloaded" = false ]; then
    if [ -f "$final_dest" ] && [ -x "$final_dest" ]; then
      warn_step "Remote release unreachable; using existing binary at ${CYAN}${final_dest}${RESET}"
    else
      rm -f "$temp_dest"
      error_exit "Could not download binary from https://github.com/${REPO}. Please verify release assets on GitHub."
    fi
  fi
}

# 4. Register Native Messaging Host
register_manifests() {
  info_step "4" "Registering native host" "${CYAN}${HOST_NAME}${RESET}"
  
  local final_dest="$INSTALL_DIR/${BINARY_NAME}"
  
  # Build JSON manifest
  local manifest_json="{\n  \"name\": \"${HOST_NAME}\",\n  \"description\": \"Trace Forge Native Messaging Host\",\n  \"path\": \"${final_dest}\",\n  \"type\": \"stdio\",\n  \"allowed_origins\": [\n"
  local count=${#ALLOWED_EXTENSION_IDS[@]}
  for ((i=0; i<count; i++)); do
    manifest_json+="    \"chrome-extension://${ALLOWED_EXTENSION_IDS[i]}/\""
    if [ $i -lt $((count - 1)) ]; then
      manifest_json+=",\n"
    else
      manifest_json+="\n"
    fi
  done
  manifest_json+="  ]\n}"

  # Target Browser Directories
  local target_dirs=()
  if [ "$(uname -s)" = "Darwin" ]; then
    target_dirs+=(
      "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
      "$HOME/Library/Application Support/Chromium/NativeMessagingHosts"
      "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"
      "$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
      "$HOME/Library/Application Support/Arc/User Data/NativeMessagingHosts"
    )
  else
    target_dirs+=(
      "$HOME/.config/google-chrome/NativeMessagingHosts"
      "$HOME/.config/chromium/NativeMessagingHosts"
      "$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
      "$HOME/.config/microsoft-edge/NativeMessagingHosts"
    )
  fi

  local registered=0
  for dir in "${target_dirs[@]}"; do
    mkdir -p "$dir" 2>/dev/null || true
    if [ -d "$dir" ]; then
      printf "%b" "$manifest_json" > "$dir/${HOST_NAME}.json" 2>/dev/null && ((registered++)) || true
    fi
  done

  success_step "Native messaging manifest registered across ${registered} browser profiles"

  # Greenfield Workspace
  mkdir -p "$DEFAULT_WORKSPACE" 2>/dev/null || true
  if [ ! -f "$DEFAULT_WORKSPACE/README.md" ]; then
    cat << 'README' > "$DEFAULT_WORKSPACE/README.md"
# Trace Greenfield
This is your default Trace workspace for building new web applications.
Trace creates new projects here when you click Connect in the Trace extension.
README
  fi
  success_step "Workspace ready at ${DIM}${DEFAULT_WORKSPACE}${RESET}"
}

# 5. Background Daemon Registration (Decoupled from Chrome)
setup_daemon() {
  local final_dest="$INSTALL_DIR/${BINARY_NAME}"

  if [ "$(uname -s)" = "Darwin" ]; then
    info_step "5" "Configuring LaunchAgent daemon" "${CYAN}dev.gettrace.forge${RESET}"
    local agents_dir="$HOME/Library/LaunchAgents"
    local plist_path="$agents_dir/dev.gettrace.forge.plist"
    local log_dir="$HOME/.trace/logs"

    mkdir -p "$agents_dir" "$log_dir" 2>/dev/null || true

    cat << PLIST > "$plist_path"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dev.gettrace.forge</string>
    <key>ProgramArguments</key>
    <array>
        <string>${final_dest}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${log_dir}/forge-daemon.log</string>
    <key>StandardErrorPath</key>
    <string>${log_dir}/forge-daemon.err</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${HOME}/.cargo/bin:${HOME}/.local/bin</string>
        <key>TRACE_HTTP_PORT</key>
        <string>8766</string>
        <key>RUST_BACKTRACE</key>
        <string>1</string>
    </dict>
</dict>
</plist>
PLIST

    # Bootstrap with launchctl
    local uid_num
    uid_num=$(id -u)
    launchctl bootout "gui/$uid_num/dev.gettrace.forge" 2>/dev/null || launchctl unload "$plist_path" 2>/dev/null || true
    if launchctl bootstrap "gui/$uid_num" "$plist_path" 2>/dev/null || launchctl load -w "$plist_path" 2>/dev/null; then
      success_step "LaunchAgent registered & active (independent from browser, auto-restarts on crash)"
    else
      warn_step "Could not load LaunchAgent via launchctl (will start automatically on demand)"
    fi
  elif [ "$(uname -s)" = "Linux" ]; then
    info_step "5" "Configuring systemd user service" "${CYAN}trace-forge${RESET}"
    local unit_dir="$HOME/.config/systemd/user"
    mkdir -p "$unit_dir" 2>/dev/null || true
    cat << SERVICE > "$unit_dir/trace-forge.service"
[Unit]
Description=Trace Forge Background Engine
After=network.target

[Service]
ExecStart=${final_dest}
Restart=always
RestartSec=2
Environment=TRACE_HTTP_PORT=8766
Environment=PATH=/usr/local/bin:/usr/bin:/bin:${HOME}/.cargo/bin:${HOME}/.local/bin

[Install]
WantedBy=default.target
SERVICE
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now trace-forge 2>/dev/null && success_step "systemd user service enabled & running" || true
  fi
}

# Summary Screen
print_summary() {
  local final_dest="$INSTALL_DIR/${BINARY_NAME}"
  printf "\n${DIM}──────────────────────────────────────────────────────────────────${RESET}\n"
  printf "  ${GREEN}${BOLD}✅ Trace Forge installed successfully!${RESET}\n\n"
  printf "  ${BOLD}Binary:${RESET}    ${CYAN}%s${RESET}\n" "$final_dest"
  printf "  ${BOLD}Host ID:${RESET}   ${DIM}%s${RESET}\n" "$HOST_NAME"
  printf "  ${BOLD}Daemon:${RESET}    ${DIM}dev.gettrace.forge (independent background daemon)${RESET}\n"
  printf "  ${BOLD}Workspace:${RESET} ${DIM}%s${RESET}\n\n" "$DEFAULT_WORKSPACE"
  printf "  ${BLUE}${BOLD}🚀 Next Step:${RESET} Open Chrome and click ${BOLD}Connect${RESET} in the Trace panel.\n"
  printf "${DIM}──────────────────────────────────────────────────────────────────${RESET}\n\n"
}

main() {
  print_banner
  detect_platform
  resolve_release
  download_binary
  register_manifests
  setup_daemon
  print_summary
}

main "$@"
