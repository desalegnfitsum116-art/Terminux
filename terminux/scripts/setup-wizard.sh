#!/usr/bin/env bash
#
# Terminux First-Time Setup Wizard
# Guides the user through initial configuration.
#

set -euo pipefail

BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
CLS="\033[2J\033[H"
HIDE_CURSOR="\033[?25l"
SHOW_CURSOR="\033[?25h"
GREEN="\033[38;5;76m"
YELLOW="\033[38;5;220m"
WHITE="\033[38;5;255m"
DIM_FG="\033[38;5;240m"
ACCENT="\033[38;5;76m"

CONFIG_DIR="${TERMINUX_CONFIG_DIR:-$HOME/.config/terminux}"
SETTINGS_FILE="$CONFIG_DIR/settings.lua"
DASHBOARD_FILE="$CONFIG_DIR/dashboard.lua"

cleanup() {
    printf "${SHOW_CURSOR}${RESET}\n"
    stty echo 2>/dev/null || true
}
trap cleanup EXIT INT TERM

stty -echo -icanon time 0 min 0 2>/dev/null || true
printf "${HIDE_CURSOR}${CLS}"

# ---- UI Helpers ----
draw_header() {
    local w="${1:-60}"
    printf "${ACCENT}╔"
    for ((i=0; i<w-2; i++)); do printf "═"; done
    printf "╗${RESET}\n"
    printf "${ACCENT}║${RESET}  ${BOLD}${GREEN}TERMINUX SETUP${RESET}${DIM_FG} - First Time Configuration${RESET}  ${ACCENT}║${RESET}\n"
    printf "${ACCENT}╚"
    for ((i=0; i<w-2; i++)); do printf "═"; done
    printf "╝${RESET}\n"
}

prompt_choice() {
    local prompt="$1" default="$2"
    printf "\n${BOLD}${prompt}${RESET} [${default}]: "
    stty echo 2>/dev/null || true
    read -r input
    stty -echo 2>/dev/null || true
    if [ -z "$input" ]; then
        echo "$default"
    else
        echo "$input"
    fi
}

prompt_select() {
    local prompt="$1" default="$2"
    shift 2
    local options=("$@")
    local w=60
    printf "\n${BOLD}${prompt}${RESET}\n"
    printf "\n"
    for i in "${!options[@]}"; do
        local num=$((i + 1))
        printf "  ${ACCENT}[${WHITE}${num}${ACCENT}]${RESET}  ${options[$i]}\n"
    done
    printf "\n${DIM_FG}Enter number${RESET} (1-${#options[@]}, default: ${default}): "
    stty echo 2>/dev/null || true
    read -r input
    stty -echo 2>/dev/null || true
    if [ -z "$input" ]; then
        echo "$default"
    elif [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le "${#options[@]}" ]; then
        echo "${options[$((input - 1))]}"
    else
        echo "$default"
    fi
}

wait_key() {
    printf "\n${DIM_FG}Press any key to continue...${RESET}"
    read -r -n1 || true
}

# ---- Wizard Steps ----
step_welcome() {
    local w=60
    printf "${CLS}"
    draw_header "$w"
    printf "\n"
    printf "  ${BOLD}Welcome to Terminux!${RESET}\n"
    printf "\n"
    printf "  Terminux is a modern, GPU-accelerated terminal emulator\n"
    printf "  built for developers. Let's get you set up.\n"
    printf "\n"
    printf "  This wizard will help you configure:\n"
    printf "  ${DIM_FG}  \u2022 Theme selection${RESET}\n"
    printf "  ${DIM_FG}  \u2022 Default shell${RESET}\n"
    printf "  ${DIM_FG}  \u2022 Font preferences${RESET}\n"
    printf "  ${DIM_FG}  \u2022 Window settings${RESET}\n"
    wait_key
}

step_theme() {
    local w=60
    printf "${CLS}"
    draw_header "$w"
    printf "\n"
    printf "  ${BOLD}Choose a Theme${RESET}\n"
    printf "\n"
    printf "  ${DIM_FG}  1) Terminux Dark  - Dark background, lime green accent${RESET}\n"
    printf "  ${DIM_FG}  2) Terminux Light - Light background, indigo accent${RESET}\n"
    printf "  ${DIM_FG}  3) Neon           - Cyberpunk neon with magenta/cyan${RESET}\n"
    printf "  ${DIM_FG}  4) Midnight       - Pure black with subtle grays${RESET}\n"
    local theme
    theme=$(prompt_select "Select Theme" "terminux-dark" "terminux-dark" "terminux-light" "neon" "midnight")
    echo "$theme"
}

