# Utility Scripts

Small personal utility scripts for media processing, macOS maintenance, Linux server administration, storage reporting, and migration jobs.

These scripts are intentionally environment-specific. Review each script before running it, especially the server and migration helpers, because several commands use hard-coded paths, hosts, SSH ports, email addresses, SLURM options, privileged system paths, or source-file removal after transfer.

## Files

| File | Purpose |
| --- | --- |
| `authfail_notify.sh` | PAM helper that emails a notification for failed login attempts. |
| `Backup.sh` | Archives account-related system files and emails the backup archive. |
| `check_system.sh` | Checks CPU, memory, temperature, and optional NVIDIA GPU thresholds, then emails warnings or errors to the configured alert recipient with the configured number of heaviest related processes. |
| `check_system_cpu.sh` | Checks CPU threshold and sends process-heavy alerts; called by `check_system.sh`. |
| `check_system_memory.sh` | Checks memory threshold and sends process-heavy alerts; called by `check_system.sh`. |
| `check_system_temperature.sh` | Checks thermal threshold and sends alerts with heavy CPU process context; called by `check_system.sh`. |
| `disable_spotlight.sh` | Adds `.metadata_never_index` to one or more target directories and runs `dot_clean`; intended for macOS volumes. |
| `make_user.sh` | Argument-driven Linux user creation helper with optional `--home` base, default initial password, and interactive `adduser` user-information prompts. |
| `migration_arrange.sh` | Prepares a directory for migration by deleting empty files and writing consistent `md5.txt` and `tree.txt` manifests. |
| `migration_check.sh` | Verifies a migrated directory against `tree.txt` and `md5.txt`. |
| `migration_store.sh` | Prepares checksums, stores a tree listing, transfers the directory with `rsync --remove-source-files`, and removes transferred source files after success. |
| `nemo.py` | Python helper used by `nemo.sh` for model compatibility checks, speaker-aware SRT/WebVTT generation, and timestamp-free playbook creation. |
| `nemo.sh` | Converts audio or video with `ffmpeg`, passes direct local ASR and diarization model paths to `nemo-speech`, writes speaker-labeled source and translated subtitles, and can mux them into MP4 subtitle tracks. |
| `nologin.txt` | Login-disabled message for server account administration. |
| `pdf2jpg.sh` | Converts PDF pages to 600 DPI JPEG images with `pdftoppm` and JPEG quality 100. |
| `r-freeze.R` | Backs up the active R package environment into `renv.lock`, `requirements.txt`, and package/session metadata files, including remote-source and Bioconductor release metadata when available. |
| `r-restore.R` | Restores R packages from a backup made by `r-freeze.R`, preferring `renv.lock` and using backup metadata for GitHub/remotes and Bioconductor packages. |
| `report_storage.sh` | Creates and emails a storage usage report for the current directory. |
| `reporting.sh` | Collects `sysstat` data from remote hosts, renders reports, and emails generated images. |
| `update_key.sh` | Exports legacy trusted keys from `/etc/apt/trusted.gpg` into `/etc/apt/keyrings` for `signed-by`-style source entries. |
| `whisper.sh` | Generates `.srt` subtitles by default, or `.vtt` when selected, from `mp4`, `avi`, `mkv`, `m4a`, `aac`, or `mp3` files using `ffmpeg` and `whisper-cli`. |
| `yt-dlp.conf` | MP4-oriented `yt-dlp` defaults that prefer non-Premium video, use bounded retry backoff, and embed thumbnails, metadata, chapters, and manual subtitles except live chat. |

## Usage

### Media Processing

Run media scripts directly from this directory or by path:

