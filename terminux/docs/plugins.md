# Terminux Plugin System

Terminux has a Lua-based plugin system that allows extending functionality without modifying the core.

## Plugin Directory Structure

Plugins are installed in `~/.config/terminux/plugins/`:

```
~/.config/terminux/plugins/
├── hello_terminux/
│   ├── plugin.lua          # Entry point (mandatory)
│   ├── manifest.json       # Plugin manifest (optional)
│   └── README.md           # Documentation (optional)
└── theme_pack/
    └── plugin.lua
```

## Manifest Format

Create `manifest.json` to describe your plugin:

```json
{
    "name": "hello_terminux",
    "display_name": "Hello Terminux",
    "version": "1.0.0",
    "author": "Terminux Team",
    "description": "Example plugin",
    "entry": "plugin.lua",
    "min_terminux_version": "1.0.0"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Must match the directory name |
| `display_name` | No | Human-readable name |
| `version` | No | Semantic version |
| `author` | No | Plugin author |
| `description` | No | Brief description |
| `entry` | Yes | Entry point file (relative to plugin dir) |
| `min_terminux_version` | No | Minimum Terminux version |

If no manifest is found, defaults are used (entry = `plugin.lua`).

## Lua API

Plugins receive a sandboxed `terminux` table with the following methods:

### Logging

```lua
terminux:log("message")          -- Info-level log
terminux:log_error("message")    -- Error-level log
```

### Notifications

```lua
terminux:notify("Hello!")        -- Info notification
terminux:notify_error("Oops!")   -- Error notification
```

### Register Commands

```lua
terminux:register_command({
    name = "my-command",           -- Command name
    description = "Does something", -- Description for palette
    callback = function()           -- Handler function
        terminux:notify("Done!")
    end,
})
```

Commands appear in the command palette (CTRL+SHIFT+P) under the plugin section.

### Execute Shell Commands

```lua
local output = terminux:exec("git status --short")
```

Returns the command's stdout as a string.

### State Persistence

```lua
-- Load saved state
local state = terminux:load_state() or { count = 0 }

-- Modify state
state.count = state.count + 1

-- Save state
terminux:save_state(state)
```

State is stored in `~/.config/terminux/plugin-data/<plugin-name>/state.lua`.

### Environment

```lua
local version = terminux:get_version()      -- Terminux version
local config = terminux:get_config_dir()    -- Config directory
local data = terminux:get_data_dir()        -- Data directory
```

### Open New Tab

```lua
terminux:open_tab({ cwd = "~/Projects" })  -- Open a tab in a directory
```

## Lifecycle Hooks

Define these global functions in your plugin:

| Hook | Called When |
|------|-------------|
| `on_load()` | Plugin is loaded |
| `on_unload()` | Plugin is being unloaded |
| `on_startup()` | Terminux has started (after config load) |
| `on_shutdown()` | Terminux is shutting down |
| `on_theme_changed(theme)` | User switches theme |
| `on_workspace_changed(name)` | User switches workspace |

Example:

```lua
function on_load()
    terminux:log("Plugin initialized")
end

function on_theme_changed(theme)
    terminux:notify("Theme changed to " .. theme)
end
```

## CLI Commands

```bash
terminux plugin list              # List installed plugins
terminux plugin enable <name>     # Enable a plugin
terminux plugin disable <name>    # Disable a plugin
terminux plugin reload            # Reload all plugins (via config reload)
```

## Command Palette

The following plugin commands appear in the palette:

| Command | Description |
|---------|-------------|
| Plugins: List Installed | Show all installed plugins |
| Plugins: Reload All | Reload configuration and plugins |
| Plugins: Open Plugin Directory | Open plugin directory in shell |
| Plugins: Enable *name* | Enable a specific plugin |
| Plugins: Disable *name* | Disable a specific plugin |
| *plugin commands* | Commands registered by plugins |

## Enabling/Disabling

Disable a plugin when it causes issues:

```bash
terminux plugin disable hello_terminux
```

Re-enable:

```bash
terminux plugin enable hello_terminux
```

Disabled plugins persist across restarts in `~/.config/terminux/disabled_plugins.lua`.

## Error Handling & Safety

- Plugin code runs in a **sandboxed environment** with limited global access
- Only whitelisted Lua functions and the `terminux` API are available
- Runtime errors are caught by `pcall()` and logged
- Repeated crashes are recorded in `~/.config/terminux/plugin-logs/<name>.log`
- A crashing plugin **does not crash Terminux**

## Plugin Data

Each plugin gets a private data directory:

```
~/.config/terminux/plugin-data/<plugin-name>/
```

Use `terminux:load_state()` and `terminux:save_state()` to persist data.

## Logs

Plugin logs are written to:

```
~/.config/terminux/plugin-logs/<plugin-name>.log
```

## Developing Plugins

1. Create a directory in `~/.config/terminux/plugins/<name>/`
2. Add `plugin.lua` with your code
3. Optionally add `manifest.json`
4. Reload config (CTRL+SHIFT+R or `terminux reload`)

### Example Minimal Plugin

```lua
-- ~/.config/terminux/plugins/my_plugin/plugin.lua

function on_load()
    terminux:log("My plugin loaded!")
end

terminux:register_command({
    name = "my-plugin-hello",
    description = "Say hello from my plugin",
    callback = function()
        terminux:notify("Hello from my plugin!")
    end,
})
```

### Using State

```lua
local state = terminux:load_state() or { count = 0 }
state.count = state.count + 1
terminux:save_state(state)
terminux:notify("Run count: " .. state.count)
```

### Executing Commands

```lua
local files = terminux:exec("ls -la")
terminux:log("Files:\n" .. files)
```

See the `hello_terminux` example plugin for a complete working example.

## Git-Based Plugins

Terminux also supports cloning plugins directly from Git:

```lua
terminux.plugin.require("https://github.com/user/repo")
```

This clones the repo into `~/.local/share/terminux/plugins/` and loads it.

To update all Git plugins:

```lua
terminux.plugin.update_all()
```

See the [WezTerm plugin documentation](https://github.com/wez/wezterm) for more details on Git-based plugins.
