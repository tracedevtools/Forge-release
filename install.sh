#!/usr/bin/env bash
# Trace Rust Agent — One-line Native Host Installer
set -euo pipefail

REPO="tracedevtools/Forge-release"
BINARY_NAME="trace-http-bridge"
HOST_NAME="dev.gettrace.rust.host"

# Allowed Chrome Extension IDs
EXTENSION_IDS=(
  "akabcpcfdkapeompkabhpdaofmmfjcdh"
  "adiiaelmeohkajiddjedcgjmkkhjnfcm"
  "hmlngfjlohkgbhkkhomipdbgkdgogolc"
  "nihkoalbpdeldlfkbpadfjidaampnobn"
  "jbndfblonpaiajoilmcfjnilbfidnikg"
)

# Append custom extension ID if passed via environment
if [ -n "${TRACE_EXTENSION_ID:-}" ]; then
  EXTENSION_IDS+=("$TRACE_EXTENSION_ID")
fi

info() { printf '\033[1;34m%s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m%s\033[0m\n' "$*"; }
err()  { printf '\033[1;31merror: %s\033[0m\n' "$*" >&2; exit 1; }

echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "   ⚡ Installing Trace Rust Native Agent Host      "
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Determine OS and target paths
OS="$(uname -s)"
case "$OS" in
  Darwin)
    INSTALL_DIR="$HOME/.local/share/trace-rust/native-host"
    CHROME_HOST_DIRS=(
      "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
      "$HOME/Library/Application Support/Google/Chrome Canary/NativeMessagingHosts"
      "$HOME/Library/Application Support/Chromium/NativeMessagingHosts"
      "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"
      "$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
    )
    ;;
  Linux)
    INSTALL_DIR="$HOME/.local/share/trace-rust/native-host"
    CHROME_HOST_DIRS=(
      "$HOME/.config/google-chrome/NativeMessagingHosts"
      "$HOME/.config/chromium/NativeMessagingHosts"
      "$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
      "$HOME/.config/microsoft-edge/NativeMessagingHosts"
    )
    ;;
  *)
    err "Unsupported operating system: $OS. Trace Native Host currently supports macOS and Linux."
    ;;
esac

mkdir -p "$INSTALL_DIR"

# 2. Download the prebuilt binary from GitHub Release
TARGET_BIN="$INSTALL_DIR/$BINARY_NAME"
VERSION="${TRACE_VERSION:-latest}"

if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${BINARY_NAME}"
else
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"
fi

info "• Downloading ${BINARY_NAME}..."
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

if ! curl -fSL "$DOWNLOAD_URL" -o "$tmpfile" 2>/dev/null; then
  # Fallback to direct releases if latest redirect is resolving differently
  FALLBACK_URL="https://github.com/${REPO}/releases/download/untagged-2766db8a16269b3aa27c/${BINARY_NAME}"
  info "  Attempting release download..."
  curl -fSL "$FALLBACK_URL" -o "$tmpfile" || err "Failed to download binary from GitHub Releases ($DOWNLOAD_URL)"
fi

install -m 755 "$tmpfile" "$TARGET_BIN"

# Remove macOS quarantine attribute
if [ "$OS" = "Darwin" ]; then
  xattr -d com.apple.quarantine "$TARGET_BIN" 2>/dev/null || true
fi
ok "✓ Binary installed at: $TARGET_BIN"

# 3. Build allowed_origins JSON array
ORIGINS=""
for id in "${EXTENSION_IDS[@]}"; do
  [ -n "$id" ] || continue
  if [ -n "$ORIGINS" ]; then
    ORIGINS="${ORIGINS},\n"
  fi
  ORIGINS="${ORIGINS}    \"chrome-extension://${id}/\""
done

# 4. Generate Chrome Native Messaging Host Manifest
MANIFEST_CONTENT=$(cat <<EOF
{
  "name": "${HOST_NAME}",
  "description": "Trace Rust Agent Native Messaging Host",
  "path": "${TARGET_BIN}",
  "type": "stdio",
  "allowed_origins": [
$(printf "$ORIGINS")
  ]
}
EOF
)

registered_count=0
for host_dir in "${CHROME_HOST_DIRS[@]}"; do
  parent_browser_dir="$(dirname "$host_dir")"
  # Only register if the browser is installed / directory exists, or for default Chrome
  if [ -d "$parent_browser_dir" ] || [[ "$host_dir" == *"Google/Chrome/"* ]] || [[ "$host_dir" == *"google-chrome"* ]]; then
    mkdir -p "$host_dir"
    echo "$MANIFEST_CONTENT" > "$host_dir/${HOST_NAME}.json"
    registered_count=$((registered_count + 1))
  fi
done
ok "✓ Registered Chrome Native Messaging Manifest for $registered_count browser(s)"

# 5. Create default greenfield workspace
GREENFIELD_DIR="$HOME/Documents/Trace/greenfield"
mkdir -p "$GREENFIELD_DIR"
if [ ! -f "$GREENFIELD_DIR/README.md" ]; then
  cat > "$GREENFIELD_DIR/README.md" <<EOF
# Trace Greenfield
This is your default Trace workspace for new projects.
EOF
fi
ok "✓ Workspace ready: $GREENFIELD_DIR"

echo ""
ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "✅ Trace Native Host installation complete!"
ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Reload your Trace extension in Chrome (chrome://extensions)"
echo "  2. Click 'Connect' inside the extension"
echo "  3. Chrome will automatically launch the Rust agent binary"
echo ""
