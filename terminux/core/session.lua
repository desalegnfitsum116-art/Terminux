--- Terminux Session Persistence & Workspace Recovery Module
--- Saves/restores tabs, panes, cwds, workspace, theme, SSH info.
--- Provides autosave, crash recovery, workspace snapshots, export/import.

local SessionManager = {}
SessionManager.__index = SessionManager

-- Autosave interval in seconds
local AUTOSAVE_INTERVAL = 30

-- ──────────────────────────────────────────────
-- Path helpers
-- ──────────────────────────────────────────────

local function sessions_dir()
    return terminux.config_dir .. "/sessions"
end

local function workspaces_dir()
    return sessions_dir() .. "/workspaces"
end

local function autosave_path()
    return sessions_dir() .. "/autosave.json"
end

local function autosave_bak_path()
    return sessions_dir() .. "/autosave.json.bak"
end

local function healthy_marker()
    return sessions_dir() .. "/.healthy"
end

local function recovery_log()
    return terminux.config_dir .. "/recovery.log"
end

local function ensure_dir(path)
    os.execute("mkdir -p " .. path)
end

-- ──────────────────────────────────────────────
-- Atomic file write helper
-- ──────────────────────────────────────────────

local function atomic_write(path, content)
    local tmp = path .. ".tmp." .. tostring(math.random(999999))
    local f, err = io.open(tmp, "w")
    if not f then return nil, err end
    f:write(content)
    f:close()
    local ok, rename_err = os.rename(tmp, path)
    if not ok then
        os.execute("mv " .. tmp .. " " .. path)
    end
    return true
end

-- ──────────────────────────────────────────────
-- JSON encode/decode wrapper
-- ──────────────────────────────────────────────

local function json_encode(val)
    local ok, result = pcall(terminux.json_encode, val)
    if ok and result then return result end
    local ok2, result2 = pcall(function()
        local serde = require "terminux.serde"
        return serde.encode(val)
    end)
    if ok2 and result2 then return result2 end
    return nil
end

local function json_decode(text)
    local ok, result = pcall(terminux.json_parse, text)
    if ok and result then return result end
    local ok2, result2 = pcall(function()
        local serde = require "terminux.serde"
        return serde.decode(text)
    end)
    if ok2 and result2 then return result2 end
    return nil
end

-- ──────────────────────────────────────────────
-- URI helpers
-- ──────────────────────────────────────────────

local function file_uri_to_path(uri)
    if not uri then return nil end
    local s = tostring(uri)
    if s:sub(1, 7) == "file://" then
        local path = s:sub(8)
        path = path:gsub("%%(%x%x)", function(h)
            return string.char(tonumber(h, 16))
        end)
        return path
    end
    return s
end

-- ──────────────────────────────────────────────
-- State capture (save)
-- ──────────────────────────────────────────────

function SessionManager:capture_window_state(window, pane)
    local mux_win
    if window and window.mux_window then
        mux_win = window:mux_window()
    else
        pcall(function() mux_win = window end)
    end

    local tabs_data = {}
    if mux_win then
        pcall(function()
            tabs_data = self:_capture_tabs(mux_win)
        end)
    end

    local workspace_name = "default"
    pcall(function()
        if window and window.active_workspace then
            workspace_name = window:active_workspace()
        elseif terminux.mux and terminux.mux.get_active_workspace then
            workspace_name = terminux.mux.get_active_workspace()
        end
    end)

    local theme_name = "neon"
    pcall(function()
        local settings_path = terminux.config_dir .. "/settings.lua"
        local f = io.open(settings_path, "r")
        if f then
            for line in f:lines() do
                local name = line:match('^theme%s*=%s*"([^"]+)"')
                if name then theme_name = name break end
            end
            f:close()
        end
    end)

    local font_size = 14.0
    pcall(function()
        local overrides = terminux.font or {}
        if overrides.size then font_size = overrides.size end
    end)

    local ssh_sessions = {}
    for _, tab_entry in ipairs(tabs_data) do
        for _, pane_entry in ipairs(tab_entry.panes or {}) do
            if pane_entry.domain and pane_entry.domain ~= "unix" then
                local host, user, port = pane_entry.domain:match("^ssh://([^@]+)@([^:]+):?(%d*)")
                if host then
                    table.insert(ssh_sessions, {
                        host = host,
                        user = user or "",
                        port = tonumber(port) or 22,
                    })
                end
            end
        end
    end

    local session = {
        version = 1,
        created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        terminux_version = tostring(terminux.version or "0.0.0"),
        window = self:_capture_window_dimensions(mux_win),
        tabs = tabs_data,
        workspace = {
            name = workspace_name,
            theme = theme_name,
            font_size = font_size,
        },
        ssh_sessions = ssh_sessions,
    }
    return session
