# Utility Scripts

Small personal utility scripts for media processing, macOS maintenance, Linux server administration, storage reporting, and migration jobs.

These scripts are intentionally environment-specific. Review each script before running it, especially the server and migration helpers, because several commands use hard-coded paths, hosts, ports, email addresses, SLURM options, or remove files after transfer.

## Files

| File | Purpose |
| --- | --- |
| `whisper.sh` | Generates `.srt` subtitles from `mp4`, `m4a`, `aac`, or `mp3` files using `ffmpeg` and `whisper-cli`. |
| `pdf2jpg.sh` | Converts PDF pages to high-resolution JPEG images with `pdftoppm`. |
| `disable_spotlight.sh` | Adds `.metadata_never_index` to target folders and runs `dot_clean`; intended for macOS volumes. |
| `yt-dlp.conf` | Default `yt-dlp` options for downloading, metadata embedding, subtitles, thumbnails, and MP4 remuxing. |
| `authfail_notify.sh` | PAM helper that emails a notification for failed login attempts. |
| `check_system.sh` | Checks CPU, memory, and temperature thresholds, then emails warnings or errors. |
| `Backup.sh` | Archives account-related system files and emails the backup archive. |
| `make_user.sh` | Interactive Linux user creation helper for the local server environment. |
| `update_key.sh` | Migrates legacy `apt-key` entries into `/etc/apt/trusted.gpg.d`. |
| `reporting.sh` | Collects `sysstat` data from remote hosts, renders reports, and emails generated images. |
| `report_storage.sh` | Creates and emails a storage usage report for the current directory. |
| `migration_arrange.sh` | Prepares a directory for migration by deleting empty files, writing checksum files, and saving a tree listing. |
| `migration_store.sh` | Prepares checksums, stores a tree listing, transfers the directory with `rsync`, and removes the local copy after success. |
| `migration_check.sh` | Verifies a migrated directory against `tree.txt` and `md5.txt`. |
| `nologin.txt` | Login-disabled message for server account administration. |

## Usage

Run scripts directly from this directory or by path:

```sh
utility/pdf2jpg.sh document.pdf
lang=en utility/whisper.sh audio.mp3 video.mp4
utility/disable_spotlight.sh /Volumes/ExternalDrive
```

Use `yt-dlp.conf` with `yt-dlp`:

```sh
yt-dlp --config-location utility/yt-dlp.conf URL
```

Submit SLURM-oriented migration or reporting scripts with `sbatch` only on systems where the hard-coded paths and mail settings are valid:

```sh
sbatch utility/migration_arrange.sh
sbatch utility/migration_check.sh
```

## Dependencies

Dependencies vary by script:

* Media helpers: `ffmpeg`, `whisper-cli`, `pdftoppm`, `yt-dlp`
* macOS helper: `dot_clean`
* Linux/server helpers: `mail`, `sar`, `sadf`, `sysstat`, `bc`, `gpg`, `apt-key`, `adduser`, `gpasswd`
* Migration/reporting helpers: `rsync`, `ssh`, `tree`, `md5sum`, `convert`, `scp`, SLURM `sbatch`

## Notes

Most scripts use `set -euo pipefail`, so they stop when a command fails or an expected variable is missing. Some scripts require environment variables, such as `PORT` for `reporting.sh` and `lang` for overriding the default Whisper language in `whisper.sh`.

The migration scripts create checksum and tree files in the working directory. `migration_store.sh` removes the local directory after a successful transfer, so run it only after confirming the destination and command behavior.
