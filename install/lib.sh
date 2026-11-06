#!/usr/bin/env bash
# Shared helpers for the Devy installer.
# Sourced by install.sh and every install/NN-*.sh step. Do not execute directly.
# shellcheck disable=SC2034  # variables here are used by the sourcing scripts

# ---- paths ---------------------------------------------------------------
DEVY_ROOT="${DEVY_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
DEVY_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/devy"
DEVY_LOG="$DEVY_STATE_DIR/install.log"
DEVY_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DEVY_USER="$(id -un)"

# ---- flags (set by install.sh) ----------------------------------------------
DEVY_DRY_RUN="${DEVY_DRY_RUN:-0}"
DEVY_YES="${DEVY_YES:-0}"
DEVY_PROFILE="${DEVY_PROFILE:-laptop}"
DEVY_GAMING="${DEVY_GAMING:-1}"

mkdir -p "$DEVY_STATE_DIR"

# ---- logging -----------------------------------------------------------------
if [[ -t 1 ]]; then
  _c_reset=$'\e[0m' _c_dim=$'\e[2m' _c_blue=$'\e[34m' _c_yellow=$'\e[33m' _c_red=$'\e[31m' _c_green=$'\e[32m'
else
  _c_reset='' _c_dim='' _c_blue='' _c_yellow='' _c_red='' _c_green=''
fi

_log_file() { printf '%s [%s] %s\n' "$(date '+%F %T')" "$1" "$2" >>"$DEVY_LOG"; }
log_step() {
  printf '%s==>%s %s\n' "$_c_blue" "$_c_reset" "$*"
  _log_file STEP "$*"
}
log_info() {
  printf '    %s\n' "$*"
  _log_file INFO "$*"
}
log_ok() {
  printf '    %s✓%s %s\n' "$_c_green" "$_c_reset" "$*"
  _log_file OK "$*"
}
log_warn() {
  printf '    %s!%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2
  _log_file WARN "$*"
}
die() {
  printf '%sxx%s %s\n' "$_c_red" "$_c_reset" "$*" >&2
  _log_file ERROR "$*"
  exit 1
}

# ---- command runners -----------------------------------------------------------
# run CMD...      : run a command, or only print it in dry-run mode.
# run_root CMD... : same, through sudo.
run() {
  if [[ $DEVY_DRY_RUN == 1 ]]; then
    printf '    %s[dry-run]%s %s\n' "$_c_dim" "$_c_reset" "$*"
    _log_file DRY "$*"
    return 0
  fi
  _log_file RUN "$*"
  "$@"
}

run_root() {
  if [[ $EUID -eq 0 ]]; then run "$@"; else run sudo "$@"; fi
}

has() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  # confirm "question" -> 0 if yes. --yes answers yes automatically.
  [[ $DEVY_YES == 1 ]] && return 0
  local reply
  read -r -p "    $1 [y/N] " reply
  [[ $reply =~ ^[Yy]$ ]]
}

# ---- idempotent file helpers ---------------------------------------------------
# write_root_file DEST MODE < content : write a system file only if content changed.
write_root_file() {
  local dest="$1" mode="${2:-0644}" tmp
  tmp="$(mktemp)"
  cat >"$tmp"
  if [[ -f $dest ]] && cmp -s "$tmp" "$dest"; then
    log_info "unchanged: $dest"
    rm -f "$tmp"
    return 0
  fi
  run_root install -D -m "$mode" "$tmp" "$dest"
  rm -f "$tmp"
  log_ok "wrote $dest"
}

# link_config SRC DEST : symlink a repo file/dir into $HOME. Existing real files are
# backed up once to DEST.devy-bak; an existing correct link is a no-op.
link_config() {
  local src="$1" dest="$2"
  if [[ -L $dest && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    return 0
  fi
  if [[ -e $dest || -L $dest ]]; then
    run mv -f "$dest" "$dest.devy-bak"
    log_warn "backed up existing $dest -> $dest.devy-bak"
  fi
  run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  log_ok "linked $dest"
}

# read_pkg_list FILE... : print package names, ignoring comments and blank lines.
read_pkg_list() {
  local f
  for f in "$@"; do
    [[ -f $f ]] || continue
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$f"
  done
}

# enable_unit [--user] UNIT... : enable units only if not enabled yet.
enable_unit() {
  local scope=()
  if [[ ${1:-} == --user ]]; then
    scope=(--user)
    shift
  fi
  local u
  for u in "$@"; do
    if systemctl "${scope[@]}" is-enabled --quiet "$u" 2>/dev/null; then
      log_info "already enabled: $u"
    elif [[ ${#scope[@]} -gt 0 ]]; then
      run systemctl --user enable "$u"
    else
      run_root systemctl enable "$u"
    fi
  done
}

# ---- run-once markers (for migrations / one-time steps) -----------------------
done_marker() { [[ -f "$DEVY_STATE_DIR/done/$1" ]]; }
set_marker() { [[ $DEVY_DRY_RUN == 1 ]] || {
  mkdir -p "$DEVY_STATE_DIR/done"
  touch "$DEVY_STATE_DIR/done/$1"
}; }
