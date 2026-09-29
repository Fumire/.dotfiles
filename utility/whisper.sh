#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Generate .srt subtitle files from media inputs with whisper-cli, using
#   local large/turbo Whisper models and Silero VAD by default.
# Usage:
#   utility/whisper.sh --help
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_WHISPER_MODEL_DIR="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model"
readonly DEFAULT_WHISPER_VAD_MODEL_DIR="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model"
readonly LARGE_WHISPER_MODEL="${DEFAULT_WHISPER_MODEL_DIR}/ggml-large-v3.bin"
readonly TURBO_WHISPER_MODEL="${DEFAULT_WHISPER_MODEL_DIR}/ggml-large-v3-turbo.bin"
readonly DEFAULT_WHISPER_SUBTITLE_MAX_WORDS=7
readonly SILERO_VAD_MODEL_V5_1_2_SUFFIX="/ggml-silero-v5.1.2.bin"
readonly SILERO_VAD_MODEL_V6_2_0_SUFFIX="/ggml-silero-v6.2.0.bin"

declare -a INPUT_FILES=()
whisper_lang="${lang:-ko}"
whisper_model_path="${WHISPER_MODEL_PATH:-}"
whisper_model_choice="${WHISPER_MODEL_CHOICE:-${WHISPER_MODEL:-large}}"
whisper_vad="${WHISPER_VAD:-}"
whisper_vad_model_path="${WHISPER_VAD_MODEL_PATH:-}"
whisper_vad_model_choice="${WHISPER_VAD_MODEL_CHOICE:-${WHISPER_VAD_MODEL:-auto}}"
whisper_vad_model_dir="${WHISPER_VAD_MODEL_DIR:-$DEFAULT_WHISPER_VAD_MODEL_DIR}"
whisper_subtitle="${SUBTITLE:-false}"
whisper_subtitle_max_words="${WHISPER_SUBTITLE_MAX_WORDS:-$DEFAULT_WHISPER_SUBTITLE_MAX_WORDS}"

show_help() {
    cat <<EOF
Usage:
  utility/whisper.sh [OPTIONS]... [FILE ...]

Generate .srt subtitle files from mp4, avi, mkv, m4a, aac, or mp3 inputs.
Files with an existing matching .srt are skipped.
Each input is announced as (current/total) before processing.
VAD is enabled by default; use --no-vad to disable it.

Examples:
  utility/whisper.sh video.mp4 audio.mp3
  utility/whisper.sh --lang en audio.mp3
  utility/whisper.sh --model turbo audio.mp3
  utility/whisper.sh --no-vad audio.mp3
  utility/whisper.sh --vad-model v5.1.2 audio.mp3

Model selection:
  Default and recommended:
  --model large
    $LARGE_WHISPER_MODEL

  Faster turbo model:
    --model turbo
    $TURBO_WHISPER_MODEL

  Explicit model path override:
    --model-path /path/to/model.bin

VAD model selection:
  Default auto-detected VAD model:
  --vad-model auto
    newest ggml-silero-v*.bin in $DEFAULT_WHISPER_VAD_MODEL_DIR
    fallback: $DEFAULT_WHISPER_VAD_MODEL_DIR/ggml-silero-v6.2.0.bin

  Explicit VAD model choices:
    --vad-model v6.2.0
    $DEFAULT_WHISPER_VAD_MODEL_DIR/ggml-silero-v6.2.0.bin

    --vad-model v5.1.2
    $DEFAULT_WHISPER_VAD_MODEL_DIR/ggml-silero-v5.1.2.bin

  Explicit VAD model path override:
    --vad-model-path /path/to/vad-model.bin

Environment:
  --lang                               Spoken language passed to whisper-cli; default: ko
  --subtitle-max-words                 Maximum words per subtitle line; 0 disables; default: 7
  --model                              Model choice: large or turbo; default: large
  --model-choice                       Alias for --model
  --model-path                         Explicit Whisper model file path
  --vad                                Enable/disable VAD; false/no/off/0 disables
  --vad-model                          VAD model choice: auto, v6.2.0, v5.1.2, or path; default: auto
  --vad-model-choice                   Alias for --vad-model
  --vad-model-path                     Explicit VAD model file path
  --vad-model-dir                      VAD model directory scanned by auto; default: $DEFAULT_WHISPER_VAD_MODEL_DIR
  --subtitle                           Set to true to mux generated SRT as soft subtitle track in MP4 (mov_text), overwrite the input MP4, and remove the generated SRT

Legacy env vars (still supported):
  WHISPER_MODEL, WHISPER_MODEL_CHOICE, WHISPER_MODEL_PATH, WHISPER_VAD,
  WHISPER_VAD_MODEL, WHISPER_VAD_MODEL_CHOICE, WHISPER_VAD_MODEL_PATH, WHISPER_VAD_MODEL_DIR,
  WHISPER_SUBTITLE_MAX_WORDS, lang, SUBTITLE

AAC decode errors:
  If ffmpeg fails while decoding corrupt AAC packets, whisper.sh retries the
  audio conversion with ffmpeg corruption-tolerance flags.

Options:
  -h, --help                            Show this help message
EOF
}

