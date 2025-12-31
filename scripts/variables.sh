#!/usr/bin/env bash

# Helper function to read tmux options
get_tmux_option() {
    local option="$1"
    local default="$2"
    local value
    value=$(tmux show-option -gqv "$option")
    echo "${value:-$default}"
}

# Feature toggles (NEW)
export password_enable=$(get_tmux_option "@1password-password-enable" "on")
export otp_enable=$(get_tmux_option "@1password-otp-enable" "on")

# Key bindings
export password_key=$(get_tmux_option "@1password-key" "u")
export otp_key=$(get_tmux_option "@1password-otp-key" "o")

# Popup dimensions (NEW)
export popup_width=$(get_tmux_option "@1password-popup-width" "80%")
export popup_height=$(get_tmux_option "@1password-popup-height" "60%")

# Existing options
export copy_to_clipboard=$(get_tmux_option "@1password-copy-to-clipboard" "off")
export auto_clear_seconds=$(get_tmux_option "@1password-auto-clear-seconds" "30")
export otp_auto_clear_seconds=$(get_tmux_option "@1password-otp-auto-clear-seconds" "10")
export categories=$(get_tmux_option "@1password-categories" "Login")
export vault=$(get_tmux_option "@1password-vault" "")
export account=$(get_tmux_option "@1password-account" "")
export use_cache=$(get_tmux_option "@1password-use-cache" "off")
export cache_age=$(get_tmux_option "@1password-cache-age" "300")
