#!/bin/bash
# Secure 1Password OTP integration for tmux
# No token files - uses biometric authentication on every access

set -e

# Redirect all output to show errors in popup
exec 2>&1

# Trap errors and show them
trap 'echo ""; echo "Error occurred at line $LINENO"; echo "Press any key to close..."; read -r -n 1' ERR

# Get tmux option with default value
get_tmux_option() {
  local option="$1"
  local default="$2"
  local value
  value=$(tmux show-option -gqv "$option")
  echo "${value:-$default}"
}

# Detect 1Password CLI command (prefer Windows version in WSL)
get_op_cmd() {
  if command -v op.exe &>/dev/null; then
    echo "op.exe"
  elif command -v op &>/dev/null; then
    echo "op"
  else
    echo ""
  fi
}

# Check required commands
check_dependencies() {
  local missing=()

  OP_CMD=$(get_op_cmd)
  if [ -z "$OP_CMD" ]; then
    missing+=("op (1Password CLI)")
  fi

  if ! command -v fzf &>/dev/null; then
    missing+=("fzf")
  fi

  if ! command -v jq &>/dev/null; then
    missing+=("jq")
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Error: Missing dependencies: ${missing[*]}"
    echo "Press any key to close..."
    read -r -n 1
    exit 1
  fi
}

# Copy to clipboard safely (no shell injection)
copy_to_clipboard() {
  local text="$1"
  if command -v clip.exe &>/dev/null; then
    echo -n "$text" | clip.exe
  elif command -v pbcopy &>/dev/null; then
    echo -n "$text" | pbcopy
  elif command -v xclip &>/dev/null; then
    echo -n "$text" | xclip -selection clipboard
  else
    return 1
  fi
  return 0
}

# Clear clipboard safely
clear_clipboard() {
  if command -v clip.exe &>/dev/null; then
    echo -n "" | clip.exe
  elif command -v pbcopy &>/dev/null; then
    echo -n "" | pbcopy
  elif command -v xclip &>/dev/null; then
    echo -n "" | xclip -selection clipboard
  fi
}

# Write cache file with secure permissions (600) and symlink protection
write_cache_file() {
  local cache_file="$1"
  local content="$2"

  # Remove existing file if it's a symlink (prevent symlink attack)
  if [ -L "$cache_file" ]; then
    rm -f "$cache_file"
  fi

  # Create temporary file securely with mktemp
  local temp_file
  temp_file=$(mktemp) || return 1

  # Set secure permissions on temp file
  chmod 600 "$temp_file" || {
    rm -f "$temp_file"
    return 1
  }

  # Write content to temp file
  echo "$content" >"$temp_file" || {
    rm -f "$temp_file"
    return 1
  }

  # Atomically replace target file (prevents race conditions)
  mv -f "$temp_file" "$cache_file" || {
    rm -f "$temp_file"
    return 1
  }

  return 0
}

