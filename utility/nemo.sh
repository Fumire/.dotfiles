#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_NEMO_BIN="${HOME}/.local/bin/nemo-speech"
readonly DEFAULT_NEMO_MODEL="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/nemotron-3.5-asr-streaming-0.6b/1c8deaecc64b91f034d73e08dd8b64625eb3395d/nemotron-3.5-asr-streaming-0.6b.q8_0.gguf"
readonly DEFAULT_NEMO_DIAR_MODEL="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/Nemotron-3-Diarization/f667ed73aee57d40cc39428eb768b4fd87a0a29e/Nemotron-3-Diarization.q8_0.gguf"
readonly DEFAULT_NEMO_VAD_MODEL="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/vad-model/ggml-silero-v6.2.0.bin"
readonly DEFAULT_NEMO_NMT_MODEL="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/translation-model/Riva-Translate-4B-Instruct-v2-Q4_K_M.gguf"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nemo_helper="/Users/fumire/.dotfiles/utility/nemo.py"

nemo_bin="${NEMO_BIN:-$DEFAULT_NEMO_BIN}"
asr_model="${NEMO_MODEL:-$DEFAULT_NEMO_MODEL}"
diar_model="${NEMO_DIAR_MODEL:-$DEFAULT_NEMO_DIAR_MODEL}"
vad_model="${NEMO_VAD_MODEL:-$DEFAULT_NEMO_VAD_MODEL}"
nmt_model="${NEMO_NMT_MODEL:-$DEFAULT_NEMO_NMT_MODEL}"
language="${NEMO_LANGUAGE:-auto}"
translate_enabled=1
cue_chars=50
vad_enabled=0
subtitle_enabled=0
force_enabled=0
playbook_enabled=0
declare -a input_files=()