end

function SessionManager:_capture_window_dimensions(mux_win)
    local info = { width = 1600, height = 900, maximized = false }
    if not mux_win then return info end
    pcall(function()
        local gui = mux_win:gui_window()
        if gui and gui.get_dimensions then
            local dims = gui:get_dimensions()
            if dims then
                info.width = dims.pixel_width or info.width
                info.height = dims.pixel_height or info.height
            end
        end
        if gui and gui.is_maximized then
            info.maximized = gui:is_maximized()
        end
    end)
    return info
end

function SessionManager:_capture_tabs(mux_win)
    local tabs_list = {}
    pcall(function()
        local tabs = mux_win:tabs()
        if not tabs then return end
        for _, tab in ipairs(tabs) do
            local tab_entry = self:_capture_tab(tab)
            if tab_entry then
                table.insert(tabs_list, tab_entry)
            end
        end
    end)
    return tabs_list
end

function SessionManager:_capture_tab(tab)
    local tab_entry = { title = "", panes = {}, layout_hint = "flat" }
    pcall(function()
        tab_entry.title = tab:get_title() or ""
    end)
    pcall(function()
        local panes = tab:panes()
        if not panes then return end
        for _, p in ipairs(panes) do
            local pentry = self:_capture_pane(p)
            if pentry then
                table.insert(tab_entry.panes, pentry)
            end
        end
    end)
    return tab_entry
end

function SessionManager:_capture_pane(pane)
    local entry = {}
    pcall(function()
        local cwd_uri = pane:get_current_working_dir()
        entry.cwd = file_uri_to_path(cwd_uri)
    end)
    pcall(function()
        entry.title = pane:get_title() or ""
    end)
    pcall(function()
        entry.domain = pane:get_domain_name() or "unix"
    end)
    pcall(function()
        local info = pane:get_foreground_process_info()
        if info and info.exe then
            entry.process = info.exe
        end
    end)
    return entry
end

-- ──────────────────────────────────────────────
-- Save / Restore core
-- ──────────────────────────────────────────────

function SessionManager:save(path, window, pane)
    local state = self:capture_window_state(window, pane)
    local json = json_encode(state)
    if not json then
        terminux.log_error("Session save failed: could not encode state")
        return false
    end
    local ok, err = atomic_write(path, json)
    if not ok then
        terminux.log_error("Session save failed: " .. tostring(err))
        return false
    end
    terminux.log_info("Session saved to " .. path)
    return true
end

function SessionManager:restore(path, window, pane)
    local f, err = io.open(path, "r")
    if not f then
        terminux.log_error("Session restore failed: " .. tostring(err))
        return false, err
    end
    local content = f:read("*all")
    f:close()
    local state = json_decode(content)
    if not state then
        terminux.log_error("Session restore failed: invalid JSON")
        return false, "invalid JSON"
    end
    if state.version ~= 1 then
        terminux.log_error("Session restore failed: unsupported version " .. tostring(state.version))
        return false, "unsupported version"
    end
    return self:restore_from_state(state, window, pane)
end

