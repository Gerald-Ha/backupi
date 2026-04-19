# backupi
<img src="https://github.com/user-attachments/assets/26c2aa65-1a07-45f2-8010-cef27f6b16f0" width="448" height="auto">

`backupi` is a small interactive backup and restore helper for Linux desktop
systems. It is meant for the things that classic personal-file backups often
miss: package lists, repository files, shell profiles, selected application
settings, desktop configuration and carefully chosen system configuration.

Developer: Gerald-H  
GitHub: https://github.com/Gerald-Ha  
Project: backupi

The main idea is simple:

- keep the latest backup directly readable in `current/`
- keep a small snapshot history for important settings
- avoid duplicating large data such as Steam or game launcher folders
- make restore decisions explicit, especially for risky desktop and system files

`backupi` is not a replacement for tools such as Pika Backup, Borg or Restic.
It is designed to complement them. Use your normal backup tool for documents,
projects, photos and other personal data. Use `backupi` for system and
configuration state that helps rebuild a Linux installation.

## Features

- Interactive terminal menu
- Configurable backup destination
- Configurable snapshot retention, default: `5`
- Current readable backup in `BACKUP_ROOT/current`
- Historical snapshots in `BACKUP_ROOT/snapshots/YYYYMMDD-HHMMSS`
- Incremental snapshots through `rsync --link-dest`
- Per-entry snapshot policy: `snapshot` or `current-only`
- Safe and risky restore categories
- Restore source selection: latest `current` or an older snapshot
- Automatic backup of the active `backupi.conf`
- System detection for OS, package managers and desktop config families
- Optional backup of entries available on the detected system
- Update checks through a compatible Update Center API
- Package list backup for DNF and Flatpak
- Install and uninstall scripts

## Backup Model

Backups are written to:

```text
BACKUP_ROOT/current
```

Historical restore points are written to:

```text
BACKUP_ROOT/snapshots/YYYYMMDD-HHMMSS
```

Snapshots use `rsync --link-dest`. Unchanged files are hardlinked from the
previous snapshot instead of copied again. This gives you multiple restore
points without storing identical small config files over and over.

Large or noisy entries can be marked as:

```text
current-only
```

Those entries are kept only in `current/` and are not copied into snapshot
history. This is useful for Steam, Lutris, UMU, local app databases, caches or
other large changing data.

On every backup run, `backupi` also stores its active configuration in:

```text
BACKUP_ROOT/current/backupi/backupi.conf
```

This internal config backup is included in snapshots. If the config did not
change, snapshots hardlink the previous copy instead of storing it again.

## Safety

`backupi` refuses to run when `BACKUP_ROOT` is empty, not absolute, or points to
obvious system directories such as `/`, `/etc`, `/usr`, `/var` or `/home`.

That means a public/example config can intentionally leave `BACKUP_ROOT` empty.
Users must set a real destination before backups can run. In the interactive
menu, `backupi` starts in a small setup screen until a valid backup destination
is configured.

Restore is also deliberately split into safer and riskier paths. Files such as
shell profiles, Git config and package lists are usually safe. KDE/Plasma,
display manager files, `fstab`, network and graphics-related config should be
restored only when you know you need them.

Before overwriting restore targets, `backupi` can save the existing target into:

```text
BACKUP_ROOT/pre-restore-snapshots/
```

## Requirements

- Bash
- `rsync`
- `curl` and `jq` for update checks
- `sudo` for backing up or restoring root-owned system files
- Fedora tools for Fedora package backup: `dnf`
- Flatpak for Flatpak app list backup: `flatpak`

The script is written with Fedora/KDE in mind, but the config format can be
adapted for Ubuntu and other distributions.

## Install

From the source folder:

```bash
chmod +x install.sh uninstall.sh backupi
./install.sh
```

The installer writes:

```text
/usr/local/bin/backupi
/etc/backupi/backupi.conf
/etc/backupi/update.conf.example
/usr/local/sbin/backupi-uninstall
```

