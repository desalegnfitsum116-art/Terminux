--- Terminux Plugin Manager
--- Loads, validates, and manages plugins from ~/.config/terminux/plugins/

local terminux = require 'terminux'

local PluginManager = {
    plugins = {},
    loaded = {},
    states = {},
    api = {},
}

-- ──────────────────────────────────────────
-- Paths
-- ──────────────────────────────────────────

function PluginManager:plugin_dir()
    return terminux.config_dir .. "/plugins"
end

function PluginManager:plugin_data_dir(name)
    return terminux.config_dir .. "/plugin-data/" .. name
end

function PluginManager:plugin_log_dir()
    return terminux.config_dir .. "/plugin-logs"
end

function PluginManager:disabled_file()
    return terminux.config_dir .. "/disabled_plugins.lua"
end

-- ──────────────────────────────────────────
-- Disabled plugins list
-- ──────────────────────────────────────────

function PluginManager:load_disabled()
    local f = io.open(self:disabled_file(), "r")
    if not f then return {} end
    local content = f:read("*all")
    f:close()
    local loader = load("return " .. content)
    if not loader then return {} end
    local ok, list = pcall(loader)
    if ok and type(list) == "table" then return list end
    return {}
end

function PluginManager:save_disabled(list)
    local content = "-- Terminux Disabled Plugins\n\nreturn {\n"
    for _, name in ipairs(list) do
        content = content .. '  "' .. name .. '",\n'
    end
    content = content .. "}\n"
    local f = io.open(self:disabled_file(), "w")
    if f then
        f:write(content)
        f:close()
    end
end

function PluginManager:is_disabled(name)
    local disabled = self:load_disabled()
    for _, d in ipairs(disabled) do
        if d == name then return true end
    end
    return false
end

function PluginManager:enable(name)
    local disabled = self:load_disabled()
    local filtered = {}
    for _, d in ipairs(disabled) do
        if d ~= name then table.insert(filtered, d) end
    end
    self:save_disabled(filtered)
    terminux.reload_configuration()
    terminux.log_info("Plugin enabled: " .. name)
end

function PluginManager:disable(name)
    local disabled = self:load_disabled()
    table.insert(disabled, name)
    self:save_disabled(disabled)
    terminux.reload_configuration()
    terminux.log_info("Plugin disabled: " .. name)
end

-- ──────────────────────────────────────────
-- Scan for plugins
-- ──────────────────────────────────────────

function PluginManager:scan()
    local plugins = {}
    local dir = self:plugin_dir()
    local f = io.popen("ls -d " .. dir .. "/*/ 2>/dev/null", "r")
    if f then
        for line in f:lines() do
            local name = line:match("([^/]+)/$")
            if name and name ~= "." and name ~= ".." then
                table.insert(plugins, name)
            end
        end
        f:close()
    end
    table.sort(plugins)
    return plugins
end

-- ──────────────────────────────────────────
-- Validate manifest
-- ──────────────────────────────────────────

function PluginManager:validate_manifest(data, plugin_name)
    if type(data) ~= "table" then
        return false, "manifest is not a table"
    end
    if not data.name then
        return false, "missing required field: name"
    end
    if not data.entry then
        return false, "missing required field: entry"
    end
    if data.name ~= plugin_name then
        return false, "manifest name '" .. data.name .. "' does not match directory '" .. plugin_name .. "'"
    end
    return true
end

function PluginManager:load_manifest(plugin_name)
    local manifest_path = self:plugin_dir() .. "/" .. plugin_name .. "/manifest.json"
    local f = io.open(manifest_path, "r")
    if not f then
        -- No manifest is OK; use defaults
        return { name = plugin_name, entry = "plugin.lua", version = "0.1.0" }
    end
    local content = f:read("*all")
    f:close()
    local ok, data = pcall(terminux.json_parse, content)
    if not ok then
        terminux.log_error("Plugin '" .. plugin_name .. "': invalid manifest.json, using defaults")
        return { name = plugin_name, entry = "plugin.lua", version = "0.1.0" }
    end
    local valid, err = self:validate_manifest(data, plugin_name)
    if not valid then
        terminux.log_error("Plugin '" .. plugin_name .. "': " .. err .. ", using defaults")
        return { name = plugin_name, entry = "plugin.lua", version = "0.1.0" }
    end
    return data