function SessionManager:restore_from_state(state, window, pane)
    local success = true
    local errors = {}

    -- Restore workspace/theme/font
    if state.workspace then
        pcall(function()
            if state.workspace.theme and state.workspace.theme ~= "" then
                local settings_path = terminux.config_dir .. "/settings.lua"
                local f = io.open(settings_path, "r")
                local lines = {}
                local found = false
                if f then
                    for line in f:lines() do
                        if line:match("^theme%s*=") then
                            table.insert(lines, 'theme = "' .. state.workspace.theme .. '"')
                            found = true
                        else
                            table.insert(lines, line)
                        end
                    end
                    f:close()
                end
                if not found then
                    table.insert(lines, 1, 'theme = "' .. state.workspace.theme .. '"')
                end
                local content = table.concat(lines, "\n") .. "\n"
                atomic_write(settings_path, content)
            end
        end)
    end

    -- Restore tabs
    if state.tabs and #state.tabs > 0 then
        pcall(function()
            self:_restore_tabs(state.tabs, window, pane)
        end)
    elseif window and pane then
        pcall(function()
            window:perform_action(terminux.action.SpawnCommandInNewTab {
                cwd = state.workspace and state.workspace.name or nil,
            }, pane)
        end)
    end

    -- Restore SSH sessions
    if state.ssh_sessions and #state.ssh_sessions > 0 then
        self:_restore_ssh_sessions(state.ssh_sessions, window, pane)
    end

    -- Notify
    pcall(function()
        if window and terminux.notify then
            terminux.notify("Session restored from " .. (state.created_at or "backup"))
        end
    end)

    return #errors == 0, errors
end

function SessionManager:_restore_tabs(tabs_data, window, pane)
    if not window then return end
    if not pane then return end

    for i, tab_data in ipairs(tabs_data) do
        local cwd = nil
        if tab_data.panes and #tab_data.panes > 0 then
            cwd = tab_data.panes[1].cwd
        end

        if i == 1 then
            if cwd and cwd ~= "" then
                pcall(function()
                    window:perform_action(terminux.action.SpawnCommandInNewTab {
                        cwd = cwd,
                    }, pane)
                end)
            end
        else
            pcall(function()
                window:perform_action(terminux.action.SpawnCommandInNewTab {
                    cwd = cwd,
                }, pane)
            end)
        end
    end
end

function SessionManager:_restore_ssh_sessions(ssh_list, window, pane)
    for _, ssh in ipairs(ssh_list) do
        local host = ssh.host or ""
        local user = ssh.user or ""
        local port = ssh.port or 22
        if host ~= "" then
            terminux.notify("SSH session saved: " .. user .. "@" .. host .. ":" .. port .. " - reconnect manually")
        end
    end
end

-- ──────────────────────────────────────────────
-- Autosave
-- ──────────────────────────────────────────────

function SessionManager:start_autosave(window, pane)
    self._autosave_window = window
    self._autosave_pane = pane
    self._autosave_enabled = true
    self:_schedule_autosave()
end

function SessionManager:stop_autosave()
    self._autosave_enabled = false
    self._autosave_window = nil
    self._autosave_pane = nil
end

function SessionManager:_schedule_autosave()
    if not self._autosave_enabled then return end
    terminux.time.call_after(AUTOSAVE_INTERVAL, function()
        if not self._autosave_enabled then return end
        self:_do_autosave()
        self:_schedule_autosave()
    end)
end

function SessionManager:_do_autosave()
    local win = self._autosave_window
    local pn = self._autosave_pane
    if not win then
        pcall(function()
            local mux = terminux.mux
            if mux and mux.all_windows then
                local windows = mux:all_windows()
                if windows and #windows > 0 then
                    win = windows[1]
                    if win.gui_window then
                        win = win:gui_window()
                    end
                end
            end
        end)
    end

    -- Back up previous autosave
    local apath = autosave_path()
    local bakpath = autosave_bak_path()
    local f = io.open(apath, "r")
    if f then
        f:close()
        os.execute("cp " .. apath .. " " .. bakpath)
    end

    local state = self:capture_window_state(win, pn)
    local json = json_encode(state)
    if json then
        atomic_write(apath, json)
    end
end

-- ──────────────────────────────────────────────
-- Crash Recovery
-- ──────────────────────────────────────────────

function SessionManager:check_crash_recovery()
    ensure_dir(sessions_dir())
    local marker = healthy_marker()
    local f = io.open(marker, "r")
    if f then
        f:close()
        -- Marker exists from previous run with no clean shutdown → crash
        self:_log_recovery("Unclean shutdown detected on " .. os.date("!%Y-%m-%dT%H:%M:%SZ"))
        return "crashed"
    end
    -- Write healthy marker
    local mf = io.open(marker, "w")
    if mf then
        mf:write("healthy\n")
        mf:close()
    end
    return "clean"
