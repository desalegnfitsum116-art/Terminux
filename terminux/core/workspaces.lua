--- Terminux Workspace Manager
--- Manages saving and restoring workspace layouts.

local terminux = require 'terminux'

local Workspaces = {}

function Workspaces:workspaces_dir()
    return terminux.config_dir .. "/workspaces"
end

function Workspaces:list()
    local dir = self:workspaces_dir()
    local workspaces = {}
    local f = io.popen("ls " .. dir .. "/*.lua 2>/dev/null", "r")
    if f then
        for file in f:lines() do
            local name = file:match("([^/]+)%.lua$")
            if name then
                table.insert(workspaces, name)
            end
        end
        f:close()
    end
    table.sort(workspaces)
    return workspaces
end

function Workspaces:save(name, state)
    state = state or {}
    local dir = self:workspaces_dir()
    os.execute("mkdir -p " .. dir)
    local file = dir .. "/" .. name .. ".lua"
    local content = "-- Terminux Workspace: " .. name .. "\n-- Auto-generated\n\nreturn {\n"
    content = content .. '  name = "' .. name .. '",\n'
    content = content .. '  created = ' .. (os.time() or 0) .. ',\n'
    if state.cwd then
        content = content .. '  cwd = "' .. state.cwd:gsub('"', '\\"') .. '",\n'
    end
    if state.tabs then
        content = content .. '  tabs = {\n'
        for _, tab in ipairs(state.tabs) do
            content = content .. '    { cwd = "' .. (tab.cwd or ""):gsub('"', '\\"') .. '" },\n'
        end
        content = content .. '  },\n'
    end
    content = content .. "}\n"
    local f = io.open(file, "w")
    if f then
        f:write(content)
        f:close()
        return true
    end
    return false
end

function Workspaces:load(name)
    local file = self:workspaces_dir() .. "/" .. name .. ".lua"
    local f = io.open(file, "r")
    if not f then
        return nil
    end
    local content = f:read("*all")
    f:close()
    local loader, err = load(content)
    if not loader then
        return nil
    end
    local ok, result = pcall(loader)
    if not ok or type(result) ~= "table" then
        return nil
    end
    return result
end

function Workspaces:delete(name)
    local file = self:workspaces_dir() .. "/" .. name .. ".lua"
    os.execute("rm -f " .. file)
end

function Workspaces:register_palette_entries(window, pane)
    local entries = {}
    local workspaces = self:list()

    table.insert(entries, {
        id = "workspace:save",
        brief = "Save Workspace",
        doc = "Save the current window layout as a workspace",
        icon = "md_save",
        action = terminux.action_callback(function()
            local cwd = terminux.home_dir
            -- Try to get cwd from pane
            if pane then
                local ok, info = pcall(function() return pane:get_cwd() end)
                if ok and info then
                    cwd = info
                end
            end
            -- Use prompt-like approach via emit
            terminux.emit("save-workspace-prompt", { cwd = cwd })
        end),
    })

    table.insert(entries, {
        id = "workspace:list",
        brief = "Switch Workspace",
        doc = "Switch to a saved workspace (" .. #workspaces .. " available)",
        icon = "md_swap_horiz",
        action = terminux.action_callback(function()
            if #workspaces == 0 then
                terminux.log_info("No workspaces saved yet. Use 'Save Workspace' first.")
                return
            end
            terminux.emit("switch-workspace-prompt", { workspaces = workspaces })
        end),
    })

    for _, ws in ipairs(workspaces) do
        table.insert(entries, {
            id = "workspace:switch:" .. ws,
            brief = "Switch to Workspace: " .. ws,
            doc = "Restore workspace layout and open its tabs",
            icon = "md_swap_horiz",
            action = terminux.action_callback(function()
                local data = self:load(ws)
                if data and data.cwd then
                    window:perform_action(terminux.action.SpawnCommandInNewTab {
                        label = ws,
                        cwd = data.cwd,
                    }, pane)
                end
            end),
        })
    end

    table.insert(entries, {
        id = "workspace:clear-history",
        brief = "Clear Workspace History",
        doc = "Delete all saved workspaces",
        icon = "md_delete",
        action = terminux.action_callback(function()
            for _, ws in ipairs(workspaces) do
                self:delete(ws)
            end
            terminux.log_info("All workspaces cleared.")
        end),
    })

    return entries
end

return Workspaces