end

-- ──────────────────────────────────────────
-- Plugin API
-- ──────────────────────────────────────────

function PluginManager:create_plugin_api(plugin_name)
    local api = {
        _name = plugin_name,
        _crash_count = 0,
    }

    function api:log(msg)
        terminux.log_info("[" .. plugin_name .. "] " .. msg)
    end

    function api:log_error(msg)
        terminux.log_error("[" .. plugin_name .. "] " .. msg)
    end

    function api:notify(msg)
        terminux.log_info("[" .. plugin_name .. "] " .. msg)
    end

    function api:notify_error(msg)
        terminux.log_error("[" .. plugin_name .. "] " .. msg)
    end

    function api:exec(cmd)
        local f = io.popen(cmd .. " 2>&1", "r")
        if not f then return "" end
        local output = f:read("*all")
        f:close()
        return output
    end

    function api:load_state()
        local dir = PluginManager:plugin_data_dir(plugin_name)
        local file = dir .. "/state.lua"
        local f = io.open(file, "r")
        if not f then return nil end
        local content = f:read("*all")
        f:close()
        local loader = load("return " .. content)
        if not loader then return nil end
        local ok, data = pcall(loader)
        if ok then return data end
        return nil
    end

    function api:save_state(tbl)
        local dir = PluginManager:plugin_data_dir(plugin_name)
        os.execute("mkdir -p " .. dir)
        local file = dir .. "/state.lua"
        local content = "-- Plugin State: " .. plugin_name .. "\n\nreturn " .. PluginManager:_serialize(tbl) .. "\n"
        local f = io.open(file, "w")
        if f then
            f:write(content)
            f:close()
        end
    end

    function api:register_command(opts)
        opts = opts or {}
        if not opts.name then
            self:log_error("register_command missing 'name'")
            return
        end
        local cmd_name = opts.name
        local cmd_desc = opts.description or opts.name
        local callback = opts.callback

        table.insert(PluginManager.commands, {
            id = "plugin:" .. plugin_name .. ":" .. cmd_name,
            brief = cmd_name,
            doc = cmd_desc .. " (plugin: " .. plugin_name .. ")",
            icon = opts.icon or "md_extension",
            plugin = plugin_name,
            callback = callback,
        })

        -- Also notify palette system to rebuild
        terminux.log_info("Plugin '" .. plugin_name .. "' registered command: " .. cmd_name)
    end

    function api:open_tab(opts)
        opts = opts or {}
        local args = {}
        if opts.cwd then
            args.cwd = opts.cwd
        end
        if opts.args then
            args.args = opts.args
        end
        -- Trigger via emit to the running window
        terminux.emit("plugin-open-tab", args)
    end

    function api:get_version()
        return terminux.version
    end

    function api:get_config_dir()
        return terminux.config_dir
    end

    function api:get_data_dir()
        return terminux.data_dir
    end

    return api
end

-- ──────────────────────────────────────────
-- Serialize Lua tables for state storage
-- ──────────────────────────────────────────

function PluginManager:_serialize(val, indent)
    indent = indent or 0
    local pad = string.rep("  ", indent)
    local t = type(val)
    if t == "number" then return tostring(val)
    elseif t == "string" then return '"' .. val:gsub('"', '\\"') .. '"'
    elseif t == "boolean" then return tostring(val)
    elseif t == "nil" then return "nil"
    elseif t == "table" then
        local parts = {}
        table.insert(parts, "{\n")
        for k, v in pairs(val) do
            local k_str
            if type(k) == "string" then
                k_str = '["' .. k:gsub('"', '\\"') .. '"]'
            else
                k_str = "[" .. tostring(k) .. "]"
            end
            table.insert(parts, pad .. "  " .. k_str .. " = " .. self:_serialize(v, indent + 1) .. ",\n")
        end
        table.insert(parts, pad .. "}")
        return table.concat(parts)
    else
        return '"' .. tostring(val) .. '"'
    end
end

-- ──────────────────────────────────────────
-- Load a single plugin
-- ──────────────────────────────────────────

