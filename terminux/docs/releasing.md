# Releasing Terminux

This guide covers the process for publishing a new Terminux release.

## Versioning

Terminux follows [Semantic Versioning](https://semver.org/):

- **MAJOR** — incompatible API/behavior changes
- **MINOR** — new features (backward compatible)
- **PATCH** — bug fixes (backward compatible)

The version source of truth is the `.tag` file at the repository root:

```
echo "1.0.1" > .tag
git add .tag
git commit -m "Bump version to 1.0.1"
```

## Creating a Release

### 1. Update Version

```bash
echo "1.0.1" > .tag
git add .tag
git commit -m "chore: bump version to 1.0.1"
```

### 2. Update Release Notes

Edit `.github/RELEASE_TEMPLATE.md` with highlights and changes for this release.

### 3. Tag and Push

```bash
git tag -a v1.0.1 -m "Terminux 1.0.1"
git push origin v1.0.1
```

### 4. Automated Release

Pushing a tag `v*` triggers the GitHub Actions workflow `.github/workflows/release.yml` which:

1. Builds the release binary for `x86_64-unknown-linux-gnu`
2. Builds `.deb` package
3. Builds AppImage
4. Creates tarball with documentation
5. Generates SHA256 checksums
6. Creates a GitHub Release with all artifacts

### 5. Manual Release Build

To build artifacts locally:

```bash
# Set version
export VERSION=1.0.1
echo "$VERSION" > .tag

# Build binaries
cargo build --release -p terminux-gui -p terminux

# Build .deb
./packaging/debian/build-deb.sh

# Build AppImage
./packaging/appimage/build-appimage.sh

# Create tarball
mkdir -p dist/terminux-linux-x86_64
cp target/release/terminux dist/terminux-linux-x86_64/
cp target/release/terminux-gui dist/terminux-linux-x86_64/
cp README.md dist/terminux-linux-x86_64/
cp -r terminux/docs dist/terminux-linux-x86_64/docs
cp -r assets/icon dist/terminux-linux-x86_64/icons
cd dist
tar czf terminux-linux-x86_64.tar.gz terminux-linux-x86_64/

# Generate checksums
sha256sum *.tar.gz *.AppImage *.deb > SHA256SUMS
```

## Release Artifacts

| Artifact | Description |
|----------|-------------|
| `terminux-linux-x86_64.tar.gz` | Portable tarball — x86_64 (binary + docs + icons) |
| `terminux-linux-aarch64.tar.gz` | Portable tarball — ARM64 |
| `Terminux-1.0.1-x86_64.AppImage` | AppImage — x86_64 |
| `Terminux-1.0.1-aarch64.AppImage` | AppImage — ARM64 |
| `terminux_1.0.1_amd64.deb` | Debian/Ubuntu package — x86_64 |
| `terminux_1.0.1_arm64.deb` | Debian/Ubuntu package — ARM64 |
| `SHA256SUMS` | Checksums for verification |

## Post-Release

1. **Verify** the release on the GitHub Releases page
2. **Download** and test the AppImage on a clean system
3. **Download** and test the .deb on a clean Debian/Ubuntu system
4. **Update** the Homebrew formula if applicable
5. **Announce** on the repository discussion page

## Automated Checks

Before each release, verify:

```bash
# All tests pass
cargo test --workspace

# CLI works
./target/release/terminux --version
./target/release/terminux help

# Plugins load (if installed)
./target/release/terminux plugin list

# Sessions work
./target/release/terminux session list

# Themes work
./target/release/terminux theme list
```