```sh
utility/whisper.sh --help
utility/nemo.sh --help
utility/pdf2jpg.sh --help
utility/pdf2jpg.sh document.pdf
utility/pdf2jpg.sh document.pdf scans/document.pdf
utility/whisper.sh -l en audio.mp3 video.mp4
utility/nemo.sh meeting.mp4
utility/nemo.sh --subtitle meeting.mp4
utility/nemo.sh -s meeting.mp4
utility/nemo.sh -f meeting.mp4
utility/nemo.sh -p meeting.mp4
utility/nemo.sh -m large meeting.mp4
utility/nemo.sh -d large meeting.mp4
utility/nemo.sh -t srt meeting.mp4
utility/nemo.sh -l en meeting.m4a
utility/nemo.sh --translate meeting.mp4
utility/nemo.sh --translate false meeting.wav
utility/nemo.sh --vad-model /path/to/silero-v6.2.0.gguf meeting.wav
utility/whisper.sh -s video.mp4
utility/whisper.sh -m large -l en audio.mp3
utility/whisper.sh -t vtt audio.mp3
utility/whisper.sh -c 35 audio.mp3
utility/whisper.sh --model-path /path/to/model.bin audio.mp3
utility/whisper.sh --no-vad audio.mp3
utility/whisper.sh --vad-model v5.1.2 audio.mp3
```

`pdf2jpg.sh` requires at least one PDF file and writes JPEGs next to each PDF, using the original input path without the trailing `.pdf` as the `pdftoppm` output prefix.

#### NeMo Speech Transcription

`nemo.sh` accepts one or more audio or video files supported by `ffmpeg`. It extracts the first audio stream, converts it to 16 kHz mono PCM WAV, and writes a speaker-labeled `<input-name>.vtt` beside each input by default. Use `-t srt` or `--type srt` to write SubRip files instead; both formats retain speaker labels. Translation is disabled by default; use `--translate` to generate the applicable English and Korean subtitles. The terminal displays a Python `tqdm` progress bar with completed/total inputs, elapsed time, processing rate, and estimated remaining time based on completed files; skipped inputs count as complete. While an input is transcribing, a second `tqdm` bar shows the current decoded media time against the WAV's full audio duration, elapsed time, and an ETA based on the observed transcription rate. This per-file position comes from the NeMo-Speech ASR SDK's `audio_processed` result, so it reflects decoded audio progress rather than a wall-clock estimate. Each translation pass also displays completed/total subtitle cues, elapsed time, and an ETA based on the observed translation rate. The installed NeMo-Speech ASR and NMT SDK libraries must be available alongside the `nemo-speech` executable. The Python 3 environment used by `nemo.sh` must have `tqdm` installed (`python3 -m pip install tqdm`). By default, it skips an input if its matching source subtitle already exists; with `--translate`, an existing translated subtitle also triggers the skip. Use `-f` or `--force` to regenerate and replace subtitle outputs. Use `-p` or `--playbook` to write a matching `.txt` file for each source or translated subtitle, without timestamps and with consecutive cues combined into speaker turns. When an existing subtitle triggers the default skip, `--playbook` still creates its matching text file. `nemo.py` is the helper for runtime model checks, language metadata, SRT/WebVTT generation, playbook creation, SDK streaming transcription, SDK cue translation, and progress display.

Shell status messages and native NeMo-Speech SDK log lines are sent through the tqdm renderer, which preserves separate terminal lines while updating the progress bars. Status text is line-framed so embedded line feeds in input paths do not corrupt progress events.

`nemo.sh` passes local GGUF model files directly to `nemo-speech`, so it does not clear or depend on symbolic links in the NeMo model cache. `-m` or `--model` selects `large` or `turbo`; turbo is the default. The ASR files are under `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/ASR`. `-d` or `--diar-model` selects `large` or `turbo` from `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/Diarization`; turbo is the default. It also accepts an explicit model path or repository.

