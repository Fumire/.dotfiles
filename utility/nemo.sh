#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_NEMO_BIN="${HOME}/.local/bin/nemo-speech"
readonly DEFAULT_NEMO_ASR_MODEL_DIR="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/ASR"
readonly NEMO_ASR_MODEL_LARGE="${DEFAULT_NEMO_ASR_MODEL_DIR}/nemotron-3.5-asr-streaming-0.6b.gguf"
readonly NEMO_ASR_MODEL_TURBO="${DEFAULT_NEMO_ASR_MODEL_DIR}/nemotron-3.5-asr-streaming-0.6b.q8_0.gguf"
readonly DEFAULT_NEMO_MODEL="$NEMO_ASR_MODEL_TURBO"
readonly DEFAULT_NEMO_DIAR_MODEL_DIR="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/Diarization"
readonly NEMO_DIAR_MODEL_LARGE="${DEFAULT_NEMO_DIAR_MODEL_DIR}/Nemotron-3-Diarization.gguf"
readonly NEMO_DIAR_MODEL_TURBO="${DEFAULT_NEMO_DIAR_MODEL_DIR}/Nemotron-3-Diarization.q8_0.gguf"
readonly DEFAULT_NEMO_DIAR_MODEL="$NEMO_DIAR_MODEL_TURBO"
readonly DEFAULT_NEMO_VAD_MODEL="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/nemo-speech-model/VAD/ggml-silero-v6.2.0.gguf"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nemo_helper="/Users/fumire/.dotfiles/utility/nemo.py"

nemo_bin="${NEMO_BIN:-$DEFAULT_NEMO_BIN}"
asr_model="${NEMO_MODEL:-$DEFAULT_NEMO_MODEL}"
diar_model="${NEMO_DIAR_MODEL:-$DEFAULT_NEMO_DIAR_MODEL}"
vad_model="${NEMO_VAD_MODEL:-$DEFAULT_NEMO_VAD_MODEL}"
language="${NEMO_LANGUAGE:-auto}"
cue_chars=50
subtitle_type="vtt"
vad_enabled=1
subtitle_enabled=0
force_enabled=0
playbook_enabled=0
declare -a input_files=()

show_help() {
    cat <<EOF
Usage:
  $(basename "$0") [OPTIONS] MEDIA_FILE [MEDIA_FILE ...]

Convert audio or video inputs to 16 kHz mono PCM WAV, transcribe them, and
write speaker-labeled source subtitles beside the inputs as VTT by default.
Use -t or --type to select SRT or VTT.
Inputs with an existing source subtitle are skipped unless -f or --force is
provided. With force enabled, generated subtitle files are replaced.
With -p or --playbook, each generated subtitle also gets a matching timestamp-free
TXT transcript in speaker-turn format. Existing subtitle files are converted before skip.
Each subtitle cue contains no more than one sentence and is limited to $cue_chars
characters including the speaker label. Use -c or --cue to adjust this limit
(minimum: 19 characters). Longer sentences are split at spaces;
when word timestamps are unavailable, sub-cue times are estimated by text length.
The terminal shows an overall tqdm progress bar for the input files and a
per-file transcription bar based on NeMo-Speech's decoded audio position. It
shows the current media time against the full audio duration, elapsed time, and
an ETA based on the transcription rate so far.
The overall ETA is estimated from files completed so far. Skipped files count
as complete. Python package tqdm and the NeMo-Speech ASR SDK libraries
installed alongside nemo-speech are required.
The ASR and diarization defaults are direct paths to local model files; the
script passes these paths to nemo-speech without preparing cache symlinks.
For MP4 inputs, -s or --subtitle adds the generated source subtitle as a soft
subtitle track (mov_text), replaces the input MP4 after a successful remux,
and removes the generated subtitle file. Subtitle muxing is off by default.
With -s or --subtitle, MP4 inputs that already contain a subtitle track are
skipped unless -f or --force is provided. Force replaces the embedded track
with the newly generated source subtitle.

Options:
  -m, --model MODEL      ASR model: large or turbo, or an explicit path/repo;
                         default: turbo (overridden by NEMO_MODEL when set)
                         Large: $NEMO_ASR_MODEL_LARGE
                         Turbo: $NEMO_ASR_MODEL_TURBO
  -d, --diar-model MODEL Speaker model: large or turbo, or an explicit
                         path/repo; default: turbo (overridden by NEMO_DIAR_MODEL)
                         Large: $NEMO_DIAR_MODEL_LARGE
                         Turbo: $NEMO_DIAR_MODEL_TURBO
  --vad MODE             VAD mode: silero or false; default: silero
  --vad-model PATH       Use a custom VAD GGUF model (enables VAD)
  --no-vad               Disable VAD (alias for --vad false)
  -t, --type FORMAT      Subtitle format: srt or vtt; default: $subtitle_type
  -c, --cue CHARS        Maximum subtitle cue length, including speaker label;
                         default: $cue_chars (minimum: 19)
  -f, --force            Regenerate and replace existing source subtitle output
  -p, --playbook         Write timestamp-free TXT transcripts from subtitle files
  -s, --subtitle         Mux generated source subtitles into MP4 inputs
  -l, --language, --lang CODE
                         Language code or prompt; default: $language
  -h, --help             Show this help
  --                     Treat all following arguments as input file paths

Speaker IDs are retained in the generated source subtitle files. Translation
is handled separately: run nemo_translate.sh on an SRT or VTT file. Generated
subtitles include a language comment, which nemo_translate.sh reads; it also
recognizes a .en or .ko filename suffix and accepts --from CODE.

VAD is enabled by default with Silero v6.2.0:
  $DEFAULT_NEMO_VAD_MODEL
Use --vad false to disable it. Set NEMO_VAD_MODEL or use --vad-model PATH to
select another compatible VAD GGUF.

Examples:
  $(basename "$0") meeting.mp4
  $(basename "$0") -m large meeting.mp4
  $(basename "$0") --model turbo meeting.mp4
  $(basename "$0") -d large meeting.mp4
  $(basename "$0") --subtitle meeting.mp4
  $(basename "$0") -s meeting.mp4
  $(basename "$0") --language en meeting.m4a
  $(basename "$0") -l de meeting.mp4
  $(basename "$0") -t srt meeting.mp4
  $(basename "$0") --type vtt meeting.mp4
  $(basename "$0") -c 40 meeting.mp4
  $(basename "$0") -f meeting.mp4
  $(basename "$0") -p meeting.mp4
  $(basename "$0") --vad silero meeting.wav
  $(basename "$0") --vad false meeting.mp3
EOF
}

