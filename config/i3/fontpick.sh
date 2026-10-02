#!/usr/bin/env bash
# Super+Shift+f: pick a font from a live preview, then choose where to use it.
# Every row in the list is drawn in its own font.

KITTY=~/.config/kitty/kitty.conf
POLYBAR=~/.config/polybar/config.ini
ROFI=~/.config/rofi/polybar.rasi
DUNST=~/.config/dunst/dunstrc
I3=~/.config/i3/config

SAMPLE='The quick brown fox jumps  0123456789  {}[]()=&gt; != -&gt;'

mapfile -t fonts < <(fc-list : family | cut -d, -f1 | sort -u)
mapfile -t mono  < <(fc-list :spacing=mono family | cut -d, -f1 | sort -u)
is_mono() { printf '%s\n' "${mono[@]}" | grep -qxF "$1"; }

rows=()
for f in "${fonts[@]}"; do
    tag=""; is_mono "$f" && tag='  <span foreground="#8ABEB7" size="small">mono</span>'
    rows+=("<span font_family=\"$f\" size=\"large\">$f</span>$tag
<span font_family=\"$f\" foreground=\"#707880\">$SAMPLE</span>")
done

i=$(printf '%s\0' "${rows[@]}" | rofi -dmenu -sep '\0' -eh 2 -markup-rows -i -format i \
    -p "font" -no-custom -theme-str 'window { width: 55%; } listview { lines: 6; }')
[ -z "$i" ] && exit 0
font=${fonts[$i]}

targets="Everything
Terminal  (kitty + status panel)
Bar  (polybar)
Launcher  (rofi)
Notifications  (dunst)
Window titles  (i3)"
target=$(printf '%s\n' "$targets" | rofi -dmenu -i -no-custom -p "use $font for" \
    -theme-str "* { font: \"$font 11\"; }")
[ -z "$target" ] && exit 0

skipped=""
set_kitty() {
    if ! is_mono "$font"; then skipped=" (terminal skipped: needs a mono font)"; return; fi
    sed -i -E "s|^font_family\s.*|font_family      $font|" "$KITTY"
    pkill -USR1 -x kitty   # kitty reloads its config on SIGUSR1
}
set_polybar() {
    sed -i -E "s|^font-0 = [^;]*;|font-0 = $font;|" "$POLYBAR"
    ~/.config/polybar/launch.sh >/dev/null 2>&1
}
set_rofi() {
    sed -i -E "s|(font:\s*\")[^\"]*( [0-9.]+\";)|\1$font\2|" "$ROFI"
}
set_dunst() {
    sed -i -E "s|^(\s*font = ).* ([0-9.]+)$|\1$font \2|" "$DUNST"
    pkill -x dunst   # D-Bus starts it again with the new font on the next notification
}
set_i3() {
    sed -i -E "s|^font pango:.* ([0-9.]+)$|font pango:$font \1|" "$I3"
    i3-msg -q reload
}

case "$target" in
    Everything*)    set_kitty; set_polybar; set_rofi; set_dunst; set_i3 ;;
    Terminal*)      set_kitty ;;
    Bar*)           set_polybar ;;
    Launcher*)      set_rofi ;;
    Notifications*) set_dunst ;;
    Window*)        set_i3 ;;
esac

sleep 0.5
gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify "fontpick" 0 "" "Font changed" \
    "$font → ${target%%  *}$skipped" "[]" "{}" 4000 >/dev/null
