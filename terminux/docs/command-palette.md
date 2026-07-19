# Terminux Command Palette

The command palette provides quick access to all Terminux features via fuzzy search.

## Opening

Press `CTRL+SHIFT+P` to open the command palette.

## Features

### Fuzzy Search

Type any part of a command name, description, or category to filter. Results are ranked by:
1. **Exact match** — highest priority
2. **Usage frequency** — commands you use often appear first
3. **Recency** — recently used commands rank higher
4. **Fuzzy score** — closest match

### Keyboard Navigation

| Key | Action |
|-----|--------|
| `CTRL+P` / `↑` | Move up |
| `CTRL+N` / `↓` | Move down |
| `Enter` | Select highlighted command |
| `Backspace` | Edit search text |
| `CTRL+U` | Clear search |
| `Escape` / `CTRL+G` | Close palette |

### Command Categories

Commands are organized into groups:

#### Terminux
| Command | Description |
|---------|-------------|
| Show Terminux Dashboard | Open the startup dashboard |
| Reload Configuration | Reload all config files without restarting |
| Clear Command History | Reset usage history |
| Open Settings File | Edit settings in your editor |

#### Themes
| Command | Description |
|---------|-------------|
| Theme: *name* | Switch instantly to a theme (checkmark shows current) |

#### SSH Connections
| Command | Description |
|---------|-------------|
| Connect: *profile* | Quick SSH connection to saved profile |

#### Workspaces
| Command | Description |
|---------|-------------|
| Save Workspace | Save current layout |
| Switch Workspace | Select a saved workspace |
| Switch to Workspace: *name* | Direct workspace switch |
| Clear Workspace History | Delete all saved workspaces |

#### Font Size
| Command | Description |
|---------|-------------|
| Increase Font Size | Scale up by 10% |
| Decrease Font Size | Scale down by 10% |
| Reset Font Size | Restore config default |

### Built-in Commands

The palette also includes all standard WezTerm commands organized by menu:

**Terminal**: New Tab, New Window, Close Tab, Split Pane, etc.
**Edit**: Copy, Paste, Copy Mode, etc.
**View**: Zoom, Full Screen, Toggle Tab Bar, etc.
**Shell**: Scroll to Bottom, Scroll to Top, etc.
**Window**: Show Launcher, Show Tab Navigator, etc.

## Theme Switching

Themes can be switched instantly from the palette:

1. Open palette (`CTRL+SHIFT+P`)
2. Type "theme:"
3. Select a theme (current theme has a checkmark ✓)
4. Theme applies immediately and persists to `settings.lua`

## SSH Profiles

Saved SSH connections appear in the palette for one-click access.

Configure SSH profiles in `~/.config/terminux/ssh_profiles.lua`:

```lua
return {
    {
        name = "Production",
        host = "prod.example.com",
        user = "ubuntu",
        port = 22,
    },
    {
        name = "VPS",
        host = "1.2.3.4",
        user = "root",
    },
}
```

Or using the standard `ssh_domains` in `settings.lua`:

```lua
ssh_domains = {
    {
        name = "server",
        remote_address = "user@host.com",
    },
}
```

## Workspaces

Workspaces save and restore terminal layouts.

### Saving

1. Open palette (`CTRL+SHIFT+P`)
2. Type "save workspace"
3. Enter a name when prompted

Saved to: `~/.config/terminux/workspaces/<name>.lua`

### Restoring

1. Open palette
2. Type "switch workspace"
3. Select a workspace
4. A new tab opens with the workspace's working directory

### Clearing

Use "Clear Workspace History" to delete all saved workspaces.

## Font Size

| Shortcut | Action |
|----------|--------|
| `CTRL+=` | Increase font size |
| `CTRL+-` | Decrease font size |
| `CTRL+0` | Reset font size |

Changes apply immediately and persist for the session. Reset restores the configured size.

## Config Reload

"Reload Configuration" (available in palette) re-reads all config files without restarting:

- `settings.lua`
- `dashboard.lua`
- `ssh_profiles.lua`
- All theme files
- Plugins

Terminal sessions are preserved during reload.

## Command History

Commands are tracked in `~/.local/share/terminux/recent-commands.json`. History affects sorting but does not limit available commands.

Use "Clear Command History" in the palette to reset.

## Files

| File | Purpose |
|------|---------|
| `~/.config/terminux/settings.lua` | Main configuration |
| `~/.config/terminux/ssh_profiles.lua` | SSH quick connect profiles |
| `~/.config/terminux/workspaces/*.lua` | Saved workspace layouts |
| `~/.local/share/terminux/recent-commands.json` | Command usage history |