After installation, run:

```bash
backupi
```

The installed command is independent from the source folder.

If `/etc/backupi/backupi.conf` already exists, the installer keeps it and writes
the new default config as:

```text
/etc/backupi/backupi.conf.example
```

Update checks use the built-in public `backupi` project key. The installer also
writes the optional override example:

```text
/etc/backupi/update.conf.example
```

Create `/etc/backupi/update.conf` only if you want to override update settings
such as channel, timeout or server URL.

## Uninstall

```bash
backupi-uninstall
```

Remove the program and the config:

```bash
backupi-uninstall --purge
```

You can also uninstall from the source folder:

```bash
./install.sh --uninstall
```

## First Run

Open the menu:

```bash
backupi
```

If the config has no backup destination yet, `backupi` opens the setup screen
first. Set a backup destination:

```text
backupi setup -> Set backup destination
```

Set how many snapshots are kept:

```text
Configuration -> Set snapshot retention
```

Default retention is `5`.

Run a backup:

```text
Run backup for all configured entries
```

Or run only entries that are available on the detected system:

```text
Run backup for detected entries only
```

## Useful Commands

Run a backup directly:

```bash
backupi --backup
```

Run a backup only for entries available on the current system:

```bash
backupi --backup-detected
```

Restore the saved backupi configuration from the selected backup root:

```bash
backupi --restore-backupi-config
```

Show detected system information:

```bash
backupi --system-info
```

List configured entries:

```bash
backupi --list
```

Edit the config:

```bash
backupi --edit-config
```

Set the backup destination:

```bash
backupi --set-backup-root "/path/to/backup"
```

Set snapshot retention:

```bash
backupi --set-snapshot-retention 5
```

Manually check for updates:

```bash
backupi --check-updates
```

Show the installed version:

```bash
backupi --version
```

Show project credits:

```bash
backupi --credits
```

Preview actions without copying:

```bash
backupi --dry-run --backup
```

Use another config file:

```bash
backupi --config ./backupi.conf --list
```

## System Detection

`backupi` can detect useful context without modifying the config:

- OS name and ID from `/etc/os-release`
- available package tools such as `dnf`, `apt`, `flatpak`, `snap`, `rpm`, `dpkg`
- current desktop session from `XDG_CURRENT_DESKTOP`,
  `XDG_SESSION_DESKTOP` or `DESKTOP_SESSION`
- existing desktop config families such as KDE Plasma, GNOME, XFCE, Cinnamon
  and MATE

The detection is intentionally advisory. `backupi` does not delete config
entries and does not permanently rewrite the config based on the current
session. This matters because a user can switch desktop environments or keep
old KDE/GNOME config around for later restore.

The `--backup-detected` mode backs up configured entries that are available on
the current machine:

- `dnf-packages` only when `dnf` exists
- `flatpak-apps` only when `flatpak` exists
- file and directory entries only when their source path exists

Missing entries are skipped instead of being treated as fatal.

## Update Checks

`backupi` can check an Update Center server for new releases:

```bash
backupi --check-updates
```

The interactive menu checks once at startup when update checks are enabled and
prints the current update status directly below the `backupi` title. Startup
checks are non-blocking in spirit: if the server is unavailable or the key is
missing, `backupi` continues normally. A message is shown when a new version is
available or the installed version is blocked.

The menu does not need a separate update-check entry because the status is
already refreshed on startup. Use `backupi --check-updates` when you want to
test the update server manually.

Update checks work out of the box with the built-in public project key.
Optional overrides are read from:

```text
/etc/backupi/update.conf
```

An override example is installed as:

```text
/etc/backupi/update.conf.example
```

Example override:

```bash
UPDATE_SERVER_URL="https://update.gerald-hasani.com"
UPDATE_PROJECT_ID="backupi"
UPDATE_CHANNEL="stable"
UPDATE_CHECK_ON_START="true"
UPDATE_CHECK_TIMEOUT="5"
```

