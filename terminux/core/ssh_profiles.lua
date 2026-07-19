--- Terminux SSH Profiles
--- Manages saved SSH connections for quick connect from the command palette.

local terminux = require 'terminux'

local SSHProfiles = {}

function SSHProfiles:profiles_file()
    return terminux.config_dir .. "/ssh_profiles.lua"
end

function SSHProfiles:list()
    local file = self:profiles_file()
    local f = io.open(file, "r")
    if f then
        local content = f:read("*all")
        f:close()
        local loader, err = load(content)
        if loader then
            local ok, profiles = pcall(loader)
            if ok and type(profiles) == "table" then
                return profiles
            end
        end
    end

    -- Fallback: check settings for ssh_domains
    local settings_ok, settings = pcall(require, "settings")
    if settings_ok and settings and settings.ssh_domains then
        local profiles = {}
        for _, domain in ipairs(settings.ssh_domains) do
            table.insert(profiles, {
                name = domain.name,
                host = domain.remote_address,
            })
        end
        return profiles
    end

    return {}
end

function SSHProfiles:register_palette_entries(window, pane)
    local entries = {}
    local profiles = self:list()

    if #profiles > 0 then
        table.insert(entries, {
            id = "ssh:header",
            brief = "── SSH Connections ──",
            doc = "Quick connect to saved SSH profiles",
            icon = "md_lock",
            action = terminux.action_callback(function()
                -- No-op header
            end),
        })
    end

    for _, profile in ipairs(profiles) do
        local host = profile.host or profile.remote_address or ""
        local user = profile.user or ""
        local connect_str = user ~= "" and (user .. "@" .. host) or host
        local port = profile.port or 22

        table.insert(entries, {
            id = "ssh:connect:" .. profile.name,
            brief = "Connect: " .. profile.name,
            doc = "SSH to " .. connect_str .. " (port " .. port .. ")",
            icon = "md_lock",
            action = terminux.action_callback(function()
                window:perform_action(terminux.action.SpawnCommandInNewTab {
                    label = "SSH: " .. profile.name,
                    args = { "ssh", connect_str, "-p", tostring(port) },
                }, pane)
            end),
        })
    end

    return entries
end

return SSHProfiles
