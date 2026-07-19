## Terminux ${{ github.ref_name }}

### Highlights

- GPU-accelerated terminal emulator forked from WezTerm
- Session persistence with crash recovery
- Plugin system with Lua-based configuration
- Workspace snapshots and management
- SSH client with multiplexer support
- 40+ built-in themes with theme pack support

### New Features

- Session persistence & workspace recovery (Phase 7)
- Plugin system with sandboxed Lua API (Phase 6)
- Dashboard with recent sessions, theme picker, SSH profiles (Phase 5)
- Custom theme engine with dark/light variants (Phase 4)
- Workspace management with save/switch/clear (Phase 3)
- Command palette (CTRL+SHIFT+P) (Phase 2)
- Branded Terminux identity (Phase 1)

### Bug Fixes

- Fixed `require .terminux.;` syntax error in test
- Improved Lua module path resolution for development builds

### Known Issues

- Scrollback buffer is not preserved across session restores
- SSH session restore requires manual reconnection
- Pane split topology is flattened during session restore
- Windows and macOS builds are not yet available for Terminux

### Installation

#### AppImage (Linux, any distro)

Choose for your architecture:

```bash
# x86_64 (Intel/AMD)
chmod +x Terminux-1.0.0-x86_64.AppImage
./Terminux-1.0.0-x86_64.AppImage

# ARM64 (aarch64)
chmod +x Terminux-1.0.0-aarch64.AppImage
./Terminux-1.0.0-aarch64.AppImage
```

#### Debian / Ubuntu

```bash
# x86_64
sudo dpkg -i terminux_1.0.0_amd64.deb

# ARM64
sudo dpkg -i terminux_1.0.0_arm64.deb

terminux start
```

#### Tarball

```bash
# x86_64
tar xzf terminux-linux-x86_64.tar.gz
cd terminux-linux-x86_64

# ARM64
tar xzf terminux-linux-aarch64.tar.gz
cd terminux-linux-aarch64

./terminux start
```

### Checksums

SHA256 checksums are in `SHA256SUMS`. Verify with:

```bash
sha256sum -c SHA256SUMS
```
