#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

for f in "$@"; do
	if [[ -f ${f%.mp4}.srt ]]; then
		continue
	fi
	echo "$f"
    ffmpeg -y -i "$f" -ar 16000 -ac 1 -c:a pcm_s16le "${f%.mp4}.wav"
    whisper-cli -m "/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/ggml-large-v3.bin" --output-srt --language ko --threads 8 --processors 8 --file "${f%.mp4}.wav"
	mv -v "${f%.mp4}.wav.srt" "${f%.mp4}.srt"
	rm -fv "${f%.mp4}.wav"
done