parse_args() {
    local -a file_args=()
    local key

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                show_help
                exit 0
                ;;
            --lang)
                if [[ $# -lt 2 || "${2:0:1}" == "-" ]]; then
                    echo "Missing value for --lang" >&2
                    exit 1
                fi
                whisper_lang="$2"
                shift 2
                ;;
            --lang=*)
                whisper_lang="${1#*=}"
                shift
                ;;
            --model | --model-choice)
                if [[ $# -lt 2 || "${2:0:1}" == "-" ]]; then
                    echo "Missing value for $1" >&2
                    exit 1
                fi
                whisper_model_choice="$2"
                shift 2
                ;;
            --model=*)
                whisper_model_choice="${1#*=}"
                shift
                ;;
            --model-path)
                if [[ $# -lt 2 || "${2:0:1}" == "-" ]]; then
                    echo "Missing value for --model-path" >&2
                    exit 1
                fi
                whisper_model_path="$2"
                shift 2
                ;;
            --model-path=*)
                whisper_model_path="${1#*=}"
                shift
                ;;
            --vad)
                if [[ $# -ge 2 && "${2:0:1}" != "-" ]]; then
                    whisper_vad="$2"
                    shift 2
                else
                    whisper_vad="1"
                    shift
                fi
                ;;
            --vad=*)
                whisper_vad="${1#*=}"
                shift
                ;;
            --no-vad)
                whisper_vad="0"
                shift
                ;;
            --vad-model | --vad-model-choice)
                if [[ $# -lt 2 || "${2:0:1}" == "-" ]]; then
                    echo "Missing value for $1" >&2
                    exit 1
                fi
                whisper_vad_model_choice="$2"
                shift 2
                ;;
            --vad-model=*)
                whisper_vad_model_choice="${1#*=}"
                shift
                ;;
            --vad-model-path)
                if [[ $# -lt 2 || "${2:0:1}" == "-" ]]; then
                    echo "Missing value for --vad-model-path" >&2
                    exit 1
                fi
                whisper_vad_model_path="$2"
                shift 2
                ;;
            --vad-model-path=*)
                whisper_vad_model_path="${1#*=}"
                shift
                ;;
            --vad-model-dir)
                if [[ $# -lt 2 || "${2:0:1}" == "-" ]]; then
                    echo "Missing value for --vad-model-dir" >&2
                    exit 1
                fi
                whisper_vad_model_dir="$2"
                shift 2
                ;;
            --vad-model-dir=*)
                whisper_vad_model_dir="${1#*=}"
                shift
                ;;
            --subtitle)
                if [[ $# -ge 2 && "${2:0:1}" != "-" ]]; then
                    whisper_subtitle="$2"
                    shift 2
                else
                    whisper_subtitle="true"
                    shift
                fi
                ;;
            --subtitle=*)
                whisper_subtitle="${1#*=}"
                shift
                ;;
            --no-subtitle)
                whisper_subtitle="false"
                shift
                ;;
            --subtitle-max-words)
                if [[ $# -lt 2 || "${2:0:1}" == "-" ]]; then
                    echo "Missing value for --subtitle-max-words" >&2
                    exit 1
                fi
                whisper_subtitle_max_words="$2"
                shift 2
                ;;
            --subtitle-max-words=*)
                whisper_subtitle_max_words="${1#*=}"
                shift
                ;;
            --)
                shift
                for key in "$@"; do
                    file_args+=("$key")
                done
                break
                ;;
            --*)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
            *)
                file_args+=("$1")
                shift
                ;;
        esac
    done

    if (( ${#file_args[@]} == 0 )); then
        echo "No input files were provided." >&2
        show_help
        exit 1
    fi

    INPUT_FILES=("${file_args[@]}")
}

parse_args "$@"

if [[ $(uname -s) != "Darwin" ]]; then
    echo "whisper.sh is only supported on macOS." >&2
    exit 0
fi

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

resolve_whisper_model() {
    if [[ -n "${whisper_model_path}" ]]; then
        printf '%s\n' "$whisper_model_path"
        return
    fi

    local model_choice="${whisper_model_choice}"
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
            echo "Unknown Whisper model choice: ${model_choice}. Use large, turbo, or set --model-path to a model file." >&2
            exit 1
            ;;
    esac
}

readonly WHISPER_MODEL_PATH="$(resolve_whisper_model)"

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

whisper_vad_enabled() {
    if is_falsey "${whisper_vad}"; then
        return 1
    fi

    return 0
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

    for model_file in "${whisper_vad_model_dir}"/ggml-silero-v*.bin; do
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
    if [[ -n "${whisper_vad_model_path}" ]]; then
        printf '%s\n' "$whisper_vad_model_path"
        return
    fi

    local vad_model_choice="${whisper_vad_model_choice}"
    local v5_1_2_model="${whisper_vad_model_dir%/}${SILERO_VAD_MODEL_V5_1_2_SUFFIX}"
    local v6_2_0_model="${whisper_vad_model_dir%/}${SILERO_VAD_MODEL_V6_2_0_SUFFIX}"
    case "$vad_model_choice" in
        auto | AUTO)
            detect_newest_whisper_vad_model || printf '%s\n' "$v6_2_0_model"
            ;;
        v6.2.0 | 6.2.0 | v6 | V6)
            printf '%s\n' "$v6_2_0_model"
            ;;
        v5.1.2 | 5.1.2 | v5 | V5)
            printf '%s\n' "$v5_1_2_model"
            ;;
        /* | ./* | ../*)
            printf '%s\n' "$vad_model_choice"
            ;;
        *)
            echo "Unknown VAD model choice: ${vad_model_choice}. Use auto, v6.2.0, v5.1.2, or set --vad-model-path to a model file." >&2
            exit 1
            ;;
    esac
}

append_whisper_vad_args() {
    local vad_model_path

    if ! vad_model_path="$(resolve_whisper_vad_model)"; then
        echo "VAD is enabled, but no VAD model was found. Set --vad-model to auto, v6.2.0, or v5.1.2, or set --vad-model-path." >&2
        exit 1
    fi

    WHISPER_ARGS+=("--vad" "--vad-model" "$vad_model_path")
}

normalize_srt_phrase_length() {
    local srt_file="$1"
    local max_words="${2:-$DEFAULT_WHISPER_SUBTITLE_MAX_WORDS}"
    local temp_file="${srt_file}.words.$$"

    [[ "$max_words" =~ ^[1-9][0-9]*$ ]] || return 0

    LC_ALL=C awk -v max_words="$max_words" '
        BEGIN { RS = ""; ORS = "\n\n" }

        function wrap_text(line,   n, i, count, output, token, words) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            if (line == "") {
                return ""
            }

            n = split(line, words, /[[:space:]]+/)
            output = ""
            count = 0
            for (i = 1; i <= n; i++) {
                token = words[i]
                if (token == "") {
                    continue
                }
                if (count == 0) {
                    output = token
                    count = 1
                } else if (count < max_words) {
                    output = output " " token
                    count++
                } else {
                    output = output "\n" token
                    count = 1
                }
            }
            return output
        }

        {
            n = split($0, lines, "\n")
            if (n < 3) {
                printf "%s\n", $0
                next
            }

            printf "%s\n%s\n", lines[1], lines[2]
            for (i = 3; i <= n; i++) {
                if (lines[i] == "") {
                    continue
                }
                wrapped = wrap_text(lines[i])
                if (wrapped != "") {
                    printf "%s\n", wrapped
                }
            }
            printf "\n"
        }
    ' "$srt_file" > "$temp_file" || return 1

    mv -f "$temp_file" "$srt_file"
}

run_whisper() {
    local input_file="$1"
    local output_srt="$2"
    local WHISPER_ARGS=(
        "-m" "$WHISPER_MODEL_PATH"
        "--output-srt"
        "--language" "${whisper_lang}"
        "--threads" "8"
        "--processors" "8"
        "--print-colors"
        "--print-confidence"
    )

    if ! [[ "$whisper_subtitle_max_words" =~ ^[0-9]+$ ]]; then
        whisper_subtitle_max_words="$DEFAULT_WHISPER_SUBTITLE_MAX_WORDS"
    fi

    if whisper_vad_enabled; then
        append_whisper_vad_args
    fi

    WHISPER_ARGS+=("--file" "$input_file")

    whisper-cli "${WHISPER_ARGS[@]}"
    mv -v "${input_file}.srt" "$output_srt"
    normalize_srt_phrase_length "$output_srt" "$whisper_subtitle_max_words"
}

run_ffmpeg_conversion() {
    local source_file="$1"
    local mp3_file="$2"
    local conversion_type="$3"
    local output_existed=0

    [[ -e "$mp3_file" ]] && output_existed=1

    case "$conversion_type" in
        video)
            if ffmpeg -y -i "$source_file" -q:a 0 -map 0:a:0 "$mp3_file"; then
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
            ffmpeg -y -fflags +discardcorrupt -err_detect ignore_err -i "$source_file" -q:a 0 -map 0:a:0 -max_error_rate 1 "$mp3_file"
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
        *.mp4)
            convert_to_mp3 "$source_file" "$mp3_file"
            run_whisper "$mp3_file" "$srt_file"
            rm -fv "$mp3_file"

            if [[ "${whisper_subtitle}" == "true" ]]; then
                if [[ ! -s "$srt_file" ]]; then
                    rm -fv "$srt_file"
                else
                    local tmp_mp4="${stem}.subtitle_tmp.mp4"
                    local existing_subtitle_count
                    existing_subtitle_count="$(ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 "$source_file" | wc -l | tr -d '[:space:]')"
                    local new_subtitle_index="$existing_subtitle_count"

                    ffmpeg -y -i "$source_file" -i "$srt_file" -map 0 -map 1 -c:v copy -c:a copy -c:s copy -c:s:"$new_subtitle_index" mov_text -metadata:s:s:"$new_subtitle_index" "language=${whisper_lang}" "$tmp_mp4"
                    mv -fv "$tmp_mp4" "$source_file"
                    rm -fv "$srt_file"
                fi
            fi
            ;;
        *.avi | *.mkv | *.m4a | *.aac)
            convert_to_mp3 "$source_file" "$mp3_file"
            run_whisper "$mp3_file" "$srt_file"
            rm -fv "$mp3_file"
            ;;
        *.mp3)
            run_whisper "$source_file" "$srt_file"
            ;;
    esac
}

total_input_files="${#INPUT_FILES[@]}"
current_input_file=0

for f in "${INPUT_FILES[@]}"; do
    current_input_file=$((current_input_file + 1))
    printf '(%d/%d) %s\n' "$current_input_file" "$total_input_files" "$f"
    process_media_file "$f"
done
