# Terminux Dashboard

Terminux includes a startup dashboard that provides quick access to common actions, system information, and configuration.

## Opening the Dashboard

- Press `CTRL+SHIFT+D` to open the dashboard
- Select "Terminux Dashboard" from the launcher (`CTRL+SHIFT+Space`)
- Type "dashboard" in the command palette (`CTRL+SHIFT+P`)

## Dashboard Features

### Quick Actions

| Key | Action | Description |
|-----|--------|-------------|
| `1` | New Shell | Opens a new shell session in the current tab |
| `2` | New Tab | Opens a new shell in a new tab |
| `3` | SSH | Connect to a remote host via SSH |
| `4` | Themes | Browse and switch Terminux themes |
| `5` | Settings | Edit the Terminux configuration file |
| `6` | Reload Config | Reload the Terminux configuration |
| `q` | Quit | Close the dashboard |

### System Info Panel

Displays:
- Terminux version
- Current theme
- Active shell
- Operating system
- GPU renderer

### Recent Sessions

The dashboard shows recently used working directories and SSH connections.

## Configuration

Create `~/.config/terminux/dashboard.lua` to customize the dashboard:

```lua
return {
    -- Set to false to disable the dashboard entirely
    enabled = true,

    -- Show system info panel
    show_system_info = true,

    -- Show recent sessions panel
    show_recent_sessions = true,

    -- Custom startup message
    startup_message = "Welcome to Terminux",

    -- Show dashboard on startup (opens automatically)
    show_on_startup = false,
}
```

### Disabling the Dashboard

Set `enabled = false` in `~/.config/terminux/dashboard.lua`.

Or disable from settings:

```lua
-- ~/.config/terminux/settings.lua
show_dashboard_on_startup = false
```

## Command Palette

Press `CTRL+SHIFT+P` to open the command palette with Terminux-specific commands:

- **Show Terminux Dashboard** - Opens the dashboard
- **Change Theme** - Launch the theme selector
- **Reload Configuration** - Reload settings
- **Open Settings File** - Edit configuration
- **New Shell Tab** - Open a new terminal

## Profile Launcher

The launcher (`CTRL+SHIFT+Space`) includes launch menu items for commonly used shells and profiles.

Add custom profiles in `~/.config/terminux/settings.lua`:

```lua
launch_menu = {
    { label = "Bash", args = { "bash" } },
    { label = "Zsh",  args = { "zsh" }  },
    { label = "Fish", args = { "fish" } },
}
```

## First-Time Setup

When Terminux runs for the first time without a configuration file, a setup wizard guides you through:

1. Theme selection (Dark, Light, Neon, Midnight)
2. Default font choice
3. Font size

The wizard creates `~/.config/terminux/settings.lua` and `~/.config/terminux/dashboard.lua`.

## Recent Sessions

Terminux tracks recent sessions in `~/.config/terminux/recent_sessions.json`.

To clear history:

```bash
rm ~/.config/terminux/recent_sessions.json
```

To view recent sessions from the CLI:

```bash
cat ~/.config/terminux/recent_sessions.json
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `CTRL+SHIFT+D` | Show Dashboard |
| `CTRL+SHIFT+P` | Command Palette |
| `CTRL+SHIFT+R` | Reload Configuration |
| `CTRL+SHIFT+Space` | Launcher / Profile Selector |

## Files

| File | Description |
|------|-------------|
| `~/.config/terminux/dashboard.lua` | Dashboard configuration |
| `~/.config/terminux/settings.lua` | Main Terminux settings |
| `~/.config/terminux/recent_sessions.json` | Session history |
| `~/.config/terminux/terminux.lua` | Main config (optional) |
