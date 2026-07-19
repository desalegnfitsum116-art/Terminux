-- Add Terminux core module paths to Lua search path
local function add_module_path(path)
    local sep = package.config:match("([^\n]+)")
    if not package.path:find(path, 1, true) then
        package.path = path .. "/?.lua" .. sep .. path .. "/?/init.lua" .. sep .. package.path
    end
end

local function add_terminux_paths()
    local exe_dir = require 'terminux'.executable_dir
    if exe_dir then
        -- When running from the Terminux project directory (development)
        add_module_path(exe_dir .. "/../../terminux")
        add_module_path(exe_dir .. "/terminux")
    end
    -- User's config directory
    local config_dir = require 'terminux'.config_dir
    if config_dir then
        add_module_path(config_dir)
    end
    -- Home directory
    local home_dir = require 'terminux'.home_dir
    if home_dir then
        add_module_path(home_dir .. "/.terminux")
    end
end

add_terminux_paths()

local terminux = require 'terminux'

-- Load settings with optional theme override
local settings = {}
local settings_ok, settings_mod = pcall(require, "settings")
if settings_ok and settings_mod then
    settings = settings_mod
end

-- Theme system
local theme = require 'core.theme'

-- Determine theme: settings > default
local theme_name = settings.theme or "terminux-dark"

-- Load and apply the theme
local active_theme = theme.load(theme_name)

-- Build the final config
local config = {
    -- Color scheme from the theme's colors block
    color_scheme = (active_theme and active_theme.color_scheme) or "Terminux Dark",

    -- Window settings from the theme
    window_background_opacity = active_theme and active_theme.window and active_theme.window.window_background_opacity,
    text_background_opacity = active_theme and active_theme.window and active_theme.window.text_background_opacity,
    window_padding = active_theme and active_theme.window and active_theme.window.padding,

    -- Cursor settings from the theme
    cursor_style = active_theme and active_theme.cursor and active_theme.cursor.style,
    cursor_blink_rate = active_theme and active_theme.cursor and active_theme.cursor.blink_rate,
    cursor_thickness = active_theme and active_theme.cursor and active_theme.cursor.thickness,

    -- Tab bar colors from the theme
    colors = active_theme and active_theme.colors or {},

    -- Terminux branding
    window_title = settings.window_title or "Terminux",
    window_frame = {
        border_left_width = "0.5cell",
        border_right_width = "0.5cell",
        border_top_height = "0.5cell",
        border_bottom_height = "0.5cell",
        border_left_color = active_theme and active_theme.colors and active_theme.colors.split or "#1E293B",
        border_right_color = active_theme and active_theme.colors and active_theme.colors.split or "#1E293B",
        border_top_color = active_theme and active_theme.colors and active_theme.colors.split or "#1E293B",
        border_bottom_color = active_theme and active_theme.colors and active_theme.colors.split or "#1E293B",
    },

    -- UI defaults
    hide_tab_bar_if_only_one_tab = settings.hide_tab_bar_if_only_one_tab or false,
    enable_scroll_bar = settings.enable_scroll_bar or true,
    scrollback_lines = settings.scrollback_lines or 10000,
    show_new_tab_button_in_tab_bar = true,
    tab_bar_at_bottom = false,

    -- Font defaults
    font = terminux.font(settings.font or "JetBrains Mono", { size = settings.font_size or 11.0 }),
    font_rules = {},
    line_height = 1.0,
    cell_width = 1.0,

        -- Dashboard
    launch_menu = settings.launch_menu or {
        {
            label = "Terminux Dashboard",
            args = { "bash", terminux.executable_dir .. "/../../terminux/scripts/dashboard.sh" },
        },
    },

    -- Default domain for SSH
    ssh_domains = settings.ssh_domains or {},

    -- Background
    window_background_image = settings.window_background_image,
    window_background_image_hpos = "Center",
    window_background_image_vpos = "Center",
    window_background_image_opacity = settings.window_background_image_opacity or 0.15,
}

-- Initialize dashboard module
local dashboard_ok, dashboard = pcall(require, "core.dashboard")
if dashboard_ok and dashboard then
    dashboard:init()
end

-- Record current session
pcall(function()
    dashboard:record_session({
        cwd = terminux.home_dir,
        shell = os.getenv("SHELL") or "unknown",
    })
end)

-- Initialize plugin manager
local pm_ok, pm = pcall(require, "core.plugin_manager")
if pm_ok and pm then
    pm:init()
end

-- Initialize session manager
local sess_ok, sess = pcall(require, "core.session")
if sess_ok and sess then
    sess:init()
    -- Start autosave after GUI is initialized
    terminux.on("update-status", function(window, pane)
        if not sess._autosave_started then
            sess._autosave_started = true
            sess:startup_autosave(window, pane)
        end
    end)
end

return config