`nemo.py` reads transcript text and timestamped words from top-level or nested ASR JSON results, and also accepts timestamped segments. Each subtitle cue contains no more than one sentence and is limited to 50 characters by default, including the speaker label. Set `-c CHARS` or `--cue CHARS` to adjust the maximum cue length; the minimum is 19 characters so the `[Speaker Unknown]` label and at least one text character can fit. Longer sentences are split at spaces. If only timestamped multi-sentence segments are available, the helper divides each segment's time across its sentence-sized cues according to text length. If recognized text has no word timestamps, it splits the transcript into sentence-sized cues, estimates their times across the full audio duration according to text length, labels them `Speaker Unknown`, and prints a warning. If the result has no recognized text, `nemo.sh` prints a warning with the JSON's top-level fields, skips subtitle creation and MP4 subtitle embedding for that input, and continues to the next input. If recognized text has no valid audio duration, it reports an error.

Translation is disabled by default. With `--translate`, English sources keep the original `<input-name>.vtt` and also get `<input-name>.ko.vtt`. Korean sources keep the original VTT and also get `<input-name>.en.vtt`. Other source languages get the original VTT plus `<input-name>.en.vtt` and `<input-name>.ko.vtt`; `-t srt` or `--type srt` changes all these extensions to `.srt`. Translations retain the source cue times and speaker IDs. If a translated cue must be split to meet the selected cue length, its source time span is divided according to text length. An empty cue result is retried twice; if it remains empty, that cue keeps its source text and the remaining translation continues. Use `--translate false` to explicitly leave translation disabled. Any existing translated subtitle that is not generated during that run is left untouched. With `--language auto` (the default), the detected language determines which outputs are needed. Use `-l`, `--language`, or the existing `--lang` alias to select a source language. Non-English, non-Korean sources are translated through English before Korean.