end

function SessionManager:mark_clean_shutdown()
    local marker = healthy_marker()
    os.execute("rm -f " .. marker)
    self._autosave_enabled = false
    -- Save last session
    local lst = sessions_dir() .. "/last-session.json"
    local apath = autosave_path()
    local f = io.open(apath, "r")
    if f then
        local content = f:read("*all")
        f:close()
        if content and #content > 0 then
            atomic_write(lst, content)
        end
    end
    self:_log_recovery("Clean shutdown on " .. os.date("!%Y-%m-%dT%H:%M:%SZ"))
end

function SessionManager:_log_recovery(msg)
    local file = recovery_log()
    local f = io.open(file, "a")
    if f then
        f:write(msg .. "\n")
        f:close()
    end
end

function SessionManager:get_recovery_log()
    local file = recovery_log()
    local f = io.open(file, "r")
    if not f then return "" end
    local content = f:read("*all")
    f:close()
    return content or ""
end

function SessionManager:clear_recovery_log()
    local file = recovery_log()
    os.execute("rm -f " .. file)
end

function SessionManager:show_recovery_dialog(window, pane)
    if not terminux.notify then return end
    terminux.notify("Terminux recovered from a crash. Use 'Session: Restore Last Session' in the palette.")
    terminux.log_info("Recovery: terminux recovered from crash. Run 'terminux session restore' to restore.")
end

-- ──────────────────────────────────────────────
-- Workspace Snapshots
-- ──────────────────────────────────────────────

function SessionManager:save_workspace(name, window, pane)
    ensure_dir(workspaces_dir())
    local state = self:capture_window_state(window, pane)
    state.metadata = { name = name, created_at = os.date("!%Y-%m-%dT%H:%M:%SZ") }
    local json = json_encode(state)
    if not json then
        terminux.log_error("Workspace save failed: could not encode")
        return false
    end
    local path = workspaces_dir() .. "/" .. name .. ".json"
    local ok, err = atomic_write(path, json)
    if not ok then
        terminux.log_error("Workspace save failed: " .. tostring(err))
        return false
    end
    terminux.log_info("Workspace '" .. name .. "' saved")
    return true
end

function SessionManager:load_workspace(name, window, pane)
    local path = workspaces_dir() .. "/" .. name .. ".json"
    local f, err = io.open(path, "r")
    if not f then
        terminux.log_error("Workspace load failed: " .. tostring(err))
        return false, err
    end
    local content = f:read("*all")
    f:close()
    local state = json_decode(content)
    if not state then
        terminux.log_error("Workspace load failed: invalid JSON")
        return false, "invalid JSON"
    end
    return self:restore_from_state(state, window, pane)
end

function SessionManager:delete_workspace(name)
    local path = workspaces_dir() .. "/" .. name .. ".json"
    os.execute("rm -f " .. path)
end

function SessionManager:list_workspaces()
    local dir = workspaces_dir()
    local names = {}
    local handle = io.popen("ls " .. dir .. "/*.json 2>/dev/null", "r")
    if handle then
        for file in handle:lines() do
            local name = file:match("([^/]+)%.json$")
            if name then table.insert(names, name) end
        end
        handle:close()
    end
    table.sort(names)
    return names
end

-- ──────────────────────────────────────────────
-- Export / Import
-- ──────────────────────────────────────────────

function SessionManager:export_session(output_path, window, pane)
    local state = self:capture_window_state(window, pane)
    state.export_metadata = {
        exported_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        format = "terminux-session-v1",
    }
    local json = json_encode(state)
    if not json then
        terminux.log_error("Export failed: could not encode")
        return false
    end
    local ok, err = atomic_write(output_path, json)
    if not ok then
        terminux.log_error("Export failed: " .. tostring(err))
        return false
    end
    terminux.log_info("Session exported to " .. output_path)
    return true
end

