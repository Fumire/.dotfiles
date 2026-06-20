# Utility Scripts

Small personal utility scripts for media processing, macOS maintenance, Linux server administration, storage reporting, and migration jobs.

These scripts are intentionally environment-specific. Review each script before running it, especially the server and migration helpers, because several commands use hard-coded paths, hosts, SSH ports, email addresses, SLURM options, privileged system paths, or source-file removal after transfer.

## Files

| File | Purpose |
| --- | --- |
| `authfail_notify.sh` | PAM helper that emails a notification for failed login attempts. |
| `Backup.sh` | Archives account-related system files and emails the backup archive. |
| `check_system.sh` | Checks CPU, memory, temperature, and optional NVIDIA GPU thresholds, then emails warnings or errors with the configured number of heaviest related processes. |
| `disable_spotlight.sh` | Adds `.metadata_never_index` to one or more target directories and runs `dot_clean`; intended for macOS volumes. |
| `make_user.sh` | Argument-driven Linux user creation helper with optional `--home` base, default initial password, and interactive `adduser` user-information prompts. |
| `migration_arrange.sh` | Prepares a directory for migration by deleting empty files, writing checksum files, and saving a tree listing. |
| `migration_check.sh` | Verifies a migrated directory against `tree.txt` and `md5.txt`. |
| `migration_store.sh` | Prepares checksums, stores a tree listing, transfers the directory with `rsync --remove-source-files`, and removes transferred source files after success. |
| `nologin.txt` | Login-disabled message for server account administration. |
| `pdf2jpg.sh` | Converts PDF pages to 600 DPI JPEG images with `pdftoppm` and JPEG quality 100. |
| `r-freeze.R` | Backs up the active R package environment into `renv.lock`, `requirements.txt`, and package/session metadata files. |
| `r-restore.R` | Restores R packages from a backup made by `r-freeze.R`, preferring `renv.lock` and falling back to `requirements.txt`. |
| `report_storage.sh` | Creates and emails a storage usage report for the current directory. |
| `reporting.sh` | Collects `sysstat` data from remote hosts, renders reports, and emails generated images. |
| `update_key.sh` | Migrates legacy `apt-key` entries into `/etc/apt/trusted.gpg.d`. |
| `whisper.sh` | Generates `.srt` subtitles from `mp4`, `avi`, `mkv`, `m4a`, `aac`, or `mp3` files using `ffmpeg` and `whisper-cli`. |
| `yt-dlp.conf` | Default `yt-dlp` options for best-format downloads, retries, geo bypass, browser impersonation, metadata, chapters, subtitles, thumbnails, multistream handling, and MP4 remuxing. |

## Usage

### Media Processing

Run media scripts directly from this directory or by path:

```sh
utility/whisper.sh --help
utility/pdf2jpg.sh --help
utility/pdf2jpg.sh document.pdf
utility/pdf2jpg.sh document.pdf scans/document.pdf
lang=en utility/whisper.sh audio.mp3 video.mp4
WHISPER_MODEL=turbo lang=en utility/whisper.sh audio.mp3
WHISPER_MODEL_PATH=/path/to/model.bin utility/whisper.sh audio.mp3
WHISPER_VAD=1 utility/whisper.sh audio.mp3
WHISPER_VAD=1 WHISPER_VAD_MODEL=v5.1.2 utility/whisper.sh audio.mp3
```

`pdf2jpg.sh` requires at least one PDF file and writes JPEGs next to each PDF, using the original input path without the trailing `.pdf` as the `pdftoppm` output prefix.

`whisper.sh` announces each input as `(current/total) FILE`, skips files that already have a matching `.srt`, uses Korean by default (`lang=ko`), and recommends the large model as the default. Set `WHISPER_MODEL=turbo` or `WHISPER_MODEL_CHOICE=turbo` to use the turbo model. Set `WHISPER_MODEL_PATH` for a specific model file.

| Choice | Model path |
| --- | --- |
| `large` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/ggml-large-v3.bin` |
| `turbo` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/ggml-large-v3-turbo.bin` |

Set `WHISPER_VAD=1` to enable whisper-cli Voice Activity Detection. VAD auto-detects the newest available Silero model by default and falls back to the v6.2.0 path when no matching model is found. Set `WHISPER_VAD_MODEL=v5.1.2` for the previous model, `WHISPER_VAD_MODEL=v6.2.0` for the current fallback model explicitly, or `WHISPER_VAD_MODEL_PATH` for a specific VAD model file.

| VAD choice | Model path |
| --- | --- |
| `auto` | Newest `ggml-silero-v*.bin` under `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model`; falls back to the v6.2.0 path below |
| `v6.2.0` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model/ggml-silero-v6.2.0.bin` |
| `v5.1.2` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model/ggml-silero-v5.1.2.bin` |

Leave `WHISPER_VAD_MODEL` unset, or set it to `auto`, to scan `WHISPER_VAD_MODEL_DIR` for the newest matching Silero VAD model. Set `WHISPER_VAD_MODEL_DIR` to scan a different directory. Explicit choices such as `WHISPER_VAD_MODEL=v5.1.2`, path values in `WHISPER_VAD_MODEL`, and `WHISPER_VAD_MODEL_PATH` still override auto-detection.

VAD tuning variables map directly to whisper-cli options: `WHISPER_VAD_THRESHOLD`, `WHISPER_VAD_MIN_SPEECH_DURATION_MS`, `WHISPER_VAD_MIN_SILENCE_DURATION_MS`, `WHISPER_VAD_MAX_SPEECH_DURATION_S`, `WHISPER_VAD_SPEECH_PAD_MS`, and `WHISPER_VAD_SAMPLES_OVERLAP`.