| Option | Purpose | Default |
| --- | --- | --- |
| `-m, --model MODEL` | ASR model choice (`large`, `turbo`) or path/repo | `turbo`: `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/ASR/nemotron-3.5-asr-streaming-0.6b.q8_0.gguf` |
| `-d, --diar-model MODEL` | Diarization choice (`large`, `turbo`) or explicit path/repo | `turbo`: `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/Diarization/Nemotron-3-Diarization.q8_0.gguf` |
| `-t, --type FORMAT` | Subtitle format: `srt` or `vtt` | `vtt` |
| `-c, --cue CHARS` | Maximum subtitle cue length, including the speaker label (minimum 19) | `50` |
| `--translate [BOOL]` | Enable translated subtitles; a bare option enables it, optional values are `true` or `false` | Off unless provided |
| `-f, --force` | Regenerate inputs with existing source or translated subtitle files | Off unless provided |
| `-p, --playbook` | Write timestamp-free TXT transcripts for generated or existing subtitle files | Off unless provided |
| `--nmt-model PATH` | Translation GGUF model | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/translation-model/Riva-Translate-4B-Instruct-v2-Q4_K_M.gguf` |
| `-s, --subtitle` | Mux generated subtitles into an MP4 as soft subtitle tracks when provided | Off unless provided |
| `-l, --language, --lang CODE` | Language code or prompt | `auto` |
| `--vad MODE` | Select `silero` or `false` | `silero`: /Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/VAD/ggml-silero-v6.2.0.gguf |
| `--vad-model PATH` | Enable VAD with a custom GGUF model | Configured Silero path |
| `--no-vad` | Disable VAD (alias for `--vad false`) | — |
| `-h, --help` | Show command help | — |
| `--` | Treat remaining arguments as input paths | — |

`-m large` selects `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/ASR/nemotron-3.5-asr-streaming-0.6b.gguf`; `-m turbo` selects the default Q8_0 model. An explicit model path or indexed HF repository can also be passed to `--model`. The `NEMO_MODEL` environment variable continues to override the default model.

`-d large` selects `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/Diarization/Nemotron-3-Diarization.gguf`; `-d turbo` selects `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/Diarization/Nemotron-3-Diarization.q8_0.gguf`. The `NEMO_DIAR_MODEL` environment variable continues to override the default.

`nemo-speech` defaults to `$HOME/.local/bin/nemo-speech`. Set `NEMO_BIN`, `NEMO_MODEL`, `NEMO_DIAR_MODEL`, `NEMO_VAD_MODEL`, `NEMO_NMT_MODEL`, or `NEMO_LANGUAGE` to change the corresponding defaults. VAD is enabled by default with Silero v6.2.0 at `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/VAD/ggml-silero-v6.2.0.gguf`. Use `--vad false` to disable it; `--vad silero` selects the default model. Set `NEMO_VAD_MODEL` or pass `--vad-model PATH` to select a different compatible VAD GGUF.

For MP4 inputs, providing `-s` or `--subtitle` embeds the source subtitle and any translated subtitles produced in that run as soft subtitle tracks using `mov_text`. The input format follows `-t` or `--type` (`vtt` by default, `srt` when selected). Before transcription, the script checks for embedded subtitle tracks; without `-f` or `--force`, it skips an MP4 that already has a subtitle track. With force enabled, old subtitle streams are excluded from the remux and replaced by the newly generated source and translated tracks. For MP4s without embedded subtitles, the source track is tagged with its detected or selected language; English and Korean translations are tagged `en` and `ko`. English and Korean inputs therefore receive two tracks, while other languages receive three when translation is enabled. Existing video and audio streams are preserved. The script remuxes to a temporary file beside the input, replaces the input MP4 only after a successful remux, then removes the generated subtitle files. If translation is disabled, only the source track is embedded. Non-MP4 inputs keep their subtitle files. Without `-s` or `--subtitle`, normal sidecar subtitle outputs are kept and the MP4 is not remuxed. This option requires `ffprobe` as well as `ffmpeg`.

`whisper.sh` announces each input as `(current/total) FILE`, skips files that already have an output in the selected subtitle format, and uses Korean by default (`-l CODE` or `--lang CODE`). The default model is turbo; use `-m large` or `--model large` to select large, or `--model-path` to specify a model file. Output is SRT by default; use `-t vtt` or `--type vtt` for WebVTT. `-t srt` or `--type srt` explicitly selects the default format. The selected format determines the sidecar extension and the Whisper CLI output flag. By default, each subtitle cue is limited to 50 characters; `-c CHARS` or `--cue CHARS` changes that limit (minimum 19). Long cues are split at sentence boundaries and spaces where possible, and their original time span is divided across the resulting cues according to text length. Set `WHISPER_CUE_CHARS` to change the default. If VAD produces no subtitle cues, `whisper.sh` retries once without VAD. Invalid UTF-8 bytes in generated subtitles are replaced so the remaining cues can still be normalized and embedded. Converted audio and raw Whisper subtitle output are written to a temporary work directory under `${TMPDIR:-/tmp}`, then removed when the script exits. Final subtitle files remain beside their inputs. Subtitle replacements use a temporary file beside the destination to avoid cross-volume ownership errors. MP4 remux output is staged beside the source video so it can replace the original on the same filesystem; the temporary remux file is removed on failure. If `-s` is rerun while a matching MP4 subtitle file already exists, the script reuses and normalizes that file before embedding it.

| Choice | Model path |
| --- | --- |
| `large` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/02_whisper.cpp/large-v3/ggml-large-v3.bin` |
| `turbo` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/02_whisper.cpp/large-v3-turbo/ggml-large-v3-turbo.bin` |

`whisper-cli` Voice Activity Detection is enabled by default. Set `--no-vad` or `--vad 0`, `false`, `no`, or `off` to disable it. VAD auto-detects the newest available Silero model by default and falls back to the v6.2.0 path when no matching model is found. Set `--vad-model v5.1.2` for the previous model, `--vad-model v6.2.0` for the current fallback model explicitly, or `--vad-model-path` for a specific VAD model file.

| VAD choice | Model path |
| --- | --- |
| `auto` | Newest `ggml-silero-v*.bin` under `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model`; falls back to the v6.2.0 path below |
| `v6.2.0` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model/ggml-silero-v6.2.0.bin` |
| `v5.1.2` | `/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model/ggml-silero-v5.1.2.bin` |

