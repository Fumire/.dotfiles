#!/bin/bash
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Generate .srt or .vtt subtitle files from media inputs with whisper-cli, using
#   local large/turbo Whisper models and Silero VAD by default.
# Usage:
#   utility/whisper.sh --help
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_WHISPER_MODEL_DIR="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/whisper-model/02_whisper.cpp"
readonly DEFAULT_WHISPER_VAD_MODEL_DIR="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model"
readonly LARGE_WHISPER_MODEL="${DEFAULT_WHISPER_MODEL_DIR}/large-v3/ggml-large-v3.bin"
readonly TURBO_WHISPER_MODEL="${DEFAULT_WHISPER_MODEL_DIR}/large-v3-turbo/ggml-large-v3-turbo.bin"
readonly DEFAULT_WHISPER_SUBTITLE_MAX_WORDS=7
readonly DEFAULT_WHISPER_CUE_CHARS=50
readonly SILERO_VAD_MODEL_V5_1_2_SUFFIX="/ggml-silero-v5.1.2.bin"
readonly SILERO_VAD_MODEL_V6_2_0_SUFFIX="/ggml-silero-v6.2.0.bin"

declare -a INPUT_FILES=()
whisper_lang="${lang:-ko}"
whisper_model_path="${WHISPER_MODEL_PATH:-}"
whisper_model_choice="${WHISPER_MODEL_CHOICE:-${WHISPER_MODEL:-turbo}}"
whisper_type="srt"
whisper_vad="${WHISPER_VAD:-true}"
whisper_vad_model_path="${WHISPER_VAD_MODEL_PATH:-}"
whisper_vad_model_choice="${WHISPER_VAD_MODEL_CHOICE:-${WHISPER_VAD_MODEL:-auto}}"
whisper_vad_model_dir="${WHISPER_VAD_MODEL_DIR:-$DEFAULT_WHISPER_VAD_MODEL_DIR}"
whisper_subtitle="${SUBTITLE:-false}"
whisper_subtitle_max_words="${WHISPER_SUBTITLE_MAX_WORDS:-$DEFAULT_WHISPER_SUBTITLE_MAX_WORDS}"
whisper_cue_chars="${WHISPER_CUE_CHARS:-$DEFAULT_WHISPER_CUE_CHARS}"

show_help() {
    cat <<EOF
Usage:
  utility/whisper.sh [OPTIONS]... [FILE ...]

Generate .srt subtitle files by default; choose srt or vtt with -t or --type.
Files with an existing output in the selected format are skipped.
Each input is announced as (current/total) before processing.
VAD is enabled by default; use --no-vad to disable it.

Examples:
  utility/whisper.sh video.mp4 audio.mp3
  utility/whisper.sh -l en audio.mp3
  utility/whisper.sh -m large audio.mp3
  utility/whisper.sh -t vtt audio.mp3
  utility/whisper.sh -c 35 audio.mp3
  utility/whisper.sh --no-vad audio.mp3
  utility/whisper.sh --vad-model v5.1.2 audio.mp3

Model selection:
  Default: turbo
    -m, --model turbo
    $TURBO_WHISPER_MODEL

  Large model:
    -m, --model large
    $LARGE_WHISPER_MODEL

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

Options:
  -l, --lang CODE                      Spoken language; default: ko
  -m, --model CHOICE                   large or turbo; default: turbo
  -t, --type FORMAT                    Subtitle format: srt or vtt; default: srt
  -c, --cue CHARS                      Maximum characters per subtitle cue; default: $whisper_cue_chars (minimum: 19)
      --model-path PATH                Explicit Whisper model file path
      --subtitle-max-words N           Maximum words per subtitle line; 0 disables; default: 7
      --vad                            Enable VAD; false/no/off/0 disables it
      --no-vad                         Disable VAD
      --vad-model CHOICE               auto, v6.2.0, v5.1.2, or a model path; default: auto
      --vad-model-path PATH            Explicit VAD model file path
      --vad-model-dir DIR              Directory scanned by auto; default: $DEFAULT_WHISPER_VAD_MODEL_DIR
      --subtitle [true|false]          Mux the selected subtitle format into MP4 as mov_text
      --no-subtitle                    Disable MP4 subtitle muxing
  -h, --help                           Show this help message

Legacy env vars (still supported):
  WHISPER_MODEL, WHISPER_MODEL_CHOICE, WHISPER_MODEL_PATH, WHISPER_VAD,
  WHISPER_VAD_MODEL, WHISPER_VAD_MODEL_CHOICE, WHISPER_VAD_MODEL_PATH, WHISPER_VAD_MODEL_DIR,
  WHISPER_SUBTITLE_MAX_WORDS, WHISPER_CUE_CHARS, lang, SUBTITLE

AAC decode errors:
  If ffmpeg fails while decoding corrupt AAC packets, whisper.sh retries the
  audio conversion with ffmpeg corruption-tolerance flags.
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
            -l | --lang)
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
            -m | --model)
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
            -t | --type)
                if [[ $# -lt 2 || "${2:0:1}" == "-" ]]; then
                    echo "Missing value for $1" >&2
                    exit 1
                fi
                whisper_type="$2"
                shift 2
                ;;
            --type=*)
                whisper_type="${1#*=}"
                shift
                ;;
            -c | --cue)
                if [[ $# -lt 2 || "${2:0:1}" == "-" ]]; then
                    echo "Missing value for $1" >&2
                    exit 1
                fi
                whisper_cue_chars="$2"
                shift 2
                ;;
            --cue=*)
                whisper_cue_chars="${1#*=}"
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
            --vad-model)
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

