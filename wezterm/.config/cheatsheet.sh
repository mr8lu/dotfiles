#!/bin/bash
# Bauhaus Terminal Cheatsheet (TMUX + Wezterm)
# Earthy Muted Tone Edition

RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;34m'
CYAN=$'\033[1;36m'
WHITE=$'\033[0;37m'
RESET=$'\033[0m'
BOLD=$'\033[1m'

cat << EOF
${RED}┌────────────────────────────────────────────────────────┐${RESET}
${RED}│${RESET}   ${RED}■${RESET}  ${BOLD}BAUHAUS TERMINAL CHEATSHEET (TMUX + WEZTERM)${RESET}  ${YELLOW}▲${RESET}   ${RED}│${RESET}
${RED}└────────────────────────────────────────────────────────┘${RESET}

  ${BLUE}[TMUX CHEATSHEET]${RESET} (Prefix: ${YELLOW}Control + b${RESET})
  ──────────────────────────────────────────────────────────
  ${CYAN}Session Management:${RESET}
    ${YELLOW}Prefix + s${RESET}       List sessions
    ${YELLOW}Prefix + d${RESET}       Detach from session
    ${YELLOW}Prefix + \$${RESET}       Rename current session

  ${CYAN}Window Management:${RESET}
    ${YELLOW}Prefix + c${RESET}       Create new window
    ${YELLOW}Prefix + ,${RESET}       Rename current window
    ${YELLOW}Prefix + n / p${RESET}   Next / Previous window
    ${YELLOW}Prefix + [0-9]${RESET}   Jump to window by index
    ${YELLOW}Prefix + &${RESET}       Kill current window

  ${CYAN}Pane Management:${RESET}
    ${YELLOW}Prefix + %${RESET}       Split pane horizontally (side-by-side)
    ${YELLOW}Prefix + "${RESET}       Split pane vertically (top-and-bottom)
    ${YELLOW}Prefix + x${RESET}       Kill current pane
    ${YELLOW}Prefix + o${RESET}       Cycle through panes
    ${YELLOW}Prefix + z${RESET}       Toggle pane zoom (maximize/minimize)
    ${YELLOW}Prefix + Space${RESET}   Cycle through layout presets

  ${CYAN}Navigation & Scroll Mode:${RESET}
    ${YELLOW}Prefix + [${RESET}       Enter scroll mode (arrow keys, ${GREEN}q${RESET} to quit)


  ${BLUE}[WEZTERM CHEATSHEET]${RESET} (macOS Native Keys)
  ──────────────────────────────────────────────────────────
  ${CYAN}Tab & Pane Management:${RESET}
    ${YELLOW}Command + t${RESET}          Create new tab
    ${YELLOW}Command + w${RESET}          Close current tab or pane
    ${YELLOW}Command + Shift + [${RESET}  Previous tab
    ${YELLOW}Command + Shift + ]${RESET}  Next tab
    ${YELLOW}Command + [1-9]${RESET}      Jump to tab by index

  ${CYAN}Search & Utilities:${RESET}
    ${YELLOW}Command + Shift + f${RESET}  Search scrollback buffer
    ${YELLOW}Command + k${RESET}          Clear scrollback / Reset terminal
    ${YELLOW}Command + + / -${RESET}      Increase / Decrease font size
    ${YELLOW}Command + 0${RESET}          Reset font size to default
    ${YELLOW}Control + Shift + P${RESET}  Open Command Palette (Pane)
    ${YELLOW}Control + Shift + C${RESET}  Open this Cheatsheet

  ${CYAN}Line & Cursor Editing:${RESET}
    ${YELLOW}Command + Left Arrow${RESET}  Jump to beginning of line
    ${YELLOW}Command + Right Arrow${RESET} Jump to end of line
    ${YELLOW}Option + Left Arrow${RESET}   Jump backward one word
    ${YELLOW}Option + Right Arrow${RESET}  Jump forward one word
    ${YELLOW}Command + Delete${RESET}      Delete to beginning of line
    ${YELLOW}Option + Delete${RESET}       Delete previous word
    ${YELLOW}Shift + Enter${RESET}         Insert new line (Zsh)

  ──────────────────────────────────────────────────────────
  Press ${GREEN}q${RESET} to close this cheatsheet window.
EOF