function SessionManager:import_session(input_path, window, pane)
    local f, err = io.open(input_path, "r")
    if not f then
        terminux.log_error("Import failed: " .. tostring(err))
        return false, err
    end
    local content = f:read("*all")
    f:close()
    local state = json_decode(content)
    if not state then
        terminux.log_error("Import failed: invalid JSON")
        return false, "invalid JSON"
    end
    if state.version ~= 1 then
        terminux.log_error("Import failed: unsupported version")
        return false, "unsupported version"
    end
    -- Copy to autosave for restore
    local json = json_encode(state)
    if json then
        atomic_write(autosave_path(), json)
    end
    return self:restore_from_state(state, window, pane)
end

-- ──────────────────────────────────────────────
-- Palette Entries
-- ──────────────────────────────────────────────

function SessionManager:register_palette_entries(window, pane)
    local entries = {}

    table.insert(entries, {
        id = "session:save-now",
        brief = "Session: Save Now",
        doc = "Save the current window layout to autosave",
        icon = "md_save",
        action = terminux.action_callback(function()
            self:save(autosave_path(), window, pane)
        end),
    })

    table.insert(entries, {
        id = "session:restore-last",
        brief = "Session: Restore Last Session",
        doc = "Restore tabs and panes from the last saved session",
        icon = "md_restore",
        action = terminux.action_callback(function()
            self:restore(autosave_path(), window, pane)
        end),
    })

    table.insert(entries, {
        id = "session:save-workspace",
        brief = "Session: Save As Workspace",
        doc = "Save current layout as a named workspace snapshot",
        icon = "md_save",
        action = terminux.action_callback(function()
            terminux.emit("save-workspace-prompt", {})
        end),
    })

    table.insert(entries, {
        id = "session:open-workspace",
        brief = "Session: Open Workspace",
        doc = "Open a saved workspace snapshot",
        icon = "md_folder_open",
        action = terminux.action_callback(function()
            local ws_list = self:list_workspaces()
            if #ws_list == 0 then
                terminux.notify("No workspace snapshots found")
                return
            end
            terminux.log_info("Available workspaces: " .. table.concat(ws_list, ", "))
        end),
    })

    table.insert(entries, {
        id = "session:delete-workspace",
        brief = "Session: Delete Workspace",
        doc = "Delete a workspace snapshot",
        icon = "md_delete",
        action = terminux.action_callback(function()
            local ws_list = self:list_workspaces()
            if #ws_list == 0 then
                terminux.notify("No workspace snapshots found")
                return
            end
            terminux.log_info("Available: " .. table.concat(ws_list, ", ") .. ". Use CLI: terminux session delete <name>")
        end),
    })

    table.insert(entries, {
        id = "session:export",
        brief = "Session: Export Session",
        doc = "Export the current session to a portable JSON file",
        icon = "md_file_upload",
        action = terminux.action_callback(function()
            local path = terminux.home_dir .. "/terminux-session-" .. os.date("%Y%m%d-%H%M%S") .. ".json"
            self:export_session(path, window, pane)
        end),
    })

    table.insert(entries, {
        id = "session:import",
        brief = "Session: Import Session",
        doc = "Import a session from a JSON file",
        icon = "md_file_download",
        action = terminux.action_callback(function()
            terminux.emit("import-session-prompt", {})
        end),
    })

    return entries
end

-- ──────────────────────────────────────────────
-- Init
-- ──────────────────────────────────────────────

function SessionManager:init()
    ensure_dir(sessions_dir())
    ensure_dir(workspaces_dir())

    local crash_status = self:check_crash_recovery()
    if crash_status == "crashed" then
        local apath = autosave_path()
        local f = io.open(apath, "r")
        if f then
            f:close()
            self._recovery_pending = true
        end
    end

    terminux.on("augment-command-palette", function(window, pane)
        return self:register_palette_entries(window, pane)
    end)

    if terminux.on_shutdown then
        terminux.on("on_shutdown", function()
            self:mark_clean_shutdown()
        end)
    end
end

function SessionManager:startup_autosave(window, pane)
    self:start_autosave(window, pane)

    if self._recovery_pending then
        self:show_recovery_dialog(window, pane)
        self._recovery_pending = false
    end
end

return SessionManager
