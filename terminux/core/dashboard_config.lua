-- Terminux Dashboard Configuration
-- Copy this file to ~/.config/terminux/dashboard.lua and customize.

return {
    -- Set to false to disable the dashboard entirely
    enabled = true,

    -- Show system info panel in the dashboard
    show_system_info = true,

    -- Show recent sessions panel
    show_recent_sessions = true,

    -- Custom startup message (shown in the dashboard header)
    startup_message = "Welcome to Terminux",

    -- Show dashboard automatically when Terminux starts
    show_on_startup = false,

    -- Position: "tab" (new tab), "current" (current pane)
    position = "tab",
}
