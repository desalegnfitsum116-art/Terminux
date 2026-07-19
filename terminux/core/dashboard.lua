local terminux = require 'terminux'

local Dashboard = {
    config = nil,
}

function Dashboard:load_config()
    if self.config then
        return self.config
    end

    local ok, user_config = pcall(require, "dashboard")
    if ok and user_config then
        self.config = user_config
    else
        self.config = {
            enabled = true,
            show_system_info = true,
            show_recent_sessions = true,
            startup_message = "Welcome to Terminux",
            show_on_startup = false,
            position = "tab",
        }
    end

    local settings_ok, settings = pcall(require, "settings")
    if settings_ok and settings then
        if settings.show_dashboard_on_startup ~= nil then
            self.config.show_on_startup = settings.show_dashboard_on_startup
        end
    end

    return self.config
end

function Dashboard:record_session(opts)
    opts = opts or {}
    local cwd = opts.cwd or terminux.home_dir
    local host = opts.host or ""
    local shell = opts.shell or ""
    local recent_file = terminux.config_dir .. "/recent_sessions.lua"
    local recent = {}
    local f = io.open(recent_file, "r")
    if f then
        local content = f:read("*all")
        f:close()
        if content then
            local loader = load("return " .. content)
            if loader then
                local ok, data = pcall(loader)
                if ok and type(data) == "table" then
                    recent = data
                end
            end
        end
    end
    local deduped = {}
    for _, entry in ipairs(recent) do
        if entry.cwd ~= cwd or entry.host ~= host then
            table.insert(deduped, entry)
        end
    end
    recent = deduped
    table.insert(recent, 1, { cwd = cwd, host = host, shell = shell, timestamp = os.time() })
    while #recent > 20 do table.remove(recent) end
    local parts = { "{" }
    for _, entry in ipairs(recent) do
        table.insert(parts, string.format('  {cwd="%s",host="%s",shell="%s",timestamp=%d},',
            entry.cwd:gsub('"', '\\"'), entry.host:gsub('"', '\\"'), entry.shell:gsub('"', '\\"'), entry.timestamp or 0))
    end
    table.insert(parts, "}")
    local f = io.open(recent_file, "w")
    if f then
        f:write("-- Terminux Recent Sessions\n\nreturn " .. table.concat(parts, "\n"))
        f:close()
    end
end

function Dashboard:get_recent_sessions(limit)
    limit = limit or 5
    local recent_file = terminux.config_dir .. "/recent_sessions.lua"
    local f = io.open(recent_file, "r")
    if not f then return {} end
    local content = f:read("*all")
    f:close()
    if not content then return {} end
    local loader = load("return " .. content)
    if not loader then return {} end
    local ok, data = pcall(loader)
    if not ok or type(data) ~= "table" then return {} end
    local result = {}
    for i, entry in ipairs(data) do
        if i > limit then break end
        table.insert(result, entry)
    end
    return result
end

function Dashboard:clear_history()
    local recent_file = terminux.config_dir .. "/recent_sessions.lua"
    local f = io.open(recent_file, "w")
    if f then
        f:write("-- Terminux Recent Sessions\n\nreturn {}\n")
        f:close()
    end
    local cmd_hist = terminux.data_dir .. "/recent-commands.json"
    os.execute("rm -f " .. cmd_hist)
end

function Dashboard:is_first_run()
    local config_dir = terminux.config_dir
    for _, file in ipairs({ config_dir .. "/terminux.lua", config_dir .. "/settings.lua" }) do
        local f = io.open(file, "r")
        if f then f:close(); return false end
    end
    return true
end

