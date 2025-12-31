# tmux-op-secure

Secure 1Password integration for tmux without token files.

## Features

- **No token files**: Uses 1Password CLI v2's biometric authentication on every access
- **fzf integration**: Fuzzy search through your 1Password items
- **Clipboard support**: Auto-copy with configurable auto-clear
- **OTP/2FA support**: Retrieve one-time passwords (TOTP) from 1Password items
- **Secure by default**: No persistent authentication tokens stored on disk

## Requirements

- [1Password CLI](https://developer.1password.com/docs/cli) v2.0.0+
- [fzf](https://github.com/junegunn/fzf)
- [jq](https://stedolan.github.io/jq/)
- Clipboard command:
  - WSL2: `clip.exe`
  - macOS: `pbcopy`
  - Linux: `xclip`

## Installation

### Installation via TPM (recommended)

Add plugin to `.tmux.conf`:

```bash
set -g @plugin 'N0nki/tmux-op-secure'
```

Press `prefix + I` to fetch and source the plugin.

### Manual Installation

Clone the repository:

```bash
git clone https://github.com/N0nki/tmux-op-secure ~/.tmux/plugins/tmux-op-secure
```

Add to `.tmux.conf`:

```bash
run-shell ~/.tmux/plugins/tmux-op-secure/op-secure.tmux
```

Reload tmux:

```bash
tmux source-file ~/.tmux.conf
```

## Usage

### Basic Usage

**Password retrieval:**

1. Press `prefix + u` (default: `Ctrl-t u`)
2. Select an item using fzf
3. Password is copied to clipboard (auto-clears in 30s)

**OTP/2FA code retrieval:**

1. Press `prefix + o` (default: `Ctrl-t o`)
2. Select an item using fzf
3. OTP code is copied to clipboard (auto-clears in 10s)

### Configuration Options

Add these to your `~/.tmux.conf` before loading the plugin:

#### Feature Toggles

```bash
# Enable/disable password feature (default: on)
set -g @1password-password-enable 'on'

# Enable/disable OTP feature (default: on)
set -g @1password-otp-enable 'on'
```

#### Key Bindings

```bash
# Change key binding for password (default: u)
set -g @1password-key 'p'

# Change key binding for OTP (default: o)
set -g @1password-otp-key 'O'

# Set to empty to disable individual feature
set -g @1password-key ''  # Disables password binding
```

#### UI Customization

```bash
# Popup dimensions (default: 80% x 60%)
set -g @1password-popup-width '90%'
set -g @1password-popup-height '70%'
```

#### Clipboard & Security

```bash
# Enable/disable clipboard copy (default: off)
set -g @1password-copy-to-clipboard 'on'

# Auto-clear clipboard after N seconds (default: 30)
set -g @1password-auto-clear-seconds '30'

# Auto-clear clipboard for OTP (default: 10 seconds)
set -g @1password-otp-auto-clear-seconds '15'
```

#### Filtering

```bash
# Filter by categories (default: Login)
# Options: Login, Password, SecureNote, CreditCard, etc.
set -g @1password-categories 'Login'

# Specify vault (optional)
set -g @1password-vault 'Private'

# Specify account (optional)
set -g @1password-account 'your-account'
```

#### Cache

```bash
# Enable cache (default: off)
# Cache contains only metadata (titles, IDs), no passwords
set -g @1password-use-cache 'on'
set -g @1password-cache-age '300'  # seconds (default: 300 = 5 min, 0 = never expire)
```

### Complete Configuration Reference

| Option                              | Default | Description                                 |
| ----------------------------------- | ------- | ------------------------------------------- |
| `@1password-password-enable`        | `on`    | Enable/disable password feature             |
| `@1password-otp-enable`             | `on`    | Enable/disable OTP feature                  |
| `@1password-key`                    | `u`     | Key binding for password (empty to disable) |
| `@1password-otp-key`                | `o`     | Key binding for OTP (empty to disable)      |
| `@1password-popup-width`            | `80%`   | Popup width                                 |
| `@1password-popup-height`           | `60%`   | Popup height                                |
| `@1password-copy-to-clipboard`      | `off`   | Copy to clipboard vs send-keys              |
| `@1password-auto-clear-seconds`     | `30`    | Password clipboard timeout                  |
| `@1password-otp-auto-clear-seconds` | `10`    | OTP clipboard timeout                       |
| `@1password-categories`             | `Login` | Filter by categories                        |
| `@1password-vault`                  | ``      | Specific vault name                         |
| `@1password-account`                | ``      | Specific account                            |
| `@1password-use-cache`              | `off`   | Enable metadata caching                     |
| `@1password-cache-age`              | `300`   | Cache age in seconds (0=never)              |

### Send to Pane vs Clipboard

**Clipboard mode** (recommended, `@1password-copy-to-clipboard 'on'`):

- Password copied to clipboard
- Auto-clears after configured seconds
- Safe for any input field

**Send-keys mode** (`@1password-copy-to-clipboard 'off'`):

- Password sent directly to current pane
- Useful for terminal password prompts
- Less safe if wrong pane is active

## Example Configurations

### Minimal Setup (TPM)

```bash
# In ~/.tmux.conf
set -g @plugin 'N0nki/tmux-op-secure'
```

### Advanced Configuration

```bash
# In ~/.tmux.conf

# Load plugin via TPM
set -g @plugin 'N0nki/tmux-op-secure'

# Or manual installation
# run-shell ~/.tmux/plugins/tmux-op-secure/op-secure.tmux

# Custom key bindings
set -g @1password-key 'P'
set -g @1password-otp-key 'O'

# Larger popup
set -g @1password-popup-width '90%'
set -g @1password-popup-height '70%'

# Clipboard mode
set -g @1password-copy-to-clipboard 'on'
set -g @1password-auto-clear-seconds '30'
set -g @1password-otp-auto-clear-seconds '10'

# Filtering
set -g @1password-categories 'Login'
set -g @1password-vault 'Private'

# Caching
set -g @1password-use-cache 'on'
set -g @1password-cache-age '300'
```

### OTP-Only Configuration

```bash
# In ~/.tmux.conf
set -g @plugin 'N0nki/tmux-op-secure'

# Disable password feature, only use OTP
set -g @1password-password-enable 'off'
set -g @1password-otp-enable 'on'
set -g @1password-otp-key 'P'
```

### Custom Popup Size

```bash
# In ~/.tmux.conf
set -g @plugin 'N0nki/tmux-op-secure'

# Extra large popup for better visibility
set -g @1password-popup-width '95%'
set -g @1password-popup-height '80%'
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
