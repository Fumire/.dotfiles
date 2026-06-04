# Utility Scripts

Small personal utility scripts for media processing, macOS maintenance, Linux server administration, storage reporting, and migration jobs.

These scripts are intentionally environment-specific. Review each script before running it, especially the server and migration helpers, because several commands use hard-coded paths, hosts, SSH ports, email addresses, SLURM options, privileged system paths, or source-file removal after transfer.

## Files

| File | Purpose |
| --- | --- |
| `whisper.sh` | Generates `.srt` subtitles from `mp4`, `m4a`, `aac`, or `mp3` files using `ffmpeg` and `whisper-cli`. |
| `pdf2jpg.sh` | Converts PDF pages to 600 DPI JPEG images with `pdftoppm` and JPEG quality 100. |
| `disable_spotlight.sh` | Adds `.metadata_never_index` to target folders and runs `dot_clean`; intended for macOS volumes. |
| `yt-dlp.conf` | Default `yt-dlp` options for best-format downloads, retries, geo bypass, browser impersonation, metadata, chapters, subtitles, thumbnails, multistream handling, and MP4 remuxing. |
| `authfail_notify.sh` | PAM helper that emails a notification for failed login attempts. |
| `check_system.sh` | Checks CPU, memory, temperature, and optional NVIDIA GPU thresholds, then emails warnings or errors. |
| `Backup.sh` | Archives account-related system files and emails the backup archive. |
| `make_user.sh` | Interactive Linux user creation helper for the local server environment. |
| `update_key.sh` | Migrates legacy `apt-key` entries into `/etc/apt/trusted.gpg.d`. |
| `reporting.sh` | Collects `sysstat` data from remote hosts, renders reports, and emails generated images. |
| `report_storage.sh` | Creates and emails a storage usage report for the current directory. |
| `migration_arrange.sh` | Prepares a directory for migration by deleting empty files, writing checksum files, and saving a tree listing. |
| `migration_store.sh` | Prepares checksums, stores a tree listing, transfers the directory with `rsync --remove-source-files`, and removes transferred source files after success. |
| `migration_check.sh` | Verifies a migrated directory against `tree.txt` and `md5.txt`. |
| `nologin.txt` | Login-disabled message for server account administration. |

## Usage

Run scripts directly from this directory or by path:

```sh
utility/pdf2jpg.sh document.pdf
lang=en utility/whisper.sh audio.mp3 video.mp4
utility/disable_spotlight.sh /Volumes/ExternalDrive
```

`whisper.sh` skips files that already have a matching `.srt`. It uses Korean by default (`lang=ko`) and a hard-coded local Whisper model path:

```text
/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/ggml-large-v3.bin
```

Use `yt-dlp.conf` with `yt-dlp`:

```sh
yt-dlp --config-location utility/yt-dlp.conf URL
```

Submit SLURM-oriented migration or reporting scripts with `sbatch` only on systems where the hard-coded paths, remote hosts, SSH settings, and mail settings are valid:

```sh
sbatch utility/migration_arrange.sh
sbatch utility/migration_store.sh
sbatch utility/migration_check.sh
sbatch utility/report_storage.sh
```

Server administration scripts such as `Backup.sh`, `check_system.sh`, `make_user.sh`, `reporting.sh`, and `update_key.sh` should be run only on the matching Linux server environment. Several of them expect root privileges, working mail delivery, and paths under `/BiO`, `/etc`, `/var/log/sysstat`, or `/var/www/html`.

## Dependencies

Dependencies vary by script:

* Media helpers: `ffmpeg`, `whisper-cli`, `pdftoppm`, `yt-dlp`
* macOS helper: `dot_clean`
* Linux/server helpers: `mail`, `top`, `free`, `bc`, `nvidia-smi`, `tar`, `gpg`, `apt-key`, `adduser`, `gpasswd`
* Sysstat/reporting helpers: `sar`, `sadf`, `sysstat`, `convert`, `scp`, `ssh`
* Migration/storage helpers: `rsync`, `tree`, `md5sum`, `du`, SLURM `sbatch`

## Notes

Most shell scripts use `set -euo pipefail`, so they stop when a command fails or an expected variable is missing. Some scripts require environment variables, such as `PORT` for `reporting.sh` and `lang` for overriding the default Whisper language in `whisper.sh`.

The migration scripts create checksum and tree files in the working directory. `migration_arrange.sh` and `migration_store.sh` delete empty files before creating checksums. `migration_store.sh` uses `rsync --remove-source-files` to move transferred files to `root@kimura.kogic.kr:/BiO/Archive/` through SSH port `3030`, so run it only after confirming the destination and command behavior.

`check_system.sh` sends CPU, memory, temperature, and GPU alerts to `root@compbio.unist.ac.kr`. GPU checks run only when `nvidia-smi` is available; warning thresholds start above 85% GPU memory or utilization, and error thresholds start above 90%.