The public update API key and the installed app version are built into
`backupi`, so the example override file does not need to change for normal
version bumps.

When an update is available, the server response can provide:

- latest version
- minimum supported version
- critical update flag
- update link
- release notes URL
- optional message

`backupi` prints the version warning in red on terminals with color support and
prints the update link and release notes link when provided by the server.

## Config Format

The config file is:

```text
/etc/backupi/backupi.conf
```

The active config is backed up automatically on every backup run. By default it
is written to:

```text
BACKUP_ROOT/current/backupi/backupi.conf
```

The relative backup path can be changed in the config:

```bash
BACKUPI_SELF_CONFIG_BACKUP_PATH="backupi/backupi.conf"
```

Each backup entry uses this format:

```text
kind|id|category|group|source|backup_path|restore_target|description|snapshot_policy
```

Fields:

- `kind`: `file`, `dir`, `dnf-packages` or `flatpak-apps`
- `id`: stable entry name
- `category`: `safe` or `risky`
- `group`: menu grouping, for example `user-safe`, `system-safe`, `gaming`
- `source`: live file or folder to back up
- `backup_path`: path inside `BACKUP_ROOT/current`
- `restore_target`: destination used during restore
- `description`: text shown in the menu
- `snapshot_policy`: `snapshot` or `current-only`

Example:

```text
file|bashrc|safe|user-safe|${HOME}/.bashrc|home-config/.bashrc|${HOME}/.bashrc|Bash shell configuration|snapshot
```

## Excludes

`backupi` supports rsync exclude patterns in the config.

Global excludes apply to every file or directory backup:

```bash
BACKUPI_EXCLUDES=(
  ".cache/"
  "Cache/"
  "logs/"
  "*.log"
  "node_modules/"
)
```

Per-entry excludes apply only to one configured item. The part before `|` is
the item id from `BACKUPI_ITEMS`; the part after `|` is the rsync exclude
pattern relative to that item's source path:

```bash
BACKUPI_ITEM_EXCLUDES=(
  "flatpak-user-data|com.valvesoftware.Steam/.local/share/Steam/steamapps/common/"
  "steam|steamapps/common/"
)
```

For example, if this source is enabled:

```text
${HOME}/.var/app
```

then this pattern excludes Steam games stored below the Flatpak Steam data
folder:

```text
com.valvesoftware.Steam/.local/share/Steam/steamapps/common/
```

To exclude only one game instead of the whole Steam `common` folder, use a more
specific pattern:

```text
com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/
```

When `BACKUP_RSYNC_DELETE_EXCLUDED=true`, excluded files that already exist in
`current/` are removed from the backup target on the next backup. This is useful
after adding excludes for large folders that were backed up before.

## Restore

Open:

```bash
backupi
```

Then choose:

```text
Restore
```

Restore options include:

- backupi configuration
- recommended safe user entries
- DNF packages and Flatpaks
- one selected safe entry
- one selected risky entry
- all safe entries, including safer `/etc` entries
- restore source selection between `current` and older snapshots

Risky entries are intentionally not restored blindly.

After a reinstall, a useful restore order is:

```text
1. Install backupi
2. Set the existing backup destination
3. Restore -> Restore backupi configuration
4. Reopen backupi or continue with the reloaded config
5. Restore packages, Flatpaks and selected user/app settings
```

When restoring `backupi.conf`, the currently selected backup destination is
kept in the restored config. This avoids losing the mounted backup path on a new
system.

## Public Configs

For a public GitHub repository, do not publish personal mount paths, usernames,
machine-specific hardware config or private application data.

A public default config can use:

```bash
BACKUP_ROOT="${BACKUP_ROOT:-}"
```

With an empty `BACKUP_ROOT`, `backupi` refuses to run backups until the user
sets a destination. The normal interactive backup and restore menu is shown
only after a valid destination is configured.

For neutral backup source ideas, see:

```text
STANDARD-BACKUP-SOURCES.md
```
