#!/usr/bin/env bash
# 50 — developer layer: runtimes (mise), Docker, git identity, Claude Code CLI.

log_step "Developer tools"

# --- runtimes via mise ------------------------------------------------------------
# mise manages per-project versions (.tool-versions / mise.toml). Global defaults:
if has mise; then
  run mise use --global node@lts
  run mise use --global python@3.13
  run mise use --global pnpm@latest
  run mise use --global uv@latest
fi

# --- Docker ----------------------------------------------------------------------------
# Rootful Docker + 'docker' group (simple, works with compose/devcontainers).
# Security note: the docker group is root-equivalent. See docs/DECISIONS.md (ADR-011).
enable_unit docker.socket
if ! id -nG "$DEVY_USER" | grep -qw docker; then
  run_root usermod -aG docker "$DEVY_USER"
  log_warn "added $DEVY_USER to 'docker' group: log out and back in for it to apply"
fi
# Keep Docker's own logs from filling the disk (default json-file driver has no limit).
write_root_file /etc/docker/daemon.json <<'JSON'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
JSON

# --- git identity (asked once) ------------------------------------------------------------
local_git="$DEVY_CONFIG_HOME/git/config.local"
if [[ ! -f $local_git && $DEVY_YES != 1 && $DEVY_DRY_RUN != 1 ]]; then
  read -r -p "    git user.name: " gname
  read -r -p "    git user.email: " gmail
  mkdir -p "$(dirname "$local_git")"
  printf '[user]\n\tname = %s\n\temail = %s\n' "$gname" "$gmail" >"$local_git"
  log_ok "wrote $local_git"
fi

# --- VS Code defaults (only if you have no settings yet) ----------------------------------
# argv.json: keep secrets (GitHub/Settings Sync tokens) in gnome-keyring.
if [[ ! -f $HOME/.vscode/argv.json && $DEVY_DRY_RUN != 1 ]]; then
  mkdir -p "$HOME/.vscode"
  printf '{\n  "password-store": "gnome-libsecret"\n}\n' >"$HOME/.vscode/argv.json"
  log_ok "wrote ~/.vscode/argv.json"
fi
code_settings="$DEVY_CONFIG_HOME/Code/User/settings.json"
if [[ ! -f $code_settings && $DEVY_DRY_RUN != 1 ]]; then
  mkdir -p "$(dirname "$code_settings")"
  cat >"$code_settings" <<'JSON'
{
  "update.mode": "none",
  "window.titleBarStyle": "custom",
  "editor.fontFamily": "'JetBrainsMono Nerd Font', monospace",
  "editor.fontSize": 14,
  "editor.fontLigatures": true,
  "editor.formatOnSave": true,
  "files.watcherExclude": { "**/node_modules/**": true, "**/.next/**": true, "**/dist/**": true },
  "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font'"
}
JSON
  log_ok "wrote $code_settings (VS Code updates come through pacman/paru)"
fi

# --- Claude Code CLI ------------------------------------------------------------------------------
# Installed with npm into mise's Node, so no sudo and no system-wide npm packages.
if ! has claude && has mise; then
  run mise exec node@lts -- npm install -g @anthropic-ai/claude-code
fi

log_ok "developer tools ready"