function PluginManager:load_plugin(plugin_name)
    if self.loaded[plugin_name] then
        return true
    end

    if self:is_disabled(plugin_name) then
        terminux.log_info("Plugin '" .. plugin_name .. "' is disabled, skipping")
        return true
    end

    local manifest = self:load_manifest(plugin_name)
    local entry_point = self:plugin_dir() .. "/" .. plugin_name .. "/" .. (manifest.entry or "plugin.lua")
    local f = io.open(entry_point, "r")
    if not f then
        terminux.log_error("Plugin '" .. plugin_name .. "': entry not found at " .. entry_point)
        return false
    end
    f:close()

    -- Create sandboxed environment
    local api = self:create_plugin_api(plugin_name)
    local sandbox_env = {
        terminux = api,
        _plugin_name = plugin_name,
        _manifest = manifest,
        print = function(...) api:log(table.concat({...}, " ")) end,
        pcall = pcall,
        xpcall = xpcall,
        error = error,
        type = type,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        tostring = tostring,
        tonumber = tonumber,
        select = select,
        string = string,
        table = table,
        math = math,
        os = { time = os.time, date = os.date, difftime = os.difftime },
    }

    local func, err = loadfile(entry_point, "t", sandbox_env)
    if not func then
        terminux.log_error("Plugin '" .. plugin_name .. "': failed to load: " .. tostring(err))
        return false
    end

    local ok, init_err = pcall(func)
    if not ok then
        terminux.log_error("Plugin '" .. plugin_name .. "': runtime error: " .. tostring(init_err))
        self:_log_crash(plugin_name, tostring(init_err))
        return false
    end

    -- Call lifecycle hooks
    if type(sandbox_env.on_load) == "function" then
        local ok, hook_err = pcall(sandbox_env.on_load)
        if not ok then
            terminux.log_error("Plugin '" .. plugin_name .. "': on_load error: " .. tostring(hook_err))
        end
    end

    self.loaded[plugin_name] = {
        name = plugin_name,
        manifest = manifest,
        env = sandbox_env,
        api = api,
    }

    terminux.log_info("Plugin loaded: " .. plugin_name .. " v" .. (manifest.version or "?"))
    return true
end

-- ──────────────────────────────────────────
-- Unload a plugin
-- ──────────────────────────────────────────

function PluginManager:unload_plugin(plugin_name)
    local plugin = self.loaded[plugin_name]
    if not plugin then return end

    if type(plugin.env.on_unload) == "function" then
        local ok, err = pcall(plugin.env.on_unload)
        if not ok then
            terminux.log_error("Plugin '" .. plugin_name .. "': on_unload error: " .. tostring(err))
        end
    end

    -- Remove registered commands
    local filtered = {}
    for _, cmd in ipairs(self.commands) do
        if cmd.plugin ~= plugin_name then
            table.insert(filtered, cmd)
        end
    end
    self.commands = filtered

    self.loaded[plugin_name] = nil
    terminux.log_info("Plugin unloaded: " .. plugin_name)
end

-- ──────────────────────────────────────────
-- Crash logging
-- ──────────────────────────────────────────

function PluginManager:_log_crash(plugin_name, err_msg)
    local log_dir = self:plugin_log_dir()
    os.execute("mkdir -p " .. log_dir)
    local log_file = log_dir .. "/" .. plugin_name .. ".log"
    local f = io.open(log_file, "a")
    if f then
        f:write(os.date("%Y-%m-%d %H:%M:%S") .. " ERROR: " .. err_msg .. "\n")
        f:close()
    end
end

-- ──────────────────────────────────────────
-- Load all plugins
-- ──────────────────────────────────────────

function PluginManager:load_all()
    self.commands = self.commands or {}
    local plugins = self:scan()
    for _, name in ipairs(plugins) do
        self:load_plugin(name)
    end
    return plugins
end

-- ──────────────────────────────────────────
-- Reload all plugins
-- ──────────────────────────────────────────

function PluginManager:reload_all()
    -- Unload all
    local names = {}
    for name, _ in pairs(self.loaded) do
        table.insert(names, name)
    end
    for _, name in ipairs(names) do
        self:unload_plugin(name)
    end

    -- Rescan and reload
    return self:load_all()
end

-- ──────────────────────────────────────────
-- Get plugin list
-- ──────────────────────────────────────────