show_help() {
    cat <<EOF
Usage:
  $(basename "$0") [OPTIONS] MEDIA_FILE [MEDIA_FILE ...]

Convert audio or video inputs to 16 kHz mono PCM WAV, transcribe them, and
write speaker-labeled source SRT files beside the inputs. With translation
enabled, English sources also get <name>.ko.srt, Korean sources get
<name>.en.srt, and other sources get both <name>.en.srt and <name>.ko.srt.
Inputs with an existing source or translated SRT are skipped unless -f or
--force is provided. With force enabled, generated SRT files are replaced.
With -p or --playbook, each generated SRT also gets a matching timestamp-free
TXT transcript in speaker-turn format. Existing SRTs are converted before skip.
Each subtitle cue contains no more than one sentence and is limited to $cue_chars
characters including the speaker label. Use -c or --cue to adjust this limit
(minimum: 19 characters). Longer sentences are split at spaces;
when word timestamps are unavailable, sub-cue times are estimated by text length.
The terminal shows an overall tqdm progress bar for the input files and a
per-file transcription status with a live spinner and elapsed time. The overall
ETA is estimated from files completed so far. Skipped files count as complete.
The installed nemo-speech CLI does not report an ASR percentage, so the per-file
status reports activity and elapsed time. Python package tqdm is required.
The ASR and diarization defaults are direct paths to local model folders; the
script passes these paths to nemo-speech without preparing cache symlinks.
For MP4 inputs, -s or --subtitle adds the generated source and translated SRTs as
soft subtitle tracks (mov_text), replaces the input MP4 after a successful
remux, and removes those generated SRT files. Subtitle muxing is off by default.
With -s or --subtitle, MP4 inputs that already contain a subtitle track are
skipped unless -f or --force is provided. Force replaces the embedded tracks
with the newly generated source and translated subtitle tracks.

Options:
  --model MODEL          ASR model; default: $asr_model
  --diar-model MODEL     Speaker diarization model; default: $diar_model
  --vad                  Enable VAD with the default model; default: off
  --vad-model PATH       Enable VAD with a specific GGUF model
  --no-vad               Disable VAD
  -c, --cue CHARS        Maximum SRT cue length, including speaker label;
                         default: $cue_chars (minimum: 19)
  -t, --translate BOOL   Generate translated SRTs; true or false (default: true)
  -f, --force            Regenerate and replace existing SRT outputs
  -p, --playbook         Write timestamp-free TXT transcripts from SRT files
  --nmt-model PATH       Translation GGUF model; default: ${nmt_model##*/}
  -s, --subtitle         Mux generated SRTs into MP4 inputs when provided
  -l, --language, --lang CODE
                         Language code or prompt; default: $language
  -h, --help             Show this help
  --                     Treat all following arguments as input file paths

Speaker IDs are retained in the source and translated SRT files. Set
--translate false to skip translated SRT generation. With --language auto, the
detected language in the structured ASR result determines whether translation
is needed. If translation is enabled, this script translates each subtitle cue separately
so translated SRTs keep the original cue times and speaker labels. If a translated
cue needs splitting for the selected cue limit, its time span is divided by text length. Sources
other than English or Korean are translated to both English and Korean through
English because supported Riva-Translate pairs include English.
English and Korean sources receive the other language when translation is enabled.
With -s or --subtitle, the source language and any generated English and Korean
translations are embedded as separate MP4 subtitle tracks. Existing video and
audio streams are preserved, and generated sidecar SRT files are removed after a
successful mux. MP4 inputs with embedded subtitles are skipped unless --force is
provided; force replaces those tracks with the generated subtitle tracks.

VAD is off by default. The configured legacy whisper.cpp ggml .bin file is not
accepted by this nemo-speech build. Use --vad-model with a runtime-compatible
GGUF model to enable VAD.

Examples:
  $(basename "$0") meeting.mp4
  $(basename "$0") --subtitle meeting.mp4
  $(basename "$0") -s meeting.mp4
  $(basename "$0") --language en meeting.m4a
  $(basename "$0") -l de meeting.mp4
  $(basename "$0") --translate false meeting.wav
  $(basename "$0") -c 40 meeting.mp4
  $(basename "$0") -f meeting.mp4
  $(basename "$0") -p meeting.mp4
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

write_playbook_from_srt() {
    local srt_path="$1"
    local txt_path="${srt_path%.srt}.txt"

    python3 "$nemo_helper" build-playbook --srt "$srt_path" --output "$txt_path"
    printf 'Saved: %s\n' "$txt_path"
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
        -f | --force)
            force_enabled=1
            shift
            ;;
        --force=*)
            printf 'Error: --force is a flag and does not take a value.\n' >&2
            exit 2
            ;;
        -p | --playbook)
            if [[ "${2:-}" == true || "${2:-}" == false ]]; then
                printf 'Error: --playbook is a flag and does not take a value.\n' >&2
                exit 2
            fi
            playbook_enabled=1
            shift
            ;;
        --playbook=*)
            printf 'Error: --playbook is a flag and does not take a value.\n' >&2
            exit 2
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
        -c | --cue)
            need_value "$1" "${2:-}"
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                printf 'Error: %s must be an integer greater than or equal to 19.\n' "$1" >&2
                exit 2
            fi
            cue_chars="$2"
            shift 2
            ;;
        --nmt-model)
            need_value "$1" "${2:-}"
            nmt_model="$2"
            shift 2
            ;;
        -s | --subtitle)
            if [[ "${2:-}" == true || "${2:-}" == false ]]; then
                printf 'Error: --subtitle is a flag and does not take a value.\n' >&2
                exit 2
            fi
            subtitle_enabled=1
            shift
            ;;
        --subtitle=*)
            printf 'Error: --subtitle is a flag and does not take a value.\n' >&2
            exit 2
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

if (( subtitle_enabled )) && ! command -v ffprobe >/dev/null 2>&1; then
    printf 'Error: required command not found: ffprobe\n' >&2
    exit 127
fi

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

if ! python3 -c 'import sys; sys.exit(0 if int(sys.argv[1]) >= 19 else 1)' "$cue_chars" >/dev/null 2>&1; then
    printf 'Error: --cue must be an integer greater than or equal to 19.\n' >&2
    exit 2
fi

if ! python3 -c 'import tqdm' >/dev/null 2>&1; then
    printf 'Error: Python package tqdm is required; install it with: python3 -m pip install tqdm\n' >&2
    exit 1
fi

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
subtitle_tmp_file=""
filter_ffmpeg_diagnostics() {
    sed -E \
        -e '/channel element 0\.0 duplicate/d' \
        -e '/Error submitting packet to decoder: Invalid data found when processing input/d' \
        "$1" >&2
}

progress_fifo="$work_dir/progress.fifo"
progress_pid=""
progress_fd_open=0
stop_progress() {
    if (( progress_fd_open )); then
        exec 3>&- || true
        progress_fd_open=0
    fi
    if [[ -n "$progress_pid" ]]; then
        wait "$progress_pid" 2>/dev/null || true
        progress_pid=""
    fi
    if [[ -n "$progress_fifo" ]]; then
        rm -f -- "$progress_fifo"
        progress_fifo=""
    fi
}
cleanup() {
    stop_progress
    if [[ -n "$subtitle_tmp_file" ]]; then
        rm -f -- "$subtitle_tmp_file"
    fi
    rm -rf -- "$work_dir"
}
trap cleanup EXIT

