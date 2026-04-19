# Standard Backup Source Ideas

This file lists neutral backup source ideas for Fedora and Ubuntu users. It is
intended as a starting point for a public `backupi.conf` and does not contain
personal mount paths, usernames or private machine-specific data.

Not every entry should be enabled for every user. Desktop, display, boot,
network and hardware-specific files should be treated carefully during restore.

## Recommended Categories

Use these categories in `backupi.conf`:

```text
safe
risky
```

Suggested restore mindset:

- `safe`: usually okay to restore, but still review when it touches `/etc`
- `risky`: restore only as an individual deliberate choice

Suggested snapshot policies:

- `snapshot`: good for small config files and package lists
- `current-only`: better for large changing app data, caches and databases

## Package Lists

### Fedora

Useful backup commands:

```bash
dnf repoquery --userinstalled
flatpak list --app --columns=application
```

Useful config entries:

```text
dnf-packages|dnf-userinstalled|safe|packages||package-lists/fedora-dnf-userinstalled.txt||Fedora DNF packages installed by the user|snapshot
flatpak-apps|flatpak-apps|safe|packages||package-lists/flatpaks.txt||Flatpak application IDs|snapshot
```

### Ubuntu

Useful backup commands:

```bash
apt-mark showmanual
snap list
flatpak list --app --columns=application
```

`backupi` does not currently have a built-in `apt-packages` kind, but package
lists can still be generated manually or added later as a new script feature.

Potential backup paths:

```text
package-lists/ubuntu-apt-manual.txt
package-lists/snaps.txt
package-lists/flatpaks.txt
```

## User Shell And CLI Config

Usually useful and small:

```text
~/.bashrc
~/.bash_profile
~/.profile
~/.zshrc
~/.gitconfig
~/.vimrc
~/.ssh/config
~/.gnupg/gpg-agent.conf
```

Restore notes:

- Shell profiles and Git config are usually safe.
- `~/.ssh/config` is often useful, but do not publish private hosts.
- Never back up or publish private SSH keys in a public repository.
- GnuPG key material should be handled separately and carefully.

Suggested policy: `snapshot`

## User Desktop Files

Useful for both Fedora and Ubuntu desktop systems:

```text
~/.local/share/applications
~/.local/share/icons
~/.local/share/wallpapers
~/.local/share/fonts
```

Restore notes:

- These are usually safe.
- Desktop launchers may contain old absolute paths.

Suggested policy: `snapshot`

## Application Config

Common user config directories:

```text
~/.config/Code
~/.config/Cursor
~/.config/obs-studio
~/.config/qBittorrent
~/.config/filezilla
~/.config/joplin-desktop
~/.config/kitty
~/.config/alacritty
~/.config/wezterm
~/.config/htop
~/.config/btop
```

Restore notes:

- App config is useful, but old versions can occasionally conflict with new app
  versions.
- Restore individual app folders when you actually need them.

Suggested policy: `snapshot`

## KDE Plasma

Useful but should be restored carefully:

```text
~/.config/kdeglobals
~/.config/dolphinrc
~/.config/konsolerc
~/.config/yakuakerc
~/.config/kglobalshortcutsrc
```

Riskier Plasma and display-related files:

```text
~/.config/kwinrc
~/.config/kwinoutputconfig.json
~/.config/plasma-org.kde.plasma.desktop-appletsrc
~/.config/plasmashellrc
~/.config/kscreenlockerrc
~/.config/kxkbrc
```

Restore notes:

- Monitor layout, panel state, Wayland, KWin and graphics settings can cause
  problems after a reinstall or GPU/display change.
- Restore these one by one.

Suggested policy: `snapshot`

Suggested category: `risky`

## GNOME

GNOME settings are often stored in dconf rather than simple files.

Useful backup command:

```bash
dconf dump / > gnome-dconf.ini
```

Useful restore command:

```bash
dconf load / < gnome-dconf.ini
```

Restore notes:

- A full dconf restore can overwrite many desktop defaults.
- Prefer restoring only after reviewing the file.

Suggested policy: `snapshot`

Suggested category: `risky`

## Fedora System Config

Useful:

```text
/etc/dnf
/etc/yum.repos.d
/etc/modprobe.d
/etc/sysctl.d
/etc/modules-load.d
/etc/default
```

Restore notes:

- Repository files may be outdated after a Fedora version upgrade.
- Kernel module and sysctl settings should match the new hardware/kernel.

Suggested policy: `snapshot`

Suggested category: `safe` or `risky`, depending on how conservative you want
the restore menu to be.

## Ubuntu System Config

Useful:

```text
/etc/apt/sources.list
/etc/apt/sources.list.d
/etc/apt/preferences.d
/etc/dpkg
/etc/modprobe.d
/etc/sysctl.d
/etc/modules-load.d
/etc/default
```

Restore notes:

- APT source files can be release-specific.
- PPAs may be stale after upgrading Ubuntu.
- Review repository files before copying them back.

Suggested policy: `snapshot`

## Network And Host Identity

Potentially useful, but risky:

```text
/etc/hosts
/etc/hostname
/etc/NetworkManager/system-connections
/etc/systemd/resolved.conf
```

Restore notes:

- Hostname and hosts files may intentionally change after reinstall.
- NetworkManager profiles can contain secrets and old interface names.
- Do not publish private Wi-Fi or VPN profiles.

Suggested policy: `snapshot`

Suggested category: `risky`

## Boot, Mount And Display Manager Config

Treat as risky:

```text
/etc/fstab
/etc/crypttab
/etc/default/grub
/etc/sddm.conf
/etc/sddm.conf.d
/etc/gdm
/etc/X11
```

Restore notes:

- `fstab` and `crypttab` can break boot if UUIDs or mount points changed.
- Display manager and X11 config can conflict with new GPU or monitor setup.
- Restore manually and only after review.

Suggested policy: `snapshot`

Suggested category: `risky`

## Large Or Noisy User Data

Usually better as `current-only` or handled by Pika Backup/Borg/Restic:

```text
~/.local/share/Steam
~/.local/share/lutris
~/.local/share/umu
~/.var/app
~/.local/share/Trash
~/.cache
```

Restore notes:

- These paths can become very large.
- They may contain caches, databases, logs or machine-specific state.
- Do not include them in snapshot history unless you explicitly want that.

Suggested policy: `current-only`

Suggested excludes for Steam and other large game data:

```bash
BACKUPI_ITEM_EXCLUDES=(
  "flatpak-user-data|com.valvesoftware.Steam/.local/share/Steam/steamapps/common/"
  "flatpak-user-data|com.valvesoftware.Steam/.local/share/Steam/steamapps/shadercache/"
  "flatpak-user-data|com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/"
  "steam|steamapps/common/"
  "steam|steamapps/shadercache/"
  "steam|steamapps/compatdata/"
)
```

To exclude only one specific game, use a narrower pattern, for example:

```text
flatpak-user-data|com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/
```

## Mail, Calendar And PIM Data

Often useful but risky:

```text
~/.local/share/akonadi
~/.local/share/local-mail
~/.local/share/contacts
~/.config/kmail2rc
~/.config/kontactrc
~/.config/korganizerrc
```

Restore notes:

- Databases may not like being copied while apps are running.
- App versions and account configuration can change.
- Restore only when needed.

Suggested policy:

- database/data folders: `current-only`
- small config files: `snapshot`

Suggested category: `risky`

## Usually Exclude

Avoid by default:

```text
~/.cache
~/.local/share/Trash
~/.local/state/*logs*
node_modules
build
dist
target
__pycache__
```

These are usually reproducible, temporary or too noisy for configuration
backup.
