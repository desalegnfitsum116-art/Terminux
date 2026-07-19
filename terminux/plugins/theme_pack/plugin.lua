-- Theme Pack Plugin
-- Adds Aurora, Dracula, and Nord themes dynamically

local themes = {
    aurora = {
        name = "Aurora",
        color_scheme = "Aurora",
        colors = {
            background = "#1E1E2E",
            foreground = "#CDD6F4",
            tab_bar = {
                background = "#1E1E2E",
                active_tab = { bg_color = "#313244", fg_color = "#89B4FA" },
                inactive_tab = { bg_color = "#181825", fg_color = "#6C7086" },
                new_tab = { bg_color = "#181825", fg_color = "#6C7086" },
            },
        },
        window = {
            padding = { left = 8, right = 8, top = 4, bottom = 4 },
            window_background_opacity = 0.95,
        },
    },
    dracula = {
        name = "Dracula",
        color_scheme = "Dracula",
        colors = {
            background = "#282A36",
            foreground = "#F8F8F2",
            tab_bar = {
                background = "#282A36",
                active_tab = { bg_color = "#44475A", fg_color = "#FF79C6" },
                inactive_tab = { bg_color = "#21222C", fg_color = "#6272A4" },
                new_tab = { bg_color = "#21222C", fg_color = "#6272A4" },
            },
        },
        window = {
            padding = { left = 8, right = 8, top = 4, bottom = 4 },
        },
    },
    nord = {
        name = "Nord",
        color_scheme = "Nord",
        colors = {
            background = "#2E3440",
            foreground = "#D8DEE9",
            tab_bar = {
                background = "#2E3440",
                active_tab = { bg_color = "#3B4252", fg_color = "#88C0D0" },
                inactive_tab = { bg_color = "#2E3440", fg_color = "#4C566A" },
                new_tab = { bg_color = "#2E3440", fg_color = "#4C566A" },
            },
        },
        window = {
            padding = { left = 8, right = 8, top = 4, bottom = 4 },
        },
    },
}

-- Install themes on load
function on_load()
    terminux:log("Theme Pack plugin loaded")
    local config_dir = terminux:get_config_dir()
    local themes_dir = config_dir .. "/themes"

    -- Create themes directory
    terminux:exec("mkdir -p " .. themes_dir  .. " 2>/dev/null")

    for key, theme in pairs(themes) do
        local file_path = themes_dir .. "/" .. key .. ".lua"
        local content = 'return {\n'
        content = content .. '  name = "' .. theme.name .. '",\n'
        content = content .. '  color_scheme = "' .. (theme.color_scheme or theme.name) .. '",\n'
        content = content .. '  colors = {\n'
        for ck, cv in pairs(theme.colors or {}) do
            if type(cv) == "table" then
                content = content .. '    ' .. ck .. ' = {\n'
                for sk, sv in pairs(cv) do
                    if type(sv) == "table" then
                        content = content .. '      ' .. sk .. ' = { bg_color = "' .. (sv.bg_color or "") .. '", fg_color = "' .. (sv.fg_color or "") .. '" },\n'
                    else
                        content = content .. '      ' .. sk .. ' = "' .. sv .. '",\n'
                    end
                end
                content = content .. '    },\n'
            else
                content = content .. '  ' .. ck .. ' = "' .. cv .. '",\n'
            end
        end
        content = content .. '  },\n'
        if theme.window then
            content = content .. '  window = {\n'
            for wk, wv in pairs(theme.window) do
                if type(wv) == "table" then
                    content = content .. '    ' .. wk .. ' = { '
                    for sk, sv in pairs(wv) do
                        content = content .. sk .. ' = ' .. sv .. ', '
                    end
                    content = content .. '},\n'
                else
                    content = content .. '    ' .. wk .. ' = ' .. tostring(wv) .. ',\n'
                end
            end
            content = content .. '  },\n'
        end
        content = content .. '}\n'

        local f = io.open(file_path, "w")
        if f then
            f:write(content)
            f:close()
            terminux:log("Installed theme: " .. key)
        else
            terminux:log_error("Failed to install theme: " .. key)
        end
    end

    terminux:notify("Theme Pack installed 3 themes! Try: aurora, dracula, or nord")
end

-- Register theme switching commands
for key, theme in pairs(themes) do
    terminux:register_command({
        name = "theme-pack-" .. key,
        description = "Switch to " .. theme.name .. " theme (Theme Pack)",
        callback = function()
            -- Write theme selection to settings
            local config_dir = terminux:get_config_dir()
            local settings_path = config_dir .. "/settings.lua"
            local f = io.open(settings_path, "r")
            local content
            if f then
                content = f:read("*all")
                f:close()
            end
            if content then
                if content:match('theme%s*=') then
                    content = content:gsub('theme%s*=%s*"[^"]*"', 'theme = "' .. key .. '"')
                else
                    content = content .. '\ntheme = "' .. key .. '"\n'
                end
            else
                content = 'theme = "' .. key .. '"\n'
            end
            local f = io.open(settings_path, "w")
            if f then
                f:write(content)
                f:close()
                terminux:notify("Theme changed to " .. theme.name .. ". Reload config (CTRL+SHIFT+R) to apply.")
            end
        end,
    })
end

function on_theme_changed(theme)
    terminux:log("Active theme changed to: " .. theme)
end
