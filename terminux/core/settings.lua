-- Terminux Settings
-- This file is managed by 'terminux theme set <name>' and can be edited manually.

-- Selected theme
theme = "terminux-dark"

-- Window settings
window_title = "Terminux"
hide_tab_bar_if_only_one_tab = false
enable_scroll_bar = true
scrollback_lines = 10000

-- Font settings
font = "JetBrains Mono"
font_size = 11.0
line_height = 1.0
cell_width = 1.0

-- Dashboard
show_dashboard_on_startup = false

-- Launch menu (appears in CTRL+SHIFT+Space launcher)
launch_menu = {
    {
        label = "Bash",
        args = { "bash" },
    },
}

-- SSH domains
-- ssh_domains = {
--     {
--         name = "server",
--         remote_address = "user@server.com",
--     },
-- }

-- Background image (optional)
-- window_background_image = "~/.config/terminux/background.png"
-- window_background_image_opacity = 0.15
