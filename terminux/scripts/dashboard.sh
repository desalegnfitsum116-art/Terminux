#!/usr/bin/env bash
#
# Terminux Dashboard
# Shows a startup dashboard with quick actions, system info, and theme selector.
#

set -euo pipefail

# ---- ANSI Setup ----
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
CLS="\033[2J\033[H"
HIDE_CURSOR="\033[?25l"
SHOW_CURSOR="\033[?25h"

# Colors (use terminal defaults, works with all themes)
HEADER_FG="\033[38;5;76m"    # green
ACCENT="\033[38;5;76m"
DIM_FG="\033[38;5;240m"
WHITE="\033[38;5;255m"
BG="\033[48;5;233m"
SEPARATOR="\033[38;5;236m"

readonly VERSION="1.0.0"

# ---- Terminal Setup ----
cleanup() {
    printf "${SHOW_CURSOR}${RESET}\n"
    stty echo 2>/dev/null || true
}
trap cleanup EXIT INT TERM

stty -echo -icanon time 0 min 0 2>/dev/null || true
printf "${HIDE_CURSOR}${CLS}"

# ---- Detect System Info ----
detect_shell() {
    basename "${SHELL:-unknown}"
}

detect_os() {
    case "$(uname -s)" in
        Linux) echo "Linux" ;;
        Darwin) echo "macOS" ;;
        MINGW*|MSYS*) echo "Windows" ;;
        *) uname -s ;;
    esac
}

detect_gpu() {
    if command -v glxinfo &>/dev/null; then
        glxinfo 2>/dev/null | grep "OpenGL renderer" | sed 's/.*: //' | head -1
    elif command -v wgpu &>/dev/null; then
        echo "WebGPU"
    else
        echo "GPU Enabled (default)"
    fi
}

get_terminal_size() {
    if command -v stty &>/dev/null; then
        stty size 2>/dev/null || echo "24 80"
    else
        echo "24 80"
    fi
}

read rows cols <<< "$(get_terminal_size)"

# ---- Theme Detection ----
detect_theme() {
    local theme_file="${TERMINUX_CONFIG_DIR:-$HOME/.config/terminux}/settings.lua"
    if [ -f "$theme_file" ]; then
        grep -oP 'theme\s*=\s*"\K[^"]+' "$theme_file" 2>/dev/null || echo "terminux-dark"
    else
        echo "terminux-dark"
    fi
}

# ---- Recent Sessions ----
recent_file="${TERMINUX_CONFIG_DIR:-$HOME/.config/terminux}/recent_sessions.lua"

load_recent() {
    if [ -f "$recent_file" ]; then
        # Extract cwd values from Lua table format
        grep -oP 'cwd="\K[^"]+' "$recent_file" 2>/dev/null || true
    fi
}

open_recent() {
    local idx="$1"
    local dir
    dir=$(load_recent | sed -n "${idx}p" 2>/dev/null)
    if [ -n "$dir" ] && [ -d "$dir" ]; then
        printf "${SHOW_CURSOR}${RESET}\n"
        cd "$dir" && exec "${SHELL:-/bin/bash}" -l
    fi
}

