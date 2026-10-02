#!/usr/bin/env bash
# System status panel. Runs inside the kitty window opened by Super+i.
# Colours match ~/.config/polybar/config.ini [colors]. q or Esc closes it.

rgb() { printf '\e[38;2;%d;%d;%dm' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }
FG=$(rgb '#C5C8C6')
DIM=$(rgb '#707880')
TRACK=$(rgb '#373B41')
ACCENT=$(rgb '#F0C674')
OK=$(rgb '#8ABEB7')
ALERT=$(rgb '#A54242')
B=$'\e[1m'; N=$'\e[0m'

# left text, right text, left colour, right colour: one row spread across W
spread() { printf '  %s%s%s%*s%s%s%s\e[K\n' "$3" "$1" "$N" $((W-${#1}-${#2})) "" "$4" "$2" "$N"; }

human() { numfmt --to=iec --suffix=B --format='%.1f' "$1"; }

dur() {  # seconds -> "2d 3h 14m"
    local s=${1%.*} d h m
    d=$((s/86400)); h=$((s%86400/3600)); m=$((s%3600/60))
    if ((d)); then printf '%dd %dh %dm' $d $h $m
    elif ((h)); then printf '%dh %dm' $h $m
    else printf '%dm' $m; fi
}

LINE=━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

level() {  # percent [invert] -> colour
    local p=$1
    if [[ $2 == invert ]]; then
        ((p<=15)) && { echo "$ALERT"; return; }; ((p<=30)) && { echo "$ACCENT"; return; }; echo "$OK"
    else
        ((p>=90)) && { echo "$ALERT"; return; }; ((p>=70)) && { echo "$ACCENT"; return; }; echo "$OK"
    fi
}

# title, percent, detail, [invert]
meter() {
    local p=$2; ((p>100)) && p=100
    local c fill pct=" $p%"
    c=$(level "$p" "$4")
    fill=$((p*W/100))
    spread "$1" "$pct" "$FG$B" "$c$B"
    printf '  %s%s%s%s%s\e[K\n' "$c" "${LINE:0:fill}" "$TRACK" "${LINE:0:W-fill}" "$N"
    printf '  %s%s%s\e[K\n\n' "$DIM" "$3" "$N"
}

# label, value
kv() { spread "$1" "$2" "$DIM" "$FG"; }

read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
sleep 0.5   # give the first CPU reading a real interval

draw() {
    W=$(( $(tput cols) - 4 ))

    # CPU usage since last frame
    read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat
    local busy=$(( (u2+n2+s2+q2+sq2+st2) - (u1+n1+s1+q1+sq1+st1) ))
    local idle=$(( (i2+w2) - (i1+w1) ))
    local cpu=0; (( busy+idle > 0 )) && cpu=$(( 100*busy/(busy+idle) ))
    u1=$u2 n1=$n2 s1=$s2 i1=$i2 w1=$w2 q1=$q2 sq1=$sq2 st1=$st2

    local load mhz temp
    load=$(cut -d' ' -f1 /proc/loadavg)
    mhz=$(awk -F: '/cpu MHz/{s+=$2;n++} END{if(n) printf "%.1f", s/n/1000}' /proc/cpuinfo)
    temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1)
    [[ -n $temp ]] && temp="$((temp/1000))°C" || temp="–"

    # Memory
    local mt ma st sf
    read -r mt ma st sf < <(awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} /^SwapTotal/{st=$2} /^SwapFree/{sf=$2}
        END{print t*1024, a*1024, st*1024, sf*1024}' /proc/meminfo)
    local mp=$(( (mt-ma)*100/mt ))

    # Storage
    local dsize dused
    read -r dsize dused <<<"$(df -B1 --output=size,used / | tail -1)"

    # Time: awake = monotonic (excludes sleep), boottime includes sleep
    local awake since
    read -r awake since < <(python3 -c 'import time;print(time.clock_gettime(time.CLOCK_MONOTONIC),time.clock_gettime(time.CLOCK_BOOTTIME))')

    # Battery
    local bat=/sys/class/power_supply/BAT0 bp="" bs detail
    if [[ -d $bat ]]; then
        bp=$(<"$bat/capacity"); bs=$(<"$bat/status")
        detail=${bs,,}
        local en pn
        en=$(cat "$bat/energy_now" 2>/dev/null || cat "$bat/charge_now" 2>/dev/null)
        pn=$(cat "$bat/power_now" 2>/dev/null || cat "$bat/current_now" 2>/dev/null)
        [[ $bs == Discharging && -n $pn && $pn -gt 0 ]] && detail="$(dur $(( en*3600/pn ))) left"
    fi

    printf '\e[H\n'
    local host; host="$USER@$(</etc/hostname)"
    spread "$host" "$(date '+%H:%M')" "$ACCENT$B" "$FG$B"
    printf '  %s%s\e[K\n\n' "$DIM" "$(date '+%A, %d %B')$N"

    meter "CPU"     "$cpu" "${mhz} GHz  ·  ${temp}  ·  load ${load}"
    meter "Memory"  "$mp"  "$(human $((mt-ma))) / $(human $mt)  ·  swap $(human $((st-sf)))"
    meter "Storage" "$((dused*100/dsize))" "$(human $dused) / $(human $dsize)  ·  $(human $((dsize-dused))) free"
    [[ -n $bp ]] && meter "Battery" "$bp" "$detail" invert

    kv "Awake"  "$(dur "$awake")"
    kv "Slept"  "$(dur $(( ${since%.*} - ${awake%.*} )))"
    kv "Booted" "$(date -d "$(uptime -s)" '+%a %d %b, %H:%M')"
    printf '\e[J'
}

printf '\e[?25l\e[2J'
trap 'printf "\e[?25h\e[0m"' EXIT
trap 'printf "\e[2J"' WINCH
while true; do
    draw
    read -rsn1 -t 2 key && [[ $key == q || $key == $'\e' ]] && break
done