step_shell() {
    local w=60
    printf "${CLS}"
    draw_header "$w"
    printf "\n"
    printf "  ${BOLD}Default Shell${RESET}\n"
    printf "\n"
    printf "  ${DIM_FG}  Your default shell will be used (${SHELL:-/bin/bash}).${RESET}\n"
    printf "\n"
    printf "  ${DIM_FG}  You can override this later in settings.lua${RESET}\n"
    echo "${SHELL:-/bin/bash}"
    wait_key
}

step_font() {
    local w=60
    printf "${CLS}"
    draw_header "$w"
    printf "\n"
    printf "  ${BOLD}Font Selection${RESET}\n"
    printf "\n"
    printf "  ${DIM_FG}  1) JetBrains Mono  - Developer-friendly ligature font${RESET}\n"
    printf "  ${DIM_FG}  2) Cascadia Code   - Windows Terminal font${RESET}\n"
    printf "  ${DIM_FG}  3) Fira Code       - Popular coding font${RESET}\n"
    printf "  ${DIM_FG}  4) Hack            - Classic monospace${RESET}\n"
    local font
    font=$(prompt_select "Select Font" "JetBrains Mono" "JetBrains Mono" "Cascadia Code" "Fira Code" "Hack")
    printf "\n"
    local size
    size=$(prompt_choice "Font Size" "11.0")
    echo "${font}|${size}"
}

step_finish() {
    local w=60
    printf "${CLS}"
    draw_header "$w"
    printf "\n"
    printf "  ${BOLD}Configuration Complete!${RESET}\n"
    printf "\n"
    printf "  ${DIM_FG}Your settings have been saved to:${RESET}\n"
    printf "  ${DIM}  $SETTINGS_FILE${RESET}\n"
    printf "\n"
    printf "  ${YELLOW}\u26A0 Note:${RESET} You can customize further by editing:\n"
    printf "  ${DIM}  $CONFIG_DIR/terminux.lua${RESET}\n"
    printf "\n"
    printf "  ${BOLD}Quick Tips:${RESET}\n"
    printf "  ${DIM_FG}  \u2022 CTRL+SHIFT+D  - Open dashboard${RESET}\n"
    printf "  ${DIM_FG}  \u2022 CTRL+SHIFT+P  - Command palette${RESET}\n"
    printf "  ${DIM_FG}  \u2022 CTRL+SHIFT+R  - Reload config${RESET}\n"
    printf "  ${DIM_FG}  \u2022 CTRL+SHIFT+Space - Launcher${RESET}\n"
    wait_key
}

# ---- Save Configuration ----
save_config() {
    local theme="$1" font="$2" font_size="$3"

    mkdir -p "$CONFIG_DIR"

    cat > "$SETTINGS_FILE" << EOF
-- Terminux Settings
-- Generated by setup wizard

theme = "${theme}"
font = "${font}"
font_size = ${font_size}
window_title = "Terminux"
hide_tab_bar_if_only_one_tab = false
enable_scroll_bar = true
scrollback_lines = 10000
show_dashboard_on_startup = false
EOF

    cat > "$DASHBOARD_FILE" << 'EOF'
-- Terminux Dashboard Configuration
return {
    enabled = true,
    show_system_info = true,
    show_recent_sessions = true,
    startup_message = "Welcome to Terminux",
    show_on_startup = false,
}
EOF

    printf "\n${GREEN}\u2713 Configuration saved!${RESET}\n"
}

# ---- Main ----
main() {
    printf "${CLS}"

    # Skip if settings already exist
    if [ -f "$SETTINGS_FILE" ]; then
        printf "  ${DIM_FG}Configuration already exists at %s${RESET}\n" "$SETTINGS_FILE"
        printf "  ${DIM_FG}Delete it and re-run to reconfigure.${RESET}\n"
        printf "\n"
        printf "  ${YELLOW}Terminux Dashboard${RESET}\n"
        printf "  ${DIM_FG}CTRL+SHIFT+D to open${RESET}\n"
        wait_key
        return
    fi

    step_welcome

    local theme
    theme=$(step_theme)

    step_shell

    local font_result font font_size
    font_result=$(step_font)
    font="${font_result%%|*}"
    font_size="${font_result##*|}"

    save_config "$theme" "$font" "$font_size"

    step_finish
}

main "$@"
printf "${SHOW_CURSOR}${RESET}\n"
