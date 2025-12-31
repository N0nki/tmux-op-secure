# Repository Guidelines

## Project Structure & Module Organization

- `op-secure.tmux` is the plugin entrypoint; it wires tmux key bindings and launches scripts in a popup.
- `scripts/main.sh` handles password selection, fetching, and clipboard or send-keys behavior.
- `scripts/otp.sh` handles OTP selection and clipboard copy.
- `scripts/variables.sh` centralizes tmux option defaults and feature toggles.

## Build, Test, and Development Commands

- No build step; this is a tmux plugin driven by shell scripts.
- Manual smoke test in tmux:
  - `tmux source-file ~/.tmux.conf` to reload the plugin.
  - Trigger `prefix + u` (password) or `prefix + o` (OTP) to exercise flows.

## Coding Style & Naming Conventions

- Shell scripts use Bash with `set -e`; keep functions small and guard external commands.
- Indentation is 2 spaces in `scripts/*.sh`.
- Prefer lowercase, descriptive function names (e.g., `get_tmux_option`, `copy_to_clipboard`).
- Keep tmux option names scoped with the `@1password-` prefix.

## Testing Guidelines

- No automated test suite in this repo.
- Validate changes by running both password and OTP flows in tmux, including:
  - Missing dependency errors (e.g., uninstall `jq`) and recovery messaging.
  - Clipboard mode and auto-clear timing.

## Commit & Pull Request Guidelines

- No explicit commit convention is documented; use concise, imperative messages (e.g., "Add cache age validation").
- PRs should include:
  - A short description of behavior changes and affected files.
  - Any new tmux options or config changes in the README.
  - Screenshots or terminal snippets for UI changes in the tmux popup.

## Security & Configuration Tips

- Avoid persisting secrets; use the existing cache only for metadata.
- Keep clipboard auto-clear enabled for passwords and OTPs.
- When adding new options, wire defaults in `scripts/variables.sh` and document them in `README.md`.