Leave `--vad-model` unset, or set it to `auto`, to scan `--vad-model-dir` for the newest matching Silero VAD model. Set `--vad-model-dir` to scan a different directory. Explicit choices such as `--vad-model=v5.1.2`, path values in `--vad-model`, and `--vad-model-path` still override auto-detection.

Subtitle line wrapping for SRT and WebVTT is limited to `--subtitle-max-words` words per line (default: 7). Set `--subtitle-max-words 0` to disable post-processing wrapping.

If `-s` or `--subtitle` is provided for an MP4 input, whisper.sh muxes the generated subtitle file (`.srt` by default or `.vtt` with `--type vtt`) into the original MP4 as a soft subtitle track (`mov_text`). It preserves existing video/audio/subtitle tracks by remuxing streams with `copy`, overwrites the original MP4, and removes the sidecar file after successful muxing. If the generated subtitle file is empty (`0 byte`), it skips MP4 muxing and removes that empty file. If a matching subtitle file already exists when `-s` is provided, it is normalized and reused for the mux.

```sh
ffmpeg -i input.mp4 -i input.srt -map 0 -map 1 \
  -c:v copy -c:a copy \
  -c:s copy -c:s:<subtitle_index> mov_text \
  output.mp4
```

(`output.mp4` is the temporary muxed file that is renamed back to the input path.)

For MP4, AVI, MKV, M4A, and AAC inputs, `whisper.sh` extracts the audio to a temporary MP3 with `ffmpeg` before running `whisper-cli`. MP3 inputs are linked into the temporary work directory so Whisper's generated subtitle also stays there until it is moved beside the input.

### R Environment Backup

Back up the active R package environment before an OS or R reinstall:

```sh
utility/r-freeze.R ~/r-env-backup
```

Restore it after reinstalling R:

```sh
utility/r-restore.R ~/r-env-backup
```

`r-freeze.R` writes `renv.lock` as the primary reproducibility artifact, plus a pip-style `requirements.txt`, `r-packages.tsv`, `sessionInfo.txt`, `R.version.txt`, `libPaths.txt`, and `bioconductor-version.txt` when `BiocManager` is available. `r-packages.tsv` records repository and remote metadata used by `r-restore.R` to reinstall GitHub, GitLab, Bitbucket, git URL, URL, and Bioconductor packages from their recorded sources. `r-restore.R` prefers `renv.lock`, then reapplies recorded remote and Bioconductor metadata; if the lockfile is missing, it restores from `r-packages.tsv` and falls back to `requirements.txt` when package metadata is unavailable. Set `R_RESTORE_LIBRARY=/path/to/library` to restore into a specific R library instead of `.libPaths()[1]`.

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
yt-dlp --config-locations utility/yt-dlp.conf URL
```

The configuration first tries the best separate video and audio streams with a video not labelled Premium, retaining videos without `format_note`, and falls back to the best combined format when necessary. The `mp4` preset prefers H.264 video and AAC audio, then merges or remuxes to MP4 when supported; it does not re-encode incompatible codecs. HTTP and fragment failures are retried up to 10 times with exponential backoff. Thumbnails, metadata, chapters, and all available manual subtitles except live chat are embedded; automatic captions are not requested.

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
CHECK_SYSTEM_ALERT_RECIPIENT=ops@example.org utility/check_system.sh
utility/check_system.sh --alert-recipient ops@example.org
```

