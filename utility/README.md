# Utility Scripts

Small personal utility scripts for media processing, macOS maintenance, Linux server administration, storage reporting, and migration jobs.

These scripts are intentionally environment-specific. Review each script before running it, especially the server and migration helpers, because several commands use hard-coded paths, hosts, SSH ports, email addresses, SLURM options, privileged system paths, or source-file removal after transfer.

## Files

| File | Purpose |
| --- | --- |
| `authfail_notify.sh` | PAM helper that emails a notification for failed login attempts. |
| `Backup.sh` | Archives account-related system files and emails the backup archive. |
| `check_system.sh` | Checks CPU, memory, temperature, and optional NVIDIA GPU thresholds, then emails warnings or errors with the five heaviest related processes. |
| `disable_spotlight.sh` | Adds `.metadata_never_index` to target folders and runs `dot_clean`; intended for macOS volumes. |
| `make_user.sh` | Interactive Linux user creation helper for the local server environment. |
| `migration_arrange.sh` | Prepares a directory for migration by deleting empty files, writing checksum files, and saving a tree listing. |
| `migration_check.sh` | Verifies a migrated directory against `tree.txt` and `md5.txt`. |
| `migration_store.sh` | Prepares checksums, stores a tree listing, transfers the directory with `rsync --remove-source-files`, and removes transferred source files after success. |
| `nologin.txt` | Login-disabled message for server account administration. |
| `pdf2jpg.sh` | Converts PDF pages to 600 DPI JPEG images with `pdftoppm` and JPEG quality 100. |
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
utility/pdf2jpg.sh document.pdf
lang=en utility/whisper.sh audio.mp3 video.mp4
WHISPER_MODEL=turbo lang=en utility/whisper.sh audio.mp3
WHISPER_MODEL_PATH=/path/to/model.bin utility/whisper.sh audio.mp3
WHISPER_VAD=1 utility/whisper.sh audio.mp3
```

`whisper.sh` skips files that already have a matching `.srt`. It uses Korean by default (`lang=ko`) and recommends the large model as the default. Set `WHISPER_MODEL=turbo` or `WHISPER_MODEL_CHOICE=turbo` to use the turbo model. Set `WHISPER_MODEL_PATH` for a specific model file.

| Choice | Model path |
| --- | --- |
| `large` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/ggml-large-v3.bin` |
| `turbo` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/ggml-large-v3-turbo.bin` |

Set `WHISPER_VAD=1` to enable whisper-cli Voice Activity Detection. By default, VAD looks for Silero models in `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model`, including `ggml-silero-v6.2.0.bin`. Set `WHISPER_VAD_MODEL` for a specific VAD model file or `WHISPER_VAD_MODEL_DIR` for another model directory. VAD tuning variables map directly to whisper-cli options: `WHISPER_VAD_THRESHOLD`, `WHISPER_VAD_MIN_SPEECH_DURATION_MS`, `WHISPER_VAD_MIN_SILENCE_DURATION_MS`, `WHISPER_VAD_MAX_SPEECH_DURATION_S`, `WHISPER_VAD_SPEECH_PAD_MS`, and `WHISPER_VAD_SAMPLES_OVERLAP`.

### macOS Maintenance

Use `disable_spotlight.sh` on macOS volumes or directories:

```sh
utility/disable_spotlight.sh /Volumes/ExternalDrive
```

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

## Dependencies

Dependencies vary by script:

* Media helpers: `ffmpeg`, `whisper-cli`, `pdftoppm`, `yt-dlp`
* macOS helper: `dot_clean`
* Linux/server helpers: `mail`, `top`, `ps`, `free`, `bc`, `nvidia-smi`, `tar`, `gpg`, `apt-key`, `adduser`, `gpasswd`
* Sysstat/reporting helpers: `sar`, `sadf`, `sysstat`, `convert`, `scp`, `ssh`
* Migration/storage helpers: `rsync`, `tree`, `md5sum`, `du`, SLURM `sbatch`

## Notes

Most shell scripts use `set -euo pipefail`, so they stop when a command fails or an expected variable is missing. Some scripts require environment variables, such as `PORT` for `reporting.sh`, `lang` for overriding the default Whisper language in `whisper.sh`, `WHISPER_MODEL`, `WHISPER_MODEL_CHOICE`, or `WHISPER_MODEL_PATH` for overriding Whisper model selection, and `WHISPER_VAD_MODEL` for VAD transcription.

The migration scripts create checksum and tree files in the working directory. `migration_arrange.sh` and `migration_store.sh` delete empty files before creating checksums. `migration_store.sh` uses `rsync --remove-source-files` to move transferred files to `root@kimura.kogic.kr:/BiO/Archive/` through SSH port `3030`, so run it only after confirming the destination and command behavior.

`check_system.sh` sends CPU, memory, temperature, and GPU alerts to `root@compbio.unist.ac.kr`. CPU and temperature alerts include the five busiest CPU processes with PID, process name, user, UID, CPU%, memory GB, and memory %. Memory alerts include the five largest memory users with the same process fields. GPU alerts include the five largest reported GPU compute processes with PID, process name, user, UID, GPU%, and GPU memory. GPU checks run only when `nvidia-smi` is available; warning thresholds start above 85% GPU memory or utilization, and error thresholds start above 90%.
