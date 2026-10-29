#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_NEMO_BIN="${HOME}/.local/bin/nemo-speech"
readonly DEFAULT_NEMO_VAD_MODEL="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model/ggml-silero-v6.2.0.bin"
readonly DEFAULT_NEMO_NMT_MODEL="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/translation-model/Riva-Translate-4B-Instruct-v2-Q4_K_M.gguf"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nemo_helper="/Users/fumire/.dotfiles/utility/nemo.py"

nemo_bin="${NEMO_BIN:-$DEFAULT_NEMO_BIN}"
asr_model="${NEMO_MODEL:-nemotron-3.5}"
diar_model="${NEMO_DIAR_MODEL:-nemotron-3-diarization}"
vad_model="${NEMO_VAD_MODEL:-$DEFAULT_NEMO_VAD_MODEL}"
nmt_model="${NEMO_NMT_MODEL:-$DEFAULT_NEMO_NMT_MODEL}"
language="${NEMO_LANGUAGE:-auto}"
translate_enabled=1
vad_enabled=0
declare -a input_files=()

show_help() {
    cat <<EOF
Usage:
  $(basename "$0") [OPTIONS] MEDIA_FILE [MEDIA_FILE ...]

Convert audio or video inputs to 16 kHz mono PCM WAV, transcribe them, and
write speaker-labeled SRT files beside the inputs. When translation is enabled,
also write a Korean SRT as <name>.ko.srt if the source language is not Korean.
Existing output files are replaced after their new results are ready.

Options:
  --model MODEL          ASR model; default: $asr_model
  --diar-model MODEL     Speaker diarization model; default: $diar_model
  --vad                  Enable VAD with the default model; default: off
  --vad-model PATH       Enable VAD with a specific GGUF model
  --no-vad               Disable VAD
  -t, --translate BOOL   Translate to Korean; true or false (default: true)
  --nmt-model PATH       Translation GGUF model; default: ${nmt_model##*/}
  -l, --language, --lang CODE
                         Language code or prompt; default: $language
  -h, --help             Show this help
  --                     Treat all following arguments as input file paths

Speaker IDs are retained in the source and translated SRT files. Set
--translate false to write only the source SRT. With --language auto, the
detected language in the structured ASR result determines whether translation
is needed. If translation is enabled, the installed transcribe command only
supports --translate-to with text or JSON output. This script translates each
subtitle cue separately so the Korean SRT keeps the original cue times and
speaker labels. Non-English sources are routed through English because
supported Riva-Translate pairs include English.

VAD is off by default. The configured legacy whisper.cpp ggml .bin file is not
accepted by this nemo-speech build. Use --vad-model with a runtime-compatible
GGUF model to enable VAD.

Examples:
  $(basename "$0") meeting.mp4
  $(basename "$0") --language en meeting.m4a
  $(basename "$0") --translate false meeting.wav
  $(basename "$0") --vad-model /path/to/silero-v6.2.0.gguf meeting.wav
  $(basename "$0") --no-vad meeting.mp3
EOF
}

need_value() {
    local option="$1"
    if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
        printf 'Error: %s requires a value.\n' "$option" >&2
        exit 2
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            show_help
            exit 0
            ;;
        --model)
            need_value "$1" "${2:-}"
            asr_model="$2"
            shift 2
            ;;
        --diar-model)
            need_value "$1" "${2:-}"
            diar_model="$2"
            shift 2
            ;;
        --vad)
            vad_enabled=1
            shift
            ;;
        --vad-model)
            need_value "$1" "${2:-}"
            vad_model="$2"
            vad_enabled=1
            shift 2
            ;;
        --no-vad)
            vad_enabled=0
            shift
            ;;
        -t | --translate)
            need_value "$1" "${2:-}"
            case "$2" in
                true)
                    translate_enabled=1
                    ;;
                false)
                    translate_enabled=0
                    ;;
                *)
                    printf 'Error: %s must be either true or false.\n' "$1" >&2
                    exit 2
                    ;;
            esac
            shift 2
            ;;
        --nmt-model)
            need_value "$1" "${2:-}"
            nmt_model="$2"
            shift 2
            ;;
        -l | --language | --lang)
            need_value "$1" "${2:-}"
            language="$2"
            shift 2
            ;;
        --)
            shift
            input_files+=("$@")
            break
            ;;
        --*)
            printf 'Error: unknown option: %s\n' "$1" >&2
            show_help >&2
            exit 2
            ;;
        *)
            input_files+=("$1")
            shift
            ;;
    esac
done