if ! [[ "$whisper_cue_chars" =~ ^[0-9]+$ ]] || (( whisper_cue_chars < 19 )); then
    echo "Invalid cue length: ${whisper_cue_chars}. Use an integer of at least 19." >&2
    exit 2
fi

case "$whisper_type" in
    srt | vtt)
        ;;
    *)
        echo "Invalid subtitle type: ${whisper_type}. Use srt or vtt." >&2
        exit 2
        ;;
esac

if [[ $(uname -s) != "Darwin" ]]; then
    echo "whisper.sh is only supported on macOS." >&2
    exit 0
fi

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

resolve_input_files() {
    local input_file
    local input_path
    local absolute_path
    local -a absolute_input_files=()

    if ! command -v realpath > /dev/null 2>&1; then
        echo "realpath is required to resolve input file paths." >&2
        return 127
    fi

    for input_file in "${INPUT_FILES[@]}"; do
        input_path="$input_file"
        if [[ "$input_path" != /* ]]; then
            input_path="./$input_path"
        fi

        if ! absolute_path="$(realpath "$input_path")"; then
            echo "Could not resolve input file: $input_file" >&2
            return 1
        fi
        absolute_input_files+=("$absolute_path")
    done

    INPUT_FILES=("${absolute_input_files[@]}")
}

resolve_input_files

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

normalize_subtitle_phrase_length() {
    local subtitle_file="$1"
    local subtitle_type="$2"
    local max_words="${3:-$DEFAULT_WHISPER_SUBTITLE_MAX_WORDS}"
    local temp_file="${subtitle_file}.words.$$"

    [[ "$max_words" =~ ^[1-9][0-9]*$ ]] || return 0

    LC_ALL=C awk -v max_words="$max_words" -v subtitle_type="$subtitle_type" '
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
            if (subtitle_type == "vtt" && lines[1] ~ /^WEBVTT([[:space:]].*)?$/) {
                printf "%s\n\n", $0
                next
            }

            if (subtitle_type == "srt") {
                timing_line = 2
            } else {
                timing_line = 0
                for (i = 1; i <= n; i++) {
                    if (lines[i] ~ /-->/) {
                        timing_line = i
                        break
                    }
                }
            }
            if (timing_line == 0 || n <= timing_line || lines[timing_line] !~ /-->/) {
                printf "%s\n\n", $0
                next
            }

            for (i = 1; i <= timing_line; i++) {
                printf "%s\n", lines[i]
            }
            for (i = timing_line + 1; i <= n; i++) {
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
    ' "$subtitle_file" > "$temp_file" || return 1

    mv -f "$temp_file" "$subtitle_file"
}

normalize_subtitle_cue_length() {
    local subtitle_file="$1"
    local subtitle_type="$2"
    local max_chars="$3"

    python3 - "$subtitle_file" "$subtitle_type" "$max_chars" <<'PY'
import re
import sys
from pathlib import Path

subtitle_path = Path(sys.argv[1])
subtitle_type = sys.argv[2]
max_chars = int(sys.argv[3])
content = subtitle_path.read_text(encoding="utf-8")
content = content.replace("\r\n", "\n").replace("\r", "\n").strip()
blocks = re.split(r"\n[ \t]*\n", content) if content else []
timing_pattern = re.compile(
    r"^\s*(\d{2,}:\d{2}(?::\d{2})?[,.]\d{3})\s*-->\s*"
    r"(\d{2,}:\d{2}(?::\d{2})?[,.]\d{3})(.*)$"
)

def to_milliseconds(value):
    fields = value.replace(",", ".").split(":")
    if len(fields) == 3:
        hours, minutes, seconds = fields
    elif len(fields) == 2:
        hours = "0"
        minutes, seconds = fields
    else:
        raise ValueError(f"Invalid subtitle timestamp: {value}")
    whole_seconds, fraction = seconds.split(".")
    return (
        int(hours) * 3_600_000
        + int(minutes) * 60_000
        + int(whole_seconds) * 1_000
        + int(fraction[:3].ljust(3, "0"))
    )

def from_milliseconds(value):
    hours, value = divmod(value, 3_600_000)
    minutes, value = divmod(value, 60_000)
    seconds, milliseconds = divmod(value, 1_000)
    separator = "." if subtitle_type == "vtt" else ","
    return f"{hours:02}:{minutes:02}:{seconds:02}{separator}{milliseconds:03}"

def split_sentence(sentence):
    pieces = []
    remaining = sentence.strip()
    while len(remaining) > max_chars:
        split_at = remaining.rfind(" ", 0, max_chars + 1)
        if split_at <= 0:
            split_at = max_chars
        pieces.append(remaining[:split_at].strip())
        remaining = remaining[split_at:].strip()
    if remaining:
        pieces.append(remaining)
    return pieces

def split_text(text):
    text = " ".join(text.split())
    if not text:
        return []
    sentences = re.split(r"(?<=[.!?。！？])\s+", text)
    return [
        piece
        for sentence in sentences
        for piece in split_sentence(sentence)
    ]

output_blocks = []
srt_index = 0
for block in blocks:
    lines = block.splitlines()
    timing_index = next(
        (index for index, line in enumerate(lines) if "-->" in line),
        None,
    )
    if timing_index is None:
        output_blocks.append(block)
        continue

    match = timing_pattern.match(lines[timing_index])
    if not match or timing_index + 1 >= len(lines):
        output_blocks.append(block)
        continue

    text = " ".join(line.strip() for line in lines[timing_index + 1:] if line.strip())
    chunks = split_text(text)
    if not chunks:
        output_blocks.append(block)
        continue

    start_ms = to_milliseconds(match.group(1))
    end_ms = max(start_ms, to_milliseconds(match.group(2)))
    duration_ms = end_ms - start_ms
    if len(chunks) > 1 and duration_ms < len(chunks):
        duration_ms = len(chunks)
        end_ms = start_ms + duration_ms

    prefix = lines[:timing_index]
    weights = [max(1, len(chunk)) for chunk in chunks]
    total_weight = sum(weights)
    elapsed_weight = 0
    cue_start = start_ms
    for chunk_index, (chunk, weight) in enumerate(zip(chunks, weights), 1):
        elapsed_weight += weight
        if chunk_index == len(chunks):
            cue_end = end_ms
        else:
            target_end = start_ms + round(duration_ms * elapsed_weight / total_weight)
            remaining_cues = len(chunks) - chunk_index
            cue_end = max(cue_start + 1, min(target_end, end_ms - remaining_cues))

        if subtitle_type == "srt":
            srt_index += 1
            cue_prefix = [str(srt_index)]
        elif len(chunks) > 1 and prefix:
            cue_prefix = [*prefix[:-1], f"{prefix[-1]}-{chunk_index}"]
        else:
            cue_prefix = prefix

        timing = (
            f"{from_milliseconds(cue_start)} --> {from_milliseconds(cue_end)}"
            f"{match.group(3)}"
        )
        output_blocks.append("\n".join([*cue_prefix, timing, chunk]))
        cue_start = cue_end

subtitle_path.write_text("\n\n".join(output_blocks) + ("\n" if output_blocks else ""), encoding="utf-8")
PY
}

run_whisper() {
    local input_file="$1"
    local output_subtitle="$2"
    local generated_subtitle="${input_file}.${whisper_type}"
    local WHISPER_ARGS=(
        "-m" "$WHISPER_MODEL_PATH"
        "--output-${whisper_type}"
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
    mv -v "$generated_subtitle" "$output_subtitle"
    normalize_subtitle_cue_length "$output_subtitle" "$whisper_type" "$whisper_cue_chars"
    normalize_subtitle_phrase_length "$output_subtitle" "$whisper_type" "$whisper_subtitle_max_words"
}

run_ffmpeg_conversion() {
    local source_file="$1"
    local mp3_file="$2"
    local conversion_type="$3"
    local output_existed=0

    [[ -e "$mp3_file" ]] && output_existed=1

    case "$conversion_type" in
        video)
            if ffmpeg -y -i "$source_file" -q:a 0 -map 0:a:0 -af "asetpts=N/SR/TB" "$mp3_file"; then
                return
            fi
            ;;
        m4a)
            if ffmpeg -i "$source_file" -c:v copy -c:a libmp3lame -q:a 4 -af "asetpts=N/SR/TB" "$mp3_file"; then
                return
            fi
            ;;
        aac)
            if ffmpeg -i "$source_file" -af "asetpts=N/SR/TB" -acodec libmp3lame "$mp3_file"; then
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
            ffmpeg -y -fflags +discardcorrupt -err_detect ignore_err -i "$source_file" -q:a 0 -map 0:a:0 -af "asetpts=N/SR/TB" -max_error_rate 1 "$mp3_file"
            ;;
        m4a)
            ffmpeg -y -fflags +discardcorrupt -err_detect ignore_err -i "$source_file" -c:v copy -c:a libmp3lame -q:a 4 -af "asetpts=N/SR/TB" -max_error_rate 1 "$mp3_file"
            ;;
        aac)
            ffmpeg -y -fflags +discardcorrupt -err_detect ignore_err -i "$source_file" -af "asetpts=N/SR/TB" -acodec libmp3lame -max_error_rate 1 "$mp3_file"
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
    local subtitle_file="${stem}.${whisper_type}"
    local mp3_file="${stem}.mp3"

    if [[ -f "$subtitle_file" ]]; then
        return
    fi

    case "$source_file" in
        *.mp4)
            convert_to_mp3 "$source_file" "$mp3_file"
            run_whisper "$mp3_file" "$subtitle_file"
            rm -fv "$mp3_file"

            if [[ "${whisper_subtitle}" == "true" ]]; then
                if [[ ! -s "$subtitle_file" ]]; then
                    rm -fv "$subtitle_file"
                else
                    local tmp_mp4="${stem}.subtitle_tmp.mp4"
                    local existing_subtitle_count
                    existing_subtitle_count="$(ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 "$source_file" | wc -l | tr -d '[:space:]')"
                    local new_subtitle_index="$existing_subtitle_count"

                    ffmpeg -y -i "$source_file" -i "$subtitle_file" -map 0 -map 1 -c:v copy -c:a copy -c:s copy -c:s:"$new_subtitle_index" mov_text -metadata:s:s:"$new_subtitle_index" "language=${whisper_lang}" "$tmp_mp4"
                    mv -fv "$tmp_mp4" "$source_file"
                    rm -fv "$subtitle_file"
                fi
            fi
            ;;
        *.avi | *.mkv | *.m4a | *.aac)
            convert_to_mp3 "$source_file" "$mp3_file"
            run_whisper "$mp3_file" "$subtitle_file"
            rm -fv "$mp3_file"
            ;;
        *.mp3)
            run_whisper "$source_file" "$subtitle_file"
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
