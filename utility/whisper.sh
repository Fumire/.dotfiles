#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
set -euo pipefail
IFS=$'\n\t'

if [[ $(uname -s) != "Darwin" ]]; then
    echo "whisper.sh is only supported on macOS." >&2
    exit 0
fi

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

readonly DEFAULT_WHISPER_MODEL_DIR="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model"
readonly FALLBACK_WHISPER_MODEL="${DEFAULT_WHISPER_MODEL_DIR}/ggml-large-v3.bin"
readonly WHISPER_MODEL_DIR="${WHISPER_MODEL_DIR:-$DEFAULT_WHISPER_MODEL_DIR}"

resolve_whisper_model() {
    local configured_model="${WHISPER_MODEL_PATH:-${WHISPER_MODEL:-}}"
    if [[ -n "$configured_model" ]]; then
        printf '%s\n' "$configured_model"
        return
    fi

    local model_name
    for model_name in \
        "current.bin" \
        "distil-large-v3.5-ggml.bin" \
        "ggml-large-v3-q5_0.bin" \
        "ggml-large-v3-turbo.bin"; do
        if [[ -f "${WHISPER_MODEL_DIR}/${model_name}" ]]; then
            printf '%s\n' "${WHISPER_MODEL_DIR}/${model_name}"
            return
        fi
    done

    printf '%s\n' "$FALLBACK_WHISPER_MODEL"
}

readonly WHISPER_MODEL_PATH="$(resolve_whisper_model)"

run_whisper() {
    local input_file="$1"
    local output_srt="$2"

    whisper-cli -m "$WHISPER_MODEL_PATH" --output-srt --language "${lang:-ko}" --threads 8 --processors 8 --print-colors --print-confidence --file "$input_file"
    mv -v "${input_file}.srt" "$output_srt"
}

convert_to_mp3() {
    local source_file="$1"
    local mp3_file="$2"

    case "$source_file" in
        *.mp4 | *.avi | *.mkv)
            ffmpeg -y -i "$source_file" -q:a 0 -map a "$mp3_file"
            ;;
        *.m4a)
            ffmpeg -i "$source_file" -c:v copy -c:a libmp3lame -q:a 4 "$mp3_file"
            ;;
        *.aac)
            ffmpeg -i "$source_file" -acodec libmp3lame "$mp3_file"
            ;;
    esac
}

process_media_file() {
    local source_file="$1"
    local stem="${source_file%.*}"
    local srt_file="${stem}.srt"
    local mp3_file="${stem}.mp3"

    if [[ -f "$srt_file" ]]; then
        return
    fi

    case "$source_file" in
        *.mp4 | *.avi | *.mkv | *.m4a | *.aac)
            convert_to_mp3 "$source_file" "$mp3_file"
            run_whisper "$mp3_file" "$srt_file"
            rm -fv "$mp3_file"
            ;;
        *.mp3)
            run_whisper "$source_file" "$srt_file"
            ;;
    esac
}

for f in "$@"; do
    echo "$f"
    process_media_file "$f"
done
