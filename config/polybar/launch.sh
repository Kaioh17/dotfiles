#!/usr/bin/env bash
# Kill running bars and wait for them to exit
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.5; done

polybar main 2>&1 | tee -a /tmp/polybar.log & disown