need_value() {
    local option="$1"
    if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
        printf 'Error: %s requires a value.\n' "$option" >&2
        exit 2
    fi
}

set_asr_model() {
    case "$1" in
        large)
            asr_model="$NEMO_ASR_MODEL_LARGE"
            ;;
        turbo)
            asr_model="$NEMO_ASR_MODEL_TURBO"
            ;;
        *)
            asr_model="$1"
            ;;
    esac
}

set_asr_model "$asr_model"

set_diar_model() {
    case "$1" in
        large | Nemotron-3-Diarization.gguf)
            diar_model="$NEMO_DIAR_MODEL_LARGE"
            ;;
        turbo | Nemotron-3-Diarization.q8_0.gguf)
            diar_model="$NEMO_DIAR_MODEL_TURBO"
            ;;
        *)
            diar_model="$1"
            ;;
    esac
}

set_diar_model "$diar_model"

set_vad_mode() {
    case "$1" in
        silero)
            vad_model="${NEMO_VAD_MODEL:-$DEFAULT_NEMO_VAD_MODEL}"
            vad_enabled=1
            ;;
        false)
            vad_enabled=0
            ;;
        *)
            printf 'Error: --vad must be either silero or false.\n' >&2
            exit 2
            ;;
    esac
}

report_status() {
    local message="$1"
    if (( progress_fd_open )); then
        local encoded
        encoded="$(printf '%s' "$message" | base64 | tr -d '\r\n')"
        printf 'status-base64 %s\n' "$encoded" >&3 || true
    else
        printf '%s\n' "$message"
    fi
}

write_playbook_from_srt() {
    local srt_path="$1"
    local txt_path="${srt_path%.*}.txt"

    python3 "$nemo_helper" build-playbook --subtitle "$srt_path" --output "$txt_path"
    report_status "Saved: $txt_path"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            show_help
            exit 0
            ;;
        -m | --model)
            need_value "$1" "${2:-}"
            set_asr_model "$2"
            shift 2
            ;;
        --model=*)
            model_value="${1#*=}"
            if [[ -z "$model_value" ]]; then
                printf 'Error: --model requires a value.\n' >&2
                exit 2
            fi
            set_asr_model "$model_value"
            shift
            ;;
        -d | --diar-model)
            need_value "$1" "${2:-}"
            set_diar_model "$2"
            shift 2
            ;;
        --diar-model=*)
            diar_model_value="${1#*=}"
            if [[ -z "$diar_model_value" ]]; then
                printf 'Error: --diar-model requires a value.\n' >&2
                exit 2
            fi
            set_diar_model "$diar_model_value"
            shift
            ;;
        --vad)
            need_value "$1" "${2:-}"
            set_vad_mode "$2"
            shift 2
            ;;
        --vad=*)
            vad_choice="${1#*=}"
            if [[ -z "$vad_choice" ]]; then
                printf 'Error: --vad requires either silero or false.\n' >&2
                exit 2
            fi
            set_vad_mode "$vad_choice"
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
        -t | --type)
            need_value "$1" "${2:-}"
            subtitle_type="$2"
            shift 2
            ;;
        --type=*)
            subtitle_type="${1#*=}"
            shift
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