`check_system.sh` uses idle-percentage thresholds for CPU and memory, so lower values are worse. By default, CPU and memory warnings start when idle capacity falls below 15%, and errors start below 10%. Temperature and GPU thresholds are upper bounds, so higher values are worse. By default, temperature warnings start above 70 C and errors above 80 C; GPU memory or utilization warnings start above 85%, and errors above 90%. The error threshold must be more severe than the warning threshold. Alerts default to `root@compbio.unist.ac.kr`; set `CHECK_SYSTEM_ALERT_RECIPIENT` to change the environment default, or pass `--alert-recipient` to override it for one run.

## Dependencies

Dependencies vary by script:

* Media helpers: `ffmpeg`, `whisper-cli`, `nemo-speech`, `python3`, `pdftoppm`, `yt-dlp`
* macOS helper: `dot_clean`
* R environment helpers: `Rscript`, `renv`, `remotes`, optional `BiocManager`
* Linux/server helpers: `mail`, `top`, `ps`, `free`, `bc`, `nvidia-smi`, `tar`, `gpg`, `adduser`, `gpasswd`
* Sysstat/reporting helpers: `sar`, `sadf`, `sysstat`, `convert`, `scp`, `ssh`
* Migration/storage helpers: `rsync`, `tree`, `md5sum`, `du`, SLURM `sbatch`

## Notes

Most shell scripts use `set -euo pipefail`, so they stop when a command fails or an expected variable is missing. Some scripts require or accept environment variables, such as `PORT` for `reporting.sh`, `CHECK_SYSTEM_ALERT_RECIPIENT` for the default `check_system.sh` alert recipient.

For `whisper.sh`, command arguments are preferred (`--lang`, `--model`, `--vad-model`, `--subtitle`, etc.), while environment variables (`lang`, `WHISPER_MODEL`, `WHISPER_MODEL_CHOICE`, `WHISPER_MODEL_PATH`, `WHISPER_VAD`, `WHISPER_VAD_MODEL`, `WHISPER_VAD_MODEL_CHOICE`, `WHISPER_VAD_MODEL_PATH`, `WHISPER_VAD_MODEL_DIR`, `WHISPER_SUBTITLE_MAX_WORDS`, `WHISPER_CUE_CHARS`, `SUBTITLE`) are still supported for compatibility.

For `nemo.sh`, `-t` or `--type` selects `vtt` (default) or `srt`. Translation is off by default and is enabled with `--translate`; the optional value `false` explicitly keeps it disabled. The language option accepts `-l`, `--language`, or `--lang`. Model and executable defaults can be overridden with `NEMO_BIN`, `NEMO_MODEL`, `NEMO_DIAR_MODEL`, `NEMO_VAD_MODEL`, `NEMO_NMT_MODEL`, and `NEMO_LANGUAGE`.

The migration scripts create `md5.txt` and `tree.txt` manifests in the working directory. Both manifests exclude themselves and legacy `*.md5sum` sidecars so `migration_check.sh` can reproduce the same inputs after transfer. `migration_arrange.sh` and `migration_store.sh` delete empty files before creating the manifests. `migration_store.sh` uses `rsync --remove-source-files` to move transferred files to `root@kimura.kogic.kr:/BiO/Archive/` through SSH port `3030`, so run it only after confirming the destination and command behavior.

`check_system.sh` sends CPU, memory, temperature, and GPU alerts to `root@compbio.unist.ac.kr` by default. `CHECK_SYSTEM_ALERT_RECIPIENT` changes that default, and `--alert-recipient ADDRESS` overrides both for one invocation. CPU and temperature alerts include the configured number of busiest CPU processes with PID, process name, user, UID, CPU%, memory GB, and memory %. Memory alerts include the configured number of largest memory users with the same process fields. Temperature checks use the first readable `/sys/class/thermal/thermal_zone*/temp` file and are skipped on hosts without one. GPU alerts include the configured number of largest reported GPU compute processes with PID, process name, user, UID, GPU%, and GPU memory. GPU checks run only when `nvidia-smi` is available and can communicate with the NVIDIA driver; hosts without a usable NVIDIA driver skip GPU monitoring.



## Last Updated

- 2026-10-30