For MP4, AVI, MKV, M4A, and AAC inputs, `whisper.sh` extracts the audio to MP3 with `ffmpeg -i INPUT -vn -q:a 0 -map a OUTPUT.mp3` before running `whisper-cli`.

### R Environment Backup

Back up the active R package environment before an OS or R reinstall:

```sh
utility/r-freeze.R ~/r-env-backup
```

Restore it after reinstalling R:

```sh
utility/r-restore.R ~/r-env-backup
```

`r-freeze.R` writes `renv.lock` as the primary reproducibility artifact, plus a pip-style `requirements.txt`, `r-packages.tsv`, `sessionInfo.txt`, `R.version.txt`, and `libPaths.txt`. `r-restore.R` prefers `renv.lock`; if the lockfile is missing, it installs packages from `requirements.txt`. Set `R_RESTORE_LIBRARY=/path/to/library` to restore into a specific R library instead of `.libPaths()[1]`.

### macOS Maintenance

Use `disable_spotlight.sh` on macOS volumes or directories:

```sh
utility/disable_spotlight.sh /Volumes/ExternalDrive
utility/disable_spotlight.sh /Volumes/ExternalDrive /Volumes/BackupDrive
```

At least one target directory is required. Run `utility/disable_spotlight.sh --help` to show the usage message.

### yt-dlp Configuration

Use `yt-dlp.conf` with `yt-dlp`:

```sh
yt-dlp --config-location utility/yt-dlp.conf URL
```

### SLURM Migration And Reporting

Submit SLURM-oriented migration or reporting scripts with `sbatch` only on systems where the hard-coded paths, remote hosts, SSH settings, and mail settings are valid:

```sh
sbatch utility/migration_arrange.sh
sbatch utility/migration_store.sh
sbatch utility/migration_check.sh
sbatch utility/report_storage.sh
```

### Server Administration

Server administration scripts such as `Backup.sh`, `check_system.sh`, `make_user.sh`, `reporting.sh`, and `update_key.sh` should be run only on the matching Linux server environment. Several of them expect root privileges, working mail delivery, and paths under `/BiO`, `/etc`, `/var/log/sysstat`, or `/var/www/html`.

```sh
utility/check_system.sh --help
utility/check_system.sh --heavy-task-limit 10
utility/check_system.sh --idle-warning-threshold 20 --idle-error-threshold 10
utility/check_system.sh --temperature-warning-threshold 75 --temperature-error-threshold 85
utility/check_system.sh --gpu-warning-threshold 80 --gpu-error-threshold 90
```

`check_system.sh` uses idle-percentage thresholds for CPU and memory, so lower values are worse. By default, CPU and memory warnings start when idle capacity falls below 15%, and errors start below 10%. Temperature and GPU thresholds are upper bounds, so higher values are worse. By default, temperature warnings start above 70 C and errors above 80 C; GPU memory or utilization warnings start above 85%, and errors above 90%. The error threshold must be more severe than the warning threshold.

## Dependencies

Dependencies vary by script:

* Media helpers: `ffmpeg`, `whisper-cli`, `pdftoppm`, `yt-dlp`
* macOS helper: `dot_clean`
* R environment helpers: `Rscript`, `renv`, `remotes`, optional `BiocManager`
* Linux/server helpers: `mail`, `top`, `ps`, `free`, `bc`, `nvidia-smi`, `tar`, `gpg`, `apt-key`, `adduser`, `gpasswd`
* Sysstat/reporting helpers: `sar`, `sadf`, `sysstat`, `convert`, `scp`, `ssh`
* Migration/storage helpers: `rsync`, `tree`, `md5sum`, `du`, SLURM `sbatch`

## Notes

Most shell scripts use `set -euo pipefail`, so they stop when a command fails or an expected variable is missing. Some scripts require environment variables, such as `PORT` for `reporting.sh`, `lang` for overriding the default Whisper language in `whisper.sh`, `WHISPER_MODEL`, `WHISPER_MODEL_CHOICE`, or `WHISPER_MODEL_PATH` for overriding Whisper model selection, and `WHISPER_VAD_MODEL`, `WHISPER_VAD_MODEL_DIR`, or `WHISPER_VAD_MODEL_PATH` for VAD transcription.

The migration scripts create checksum and tree files in the working directory. `migration_arrange.sh` and `migration_store.sh` delete empty files before creating checksums. `migration_store.sh` uses `rsync --remove-source-files` to move transferred files to `root@kimura.kogic.kr:/BiO/Archive/` through SSH port `3030`, so run it only after confirming the destination and command behavior.

`check_system.sh` sends CPU, memory, temperature, and GPU alerts to `root@compbio.unist.ac.kr`. CPU and temperature alerts include the configured number of busiest CPU processes with PID, process name, user, UID, CPU%, memory GB, and memory %. Memory alerts include the configured number of largest memory users with the same process fields. Temperature checks use the first readable `/sys/class/thermal/thermal_zone*/temp` file and are skipped on hosts without one. GPU alerts include the configured number of largest reported GPU compute processes with PID, process name, user, UID, GPU%, and GPU memory. GPU checks run only when `nvidia-smi` is available and can communicate with the NVIDIA driver; hosts without a usable NVIDIA driver skip GPU monitoring.
