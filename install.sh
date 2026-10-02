#!/usr/bin/env bash
# Links these dotfiles into place. Safe to run again: anything already there
# is moved to a .backup-<date> copy first.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
stamp=$(date +%Y%m%d-%H%M%S)

ask() { read -rp "$1 [y/N] " a; [[ $a == [yY]* ]]; }

link() {  # source target
    if [[ -L $2 && $(readlink "$2") == "$1" ]]; then return; fi
    if [[ -e $2 || -L $2 ]]; then
        mv "$2" "$2.backup-$stamp"
        echo "  backed up $2"
    fi
    ln -s "$1" "$2"
    echo "  linked $2"
}

if ask "Install packages with pacman (needs sudo)?"; then
    sudo pacman -S --needed $(grep -v '^#' "$here/packages.txt")
fi

echo "Linking configs..."
mkdir -p ~/.config
for dir in "$here"/config/*/; do
    dir=${dir%/}
    link "$dir" ~/.config/"$(basename "$dir")"
done
for file in "$here"/home/.[!.]*; do
    link "$file" ~/"$(basename "$file")"
done

cp "$here/assets/fox-avatar.png" ~/.face
mkdir -p ~/Pictures
cp -n "$here/assets/fox-avatar.png" ~/Pictures/fox-avatar.png

if [[ ! -f ~/Pictures/wallpaper.jpg ]]; then
    echo
    echo "No wallpaper yet: save one as ~/Pictures/wallpaper.jpg"
fi

if ask "Set up the login screen and fox avatar (needs sudo)?"; then
    sudo "$here/system/setup-login-screen.sh"
fi

if pgrep -x i3 >/dev/null; then
    i3-msg -q restart && echo "Restarted i3."
fi
echo "Done."
