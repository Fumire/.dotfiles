#!/bin/bash
# Maintainer: 230@fumire.moe
set -euo pipefail
IFS=$'\n\t'

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

for f in "$@"; do
	echo "$f"

    if [[ "$f" == *.mp4 ]]; then
        if [[ -f "${f/%.mp4/.srt}" ]]; then
            continue
        fi
        ffmpeg -y -i "$f" -q:a 0 -map a "${f/%.mp4/.mp3}"
        whisper-cli -m "/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/ggml-large-v3.bin" --output-srt --language ko --threads 8 --processors 8 --print-colors --print-confidence --file "${f/%.mp4/.mp3}"
        mv -v "${f/%.mp4/.mp3.srt}" "${f/%.mp4/.srt}"
        rm -fv "${f/%.mp4/.mp3}"
    elif [[ "$f" == *.m4a ]]; then
        if [[ -f "${f/%.m4a/.srt}" ]]; then
            continue
        fi
        ffmpeg -i "$f" -c:v copy -c:a libmp3lame -q:a 4 "${f/%.m4a/.mp3}"
        whisper-cli -m "/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/ggml-large-v3.bin" --output-srt --language ko --threads 8 --processors 8 --print-colors --print-confidence --file "${f/%.m4a/.mp3}"
        mv -v "${f/%.m4a/.mp3.srt}" "${f/%.m4a/.srt}"
        rm -fv "${f/%.m4a/.mp3}"
    elif [[ "$f" == *.mp3 ]]; then
        if [[ -f "${f/%.mp3/.srt}" ]]; then
            continue
        fi
        whisper-cli -m "/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/ggml-large-v3.bin" --output-srt --language ko --threads 8 --processors 8 --print-colors --print-confidence --file "$f"
        mv -v "${f/%.mp3/.mp3.srt}" "${f/%.mp3/.srt}"
    fi
done