case "$subtitle_type" in
    srt | vtt) ;;
    *)
        printf 'Error: --type must be either srt or vtt.\n' >&2
        exit 2
        ;;
esac

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
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        report_status "$line"
    done < <(sed -E \
        -e '/channel element 0\.0 duplicate/d' \
        -e '/Error submitting packet to decoder: Invalid data found when processing input/d' \
        "$1")
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
        printf 'Error: no generated subtitle files are available to mux into: %s\n' "$source_file" >&2
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
    report_status "Embedded ${#subtitle_files[@]} subtitle track(s) in: $source_file"
    report_status 'Removed generated subtitle files after successful MP4 muxing.'
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

    output_srt="$input_dir/$stem.$subtitle_type"

    if (( subtitle_enabled )) && is_mp4_file "$input_file"; then
        if ! embedded_subtitle_streams="$(
            ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 "$input_file"
        )"; then
            printf 'Error: could not inspect embedded subtitle tracks in: %s\n' "$input_file" >&2
            exit 1
        fi
        if [[ -n "$embedded_subtitle_streams" ]] && (( force_enabled == 0 )); then
            report_status "Skipping: MP4 already contains embedded subtitle track(s): $input_file"
            advance_progress
            continue
        elif [[ -n "$embedded_subtitle_streams" ]]; then
            report_status "Replacing existing embedded subtitle track(s) in: $input_file"
        fi
    fi

    subtitle_candidates=("$output_srt")
    existing_srt_files=()
    for existing_srt in "${subtitle_candidates[@]}"; do
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
        report_status "Skipping: subtitle output already exists (use --force to overwrite): ${existing_srt_files[0]}"
        advance_progress
        continue
    fi

    wav_file="$work_dir/input.wav"
    json_file="$work_dir/transcript.json"
    temp_srt="$work_dir/transcript.$subtitle_type"
    cue_metadata="$work_dir/cues.json"
    translation_input="$work_dir/translation-input.txt"
    ffmpeg_log="$work_dir/ffmpeg-convert.log"

    report_status "Processing: $input_file"

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

    asr_args=(
        transcribe-stream
        --nemo-bin "$nemo_bin"
        --wav "$wav_file"
        --json "$json_file"
        --model "$asr_model"
        --language "$language"
        --diar-model "$diar_model"
    )
    if (( vad_enabled )); then
        asr_args+=(--vad-model "$vad_model")
    fi
    python3 "$nemo_helper" "${asr_args[@]}"

    if python3 "$nemo_helper" build-source \
        --json "$json_file" \
        --subtitle "$temp_srt" \
        --metadata "$cue_metadata" \
        --translation-input "$translation_input" \
        --language "$language" \
        --max-cue-chars "$cue_chars"; then
        :
    else
        helper_status=$?
        if (( helper_status == 3 )); then
            report_status "Warning: no transcript was recognized; skipping subtitle generation and embedding for: $input_file"
            rm -f -- "$temp_srt" "$wav_file" "$json_file" "$cue_metadata" "$translation_input"
            advance_progress
            continue
        fi
        exit "$helper_status"
    fi

    if [[ ! -s "$temp_srt" ]]; then
        printf 'Error: subtitle output is empty for input: %s\n' "$input_file" >&2
        exit 1
    fi

    source_language="$(python3 "$nemo_helper" get-language --metadata "$cue_metadata")"
    case "$source_language" in
        eng) source_language=en ;;
        kor) source_language=ko ;;
    esac
    if [[ -z "$source_language" ]]; then
        source_language=und
    fi
    python3 "$nemo_helper" annotate-subtitle \
        --subtitle "$temp_srt" \
        --language "$source_language"

    mv -f "$temp_srt" "$output_srt"
    report_status "Saved: $output_srt"
    if (( playbook_enabled )); then
        write_playbook_from_srt "$output_srt"
    fi

    if (( subtitle_enabled )); then
        if is_mp4_file "$input_file"; then
            mux_subtitles_into_mp4 "$input_file" "$output_srt" "$source_language"
        else
            report_status "Subtitle muxing applies only to MP4 inputs; keeping subtitle files for: $input_file"
        fi
    fi

    rm -f -- "$wav_file" "$json_file" "$cue_metadata" "$translation_input"
    advance_progress
done