# ---- Draw Functions ----
center_text() {
    local text="$1"
    local width="${2:-80}"
    local pad=$(( (width - ${#text}) / 2 ))
    printf "%${pad}s" ""
    printf "%s" "$text"
    local rest=$(( width - pad - ${#text} ))
    printf "%${rest}s" ""
}

draw_box_top() {
    local w="$1"
    printf "${ACCENT}╔"
    for ((i=0; i<w-2; i++)); do printf "═"; done
    printf "╗${RESET}\n"
}

draw_box_bottom() {
    local w="$1"
    printf "${ACCENT}╚"
    for ((i=0; i<w-2; i++)); do printf "═"; done
    printf "╝${RESET}\n"
}

draw_box_line() {
    local w="$1"
    printf "${ACCENT}║${RESET} %-*s ${ACCENT}║${RESET}\n" $((w-4)) ""
}

draw_box_text() {
    local w="$1" txt="$2"
    printf "${ACCENT}║${RESET} %-*s ${ACCENT}║${RESET}\n" $((w-4)) "$txt"
}

draw_hotkey() {
    local key="$1" label="$2"
    printf " [${BOLD}${WHITE}%s${RESET}] ${DIM_FG}%s${RESET}" "$key" "$label"
}

# ---- Dashboard ----
dashboard() {
    local theme
    theme=$(detect_theme)

    printf "${CLS}"

    # Calculate usable width
    local w=$(( cols > 80 ? 80 : cols ))
    w=$(( w < 40 ? 40 : w ))

    local y=1

    # Header
    printf "\n"
    draw_box_top "$w"
    draw_box_text "$w" ""
    printf "${ACCENT}║${RESET}  ${BOLD}${HEADER_FG}TERMINUX${RESET} ${DIM_FG}Modern GPU Accelerated Terminal${RESET}      ${ACCENT}║${RESET}\n"
    draw_box_text "$w" ""
    draw_box_bottom "$w"
    printf "\n"

    # Quick Actions
    draw_box_top "$w"
    draw_box_text "$w" "  ${BOLD}QUICK ACTIONS${RESET}"
    draw_box_text "$w" ""
    draw_box_text "$w" "  $(draw_hotkey 1 "New Shell")    $(draw_hotkey 2 "New Tab")    $(draw_hotkey 3 "SSH")"
    draw_box_text "$w" "  $(draw_hotkey 4 "Themes")      $(draw_hotkey 5 "Settings")   $(draw_hotkey 6 "Reload Config")"
    draw_box_text "$w" ""
    draw_box_bottom "$w"
    printf "\n"

    # System Info
    draw_box_top "$w"
    draw_box_text "$w" "  ${BOLD}SYSTEM INFO${RESET}"
    draw_box_text "$w" ""
    draw_box_text "$w" "  ${DIM_FG}Version:${RESET}  Terminux v${VERSION}"
    draw_box_text "$w" "  ${DIM_FG}Theme:${RESET}    ${theme}"
    draw_box_text "$w" "  ${DIM_FG}Shell:${RESET}    $(detect_shell)"
    draw_box_text "$w" "  ${DIM_FG}OS:${RESET}       $(detect_os)"
    draw_box_text "$w" "  ${DIM_FG}Renderer:${RESET} $(detect_gpu)"
    draw_box_text "$w" ""
    draw_box_bottom "$w"
    printf "\n"

    # Recent
    local recent_lines=()
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            recent_lines+=("$line")
        fi
    done < <(load_recent | head -5)

    local recent_start=7
    if [ ${#recent_lines[@]} -gt 0 ]; then
        draw_box_top "$w"
        draw_box_text "$w" "  ${BOLD}RECENT${RESET}"
        draw_box_text "$w" ""
        local i=1
        for line in "${recent_lines[@]}"; do
            draw_box_text "$w" "  $(draw_hotkey "$((recent_start + i - 1))" "$line")"
            i=$((i + 1))
        done
        draw_box_text "$w" ""
        draw_box_bottom "$w"
        printf "\n"
    fi

    # Footer
    printf "${DIM_FG}"
    center_text "Press [1-6] for actions • [$recent_start-$(($recent_start + ${#recent_lines[@]} - 1))] recent dirs • [q] quit • [r] refresh" "$w"
    printf "${RESET}\n"
    printf "${DIM_FG}"
    center_text "CTRL+SHIFT+D to reopen • CTRL+SHIFT+P for command palette" "$w"
    printf "${RESET}\n"
}

# ---- Actions ----
action_new_shell() {
    printf "${SHOW_CURSOR}${RESET}\n"
    exec "${SHELL:-/bin/bash}" -l
}

action_new_tab() {
    # This runs inside the dashboard tab, so we launch a shell in a new mux tab
    # by using the terminux CLI
    if command -v terminux &>/dev/null; then
        terminux cli spawn --new-tab 2>/dev/null || true
    fi
    # Then launch shell
    action_new_shell
}

action_ssh() {
    printf "${SHOW_CURSOR}${RESET}\n"
    printf "\n${BOLD}SSH Connection${RESET}\n"
    printf "Enter host: "
    read -r host
    if [ -n "$host" ]; then
        exec ssh "$host"
    fi
}

action_themes() {
    printf "${SHOW_CURSOR}${RESET}\n"
    if command -v terminux &>/dev/null; then
        terminux theme list
        printf "\n${BOLD}Set theme${RESET} (type name or Enter to cancel): "
        read -r theme_name
        if [ -n "$theme_name" ]; then
            terminux theme set "$theme_name" 2>/dev/null || printf "Theme not found\n"
        fi
    else
        printf "terminux CLI not available. Edit ~/.config/terminux/settings.lua manually.\n"
    fi
    printf "\n${DIM_FG}Press any key to return to dashboard...${RESET}"
    read -r -n1 || true
}

action_settings() {
    local config_dir="${TERMINUX_CONFIG_DIR:-$HOME/.config/terminux}"
    local settings="$config_dir/settings.lua"
    if [ -f "$settings" ]; then
        if command -v nano &>/dev/null; then
            nano "$settings"
        elif command -v vim &>/dev/null; then
            vim "$settings"
        elif command -v vi &>/dev/null; then
            vi "$settings"
        else
            printf "${SHOW_CURSOR}${RESET}\n"
            cat "$settings"
            printf "\n${DIM_FG}Press any key to return...${RESET}"
            read -r -n1 || true
        fi
    else
        printf "${SHOW_CURSOR}${RESET}\n"
        printf "No settings file found at %s\n" "$settings"
        printf "\n${DIM_FG}Press any key to return...${RESET}"
        read -r -n1 || true
    fi
}

action_reload() {
    printf "${SHOW_CURSOR}${RESET}\n"
    printf "${BOLD}Reloading configuration...${RESET}\n"
    # Try to reload via terminux CLI if available
    if command -v terminux &>/dev/null; then
        terminux reload 2>/dev/null || true
    fi
    printf "\n${GREEN}\u2713 Configuration reload triggered${RESET}\n"
    printf "${DIM_FG}Tip: Press CTRL+SHIFT+R to reload manually.${RESET}\n"
    sleep 1
}

# ---- Main Loop ----
main() {
    while true; do
        dashboard
        read -r -n1 key || true
    case "$key" in
        1|s|S) action_new_shell ;;
        2|t|T) action_new_tab ;;
        3|h|H) action_ssh ;;
        4|h|H) action_themes ;;
        5|S) action_settings ;;
        6|r|R) action_reload ;;
        7|8|9)
            local idx=$((key - 6))
            open_recent "$idx"
            ;;
        q|Q) break ;;
        *) ;;
    esac
    done
    printf "${SHOW_CURSOR}${RESET}\n"
}

main "$@"
