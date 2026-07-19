# Terminux Release Checklist

Use this checklist before and after publishing a release.

## Pre-Release

- [ ] All tests pass: `cargo test --workspace`
- [ ] Release builds succeed: `cargo build --release -p terminux-gui -p terminux`
- [ ] Version is correct: `.tag` file has the intended version
- [ ] `--version` output is correct: `./target/release/terminux --version`
- [ ] CLI commands work:
  - [ ] `terminux help` shows all subcommands
  - [ ] `terminux theme list` shows themes
  - [ ] `terminux plugin list` shows plugins (if installed)
  - [ ] `terminux session list` shows sessions
- [ ] `.tag` file is committed and pushed
- [ ] Git tag is created: `git tag -a v<VERSION> -m "Terminux <VERSION>"`
- [ ] Release notes are updated in `.github/RELEASE_TEMPLATE.md`
- [ ] GitHub Actions workflow is valid

## Build Verification

- [ ] Release binary builds with LTO:
  ```bash
  cargo build --release -p terminux-gui -p terminux
  ```
- [ ] Binary is stripped: `file target/release/terminux` (should not say "not stripped")
- [ ] No missing shared libraries: `ldd target/release/terminux | grep "not found"`
- [ ] .deb package builds:
  ```bash
  ./packaging/debian/build-deb.sh
  ```
- [ ] .deb installs correctly:
  ```bash
  sudo dpkg -i dist/terminux_<VERSION>_amd64.deb
  ```
- [ ] AppImage builds (if appimagetool available):
  ```bash
  ./packaging/appimage/build-appimage.sh
  ```
- [ ] Tarball is complete:
  ```bash
  tar tzf dist/terminux-linux-x86_64.tar.gz
  ```
- [ ] SHA256 checksums match:
  ```bash
  cd dist && sha256sum -c SHA256SUMS
  ```

## Feature Verification

- [ ] GUI launches: `terminux start`
- [ ] Dashboard appears on first launch
- [ ] Command palette works: CTRL+SHIFT+P
- [ ] Themes load:
  - [ ] `terminux theme list` shows all themes
  - [ ] `terminux theme set neon` switches theme
- [ ] Plugins load:
  - [ ] Plugins directory is scanned
  - [ ] Plugin commands appear in palette
- [ ] Session persistence:
  - [ ] `Session: Save Now` saves state
  - [ ] Autosave runs (wait 30s)
  - [ ] Session restore works after restart
- [ ] Workspace snapshots work
- [ ] Crash recovery:
  - [ ] Kill Terminux, restart, recovery notification appears
  - [ ] Recovery log is written

## Post-Release

- [ ] GitHub Release created automatically
- [ ] All artifacts uploaded (both architectures):
  - [ ] `terminux-linux-x86_64.tar.gz`
  - [ ] `terminux-linux-aarch64.tar.gz`
  - [ ] `Terminux-<VERSION>-x86_64.AppImage`
  - [ ] `Terminux-<VERSION>-aarch64.AppImage`
  - [ ] `terminux_<VERSION>_amd64.deb`
  - [ ] `terminux_<VERSION>_arm64.deb`
  - [ ] `SHA256SUMS`
- [ ] Release page looks correct
- [ ] Download and test AppImage on clean Linux Mint VM
- [ ] Download and test .deb on clean Ubuntu VM
- [ ] Installation instructions are up to date

## Emergency Rollback

If a release has critical issues:

```bash
# Remove the remote tag
git push --delete origin v<VERSION>

# Delete the GitHub Release (manual via web UI)

# Fix the issue, create a new patch release
```
