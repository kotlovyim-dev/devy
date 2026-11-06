#!/usr/bin/env python3
"""Run Devy's Hyprland Lua config against a mock `hl` API (no Hyprland needed).

Checks:
  * every file parses and runs without Lua runtime errors
  * every hl.config() key exists in the Hyprland 0.57 option list
    (tests/hypr-options-0.57.json, extracted from the official wiki)
  * hl.bind() gets a key string and a dispatcher; no duplicate key combos
  * every hl.dsp.* function used is a known dispatcher

Usage: python3 -I tests/lua-check.py [config_dir] [extra.lua ...]
Requires: pip install lupa
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    import lupa
except ImportError:  # pragma: no cover
    sys.exit("lua-check: needs `pip install lupa`")

ROOT = Path(__file__).resolve().parent.parent
OPTIONS = json.loads((ROOT / "tests" / "hypr-options-0.57.json").read_text())

# Dispatchers documented on wiki configuring/core/dispatchers.md (Hyprland 0.57).
DSP = {
    "": {"exec_cmd", "exec_raw", "exit", "focus", "force_idle", "force_renderer_reload", "global",
         "layout", "no_op", "pass", "release_input_capture", "reload_config", "send_key_state",
         "send_shortcut", "submap", "dpms"},
    "window": {"alter_zorder", "center", "clear_tags", "close", "cycle_next", "deny_from_group",
               "drag", "float", "fullscreen_state", "fullscreen", "kill", "move", "pin", "pseudo",
               "resize", "set_prop", "signal", "swap", "tag", "toggle_swallow"},
    "workspace": {"change_id", "move", "rename", "swap_monitors", "toggle_special"},
    "group": {"active", "lock", "move_window", "next", "prev", "toggle"},
    "cursor": {"move", "move_to_corner"},
}
# Tables inside hl.config that are values, not option categories.
VALUE_TABLES = {"col.active_border", "col.inactive_border"}

errors: list[str] = []
binds: dict[str, str] = {}


def flatten(table, prefix=""):
    """Yield (category, key) pairs from a nested Lua table passed to hl.config."""
    for k, v in table.items():
        k = str(k)
        path = f"{prefix}.{k}" if prefix else k
        is_table = lupa.lua_type(v) == "table"
        if is_table and path not in VALUE_TABLES and not path.endswith("col.active_border") \
                and not path.endswith("col.inactive_border") and not _is_gradient(v):
            yield from flatten(v, path)
        else:
            cat, _, key = path.rpartition(".")
            yield cat, key


def _is_gradient(v) -> bool:
    keys = {str(k) for k in v.keys()}
    return "colors" in keys


def make_runtime(config_dir: Path):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()

    def check_config(tbl):
        for cat, key in flatten(tbl):
            known = OPTIONS.get(cat)
            if known is None:
                errors.append(f"hl.config: unknown category '{cat}' (key '{key}')")
            elif key not in known:
                errors.append(f"hl.config: unknown option '{cat}.{key}'")

    def bind(keys, dispatcher=None, flags=None):
        if not isinstance(keys, str) or dispatcher is None:
            errors.append(f"hl.bind: bad arguments ({keys!r})")
            return
        norm = " + ".join(sorted(p.strip().lower() for p in keys.split("+")))
        if norm in binds:
            errors.append(f"hl.bind: duplicate binding '{keys}'")
        binds[norm] = keys

    lua.execute("""
      function __devy_make_hl(check_config, bind)
        local handle = { set_enabled = function() end }
        local function rec() return handle end
        local hl = {
          config = function(t) check_config(t) end,
          bind = function(k, d, f) bind(k, d, f); return handle end,
          env = function(k, v) assert(type(k) == "string" and type(v) == "string", "hl.env needs strings") end,
          monitor = rec, curve = rec, animation = rec, gesture = rec, device = rec,
          window_rule = rec, layer_rule = rec, workspace_rule = rec, permission = rec,
          exec_cmd = rec, dispatch = rec, timer = rec,
          on = function(ev, fn) assert(type(fn) == "function"); fn() end,
        }
        return hl
      end
    """)
    hl = g.__devy_make_hl(check_config, bind)

    # hl.dsp.* : built in Lua; unknown dispatcher names are reported back to Python.
    def report(msg):
        errors.append(str(msg))
    known = lua.table()
    for ns, names in DSP.items():
        known[ns] = lua.table_from({n: True for n in names})
    lua.execute("""
      function __devy_make_dsp(known, report)
        local function ns_table(ns)
          return setmetatable({}, { __index = function(_, name)
            if not known[ns][name] then
              report("unknown dispatcher hl.dsp." .. (ns ~= "" and (ns .. ".") or "") .. name)
            end
            return function(...) return { __dispatcher = name } end
          end })
        end
        local dsp = { window = ns_table("window"), workspace = ns_table("workspace"),
                      group = ns_table("group"), cursor = ns_table("cursor") }
        local root = ns_table("")
        return setmetatable(dsp, { __index = function(_, name) return root[name] end })
      end
    """)
    hl.dsp = g.__devy_make_dsp(known, report)
    g.hl = hl

    # Hyprland's require(): relative to the config dir, or an absolute *.lua path.
    def require(name):
        p = Path(name) if name.startswith("/") else config_dir / (name + ".lua")
        if not p.is_file():
            errors.append(f"require: file not found: {p}")
            return None
        try:
            lua.execute(p.read_text())
        except lupa.LuaError as e:
            errors.append(f"{p.relative_to(ROOT) if ROOT in p.parents else p}: {e}")
        return None
    g.require = require
    return lua


def main() -> int:
    config_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "config" / "hypr"
    extras = [Path(a) for a in sys.argv[2:]]
    lua = make_runtime(config_dir)
    entry = config_dir / "hyprland.lua"
    try:
        lua.execute(entry.read_text())
    except lupa.LuaError as e:
        errors.append(f"{entry}: {e}")
    for f in extras:
        try:
            lua.execute(f.read_text())
        except lupa.LuaError as e:
            errors.append(f"{f}: {e}")
    if errors:
        print("lua-check: FAILED")
        for e in errors:
            print("  -", e)
        return 1
    print(f"lua-check: ok ({len(binds)} binds, {1 + len(extras)} entry files)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
