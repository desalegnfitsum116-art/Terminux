#!/bin/bash
set -euo pipefail

# Terminux Uninstallation Script
# Removes binary, desktop entry, and icons.
# Usage: sudo ./scripts/uninstall.sh [prefix]
# Default prefix: /usr/local

PREFIX="${1:-/usr/local}"
BINDIR="$PREFIX/bin"
APPDIR="$PREFIX/share/applications"
ICONDIR="$PREFIX/share/icons/hicolor"

if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo or as root."
    exit 1
fi

echo "=== Uninstalling Terminux ==="

# Remove binary
if [ -f "$BINDIR/terminux" ]; then
    echo ">>> Removing binary..."
    rm -f "$BINDIR/terminux"
fi

# Remove desktop file
if [ -f "$APPDIR/terminux.desktop" ]; then
    echo ">>> Removing desktop entry..."
    rm -f "$APPDIR/terminux.desktop"
fi

# Remove icons
echo ">>> Removing icons..."
for size in 16x16 32x32 64x64 128x128 256x256 scalable; do
    rm -f "$ICONDIR/$size/apps/terminux.png"
    rm -f "$ICONDIR/$size/apps/terminux.svg"
done

# Remove x-terminal-emulator alternative
if command -v update-alternatives &>/dev/null; then
    update-alternatives --remove x-terminal-emulator "$BINDIR/terminux" 2>/dev/null || true
fi

# Update databases
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$APPDIR" || true
fi
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$ICONDIR" || true
fi

echo "=== Uninstallation complete ==="