if (( ${#input_files[@]} == 0 )); then
    printf 'Error: no input files were provided.\n\n' >&2
    show_help >&2
    exit 2
fi

for command_name in ffmpeg python3; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Error: required command not found: %s\n' "$command_name" >&2
        exit 127
    fi
done

if [[ ! -x "$nemo_bin" ]]; then
    printf 'Error: nemo-speech executable not found or not executable: %s\n' "$nemo_bin" >&2
    exit 127
fi

if [[ ! -r "$nemo_helper" ]]; then
    printf 'Error: Python helper not found or unreadable: %s\n' "$nemo_helper" >&2
    exit 1
fi

if (( vad_enabled )); then
    python3 "$nemo_helper" check-model \
        --kind vad \
        --nemo-bin "$nemo_bin" \
        --path "$vad_model"
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/nemo.XXXXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT

for input_file in "${input_files[@]}"; do
    if [[ ! -f "$input_file" || ! -r "$input_file" ]]; then
        printf 'Error: input file not found or unreadable: %s\n' "$input_file" >&2
        exit 1
    fi

    input_dir="$(dirname "$input_file")"
    input_name="$(basename "$input_file")"
    stem="${input_name%.*}"
    [[ -n "$stem" ]] || stem="$input_name"

    output_srt="$input_dir/$stem.srt"
    output_ko_srt="$input_dir/$stem.ko.srt"
    wav_file="$work_dir/input.wav"
    json_file="$work_dir/transcript.json"
    temp_srt="$work_dir/transcript.srt"
    cue_metadata="$work_dir/cues.json"
    translation_input="$work_dir/translation-input.txt"
    english_translation="$work_dir/translation-en.txt"
    korean_translation="$work_dir/translation-ko.txt"
    temp_ko_srt="$work_dir/translation.srt"

    printf 'Processing: %s\n' "$input_file"

    ffmpeg -nostdin -hide_banner -loglevel error -y \
        -i "$input_file" \
        -map 0:a:0 -vn \
        -ac 1 -ar 16000 \
        -c:a pcm_s16le \
        "$wav_file"

    nemo_args=(
        transcribe "$wav_file"
        --model "$asr_model"
        --language "$language"
        --format json
        --output "$json_file"
        --force
        --diar-model "$diar_model"
    )
    if (( vad_enabled )); then
        nemo_args+=(--vad-model "$vad_model" --vad-masking)
    fi
    "$nemo_bin" "${nemo_args[@]}"

    python3 "$nemo_helper" build-source \
        --json "$json_file" \
        --srt "$temp_srt" \
        --metadata "$cue_metadata" \
        --translation-input "$translation_input" \
        --language "$language"

    if [[ ! -s "$temp_srt" ]]; then
        printf 'Error: SRT output is empty for input: %s\n' "$input_file" >&2
        exit 1
    fi

    mv -f "$temp_srt" "$output_srt"
    printf 'Saved: %s\n' "$output_srt"

    if (( translate_enabled == 0 )); then
        printf 'Translation is disabled; skipping Korean SRT generation.\n'
        rm -f -- "$wav_file" "$json_file" "$cue_metadata" "$translation_input"
        continue
    fi

    source_language="$(python3 "$nemo_helper" get-language --metadata "$cue_metadata")"
    if [[ "$source_language" == "ko" ]]; then
        printf 'Source language is Korean; no translated SRT will be created.\n'
        rm -f -- "$wav_file" "$json_file" "$cue_metadata" "$translation_input"
        continue
    fi

    if [[ -z "$source_language" ]]; then
        printf 'Error: source language could not be detected; specify a language code with --language.\n' >&2
        exit 1
    fi

    python3 "$nemo_helper" check-model \
        --kind nmt \
        --nemo-bin "$nemo_bin" \
        --path "$nmt_model"

    if [[ "$source_language" == "en" ]]; then
        "$nemo_bin" translate \
            --model "$nmt_model" \
            --from en \
            --to ko \
            --input "$translation_input" \
            --output "$korean_translation" \
            --force
    else
        "$nemo_bin" translate \
            --model "$nmt_model" \
            --from "$source_language" \
            --to en \
            --input "$translation_input" \
            --output "$english_translation" \
            --force

        "$nemo_bin" translate \
            --model "$nmt_model" \
            --from en \
            --to ko \
            --input "$english_translation" \
            --output "$korean_translation" \
            --force
    fi

    python3 "$nemo_helper" build-translation \
        --metadata "$cue_metadata" \
        --translation "$korean_translation" \
        --output "$temp_ko_srt"

    if [[ ! -s "$temp_ko_srt" ]]; then
        printf 'Error: Korean SRT output is empty for input: %s\n' "$input_file" >&2
        exit 1
    fi

    mv -f "$temp_ko_srt" "$output_ko_srt"
    printf 'Saved: %s\n' "$output_ko_srt"

    rm -f -- "$wav_file" "$json_file" "$cue_metadata" "$translation_input" "$english_translation" "$korean_translation"
done