# Main function
main() {
  check_dependencies

  local auto_clear_seconds
  local vault
  local account

  # OTP codes expire quickly, use shorter auto-clear time
  # Note: OTP mode always copies to clipboard (no send-keys mode)
  auto_clear_seconds=$(get_tmux_option "@1password-otp-auto-clear-seconds" "10")
  vault=$(get_tmux_option "@1password-vault" "")
  account=$(get_tmux_option "@1password-account" "")
  local categories
  categories=$(get_tmux_option "@1password-categories" "Login")
  local use_cache
  use_cache=$(get_tmux_option "@1password-use-cache" "off")
  # Secure cache file with proper permissions (600) and per-user isolation
  local cache_file="/tmp/tmux-op-secure-${USER}-cache.json"
  local cache_age
  cache_age=$(get_tmux_option "@1password-cache-age" "300")

  # Build op item list command arguments (using array to prevent injection)
  local list_args=("item" "list" "--format=json")
  [ -n "$vault" ] && list_args+=("--vault" "$vault")
  [ -n "$account" ] && list_args+=("--account" "$account")
  [ -n "$categories" ] && list_args+=("--categories" "$categories")

  # Get items and format for fzf
  local items
  local error_output

  # Check cache if enabled
  local exit_code=0
  if [ "$use_cache" = "on" ] && [ -f "$cache_file" ]; then
    local cache_timestamp
    cache_timestamp=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    local current_time
    current_time=$(date +%s)
    local age=$((current_time - cache_timestamp))

    # If cache_age is 0 or negative, cache never expires
    if [ "$cache_age" -le 0 ] || [ "$age" -lt "$cache_age" ]; then
      items=$(cat "$cache_file")
      exit_code=$?
      if [ "$cache_age" -le 0 ]; then
        echo "Using cached data (never expires)..."
      else
        echo "Using cached data (age: ${age}s)..."
      fi
      sleep 0.5
    else
      echo "Fetching items from 1Password..."
      items=$("$OP_CMD" "${list_args[@]}" 2>&1)
      exit_code=$?
      [ $exit_code -eq 0 ] && write_cache_file "$cache_file" "$items"
    fi
  else
    echo "Fetching items from 1Password..."
    items=$("$OP_CMD" "${list_args[@]}" 2>&1)
    exit_code=$?
    [ $exit_code -eq 0 ] && [ "$use_cache" = "on" ] && write_cache_file "$cache_file" "$items"
  fi

  if [ $exit_code -ne 0 ]; then
    # Extract first line of error message
    error_output=$(echo "$items" | head -1)
    echo "1Password CLI Error:"
    echo "$error_output"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check 1Password app is running"
    echo "2. Enable: Settings > Developer > 'Integrate with 1Password CLI'"
    echo "3. Run: op signin"
    echo ""
    echo "Press any key to close..."
    read -r -n 1
    exit 1
  fi

  local formatted_items
  formatted_items=$(echo "$items" | jq -r '.[] | "\(.title)\t\(.vault.name)\t\(.id)"')

  if [ -z "$formatted_items" ]; then
    echo "No items found in 1Password"
    echo "Press any key to close..."
    read -r -n 1
    exit 1
  fi

  # Show fzf selector (already in tmux popup)
  local selected
  selected=$(echo "$formatted_items" | fzf \
    --layout=reverse \
    --border \
    --prompt="1Password OTP > " \
    --delimiter='\t' \
    --with-nth=1,2 \
    --preview="echo {1}" \
    --preview-window=up:3:wrap)

  if [ -z "$selected" ]; then
    exit 0
  fi

  local item_title
  item_title=$(echo "$selected" | awk -F'\t' '{print $1}')

  # Get OTP code using op item get --otp (array prevents injection)
  local otp_args=("item" "get" "$item_title" "--otp")
  [ -n "$vault" ] && otp_args+=("--vault" "$vault")
  [ -n "$account" ] && otp_args+=("--account" "$account")

  local otp_code
  otp_code=$("$OP_CMD" "${otp_args[@]}" 2>&1)
  local exit_code=$?

  # Check if command succeeded and output looks like an OTP code (6-8 digits)
  if [ $exit_code -ne 0 ] || [ -z "$otp_code" ] || ! echo "$otp_code" | grep -qE '^[0-9]{6,8}$'; then
    echo "Failed to get OTP code"
    echo ""
    if [ -n "$otp_code" ]; then
      echo "Error: $otp_code"
      echo ""
    fi
    echo "Note: This item may not have OTP/2FA configured"
    echo "Or the item name may contain special characters"
    echo ""
    echo "Press any key to close..."
    read -r -n 1
    exit 1
  fi

  # Copy OTP code to clipboard (OTP doesn't support send-keys mode)
  if ! copy_to_clipboard "$otp_code"; then
    echo "No clipboard command found"
    echo "Press any key to close..."
    read -r -n 1
    exit 1
  fi

  echo "✓ OTP code copied to clipboard (auto-clear in ${auto_clear_seconds}s)"

  # Clear clipboard after specified seconds
  if [ "$auto_clear_seconds" -gt 0 ]; then
    (sleep "$auto_clear_seconds" && clear_clipboard 2>/dev/null) &
  fi
}

main "$@"
