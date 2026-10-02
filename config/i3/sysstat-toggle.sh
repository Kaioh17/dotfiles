#!/usr/bin/env bash
# Super+i: open the status panel, or close it if it's already open.
if pgrep -f '^kitty --class sysstat' >/dev/null; then
    pkill -f '^kitty --class sysstat'
    exit
fi

kitty --class sysstat -o font_size=10 -o background=#282A2E -o foreground=#C5C8C6 \
    -o window_padding_width=10 -o cursor_shape=beam \
    ~/.config/i3/sysstat.sh &

# Wait for the window, then pin it to the top-right of the current workspace
# (the workspace area already excludes polybar and the outer gaps).
for _ in $(seq 30); do
    sleep 0.1
    i3-msg -t get_tree | grep -q '"class":"sysstat"' && break
done
read -r x y < <(i3-msg -t get_workspaces | python3 -c '
import json, sys
r = next(w["rect"] for w in json.load(sys.stdin) if w["focused"])
print(r["x"] + r["width"] - 400, r["y"])')
i3-msg -q "[class=\"sysstat\"] move position $x $y"
