# Terminux

<img height="128" alt="Terminux" src="https://raw.githubusercontent.com/wezterm/wezterm/main/assets/icon/wezterm-icon.svg" align="left">

*A high-performance terminal emulator for modern development environments.*

Terminux is a modern, GPU-accelerated terminal emulator built on top of the excellent [WezTerm](https://github.com/wezterm/wezterm) project by [@wez](https://github.com/wez).

## About

Terminux is a fork of WezTerm with custom branding and defaults. All original WezTerm code remains under the MIT License.

- **Original project:** [WezTerm](https://github.com/wezterm/wezterm) by Wez Furlong
- **Modified project:** Terminux contributors

## Installation

### From source

Build dependencies (Ubuntu/Debian):

```bash
sudo apt-get install -y \
    cmake gcc g++ pkg-config libssl-dev libfontconfig1-dev \
    libegl1-mesa-dev libwayland-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libxcb-*-dev xorg-dev \
    libharfbuzz-dev libpango1.0-dev libcairo2-dev
```

Build:

```bash
cargo build --release -p terminux-gui
```

Run:

```bash
./target/release/terminux-gui start
```

### Configuration

Terminux looks for configuration in (in order of priority):
- `$TERMINUX_CONFIG_FILE` environment variable
- `$XDG_CONFIG_HOME/terminux/terminux.lua`
- `~/.config/terminux/terminux.lua`
- `~/.terminux.lua`

See [WezTerm documentation](https://wezterm.org/) for configuration options (the Lua API is the same).

## Credits

- **WezTerm** by Wez Furlong (https://github.com/wezterm/wezterm) — the original project
- All WezTerm contributors
- Terminux contributors

## License

This project is licensed under the MIT License — see [LICENSE.md](LICENSE.md) for details.

All original WezTerm copyright and license notices are preserved.
