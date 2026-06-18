#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Generate .srt subtitle files from media inputs with whisper-cli, using
#   local large/turbo Whisper models and optional Silero VAD.
# Usage:
#   utility/whisper.sh --help
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_WHISPER_MODEL_DIR="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model"
readonly DEFAULT_WHISPER_VAD_MODEL_DIR="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model"
readonly LARGE_WHISPER_MODEL="${DEFAULT_WHISPER_MODEL_DIR}/ggml-large-v3.bin"
readonly TURBO_WHISPER_MODEL="${DEFAULT_WHISPER_MODEL_DIR}/ggml-large-v3-turbo.bin"
readonly WHISPER_VAD_MODEL_DIR="${WHISPER_VAD_MODEL_DIR:-$DEFAULT_WHISPER_VAD_MODEL_DIR}"
readonly SILERO_VAD_MODEL_V5_1_2="${WHISPER_VAD_MODEL_DIR}/ggml-silero-v5.1.2.bin"
readonly SILERO_VAD_MODEL_V6_2_0="${WHISPER_VAD_MODEL_DIR}/ggml-silero-v6.2.0.bin"

show_help() {
    cat <<EOF
Usage:
  utility/whisper.sh [FILE ...]

Generate .srt subtitle files from mp4, avi, mkv, m4a, aac, or mp3 inputs.
Files with an existing matching .srt are skipped.
Each input is announced as (current/total) before processing.

Examples:
  utility/whisper.sh video.mp4 audio.mp3
  lang=en utility/whisper.sh audio.mp3
  WHISPER_MODEL=turbo utility/whisper.sh audio.mp3
  WHISPER_VAD=1 utility/whisper.sh audio.mp3
  WHISPER_VAD=1 WHISPER_VAD_MODEL=v5.1.2 utility/whisper.sh audio.mp3

Model selection:
  Default and recommended:
    WHISPER_MODEL=large
    $LARGE_WHISPER_MODEL

  Faster turbo model:
    WHISPER_MODEL=turbo
    $TURBO_WHISPER_MODEL

  Explicit model path override:
    WHISPER_MODEL_PATH=/path/to/model.bin

VAD model selection:
  Default auto-detected VAD model:
    WHISPER_VAD_MODEL=auto
    newest ggml-silero-v*.bin in $WHISPER_VAD_MODEL_DIR
    fallback: $SILERO_VAD_MODEL_V6_2_0

  Explicit VAD model choices:
    WHISPER_VAD_MODEL=v6.2.0
    $SILERO_VAD_MODEL_V6_2_0

    WHISPER_VAD_MODEL=v5.1.2
    $SILERO_VAD_MODEL_V5_1_2

  Explicit VAD model path override:
    WHISPER_VAD_MODEL_PATH=/path/to/vad-model.bin

Environment:
  lang                                  Spoken language passed to whisper-cli; default: ko
  WHISPER_MODEL                         Model choice: large or turbo; default: large
  WHISPER_MODEL_CHOICE                  Alias for WHISPER_MODEL
  WHISPER_MODEL_PATH                    Explicit Whisper model file path
  WHISPER_VAD                           Enable VAD when set to 1, true, yes, or on
  WHISPER_VAD_MODEL                     VAD model choice: auto, v6.2.0, v5.1.2, or path; default: auto
  WHISPER_VAD_MODEL_CHOICE              Alias for WHISPER_VAD_MODEL
  WHISPER_VAD_MODEL_PATH                Explicit VAD model file path
  WHISPER_VAD_MODEL_DIR                 VAD model directory scanned by auto; default: $DEFAULT_WHISPER_VAD_MODEL_DIR
  WHISPER_VAD_THRESHOLD                 whisper-cli --vad-threshold
  WHISPER_VAD_MIN_SPEECH_DURATION_MS    whisper-cli --vad-min-speech-duration-ms
  WHISPER_VAD_MIN_SILENCE_DURATION_MS   whisper-cli --vad-min-silence-duration-ms
  WHISPER_VAD_MAX_SPEECH_DURATION_S     whisper-cli --vad-max-speech-duration-s
  WHISPER_VAD_SPEECH_PAD_MS             whisper-cli --vad-speech-pad-ms
  WHISPER_VAD_SAMPLES_OVERLAP           whisper-cli --vad-samples-overlap

AAC decode errors:
  If ffmpeg fails while decoding corrupt AAC packets, whisper.sh retries the
  audio conversion with ffmpeg corruption-tolerance flags.

Options:
  -h, --help                            Show this help message
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

if [[ $(uname -s) != "Darwin" ]]; then
    echo "whisper.sh is only supported on macOS." >&2
    exit 0
fi

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

resolve_whisper_model() {
    if [[ -n "${WHISPER_MODEL_PATH:-}" ]]; then
        printf '%s\n' "$WHISPER_MODEL_PATH"
        return
    fi

    local model_choice="${WHISPER_MODEL_CHOICE:-${WHISPER_MODEL:-large}}"
    case "$model_choice" in
        large | LARGE)
            printf '%s\n' "$LARGE_WHISPER_MODEL"
            ;;
        turbo | TURBO)
            printf '%s\n' "$TURBO_WHISPER_MODEL"
            ;;
        /* | ./* | ../*)
            printf '%s\n' "$model_choice"
            ;;
        *)
            echo "Unknown Whisper model choice: ${model_choice}. Use large, turbo, or set WHISPER_MODEL_PATH to a model file." >&2
            exit 1
            ;;
    esac
}

readonly WHISPER_MODEL_PATH="$(resolve_whisper_model)"

is_truthy() {
    case "${1:-}" in
        1 | true | TRUE | yes | YES | on | ON)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

is_falsey() {
    case "${1:-}" in
        0 | false | FALSE | no | NO | off | OFF)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

whisper_vad_configured() {
    [[ -n "${WHISPER_VAD_MODEL:-}" ]] ||
        [[ -n "${WHISPER_VAD_MODEL_CHOICE:-}" ]] ||
        [[ -n "${WHISPER_VAD_MODEL_PATH:-}" ]] ||
        [[ -n "${WHISPER_VAD_THRESHOLD:-}" ]] ||
        [[ -n "${WHISPER_VAD_MIN_SPEECH_DURATION_MS:-}" ]] ||
        [[ -n "${WHISPER_VAD_MIN_SILENCE_DURATION_MS:-}" ]] ||
        [[ -n "${WHISPER_VAD_MAX_SPEECH_DURATION_S:-}" ]] ||
        [[ -n "${WHISPER_VAD_SPEECH_PAD_MS:-}" ]] ||
        [[ -n "${WHISPER_VAD_SAMPLES_OVERLAP:-}" ]]
}

whisper_vad_enabled() {
    if is_falsey "${WHISPER_VAD:-}"; then
        return 1
    fi

    is_truthy "${WHISPER_VAD:-}" || whisper_vad_configured
}

extract_whisper_vad_model_version() {
    local model_name="${1##*/}"

    if [[ "$model_name" =~ ^ggml-silero-v([0-9]+([.][0-9]+)*)[.]bin$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi

    return 1
}

version_greater_than() {
    local left_version="$1"
    local right_version="$2"
    local left_part
    local right_part
    local i
    local max_parts
    local -a left_parts
    local -a right_parts
    local IFS=.

    left_parts=($left_version)
    right_parts=($right_version)
    max_parts="${#left_parts[@]}"

    if (( ${#right_parts[@]} > max_parts )); then
        max_parts="${#right_parts[@]}"
    fi

    for (( i = 0; i < max_parts; i++ )); do
        left_part="${left_parts[$i]:-0}"
        right_part="${right_parts[$i]:-0}"

        if (( 10#$left_part > 10#$right_part )); then
            return 0
        fi
        if (( 10#$left_part < 10#$right_part )); then
            return 1
        fi
    done

    return 1
}

detect_newest_whisper_vad_model() {
    local model_file
    local model_version
    local newest_model=""
    local newest_version=""

    for model_file in "${WHISPER_VAD_MODEL_DIR}"/ggml-silero-v*.bin; do
        [[ -e "$model_file" ]] || continue

        if ! model_version="$(extract_whisper_vad_model_version "$model_file")"; then
            continue
        fi

        if [[ -z "$newest_model" ]] || version_greater_than "$model_version" "$newest_version"; then
            newest_model="$model_file"
            newest_version="$model_version"
        fi
    done

    if [[ -n "$newest_model" ]]; then
        printf '%s\n' "$newest_model"
        return 0
    fi

    return 1
}

resolve_whisper_vad_model() {
    if [[ -n "${WHISPER_VAD_MODEL_PATH:-}" ]]; then
        printf '%s\n' "$WHISPER_VAD_MODEL_PATH"
        return
    fi

    local vad_model_choice="${WHISPER_VAD_MODEL_CHOICE:-${WHISPER_VAD_MODEL:-auto}}"
    case "$vad_model_choice" in
        auto | AUTO)
            detect_newest_whisper_vad_model || printf '%s\n' "$SILERO_VAD_MODEL_V6_2_0"
            ;;
        v6.2.0 | 6.2.0 | v6 | V6)
            printf '%s\n' "$SILERO_VAD_MODEL_V6_2_0"
            ;;
        v5.1.2 | 5.1.2 | v5 | V5)
            printf '%s\n' "$SILERO_VAD_MODEL_V5_1_2"
            ;;
        /* | ./* | ../*)
            printf '%s\n' "$vad_model_choice"
            ;;
        *)
            echo "Unknown VAD model choice: ${vad_model_choice}. Use auto, v6.2.0, v5.1.2, or set WHISPER_VAD_MODEL_PATH to a model file." >&2
            exit 1
            ;;
    esac
}

append_whisper_vad_args() {
    local vad_model_path

    if ! vad_model_path="$(resolve_whisper_vad_model)"; then
        echo "VAD is enabled, but no VAD model was found. Set WHISPER_VAD_MODEL to auto, v6.2.0, or v5.1.2, or set WHISPER_VAD_MODEL_PATH." >&2
        exit 1
    fi

    WHISPER_ARGS+=("--vad" "--vad-model" "$vad_model_path")

    if [[ -n "${WHISPER_VAD_THRESHOLD:-}" ]]; then
        WHISPER_ARGS+=("--vad-threshold" "$WHISPER_VAD_THRESHOLD")
    fi
    if [[ -n "${WHISPER_VAD_MIN_SPEECH_DURATION_MS:-}" ]]; then
        WHISPER_ARGS+=("--vad-min-speech-duration-ms" "$WHISPER_VAD_MIN_SPEECH_DURATION_MS")
    fi
    if [[ -n "${WHISPER_VAD_MIN_SILENCE_DURATION_MS:-}" ]]; then
        WHISPER_ARGS+=("--vad-min-silence-duration-ms" "$WHISPER_VAD_MIN_SILENCE_DURATION_MS")
    fi
    if [[ -n "${WHISPER_VAD_MAX_SPEECH_DURATION_S:-}" ]]; then
        WHISPER_ARGS+=("--vad-max-speech-duration-s" "$WHISPER_VAD_MAX_SPEECH_DURATION_S")
    fi
    if [[ -n "${WHISPER_VAD_SPEECH_PAD_MS:-}" ]]; then
        WHISPER_ARGS+=("--vad-speech-pad-ms" "$WHISPER_VAD_SPEECH_PAD_MS")
    fi
    if [[ -n "${WHISPER_VAD_SAMPLES_OVERLAP:-}" ]]; then
        WHISPER_ARGS+=("--vad-samples-overlap" "$WHISPER_VAD_SAMPLES_OVERLAP")
    fi
}

run_whisper() {
    local input_file="$1"
    local output_srt="$2"
    local WHISPER_ARGS=(
        "-m" "$WHISPER_MODEL_PATH"
        "--output-srt"
        "--language" "${lang:-ko}"
        "--threads" "8"
        "--processors" "8"
        "--print-colors"
        "--print-confidence"
    )

    if whisper_vad_enabled; then
        append_whisper_vad_args
    fi

    WHISPER_ARGS+=("--file" "$input_file")

    whisper-cli "${WHISPER_ARGS[@]}"
    mv -v "${input_file}.srt" "$output_srt"
}

run_ffmpeg_conversion() {
    local source_file="$1"
    local mp3_file="$2"
    local conversion_type="$3"
    local output_existed=0

    [[ -e "$mp3_file" ]] && output_existed=1

    case "$conversion_type" in
        video)
            if ffmpeg -y -i "$source_file" -q:a 0 -map a "$mp3_file"; then
                return
            fi
            ;;
        m4a)
            if ffmpeg -i "$source_file" -c:v copy -c:a libmp3lame -q:a 4 "$mp3_file"; then
                return
            fi
            ;;
        aac)
            if ffmpeg -i "$source_file" -acodec libmp3lame "$mp3_file"; then
                return
            fi
            ;;
    esac

    if (( output_existed )) && [[ "$conversion_type" != "video" ]]; then
        return 1
    fi

    echo "ffmpeg failed for ${source_file}; retrying while discarding corrupt AAC packets." >&2

    case "$conversion_type" in
        video)
            ffmpeg -y -fflags +discardcorrupt -err_detect ignore_err -i "$source_file" -q:a 0 -map a -max_error_rate 1 "$mp3_file"
            ;;
        m4a)
            ffmpeg -y -fflags +discardcorrupt -err_detect ignore_err -i "$source_file" -c:v copy -c:a libmp3lame -q:a 4 -max_error_rate 1 "$mp3_file"
            ;;
        aac)
            ffmpeg -y -fflags +discardcorrupt -err_detect ignore_err -i "$source_file" -acodec libmp3lame -max_error_rate 1 "$mp3_file"
            ;;
        *)
            echo "Unknown ffmpeg conversion type: ${conversion_type}" >&2
            return 1
            ;;
    esac
}

convert_to_mp3() {
    local source_file="$1"
    local mp3_file="$2"

    case "$source_file" in
        *.mp4 | *.avi | *.mkv)
            run_ffmpeg_conversion "$source_file" "$mp3_file" "video"
            ;;
        *.m4a)
            run_ffmpeg_conversion "$source_file" "$mp3_file" "m4a"
            ;;
        *.aac)
            run_ffmpeg_conversion "$source_file" "$mp3_file" "aac"
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

total_input_files="$#"
current_input_file=0

for f in "$@"; do
    current_input_file=$((current_input_file + 1))
    printf '(%d/%d) %s\n' "$current_input_file" "$total_input_files" "$f"
    process_media_file "$f"
done
