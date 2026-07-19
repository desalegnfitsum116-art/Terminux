# Terminux Plugin Examples

## Example 1: Hello Terminux

Shows basic plugin structure, commands, and state persistence.

**Location:** `terminux/plugins/hello_terminux/`

### Files

```
hello_terminux/
├── manifest.json    # Plugin metadata
├── plugin.lua       # Plugin code
└── README.md        # Documentation
```

### Features Demonstrated

1. **Lifecycle hooks**: `on_load()`, `on_startup()`, `on_unload()`
2. **Registering commands**: Three commands registered
3. **State persistence**: Counter plugin tracks usage count
4. **Shell execution**: System info command shows paths

### Commands

| Command | Description |
|---------|-------------|
| `hello-terminux` | Say hello from the plugin system |
| `hello-counter` | Show invocation count (persisted) |
| `hello-system-info` | Show Terminux paths and version |

### Key Code

```lua
-- Register a command
terminux:register_command({
    name = "hello-terminux",
    description = "Display a greeting from the plugin system",
    callback = function()
        terminux:notify("Hello from Terminux!")
    end,
})

-- State persistence
terminux:register_command({
    name = "hello-counter",
    description = "Show invocation count",
    callback = function()
        local state = terminux:load_state() or { count = 0 }
        state.count = state.count + 1
        terminux:save_state(state)
        terminux:notify("Count: " .. state.count)
    end,
})
```

---

## Example 2: Theme Pack

Demonstrates dynamic theme installation and file I/O.

**Location:** `terminux/plugins/theme_pack/`

### Features Demonstrated

1. **File I/O**: Creates theme files in `~/.config/terminux/themes/`
2. **Multiple commands**: Registers one command per theme
3. **Config manipulation**: Modifies `settings.lua` to switch themes
4. **Shell commands**: Uses `terminux:exec()` to create directories

### Commands

| Command | Description |
|---------|-------------|
| `theme-pack-aurora` | Switch to Aurora theme |
| `theme-pack-dracula` | Switch to Dracula theme |
| `theme-pack-nord` | Switch to Nord theme |

### Installation

```bash
cp -r terminux/plugins/theme_pack ~/.config/terminux/plugins/
terminux reload
```

---

## Example 3: Minimal Plugin

The simplest possible plugin:

```lua
-- ~/.config/terminux/plugins/minimal/plugin.lua

function on_load()
    terminux:log("Minimal plugin loaded!")
end

terminux:register_command({
    name = "minimal-hello",
    description = "Say hello",
    callback = function()
        terminux:notify("Hello!")
    end,
})
```

---

## Example 4: Status Logger

Demonstrates shell execution and logging:

```lua
-- ~/.config/terminux/plugins/status_logger/plugin.lua

function on_startup()
    local uptime = terminux:exec("uptime")
    terminux:log("System uptime at startup:\n" .. uptime)
end

terminux:register_command({
    name = "status-disk",
    description = "Show disk usage",
    callback = function()
        local df = terminux:exec("df -h / | tail -1")
        terminux:notify("Disk usage:\n" .. df)
    end,
})

terminux:register_command({
    name = "status-memory",
    description = "Show memory usage",
    callback = function()
        local mem = terminux:exec("free -h | head -2")
        terminux:notify("Memory:\n" .. mem)
    end,
})
```

---

## Example 5: Session Tracker

Demonstrates state persistence for tracking sessions:

```lua
-- ~/.config/terminux/plugins/session_tracker/plugin.lua

function on_load()
    local state = terminux:load_state() or { sessions = {} }
    table.insert(state.sessions, {
        start = os.time(),
        cwd = terminux:get_config_dir(),
    })
    terminux:save_state(state)
    terminux:log("Session recorded (#" .. #state.sessions .. ")")
end

terminux:register_command({
    name = "session-stats",
    description = "Show session statistics",
    callback = function()
        local state = terminux:load_state() or { sessions = {} }
        local count = #state.sessions
        local last = state.sessions[count]
        terminux:notify("Sessions: " .. count .. "\nLast: " .. os.date("%c", last and last.start or 0))
    end,
})
```

---

## Installation

All plugins go in `~/.config/terminux/plugins/<name>/`:

```bash
# Copy the example plugin
cp -r terminux/plugins/hello_terminux ~/.config/terminux/plugins/

# Reload configuration
terminux reload
```

Or press `CTRL+SHIFT+R` in the GUI.

## Creating Your Own Plugin

1. Create a directory: `~/.config/terminux/plugins/my_plugin/`
2. Add `plugin.lua` with your code
3. Optionally add `manifest.json`
4. Reload configuration

See [plugins.md](plugins.md) for the full API reference.
