local terminux = require 'terminux'

local Theme = {}

local function deep_merge(t1, t2)
    local result = {}
    for k, v in pairs(t1 or {}) do
        if type(v) == "table" and type((t2 or {})[k]) == "table" then
            result[k] = deep_merge(v, t2[k])
        else
            result[k] = v
        end
    end
    for k, v in pairs(t2 or {}) do
        if type(v) == "table" and type((t1 or {})[k]) == "table" then
            result[k] = deep_merge(t1[k], v)
        else
            result[k] = v
        end
    end
    return result
end

local function search_dirs()
    local dirs = {}
    local seen = {}
    local config_dir = terminux.config_dir
    if config_dir and not seen[config_dir] then
        seen[config_dir] = true
        table.insert(dirs, config_dir .. "/themes")
    end
    local home = terminux.home_dir
    if home and not seen[home] then
        seen[home] = true
        table.insert(dirs, home .. "/.terminux/themes")
    end
    local exe_dir = terminux.executable_dir
    if exe_dir and not seen[exe_dir] then
        seen[exe_dir] = true
        table.insert(dirs, exe_dir .. "/../../terminux/themes")
        table.insert(dirs, exe_dir .. "/terminux/themes")
    end
    local data_dir = terminux.data_dir
    if data_dir and not seen[data_dir] then
        seen[data_dir] = true
        table.insert(dirs, data_dir .. "/themes")
    end
    return dirs
end

function Theme.resolve_path(name)
    for _, dir in ipairs(search_dirs()) do
        local path = dir .. "/" .. name .. ".lua"
        local f = io.open(path, "r")
        if f then
            f:close()
            return path
        end
    end
    return nil
end

function Theme.load(name)
    local ok, theme = pcall(require, "themes." .. name)
    if ok then
        return theme
    end
    local path = Theme.resolve_path(name)
    if path then
        local loader = loadfile(path)
        if loader then
            local result = loader()
            if result then
                result._path = path
            end
            return result
        end
    end
    terminux.log_error("Theme not found: " .. name)
    return nil
end

function Theme.list()
    local themes = {}
    local seen_names = {}
    for _, dir in ipairs(search_dirs()) do
        local f = io.popen("ls " .. dir .. "/*.lua 2>/dev/null", "r")
        if f then
            for file in f:lines() do
                local name = file:match("([^/]+)%.lua$")
                if name and not seen_names[name] then
                    seen_names[name] = true
                    table.insert(themes, name)
                end
            end
            f:close()
        end
    end
    table.sort(themes)
    return themes
end

function Theme.get_current()
    local settings_path = terminux.config_dir .. "/settings.lua"
    local f = io.open(settings_path, "r")
    if f then
        local content = f:read("*all")
        f:close()
        local theme_name = content:match('theme%s*=%s*"([^"]+)"')
        if theme_name then
            return theme_name
        end
    end
    return "terminux-dark"
end

function Theme.set(name)
    local theme = Theme.load(name)
    if not theme then
        return false, "Theme '" .. name .. "' not found"
    end
    local settings_path = terminux.config_dir .. "/settings.lua"
    local f = io.open(settings_path, "r")
    local content
    if f then
        content = f:read("*all")
        f:close()
    end
    if content then
        if content:match('theme%s*=') then
            content = content:gsub('theme%s*=%s*"[^"]*"', 'theme = "' .. name .. '"')
        else
            content = content .. '\n\n-- Selected theme\ntheme = "' .. name .. '"\n'
        end
    else
        content = '-- Terminux Settings\n-- This file is managed by the terminux CLI.\n\n-- Selected theme\ntheme = "' .. name .. '"\n'
    end
    local f = io.open(settings_path, "w")
    if f then
        f:write(content)
        f:close()
        return true, "Theme set to '" .. name .. "'"
    else
        return false, "Failed to write settings file: " .. settings_path
    end
end

function Theme.apply(name, overrides)
    local theme = Theme.load(name)
    if not theme then
        terminux.log_error("Failed to load theme: " .. name)
        return overrides or {}
    end
    return deep_merge(theme, overrides or {})
end

return Theme
