# dotfiles

My i3 desktop for Arch Linux: polybar, rofi, dunst, picom and kitty, all in one dark theme, plus a status panel, a keybinding cheat sheet and a font picker.

## Set up a new laptop

**1. Make an SSH key and add it to GitHub** (skip if this laptop already has one)

```sh
ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub
```

Paste the output into GitHub → Settings → SSH and GPG keys → New SSH key. Check it works:

```sh
ssh -T git@github.com
```

**2. Clone and install**

```sh
git clone git@github.com:Kaioh17/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer asks two questions:

- **Install packages?** Say yes on a fresh laptop. It installs everything in `packages.txt`.
- **Set up the login screen?** Say yes to get the themed LightDM screen and fox avatar.

Anything already in `~/.config` is moved to a `.backup-<date>` copy, not deleted.

**3. Add a wallpaper**

The wallpaper isn't in this repo. Save the one you want as:

```
~/Pictures/wallpaper.jpg
```

Then press `Super+Shift+r` to restart i3. If you said yes to the login screen in step 2 before adding the wallpaper, run `sudo ./system/setup-login-screen.sh` again so the login screen gets it too.

**4. Log out and back in.** Pick **i3** on the login screen.

## Keys

`Super` is the Windows key.

| Keys | What it does |
|---|---|
| `Super+Enter` | Terminal |
| `Super+d` | App launcher |
| `Super+/` | **Search all keybindings** (if you forget one, start here) |
| `Super+i` | System status panel (CPU, RAM, storage, battery, uptime) |
| `Super+Shift+f` | Font picker with live preview |
| `Super+Shift+h` / `Super+Shift+v` | Next window opens beside / below |
| `Super+Shift+q` | Close window |
| `Super+1` … `Super+0` | Switch workspace |
| `Super+r` | Resize mode (arrows to resize, `Esc` to leave) |
| `Super+Shift+r` | Restart i3 |

## What's in here

```
config/     → linked to ~/.config/
  i3/         window manager + scripts (status panel, cheat sheet, font picker)
  polybar/    top bar
  rofi/       launcher (same colours as polybar)
  dunst/      notifications
  picom/      rounded corners and shadows
  kitty/      terminal
  gtk-3.0/    GTK apps
  i3status/, i3blocks/   old bar configs (unused, kept for reference)
home/       → linked to ~/ (.bashrc, .bash_profile, .xinitrc)
system/     login screen config and its setup script
assets/     fox avatar
packages.txt
install.sh
```

The configs are **linked**, not copied. Editing `~/.config/i3/config` edits the file in this repo, so to save a change:

```sh
cd ~/dotfiles
git add -A
git commit -m "describe the change"
git push
```

On the other laptop, `git pull` brings the change in.

## Colours

Everything uses polybar's palette. Change it in `config/polybar/config.ini`, then update the matching values in `config/rofi/polybar.rasi`, `config/dunst/dunstrc` and the top of `config/i3/sysstat.sh`.

| | |
|---|---|
| Background | `#282A2E` |
| Background alt | `#373B41` |
| Text | `#C5C8C6` |
| Accent | `#F0C674` |
| Teal | `#8ABEB7` |
| Alert | `#A54242` |
| Dim | `#707880` |

## Troubleshooting

- **No wallpaper:** check `~/Pictures/wallpaper.jpg` exists, then `Super+Shift+r`.
- **Bar missing:** run `~/.config/polybar/launch.sh` and read `/tmp/polybar.log`.
- **No notifications:** `notify-send test hello`. If that fails, install `libnotify`.
- **Second monitor:** polybar only draws on the main monitor. Add a `monitor =` line to `[bar/main]` in `config/polybar/config.ini` to choose which.
