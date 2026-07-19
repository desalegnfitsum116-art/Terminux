#!/bin/bash
set -euo pipefail

# Terminux AppImage Builder
# Requirements: docker or appimagetool, rsync, fuse
# Usage: ./packaging/appimage/build-appimage.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/appimage"
APPDIR="$BUILD_DIR/AppDir"
DIST_DIR="$PROJECT_DIR/dist"
VERSION="${VERSION:-1.0.0}"
ARCH="${ARCH:-x86_64}"

echo "=== Terminux AppImage Builder ==="
echo "Version: $VERSION"
echo "Arch:    $ARCH"
echo ""

# Step 1: Build release binary
echo ">>> Building Terminux release binary..."
cd "$PROJECT_DIR"
cargo build --release -p terminux-gui -p terminux
echo "Build complete."
echo ""

# Step 2: Create AppDir structure
echo ">>> Creating AppDir..."
rm -rf "$BUILD_DIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/icons/hicolor/scalable/apps"

# Step 3: Copy binary and assets
echo ">>> Copying assets..."
cp "$PROJECT_DIR/target/release/terminux" "$APPDIR/usr/bin/terminux"
cp "$PROJECT_DIR/target/release/terminux-gui" "$APPDIR/usr/bin/terminux-gui"
cp "$PROJECT_DIR/packaging/linux/terminux.desktop" "$APPDIR/usr/share/applications/terminux.desktop"
cp "$PROJECT_DIR/packaging/linux/icons/256x256/terminux.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/terminux.png"
cp "$PROJECT_DIR/packaging/linux/icons/scalable/terminux.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/terminux.svg"

# Step 4: Create AppRun
cp "$SCRIPT_DIR/AppRun" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"

# Step 5: Copy libEGL and libGL if needed (common on older systems)
echo ">>> Checking for required libraries..."
mkdir -p "$APPDIR/usr/lib"
# Search both /usr/lib and /usr/lib64, and arch-specific paths
LIB_PATHS=("/usr/lib" "/usr/lib64" "/usr/lib/$ARCH-linux-gnu" "/lib/$ARCH-linux-gnu")
for lib in libEGL.so.1 libGL.so.1 libwayland-client.so.0 libxkbcommon.so.0; do
    for lp in "${LIB_PATHS[@]}"; do
        found=$(find "$lp" -maxdepth 1 -name "$lib" 2>/dev/null | head -1)
        if [ -n "$found" ]; then
            cp "$found" "$APPDIR/usr/lib/"
            break
        fi
    done
done

# Step 6: Copy desktop file to top level for AppImage detection
cp "$PROJECT_DIR/packaging/linux/terminux.desktop" "$APPDIR/terminux.desktop"
cp "$PROJECT_DIR/packaging/linux/icons/256x256/terminux.png" "$APPDIR/terminux.png"

# Step 7: Build AppImage
echo ">>> Building AppImage..."
mkdir -p "$DIST_DIR"
APPIMAGE_NAME="Terminux-${VERSION}-${ARCH}.AppImage"

if command -v appimagetool &>/dev/null; then
    appimagetool "$APPDIR" "$DIST_DIR/$APPIMAGE_NAME"
elif command -v docker &>/dev/null; then
    echo "appimagetool not found, trying Docker..."
    docker run --rm -v "$APPDIR:/AppDir" -v "$DIST_DIR:/dist" \
        -e ARCH="$ARCH" -e VERSION="$VERSION" \
        appimagecrafters/appimagetool \
        /AppDir "/dist/$APPIMAGE_NAME"
else
    echo "ERROR: appimagetool or Docker required."
    echo "Install appimagetool from: https://github.com/AppImage/AppImageKit/releases"
    exit 1
fi

echo ""
echo "=== AppImage built successfully ==="
echo "Output: $DIST_DIR/$APPIMAGE_NAME"
ls -lh "$DIST_DIR/$APPIMAGE_NAME"
