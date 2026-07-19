-- Hello Terminux Plugin
-- Demonstrates the Terminux Plugin API

function on_load()
    terminux:log("Hello Terminux plugin loaded!")
end

function on_startup()
    terminux:notify("Terminux is ready! Type 'hello-terminux' in the command palette.")
end

function on_unload()
    terminux:log("Goodbye from Hello Terminux!")
end

function on_theme_changed(theme)
    terminux:notify("Theme changed to " .. theme)
end

-- Register a command
terminux:register_command({
    name = "hello-terminux",
    description = "Display a greeting from the plugin system",
    callback = function()
        terminux:notify("Hello from the Terminux plugin system! (v" .. terminux:get_version() .. ")")
    end,
})

-- Register a counter command using state
terminux:register_command({
    name = "hello-counter",
    description = "Show how many times this command has been run",
    callback = function()
        local state = terminux:load_state() or { count = 0 }
        state.count = (state.count or 0) + 1
        terminux:save_state(state)
        terminux:notify("Hello Terminux has been invoked " .. state.count .. " time(s)!")
    end,
})

-- Register a system info command
terminux:register_command({
    name = "hello-system-info",
    description = "Show system information",
    callback = function()
        local config_dir = terminux:get_config_dir()
        local data_dir = terminux:get_data_dir()
        local version = terminux:get_version()
        local termux_env = terminux:exec("echo $TERMUX_ENV 2>/dev/null || echo 'N/A'")
        terminux:notify("Config: " .. config_dir .. "\nData: " .. data_dir .. "\nVersion: " .. version)
    end,
})
