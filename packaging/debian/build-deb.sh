#!/bin/bash
set -euo pipefail

# Terminux Debian Package Builder
# Usage: ./packaging/debian/build-deb.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
VERSION="${VERSION:-1.0.0}"

echo "=== Terminux Debian Package Builder ==="
echo "Version: $VERSION"
echo ""

# Step 1: Build release binary
echo ">>> Building release binary..."
cd "$PROJECT_DIR"
cargo build --release -p terminux-gui -p terminux
echo "Build complete."
echo ""

# Step 2: Copy binary into packaging dir
echo ">>> Preparing package files..."
mkdir -p "$SCRIPT_DIR/usr/bin"
cp "$PROJECT_DIR/target/release/terminux" "$SCRIPT_DIR/usr/bin/terminux"
strip "$SCRIPT_DIR/usr/bin/terminux"

# Step 3: Update control version
sed -i "s/Version:.*/Version: $VERSION/" "$SCRIPT_DIR/DEBIAN/control"

# Step 4: Build .deb
echo ">>> Building .deb package..."
mkdir -p "$DIST_DIR"
DEB_NAME="terminux_${VERSION}_amd64.deb"
dpkg-deb --build "$SCRIPT_DIR" "$DIST_DIR/$DEB_NAME"

echo ""
echo "=== Debian package built successfully ==="
echo "Output: $DIST_DIR/$DEB_NAME"
ls -lh "$DIST_DIR/$DEB_NAME"
