# Hello Terminux Plugin

A demonstration plugin for the Terminux Plugin System.

## Installation

Copy to `~/.config/terminux/plugins/hello_terminux/`:

```bash
cp -r terminux/plugins/hello_terminux ~/.config/terminux/plugins/
```

Then reload configuration (CTRL+SHIFT+R or `terminux reload`).

## Commands

| Command | Description |
|---------|-------------|
| `hello-terminux` | Display a greeting |
| `hello-counter` | Show invocation count (persisted) |
| `hello-system-info` | Show system paths and version |

## Files

- `plugin.lua` — Main plugin code
- `manifest.json` — Plugin manifest
- `README.md` — This file

## State

The counter command stores state in:
`~/.config/terminux/plugin-data/hello_terminux/state.lua`
