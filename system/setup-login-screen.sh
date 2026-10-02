#!/usr/bin/env bash
# Styles the LightDM login screen and sets the fox avatar.
# Run with sudo from the dotfiles folder:  sudo ./system/setup-login-screen.sh
set -euo pipefail

user=${SUDO_USER:?run this with sudo}
home=$(getent passwd "$user" | cut -d: -f6)
here=$(cd "$(dirname "$0")/.." && pwd)

# Login screen can't read inside your home folder, so copy the wallpaper out
if [[ -f $home/Pictures/wallpaper.jpg ]]; then
    install -Dm644 "$home/Pictures/wallpaper.jpg" /usr/share/backgrounds/wallpaper.jpg
else
    echo "No ~/Pictures/wallpaper.jpg yet - login screen will use a plain background."
fi

conf=/etc/lightdm/lightdm-gtk-greeter.conf
[[ -f $conf ]] && cp "$conf" "$conf.bak"
install -Dm644 "$here/system/lightdm-gtk-greeter.conf" "$conf"

# Fox avatar
install -Dm644 "$here/assets/fox-avatar.png" "/var/lib/AccountsService/icons/$user"
mkdir -p /var/lib/AccountsService/users
printf '[User]\nIcon=/var/lib/AccountsService/icons/%s\n' "$user" > "/var/lib/AccountsService/users/$user"

systemctl enable lightdm >/dev/null 2>&1 || true
echo "Login screen set up. It shows at your next login."
