# Building Terminux from Source

## Prerequisites

### System Dependencies (Debian/Ubuntu)

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    pkg-config \
    libx11-dev \
    libxext-dev \
    libxft-dev \
    libxinerama-dev \
    libxcursor-dev \
    libxrender-dev \
    libxfixes-dev \
    libpango1.0-dev \
    libgl1-mesa-dev \
    libegl1-mesa-dev \
    libwayland-dev \
    wayland-protocols \
    libxkbcommon-dev \
    libdbus-1-dev \
    libpulse-dev \
    libfontconfig-dev \
    libfreetype6-dev \
    libssl-dev
```

### Fedora / RHEL

```bash
sudo dnf install -y \
    gcc gcc-c++ make git pkg-config \
    libX11-devel libXext-devel libXft-devel \
    libXinerama-devel libXcursor-devel libXrender-devel \
    libXfixes-devel pango-devel mesa-libGL-devel \
    mesa-libEGL-devel wayland-devel wayland-protocols-devel \
    libxkbcommon-devel dbus-devel pulseaudio-libs-devel \
    fontconfig-devel freetype-devel openssl-devel
```

### Arch Linux

```bash
sudo pacman -S --needed \
    base-devel git pkg-config \
    libx11 libxext libxft libxinerama libxcursor \
    libxrender libxfixes pango mesa wayland \
    wayland-protocols libxkbcommon dbus libpulse \
    fontconfig freetype2 openssl
```

### Rust Toolchain

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustup update stable
```

Minimum Rust version: **1.77.0**

## Clone

```bash
git clone https://github.com/desalegnfitsum116-art/Terminux.git
cd Terminux
```

## Build

### Release Build (Recommended)

```bash
cargo build --release -p terminux-gui -p terminux
```

This produces:
- `target/release/terminux` — CLI binary
- `target/release/terminux-gui` — GUI binary

### Debug Build

```bash
cargo build -p terminux-gui -p terminux
```

### Build Only the CLI

```bash
cargo build --release -p terminux
```

## Run After Build

```bash
# Start the terminal
./target/release/terminux start

# Run a specific command
./target/release/terminux start -- bash

# Show version
./target/release/terminux --version
```

## Testing

```bash
# Run all tests
cargo test --workspace

# Run specific test
cargo test -p config -- lua
```

## Build Optimizations

The release profile includes:

```toml
[profile.release]
opt-level = 3
lto = true
codegen-units = 1
strip = true
panic = "abort"
```

First build will be **slow** (LTO + single codegen unit). Subsequent builds are incremental.

## Build Output

| File | Size (approx) | Description |
|------|--------------|-------------|
| `target/release/terminux` | ~15 MB | Main CLI binary (launches GUI, manages sessions, themes, plugins) |
| `target/release/terminux-gui` | ~30 MB | GUI process (rendering, window management) |

## Troubleshooting Builds

| Error | Solution |
|-------|----------|
| `openssl-sys` build failure | Install OpenSSL dev headers: `sudo apt install libssl-dev` |
| `cairo-rs` build failure | Install Cairo dev headers: `sudo apt install libcairo2-dev` |
| `libdbus` not found | Install DBus dev headers: `sudo apt install libdbus-1-dev` |
| `libpulse` not found | Install PulseAudio dev headers: `sudo apt install libpulse-dev` |
| Rust is too old | Run `rustup update stable` |
| Out of memory during LTO | Add `export CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_STRATEGY=1` |
| "requires link to `EGL`" | `sudo apt install libegl1-mesa-dev` |
