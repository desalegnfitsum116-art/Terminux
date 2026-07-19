# Installing Terminux

## System Requirements

- **OS:** Linux (x86_64)
- **GPU:** OpenGL 3.3+ or Vulkan 1.0+ capable
- **RAM:** 256 MB minimum
- **Disk:** ~50 MB for binary

## Option 1: AppImage (Recommended)

The AppImage is portable and works on any Linux distribution. Choose the file for your architecture.

### x86_64 (Intel/AMD)

```bash
wget https://github.com/desalegnfitsum116-art/Terminux/releases/download/v1.0.0/Terminux-1.0.0-x86_64.AppImage
chmod +x Terminux-1.0.0-x86_64.AppImage
./Terminux-1.0.0-x86_64.AppImage
```

### ARM64 (aarch64, e.g. Raspberry Pi, Apple Silicon VMs)

```bash
wget https://github.com/desalegnfitsum116-art/Terminux/releases/download/v1.0.0/Terminux-1.0.0-aarch64.AppImage
chmod +x Terminux-1.0.0-aarch64.AppImage
./Terminux-1.0.0-aarch64.AppImage
```

To integrate into your desktop:

```bash
# Extract
./Terminux-1.0.0-*.AppImage --appimage-extract

# Install system-wide with the install script
sudo ./scripts/install.sh /usr/local
```

## Option 2: Debian / Ubuntu (.deb)

### x86_64

```bash
wget https://github.com/desalegnfitsum116-art/Terminux/releases/download/v1.0.0/terminux_1.0.0_amd64.deb
sudo dpkg -i terminux_1.0.0_amd64.deb
sudo apt-get install -f
terminux start
```

### ARM64

```bash
wget https://github.com/desalegnfitsum116-art/Terminux/releases/download/v1.0.0/terminux_1.0.0_arm64.deb
sudo dpkg -i terminux_1.0.0_arm64.deb
sudo apt-get install -f
terminux start
```

To remove:

```bash
sudo dpkg -r terminux
```

## Option 3: Tarball

### x86_64

```bash
wget https://github.com/desalegnfitsum116-art/Terminux/releases/download/v1.0.0/terminux-linux-x86_64.tar.gz
tar xzf terminux-linux-x86_64.tar.gz
cd terminux-linux-x86_64
./terminux start
```

### ARM64

```bash
wget https://github.com/desalegnfitsum116-art/Terminux/releases/download/v1.0.0/terminux-linux-aarch64.tar.gz
tar xzf terminux-linux-aarch64.tar.gz
cd terminux-linux-aarch64
./terminux start
```

## Option 4: Install Script

Build from source and install system-wide:

```bash
# Build
cargo build --release -p terminux-gui -p terminux

# Install (requires sudo)
sudo ./scripts/install.sh /usr/local
```

## Option 5: Build from Source

See [build-from-source.md](build-from-source.md) for detailed build instructions.

## Post-Installation

### First Launch

```bash
terminux start
```

On first launch:

1. The **Terminux Dashboard** appears
2. Configure your theme, font, and SSH profiles via the dashboard or command palette
3. Explore the command palette with `CTRL+SHIFT+P`

### Verify Installation

```bash
terminux --version
```

Expected output:

```
Terminux 1.0.0
Based on WezTerm
Renderer: GPU
```

### Check Dependencies

```bash
ldd $(which terminux)
```

All libraries should resolve (no "not found" entries).

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `libEGL.so.1 not found` | `sudo apt install libegl1-mesa` |
| `libwayland-client.so.0 not found` | `sudo apt install libwayland-client0` |
| `terminux: command not found` | Ensure `~/.local/bin` or install prefix is in `$PATH` |
| AppImage won't run | Install FUSE: `sudo apt install fuse libfuse2` |
| No GPU rendering | Try software rendering: `LIBGL_ALWAYS_SOFTWARE=1 terminux start` |
