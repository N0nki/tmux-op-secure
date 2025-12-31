#!/usr/bin/env bash
# tmux-op-secure: Secure 1Password integration without token files

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration variables
source "$CURRENT_DIR/scripts/variables.sh"

# Bind password key if feature is enabled and key is set
if [ "$password_enable" = "on" ] && [ -n "$password_key" ]; then
    tmux bind-key "$password_key" \
        display-popup -E -w "$popup_width" -h "$popup_height" \
        "$CURRENT_DIR/scripts/main.sh"
fi

# Bind OTP key if feature is enabled and key is set
if [ "$otp_enable" = "on" ] && [ -n "$otp_key" ]; then
    tmux bind-key "$otp_key" \
        display-popup -E -w "$popup_width" -h "$popup_height" \
        "$CURRENT_DIR/scripts/otp.sh"
fi
