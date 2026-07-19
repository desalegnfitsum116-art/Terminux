#!/bin/bash
set -euo pipefail

# Terminux Debian Package Builder
# Usage: ARCH=amd64 ./packaging/debian/build-deb.sh
#        ARCH=arm64 ./packaging/debian/build-deb.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
VERSION="${VERSION:-1.0.0}"
ARCH="${ARCH:-$(dpkg --print-architecture 2>/dev/null || echo amd64)}"

# Map arch triple to Debian arch
case "$ARCH" in
    x86_64|amd64) DEB_ARCH="amd64" ;;
    aarch64|arm64) DEB_ARCH="arm64" ;;
    *) DEB_ARCH="$ARCH" ;;
esac

RUST_TARGET=""
case "$DEB_ARCH" in
    amd64) RUST_TARGET="x86_64-unknown-linux-gnu" ;;
    arm64) RUST_TARGET="aarch64-unknown-linux-gnu" ;;
esac

echo "=== Terminux Debian Package Builder ==="
echo "Version: $VERSION"
echo "Arch:    $DEB_ARCH"
echo "Target:  $RUST_TARGET"
echo ""

# Step 1: Build release binary
echo ">>> Building release binary..."
cd "$PROJECT_DIR"
if [ -n "$RUST_TARGET" ] && [ "$DEB_ARCH" != "$(dpkg --print-architecture 2>/dev/null)" ]; then
    rustup target add "$RUST_TARGET"
    cargo build --release --target "$RUST_TARGET" -p terminux-gui -p terminux
    BIN_DIR="$PROJECT_DIR/target/$RUST_TARGET/release"
else
    cargo build --release -p terminux-gui -p terminux
    BIN_DIR="$PROJECT_DIR/target/release"
fi
echo "Build complete."
echo ""

# Step 2: Copy binary into packaging dir
echo ">>> Preparing package files..."
mkdir -p "$SCRIPT_DIR/usr/bin"
cp "$BIN_DIR/terminux" "$SCRIPT_DIR/usr/bin/terminux"
strip "$SCRIPT_DIR/usr/bin/terminux"

# Step 3: Update version and architecture in control file
# Save originals for restore
CONTROL="$SCRIPT_DIR/DEBIAN/control"
CONTROL_ORIG="$CONTROL.bak"
cp "$CONTROL" "$CONTROL_ORIG"
sed -i "s/Version:.*/Version: $VERSION/" "$CONTROL"
sed -i "s/Architecture:.*/Architecture: $DEB_ARCH/" "$CONTROL"

# Step 4: Build .deb
echo ">>> Building .deb package..."
mkdir -p "$DIST_DIR"
DEB_NAME="terminux_${VERSION}_${DEB_ARCH}.deb"
dpkg-deb --build "$SCRIPT_DIR" "$DIST_DIR/$DEB_NAME"

# Restore original control file
mv "$CONTROL_ORIG" "$CONTROL"

echo ""
echo "=== Debian package built successfully ==="
echo "Output: $DIST_DIR/$DEB_NAME"
ls -lh "$DIST_DIR/$DEB_NAME"