start_progress() {
    if ! mkfifo "$progress_fifo"; then
        printf 'Error: could not create the progress pipe.\n' >&2
        return 1
    fi
    python3 "$nemo_helper" progress --total "${#input_files[@]}" <"$progress_fifo" &
    progress_pid=$!
    exec 3>"$progress_fifo"
    progress_fd_open=1
    rm -f -- "$progress_fifo"
    progress_fifo=""
}

advance_progress() {
    if (( progress_fd_open )); then
        printf '1\n' >&3 || true
    fi
}

start_transcription_progress() {
    if (( progress_fd_open )); then
        printf 'asr-start\n' >&3 || true
    fi
}

stop_transcription_progress() {
    if (( progress_fd_open )); then
        printf 'asr-stop\n' >&3 || true
    fi
}

is_mp4_file() {
    case "$1" in
        *.[mM][pP]4) return 0 ;;
        *) return 1 ;;
    esac
}

mux_subtitles_into_mp4() {
    local source_file="$1"
    shift
    local -a subtitle_files=()
    local -a subtitle_languages=()
    local -a ffmpeg_args=()
    local existing_subtitle_count
    local subtitle_index
    local source_mode
    local input_index=1
    local i
    local input_dir
    local input_name

    while (( $# >= 2 )); do
        subtitle_files+=("$1")
        subtitle_languages+=("$2")
        shift 2
    done

    if (( ${#subtitle_files[@]} == 0 )); then
        printf 'Error: no generated SRT files are available to mux into: %s\n' "$source_file" >&2
        return 1
    fi

    for i in "${!subtitle_files[@]}"; do
        if [[ ! -s "${subtitle_files[$i]}" ]]; then
            printf 'Error: generated subtitle file is missing or empty: %s\n' "${subtitle_files[$i]}" >&2
            return 1
        fi
    done

    if ! existing_subtitle_count="$(
        ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 "$source_file" \
            | awk 'END { print NR + 0 }'
    )"; then
        printf 'Error: could not inspect existing subtitle tracks in: %s\n' "$source_file" >&2
        return 1
    fi

    input_dir="$(dirname "$source_file")"
    input_name="$(basename "$source_file")"
    if source_mode="$(stat -f '%Lp' "$source_file" 2>/dev/null)"; then
        :
    elif source_mode="$(stat -c '%a' "$source_file" 2>/dev/null)"; then
        :
    else
        printf 'Error: could not read file permissions for: %s\n' "$source_file" >&2
        return 1
    fi

    if ! subtitle_tmp_file="$(mktemp "${input_dir}/.${input_name}.subtitle_tmp.XXXXXXXX")"; then
        printf 'Error: could not create a temporary MP4 beside: %s\n' "$source_file" >&2
        return 1
    fi

    ffmpeg_args=(-nostdin -hide_banner -loglevel error -y -i "$source_file")
    for i in "${!subtitle_files[@]}"; do
        ffmpeg_args+=(-i "${subtitle_files[$i]}")
    done

    if (( force_enabled )); then
        if (( existing_subtitle_count > 0 )); then
            ffmpeg_args+=(-map 0 -map -0:s)
        else
            ffmpeg_args+=(-map 0)
        fi
        existing_subtitle_count=0
    else
        ffmpeg_args+=(-map 0)
    fi
    for ((i = 0; i < ${#subtitle_files[@]}; i++)); do
        ffmpeg_args+=(-map "${input_index}:0")
        input_index=$((input_index + 1))
    done

    ffmpeg_args+=(-c:v copy -c:a copy -c:s copy)
    for i in "${!subtitle_files[@]}"; do
        subtitle_index=$((existing_subtitle_count + i))
        ffmpeg_args+=("-c:s:${subtitle_index}" mov_text)
        ffmpeg_args+=("-metadata:s:s:${subtitle_index}" "language=${subtitle_languages[$i]}")
    done
    ffmpeg_args+=(-f mp4 "$subtitle_tmp_file")

    if ! ffmpeg "${ffmpeg_args[@]}"; then
        printf 'Error: failed to mux subtitle tracks into: %s\n' "$source_file" >&2
        return 1
    fi

    if ! chmod "$source_mode" "$subtitle_tmp_file"; then
        printf 'Error: could not preserve file permissions for: %s\n' "$source_file" >&2
        return 1
    fi

    if ! mv -f -- "$subtitle_tmp_file" "$source_file"; then
        printf 'Error: could not replace the input MP4 with its subtitle-enabled version: %s\n' "$source_file" >&2
        return 1
    fi
    subtitle_tmp_file=""

    rm -f -- "${subtitle_files[@]}"
    printf 'Embedded %d subtitle track(s) in: %s\n' "${#subtitle_files[@]}" "$source_file"
    printf 'Removed generated SRT files after successful MP4 muxing.\n'
}

start_progress

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
    output_en_srt="$input_dir/$stem.en.srt"
    output_ko_srt="$input_dir/$stem.ko.srt"

    if (( subtitle_enabled )) && is_mp4_file "$input_file"; then
        if ! embedded_subtitle_streams="$(
            ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 "$input_file"
        )"; then
            printf 'Error: could not inspect embedded subtitle tracks in: %s\n' "$input_file" >&2
            exit 1
        fi
        if [[ -n "$embedded_subtitle_streams" ]] && (( force_enabled == 0 )); then
            printf 'Skipping: MP4 already contains embedded subtitle track(s): %s\n' "$input_file"
            advance_progress
            continue
        elif [[ -n "$embedded_subtitle_streams" ]]; then
            printf 'Replacing existing embedded subtitle track(s) in: %s\n' "$input_file"
        fi
    fi

    existing_srt_files=()
    for existing_srt in "$output_srt" "$output_en_srt" "$output_ko_srt"; do
        if [[ -e "$existing_srt" || -L "$existing_srt" ]]; then
            existing_srt_files+=("$existing_srt")
        fi
    done
    if (( force_enabled == 0 && ${#existing_srt_files[@]} > 0 )); then
        if (( playbook_enabled )); then
            for existing_srt in "${existing_srt_files[@]}"; do
                write_playbook_from_srt "$existing_srt"
            done
        fi
        printf 'Skipping: SRT output already exists (use --force to overwrite): %s\n' "${existing_srt_files[0]}"
        advance_progress
        continue
    fi

    wav_file="$work_dir/input.wav"
    json_file="$work_dir/transcript.json"
    temp_srt="$work_dir/transcript.srt"
    cue_metadata="$work_dir/cues.json"
    translation_input="$work_dir/translation-input.txt"
    english_translation="$work_dir/translation-en.txt"
    korean_translation="$work_dir/translation-ko.txt"
    temp_en_srt="$work_dir/translation-en.srt"
    temp_ko_srt="$work_dir/translation-ko.srt"
    ffmpeg_log="$work_dir/ffmpeg-convert.log"

    printf 'Processing: %s\n' "$input_file"

    if ffmpeg -nostdin -hide_banner -loglevel error -y \
        -i "$input_file" \
        -map 0:a:0 -vn \
        -ac 1 -ar 16000 \
        -c:a pcm_s16le \
        "$wav_file" 2>"$ffmpeg_log"; then
        filter_ffmpeg_diagnostics "$ffmpeg_log"
    else
        ffmpeg_status=$?
        filter_ffmpeg_diagnostics "$ffmpeg_log"
        printf 'Error: ffmpeg failed to convert input audio: %s\n' "$input_file" >&2
        exit "$ffmpeg_status"
    fi

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
    start_transcription_progress
    "$nemo_bin" "${nemo_args[@]}"
    stop_transcription_progress

    if python3 "$nemo_helper" build-source \
        --json "$json_file" \
        --srt "$temp_srt" \
        --metadata "$cue_metadata" \
        --translation-input "$translation_input" \
        --language "$language" \
        --max-cue-chars "$cue_chars"; then
        :
    else
        helper_status=$?
        if (( helper_status == 3 )); then
            printf 'Warning: no transcript was recognized; skipping SRT generation and subtitle embedding for: %s\n' "$input_file"
            rm -f -- "$temp_srt" "$wav_file" "$json_file" "$cue_metadata" "$translation_input"
            advance_progress
            continue
        fi
        exit "$helper_status"
    fi

    if [[ ! -s "$temp_srt" ]]; then
        printf 'Error: SRT output is empty for input: %s\n' "$input_file" >&2
        exit 1
    fi

    mv -f "$temp_srt" "$output_srt"
    printf 'Saved: %s\n' "$output_srt"
    if (( playbook_enabled )); then
        write_playbook_from_srt "$output_srt"
    fi

    source_language="$(python3 "$nemo_helper" get-language --metadata "$cue_metadata")"
    case "$source_language" in
        eng) source_language=en ;;
        kor) source_language=ko ;;
    esac
    if [[ -z "$source_language" ]]; then
        if (( translate_enabled )); then
            printf 'Error: source language could not be detected; specify a language code with --language.\n' >&2
            exit 1
        fi
        source_language=und
    fi

    declare -a generated_srt_files=("$output_srt")
    declare -a generated_srt_languages=("$source_language")

    if (( translate_enabled == 0 )); then
        printf 'Translation is disabled; skipping translated SRT generation.\n'
        if (( subtitle_enabled )); then
            if is_mp4_file "$input_file"; then
                mux_subtitles_into_mp4 "$input_file" "$output_srt" "$source_language"
            else
                printf 'Subtitle muxing applies only to MP4 inputs; keeping SRT files for: %s\n' "$input_file"
            fi
        fi
        rm -f -- "$wav_file" "$json_file" "$cue_metadata" "$translation_input"
        advance_progress
        continue
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
        python3 "$nemo_helper" build-translation \
            --metadata "$cue_metadata" \
            --translation "$korean_translation" \
            --output "$temp_ko_srt" \
            --max-cue-chars "$cue_chars"

        if [[ ! -s "$temp_ko_srt" ]]; then
            printf 'Error: Korean SRT output is empty for input: %s\n' "$input_file" >&2
            exit 1
        fi

        mv -f "$temp_ko_srt" "$output_ko_srt"
        printf 'Saved: %s\n' "$output_ko_srt"
        if (( playbook_enabled )); then
            write_playbook_from_srt "$output_ko_srt"
        fi
        generated_srt_files+=("$output_ko_srt")
        generated_srt_languages+=(ko)
    elif [[ "$source_language" == "ko" ]]; then
        "$nemo_bin" translate \
            --model "$nmt_model" \
            --from ko \
            --to en \
            --input "$translation_input" \
            --output "$english_translation" \
            --force

        python3 "$nemo_helper" build-translation \
            --metadata "$cue_metadata" \
            --translation "$english_translation" \
            --output "$temp_en_srt" \
            --max-cue-chars "$cue_chars"

        if [[ ! -s "$temp_en_srt" ]]; then
            printf 'Error: English SRT output is empty for input: %s\n' "$input_file" >&2
            exit 1
        fi

        mv -f "$temp_en_srt" "$output_en_srt"
        printf 'Saved: %s\n' "$output_en_srt"
        if (( playbook_enabled )); then
            write_playbook_from_srt "$output_en_srt"
        fi
        generated_srt_files+=("$output_en_srt")
        generated_srt_languages+=(en)
    else
        "$nemo_bin" translate \
            --model "$nmt_model" \
            --from "$source_language" \
            --to en \
            --input "$translation_input" \
            --output "$english_translation" \
            --force

        python3 "$nemo_helper" build-translation \
            --metadata "$cue_metadata" \
            --translation "$english_translation" \
            --output "$temp_en_srt" \
            --max-cue-chars "$cue_chars"

        if [[ ! -s "$temp_en_srt" ]]; then
            printf 'Error: English SRT output is empty for input: %s\n' "$input_file" >&2
            exit 1
        fi

        "$nemo_bin" translate \
            --model "$nmt_model" \
            --from en \
            --to ko \
            --input "$english_translation" \
            --output "$korean_translation" \
            --force

        python3 "$nemo_helper" build-translation \
            --metadata "$cue_metadata" \
            --translation "$korean_translation" \
            --output "$temp_ko_srt" \
            --max-cue-chars "$cue_chars"

        if [[ ! -s "$temp_ko_srt" ]]; then
            printf 'Error: Korean SRT output is empty for input: %s\n' "$input_file" >&2
            exit 1
        fi

        mv -f "$temp_en_srt" "$output_en_srt"
        mv -f "$temp_ko_srt" "$output_ko_srt"
        printf 'Saved: %s\n' "$output_en_srt"
        printf 'Saved: %s\n' "$output_ko_srt"
        if (( playbook_enabled )); then
            write_playbook_from_srt "$output_en_srt"
            write_playbook_from_srt "$output_ko_srt"
        fi
        generated_srt_files+=("$output_en_srt" "$output_ko_srt")
        generated_srt_languages+=(en ko)
    fi

    if (( subtitle_enabled )); then
        if is_mp4_file "$input_file"; then
            subtitle_mux_args=()
            for i in "${!generated_srt_files[@]}"; do
                subtitle_mux_args+=("${generated_srt_files[$i]}" "${generated_srt_languages[$i]}")
            done
            mux_subtitles_into_mp4 "$input_file" "${subtitle_mux_args[@]}"
        else
            printf 'Subtitle muxing applies only to MP4 inputs; keeping SRT files for: %s\n' "$input_file"
        fi
    fi

    rm -f -- "$wav_file" "$json_file" "$cue_metadata" "$translation_input" "$english_translation" "$korean_translation"
    advance_progress
done
