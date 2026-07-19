# Terminux Themes

Terminux includes a built-in theme system that lets you customize colors, window appearance, cursor style, and more.

## Default Themes

Terminux ships with four built-in themes:

| Theme | Description |
|-------|-------------|
| `terminux-dark` | Dark theme with lime green accent (Terminux default) |
| `terminux-light` | Clean light theme with indigo accent |
| `midnight` | Minimalist pure black theme with subtle grays |
| `neon` | Cyberpunk-inspired neon theme with magenta/cyan accents |

## Theme File Format

Themes are Lua files that return a table with color scheme, window, and cursor settings:

```lua
return {
    name = "My Theme",
    color_scheme = "Terminux Dark",  -- references a built-in WezTerm color scheme
    colors = {
        tab_bar = {
            background = "#...",
            active_tab = { bg_color = "#...", fg_color = "#..." },
            inactive_tab = { bg_color = "#...", fg_color = "#..." },
            new_tab = { bg_color = "#...", fg_color = "#..." },
        },
    },
    window = {
        padding = { left = 8, right = 8, top = 4, bottom = 4 },
        window_background_opacity = 0.95,
        text_background_opacity = 0.88,
    },
    cursor = {
        style = "Block",
        blink_rate = 0,
        thickness = 2.0,
    },
}
```

The `color_scheme` field references one of the 1000+ built-in color schemes. Any scheme from the [WezTerm color scheme repository](https://github.com/wez/wezterm/raw/main/docs/colorschemes/index.md) can be used.

## CLI Usage

List available themes:

```bash
terminux theme list
```

Set the active theme:

```bash
terminux theme set neon
```

Show the current theme:

```bash
terminux theme show
```

After setting a theme, reload the config with `Ctrl+Shift+R` (default keybinding) or restart Terminux.

## Theme Locations

Terminux searches for theme files in the following locations (in order):

1. `~/.config/terminux/themes/`
2. `~/.terminux/themes/`
3. `$XDG_DATA_HOME/terminux/themes/`
4. Bundled with the Terminux installation

## Creating Custom Themes

1. Create a `.lua` file in `~/.config/terminux/themes/`:

```lua
return {
    name = "My Custom Theme",
    color_scheme = "Dracula",
    window = {
        padding = { left = 12, right = 12, top = 6, bottom = 6 },
        window_background_opacity = 0.9,
    },
    cursor = {
        style = "BlinkingBlock",
        blink_rate = 500,
    },
}
```

2. List it to verify:

```bash
terminux theme list
```

3. Activate it:

```bash
terminux theme set my-custom-theme
```

4. Reload config with `Ctrl+Shift+R`.

## Programmatic Use

From your `terminux.lua` config:

```lua
local theme = require 'core.theme'

-- Load a theme
local my_theme = theme.load("neon")

-- Apply with user overrides
local config = theme.apply("neon", {
    window_background_opacity = 0.8,
})
```

List themes programmatically:

```lua
local theme = require 'core.theme'
local available = theme.list()
for _, name in ipairs(available) do
    print(name)
end
```

## Settings File

Theme selection can also be configured in `~/.config/terminux/settings.lua`:

```lua
theme = "terminux-dark"
font = "JetBrains Mono"
font_size = 11.0
window_title = "Terminux"
```

The CLI `terminux theme set` command manages this file automatically.