function Dashboard:register_palette_augmentations()
    terminux.on("augment-command-palette", function(window, pane)
        local entries = {}

        -- Terminux section
        table.insert(entries, {
            id = "terminux:dashboard",
            brief = "Show Terminux Dashboard",
            doc = "Open the startup dashboard with quick actions and system info",
            icon = "md_dashboard",
            action = terminux.action_callback(function()
                window:perform_action(terminux.action.ShowDashboard, pane)
            end),
        })

        table.insert(entries, {
            id = "terminux:reload",
            brief = "Reload Configuration",
            doc = "Reload all configuration files, themes, and plugins without restarting",
            icon = "md_refresh",
            action = terminux.action_callback(function()
                terminux.reload_configuration()
                terminux.log_info("Configuration reloaded")
            end),
        })

        table.insert(entries, {
            id = "terminux:clear-history",
            brief = "Clear Command History",
            doc = "Reset the command palette usage history and recency scores",
            icon = "md_delete",
            action = terminux.action_callback(function()
                self:clear_history()
                terminux.log_info("Command history cleared")
            end),
        })

        -- Theme section
        local theme = require 'core.theme'
        local themes = theme.list() or {}
        local current = theme.get_current()

        table.insert(entries, {
            id = "themes:header",
            brief = "── Themes ──",
            doc = "Switch between installed themes (applied instantly, persisted)",
            icon = "md_palette",
            action = terminux.action_callback(function()
                -- Header, no-op
            end),
        })

        for _, name in ipairs(themes) do
            local marker = (name == current) and " \226\152\143 " or "  "
            table.insert(entries, {
                id = "theme:switch:" .. name,
                brief = "Theme: " .. name .. marker,
                doc = "Switch to the " .. name .. " theme",
                icon = "md_palette",
                action = terminux.action_callback(function()
                    local ok, err = pcall(theme.set, name)
                    if ok then
                        terminux.reload_configuration()
                        terminux.log_info("Theme changed to " .. name)
                    end
                end),
            })
        end

        -- SSH Profiles
        local ssh_ok, ssh = pcall(require, "core.ssh_profiles")
        if ssh_ok and ssh then
            local ssh_entries = ssh:register_palette_entries(window, pane)
            for _, e in ipairs(ssh_entries) do
                table.insert(entries, e)
            end
        end

        -- Workspaces
        local ws_ok, ws = pcall(require, "core.workspaces")
        if ws_ok and ws then
            local ws_entries = ws:register_palette_entries(window, pane)
            for _, e in ipairs(ws_entries) do
                table.insert(entries, e)
            end
        end

        -- Font size section
        table.insert(entries, {
            id = "font:header",
            brief = "── Font Size ──",
            doc = "Adjust the terminal font size (CTRL+=, CTRL+-, CTRL+0)",
            icon = "md_format_size",
            action = terminux.action_callback(function() end),
        })

        table.insert(entries, {
            id = "font:increase",
            brief = "Increase Font Size",
            doc = "Scale the font size larger by 10%",
            icon = "md_format_size",
            action = terminux.action_callback(function()
                window:perform_action(terminux.action.IncreaseFontSize, pane)
            end),
        })

        table.insert(entries, {
            id = "font:decrease",
            brief = "Decrease Font Size",
            doc = "Scale the font size smaller by 10%",
            icon = "md_format_size",
            action = terminux.action_callback(function()
                window:perform_action(terminux.action.DecreaseFontSize, pane)
            end),
        })

        table.insert(entries, {
            id = "font:reset",
            brief = "Reset Font Size",
            doc = "Restore the font size to match your configuration file",
            icon = "md_format_size",
            action = terminux.action_callback(function()
                window:perform_action(terminux.action.ResetFontSize, pane)
            end),
        })

        table.insert(entries, {
            id = "terminux:open-settings",
            brief = "Open Settings File",
            doc = "Edit ~/.config/terminux/settings.lua in your default editor",
            icon = "md_settings",
            action = terminux.action_callback(function()
                local settings_path = terminux.config_dir .. "/settings.lua"
                if window and pane then
                    pane:send_text(
                        (os.getenv("EDITOR") or "vim") .. " " .. settings_path .. "\n"
                    )
                end
            end),
        })

        return entries
    end)
end

function Dashboard:init()
    local config = self:load_config()
    if config.enabled == false then
        return
    end
    self:register_palette_augmentations()
end

return Dashboard
