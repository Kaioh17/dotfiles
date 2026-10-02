#!/usr/bin/env bash
# Show i3 keybindings in rofi. Picking one runs it.
config="$HOME/.config/i3/config"

list=$(awk '
    # collect "set $var value" so bindings show real values
    /^[[:space:]]*set[[:space:]]+\$/ {
        val = $0; sub(/^[[:space:]]*set[[:space:]]+\$[^[:space:]]+[[:space:]]+/, "", val)
        gsub(/"/, "", val); vars[$2] = val; next
    }
    /^[[:space:]]*mode[[:space:]]+"/ { m = $0; gsub(/.*mode[[:space:]]+"|".*/, "", m); mode = m; next }
    mode != "" && /^[[:space:]]*}/ { mode = ""; next }
    /^[[:space:]]*bindsym[[:space:]]/ {
        line = $0; sub(/^[[:space:]]*bindsym[[:space:]]+/, "", line)
        while (line ~ /^--/) sub(/^--[^[:space:]]+[[:space:]]+/, "", line)
        key = line; sub(/[[:space:]].*/, "", key)
        cmd = line; sub(/^[^[:space:]]+[[:space:]]+/, "", cmd)
        for (v in vars) { gsub("\\" v, vars[v], key); gsub("\\" v, vars[v], cmd) }
        sub(/exec[[:space:]]+(--no-startup-id[[:space:]]+)?/, "exec ", cmd)
        gsub(/Mod4/, "Super", key); gsub(/Mod1/, "Alt", key)
        tag = (mode != "") ? "[" mode "] " : ""
        printf "%-26s %s%s\n", key, tag, cmd
    }
' "$config")

choice=$(printf '%s\n' "$list" | rofi -dmenu -i -p "keys" -no-custom \
    -theme-str 'window { width: 60%; } listview { lines: 15; }')
[ -z "$choice" ] && exit 0

# Bindings inside a mode only work in that mode, so just show them
case "$choice" in *"] "*) exit 0 ;; esac

cmd=$(printf '%s' "$choice" | sed -E 's/^[^[:space:]]+[[:space:]]+//')
i3-msg -q -- "$cmd"