function PluginManager:get_plugin_list()
    local scanned = self:scan()
    local result = {}
    for _, name in ipairs(scanned) do
        table.insert(result, {
            name = name,
            loaded = self.loaded[name] ~= nil,
            disabled = self:is_disabled(name),
        })
    end
    return result
end

-- ──────────────────────────────────────────
-- Palette entries
-- ──────────────────────────────────────────

function PluginManager:register_palette_entries(window, pane)
    local entries = {}
    local scanned = self:scan()

    table.insert(entries, {
        id = "plugins:list",
        brief = "Plugins: List Installed",
        doc = "Show all installed plugins (" .. #scanned .. " found)",
        icon = "md_extension",
        action = terminux.action_callback(function()
            local list = self:get_plugin_list()
            local msg = "Installed plugins:"
            for _, p in ipairs(list) do
                local status = p.loaded and "\226\156\147" or (p.disabled and "\226\156\141" or "?")
                msg = msg .. "\n  " .. status .. " " .. p.name
            end
            terminux.log_info(msg)
        end),
    })

    table.insert(entries, {
        id = "plugins:reload",
        brief = "Plugins: Reload All",
        doc = "Unload and reload all plugins",
        icon = "md_refresh",
        action = terminux.action_callback(function()
            terminux.reload_configuration()
            terminux.log_info("Plugins reloaded")
        end),
    })

    table.insert(entries, {
        id = "plugins:open-dir",
        brief = "Plugins: Open Plugin Directory",
        doc = "Open ~/.config/terminux/plugins/ in your file manager",
        icon = "md_folder_open",
        action = terminux.action_callback(function()
            if window and pane then
                pane:send_text("cd " .. self:plugin_dir() .. "\nls -la " .. self:plugin_dir() .. "\n")
            end
        end),
    })

    -- Plugin-specific entries
    for _, p in ipairs(scanned) do
        local disabled = self:is_disabled(p)

        if disabled then
            table.insert(entries, {
                id = "plugins:enable:" .. p,
                brief = "Plugins: Enable " .. p,
                doc = "Enable the '" .. p .. "' plugin",
                icon = "md_play_arrow",
                action = terminux.action_callback(function()
                    terminux.emit("plugin-enable", p)
                end),
            })
        else
            table.insert(entries, {
                id = "plugins:disable:" .. p,
                brief = "Plugins: Disable " .. p,
                doc = "Disable the '" .. p .. "' plugin",
                icon = "md_stop",
                action = terminux.action_callback(function()
                    terminux.emit("plugin-disable", p)
                end),
            })
        end
    end

    -- Plugin commands
    for _, cmd in ipairs(self.commands or {}) do
        table.insert(entries, {
            id = cmd.id,
            brief = cmd.brief,
            doc = cmd.doc,
            icon = cmd.icon or "md_extension",
            action = terminux.action_callback(function()
                if cmd.callback then
                    local ok, err = pcall(cmd.callback)
                    if not ok then
                        terminux.log_error("Plugin command error: " .. tostring(err))
                    end
                end
            end),
        })
    end

    return entries
end

-- ──────────────────────────────────────────
-- Initialize
-- ──────────────────────────────────────────

function PluginManager:init()
    terminux.log_info("Plugin Manager initializing")

    -- Register palette augmentation
    terminux.on("augment-command-palette", function(window, pane)
        return self:register_palette_entries(window, pane)
    end)

    -- Handle plugin enable/disable events
    terminux.on("plugin-enable", function(name)
        self:enable(name)
    end)

    terminux.on("plugin-disable", function(name)
        self:disable(name)
    end)

    terminux.on("plugin-reload", function()
        self:reload_all()
    end)

    -- Load all plugins
    self:load_all()

    -- Fire on_startup hooks
    for name, plugin in pairs(self.loaded) do
        if type(plugin.env.on_startup) == "function" then
            local ok, err = pcall(plugin.env.on_startup)
            if not ok then
                terminux.log_error("Plugin '" .. name .. "': on_startup error: " .. tostring(err))
            end
        end
    end

    terminux.log_info("Plugin Manager initialized. Loaded " .. self:count_loaded() .. " plugins.")
end

function PluginManager:count_loaded()
    local count = 0
    for _ in pairs(self.loaded) do
        count = count + 1
    end
    return count
end

return PluginManager
