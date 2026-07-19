#!/bin/bash
set -euo pipefail

# Terminux Installation Script
# Installs binary, desktop entry, and icons system-wide.
# Usage: sudo ./scripts/install.sh [prefix]
# Default prefix: /usr/local

PREFIX="${1:-/usr/local}"
BINDIR="$PREFIX/bin"
APPDIR="$PREFIX/share/applications"
ICONDIR="$PREFIX/share/icons/hicolor"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo or as root."
    exit 1
fi

echo "=== Installing Terminux ==="
echo "Prefix: $PREFIX"
echo ""

# Check for binary
if [ ! -f "$SCRIPT_DIR/target/release/terminux" ]; then
    echo "Release binary not found. Building first..."
    cd "$SCRIPT_DIR"
    cargo build --release -p terminux-gui -p terminux
fi

# Install binary
echo ">>> Installing binary..."
mkdir -p "$BINDIR"
cp "$SCRIPT_DIR/target/release/terminux" "$BINDIR/terminux"
strip "$BINDIR/terminux"
chmod 755 "$BINDIR/terminux"

# Install desktop file
echo ">>> Installing desktop entry..."
mkdir -p "$APPDIR"
cp "$SCRIPT_DIR/packaging/linux/terminux.desktop" "$APPDIR/terminux.desktop"
chmod 644 "$APPDIR/terminux.desktop"

# Install icons
echo ">>> Installing icons..."
for size in 16x16 32x32 64x64 128x128 256x256; do
    mkdir -p "$ICONDIR/$size/apps"
    cp "$SCRIPT_DIR/packaging/linux/icons/$size/terminux.png" \
       "$ICONDIR/$size/apps/terminux.png"
    chmod 644 "$ICONDIR/$size/apps/terminux.png"
done
mkdir -p "$ICONDIR/scalable/apps"
cp "$SCRIPT_DIR/packaging/linux/icons/scalable/terminux.svg" \
   "$ICONDIR/scalable/apps/terminux.svg"
chmod 644 "$ICONDIR/scalable/apps/terminux.svg"

# Update desktop database
echo ">>> Updating desktop database..."
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$APPDIR" || true
fi

# Update icon cache
echo ">>> Updating icon cache..."
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$ICONDIR" || true
fi

# Set as x-terminal-emulator alternative
if command -v update-alternatives &>/dev/null; then
    update-alternatives --install /usr/bin/x-terminal-emulator \
        x-terminal-emulator "$BINDIR/terminux" 50 || true
fi

echo ""
echo "=== Installation complete ==="
echo "Terminux installed to $BINDIR/terminux"
echo "Run 'terminux start' to launch."
