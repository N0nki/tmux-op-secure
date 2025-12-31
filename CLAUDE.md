# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

tmux-op-secure is a tmux plugin that provides secure 1Password integration without storing authentication tokens on disk. It uses 1Password CLI v2's biometric authentication for every access and provides both password and OTP retrieval via fzf-based fuzzy search within tmux popups.

## Architecture

### Entry Point & Plugin Loading

- `op-secure.tmux`: Main plugin entry point that tmux loads
  - Sources `scripts/variables.sh` to read tmux configuration options
  - Conditionally binds key mappings based on feature toggles (`@1password-password-enable`, `@1password-otp-enable`)
  - Creates tmux popups that execute the main scripts

### Configuration System

- `scripts/variables.sh`: Central configuration reader
  - Exports all tmux options as environment variables
  - Uses `get_tmux_option()` helper to read tmux global options with defaults
  - All scripts inherit these environment variables

### Core Scripts

- `scripts/main.sh`: Password retrieval flow
  - Lists 1Password items using `op item list`
  - Displays fzf selector for item selection
  - Retrieves password using `op read op://vault/title/password`
  - Supports both clipboard mode and send-keys mode
  - Implements optional metadata caching for performance

- `scripts/otp.sh`: OTP/2FA code retrieval flow
  - Similar to main.sh but retrieves TOTP codes using `op item get --otp`
  - Always uses clipboard mode (no send-keys support)
  - Uses shorter auto-clear timeout (default 10s vs 30s)
  - Validates output is a 6-8 digit code

### Key Design Patterns

**Shared Code Duplication**: Both `main.sh` and `otp.sh` duplicate several functions (`get_tmux_option`, `get_op_cmd`, `check_dependencies`, `copy_to_clipboard`, `clear_clipboard`, `write_cache_file`). This is intentional to keep scripts self-contained and avoid sourcing dependencies.

**Security-First Design**:

- Uses bash arrays for command arguments to prevent shell injection
- Atomic file writes with `mktemp` and `mv` to prevent race conditions
- Symlink attack prevention (checks and removes symlinks before writing cache)
- Secure cache file permissions (600) with per-user isolation (`/tmp/tmux-op-secure-${USER}-cache.json`)
- No persistent authentication tokens stored

**Cache System**:

- Optional metadata-only caching (item lists, not passwords)
- Configurable expiration time via `@1password-cache-age` (default 300s, 0=never expire)
- Cache file location: `/tmp/tmux-op-secure-${USER}-cache.json`

**Platform Compatibility**:

- Detects `op.exe` vs `op` for WSL2 support
- Clipboard detection: `clip.exe` (WSL2) > `pbcopy` (macOS) > `xclip` (Linux)
- Uses `stat -c %Y` for cache timestamp (may need adaptation for BSD/macOS)

## Testing the Plugin

Since this is a tmux plugin, manual testing within tmux is required:

1. Load the plugin in tmux (reload config):

   ```bash
   tmux source-file ~/.tmux.conf
   ```

2. Test password retrieval (default: `prefix + u`):
   - Verify popup appears
   - Check fzf displays 1Password items
   - Confirm password is copied/sent correctly
   - Verify auto-clear timeout works

3. Test OTP retrieval (default: `prefix + o`):
   - Verify popup appears
   - Check OTP code is copied to clipboard
   - Verify code is valid 6-8 digits

4. Test error handling:
   - Run without 1Password app open
   - Try with invalid vault/account settings
   - Test with missing dependencies (fzf, jq, op)

## Configuration Options Reference

All tmux options use the `@1password-` prefix and are read in `scripts/variables.sh`. Key options:

- `@1password-password-enable` / `@1password-otp-enable`: Feature toggles (on/off)
- `@1password-key` / `@1password-otp-key`: Key bindings (empty to disable)
- `@1password-copy-to-clipboard`: Clipboard vs send-keys mode (off/on)
- `@1password-vault` / `@1password-account`: Filter items by vault/account
- `@1password-use-cache`: Enable metadata caching (off/on)
- `@1password-cache-age`: Cache expiration in seconds (0 = never)

See README.md for complete configuration reference.

## Common Modifications

**Adding new features**: Determine if feature applies to password, OTP, or both. Modify respective script(s) and add configuration options to `variables.sh` if needed.

**Changing 1Password CLI commands**: Update command arrays in main.sh and/or otp.sh. Maintain array-based argument construction to prevent injection.

**Adding platform support**: Update `get_op_cmd()` for CLI detection and `copy_to_clipboard()`/`clear_clipboard()` for platform-specific clipboard commands.

## Dependencies

Runtime:

- 1Password CLI v2.0.0+ (`op` or `op.exe`)
- fzf (fuzzy finder)
- jq (JSON processor)
- tmux (obviously)
- Platform-specific clipboard: `clip.exe`, `pbcopy`, or `xclip`

No build process or external libraries required - pure bash implementation.
