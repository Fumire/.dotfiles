#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly DEFAULT_NEMO_BIN="${HOME}/.local/bin/nemo-speech"
readonly DEFAULT_NMT_MODEL="/Users/fumire/Library/CloudStorage/Dropbox/31_AI/translation-model/Riva-Translate-4B-Instruct-v2-Q4_K_M.gguf"
nemo_bin="${NEMO_BIN:-$DEFAULT_NEMO_BIN}"
nmt_model="${NEMO_NMT_MODEL:-$DEFAULT_NMT_MODEL}"
nemo_helper="/Users/fumire/.dotfiles/utility/nemo.py"
source_language_option=""
target_mode="auto"
max_cue_chars=50
force_enabled=0
declare -a input_files=()

show_help() {
    cat <<EOF
Usage:
  $(basename "$0") [OPTIONS] SUBTITLE_FILE [SUBTITLE_FILE ...]

Translate SRT or WebVTT subtitle files. Outputs keep the input format and cue
timing and are saved beside the input as <name>.en.srt, <name>.ko.vtt, etc.
Existing translated output files are skipped by default.

The source language is read from a nemo:language comment when present, then
inferred from a filename ending in .en or .ko. For other filenames, provide
--from CODE. Files marked as translated by nemo_translate.sh are always skipped.
English inputs produce Korean by default, Korean inputs produce English, and
other source languages produce both English and Korean through English.

Options:
  -l, --from CODE        Source language; overrides file comment and filename
                         inference
  -t, --to LANGUAGE      auto, en, ko, or both; default: auto
  -m, --nmt-model PATH   Translation GGUF model; default: ${nmt_model##*/}
  -c, --cue CHARS        Maximum translated cue length; default: $max_cue_chars
  -f, --force            Replace existing translated subtitle files (default: skip)
  -h, --help             Show this help
  --                     Treat all following arguments as input file paths

Set NEMO_BIN or NEMO_NMT_MODEL to override the executable or model.

Examples:
  $(basename "$0") --from en meeting.vtt
  $(basename "$0") --from ko meeting.srt
  $(basename "$0") --from ja --to both meeting.srt
  $(basename "$0") meeting.en.vtt
  $(basename "$0") -f --to en meeting.ko.srt
EOF
}

need_value() {
    if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
        printf 'Error: %s requires a value.\n' "$1" >&2
        exit 2
    fi
}

normalize_language() {
    local value
    value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$value" in
        eng) value=en ;;
        kor) value=ko ;;
    esac
    printf '%s' "$value"
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

subtitle_tool() {
    python3 - "$nemo_helper" "$@" <<'PY'
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]).parent))
import nemo

time_line = re.compile(
    r"^\s*((?:\d+:)?\d{2}:\d{2}[,.]\d{3})\s*-->\s*"
    r"((?:\d+:)?\d{2}:\d{2}[,.]\d{3})(?:[ \t]+.*)?\s*$"
)

def seconds(value):
    pieces = value.replace(",", ".").split(":")
    if len(pieces) == 3:
        hours, minutes, secs = pieces
    elif len(pieces) == 2:
        hours = 0
        minutes, secs = pieces
    else:
        raise ValueError(f"Unsupported timestamp: {value}")
    return int(hours) * 3600 + int(minutes) * 60 + float(secs)

def parse_subtitle(source_path, metadata_path, text_path):
    try:
        content = Path(source_path).read_text(encoding="utf-8-sig")
    except (OSError, UnicodeError) as exc:
        raise ValueError(f"Could not read subtitle file {source_path}: {exc}") from exc
    cues = []
    source_language = ""
    translated = False
    for block in re.split(r"\r?\n[ \t]*\r?\n", content.strip()):
        lines = block.splitlines()
        position = next((i for i, line in enumerate(lines) if time_line.match(line)), None)
        if position is None:
            for line in lines:
                marker = line.strip()
                if marker.lower().startswith("note "):
                    marker = marker[5:].strip()
                lowered = marker.lower()
                if lowered.startswith("nemo:language="):
                    source_language = marker.split("=", 1)[1].strip()
                elif lowered == "nemo:translated-by=nemo_translate.sh":
                    translated = True
            continue
        match = time_line.match(lines[position])
        start, end = seconds(match.group(1)), seconds(match.group(2))
        if end < start:
            raise ValueError(f"A cue ends before it starts in {source_path}")
        text = " ".join(line.strip() for line in lines[position + 1:] if line.strip())
        if not text:
            continue
        prefix = ""
        speaker = re.match(r"^(\[[^\]\r\n]+\][ \t]*)", text)
        if speaker:
            prefix = speaker.group(1)
            text = text[len(prefix):].strip()
        if text:
            cues.append({"start": start, "end": end, "prefix": prefix, "text": text})
    if not cues:
        raise ValueError(f"No timestamped subtitle cues were found in: {source_path}")
    Path(metadata_path).write_text(
        json.dumps(
            {
                "cues": cues,
                "source_language": source_language,
                "translated": translated,
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    Path(text_path).write_text("".join(cue["text"] + "\n" for cue in cues), encoding="utf-8")

def print_subtitle_metadata(metadata_path):
    metadata = json.loads(Path(metadata_path).read_text(encoding="utf-8"))
    language = metadata.get("source_language") or ""
    translated = "1" if metadata.get("translated") else "0"
    print(f"{language}\t{translated}")

def build_subtitle(metadata_path, translation_path, output_path, max_chars):
    metadata = json.loads(Path(metadata_path).read_text(encoding="utf-8"))
    translations = Path(translation_path).read_text(encoding="utf-8").splitlines()
    cues = metadata.get("cues", [])
    if not cues or len(translations) != len(cues):
        raise ValueError("The translated cue count does not match the source subtitle.")
    records = []
    for cue, translated in zip(cues, translations):
        translated = translated.strip() or cue["text"]
        prefix = cue["prefix"]
        pieces = nemo.split_subtitle_text(translated, max(1, max_chars - len(prefix)))
        if not pieces:
            pieces = [cue["text"]]
        weights = [max(1, len(piece)) for piece in pieces]
        total = sum(weights)
        elapsed = 0
        duration = max(0.0, cue["end"] - cue["start"])
        for piece, weight in zip(pieces, weights):
            start = cue["start"] + duration * elapsed / total
            elapsed += weight
            end = cue["start"] + duration * elapsed / total
            start_text = nemo.timestamp(start)
            end_text = nemo.timestamp(max(start + 0.001, end))
            if Path(output_path).suffix.lower() == ".vtt":
                start_text, end_text = start_text.replace(",", "."), end_text.replace(",", ".")
            records.append((start_text, end_text, prefix + piece))
    is_vtt = Path(output_path).suffix.lower() == ".vtt"
    output = ["WEBVTT", ""] if is_vtt else []
    for index, (start, end, text) in enumerate(records, 1):
        if not is_vtt:
            output.append(str(index))
        output.extend([f"{start} --> {end}", text, ""])
    Path(output_path).write_text("\n".join(output), encoding="utf-8")

def main():
    action = sys.argv[2]
    if action == "parse" and len(sys.argv) == 6:
        parse_subtitle(sys.argv[3], sys.argv[4], sys.argv[5])
    elif action == "metadata" and len(sys.argv) == 4:
        print_subtitle_metadata(sys.argv[3])
    elif action == "build" and len(sys.argv) == 7:
        build_subtitle(sys.argv[3], sys.argv[4], sys.argv[5], int(sys.argv[6]))
    else:
        raise ValueError("Invalid subtitle helper arguments.")

try:
    main()
except (OSError, UnicodeError, ValueError, json.JSONDecodeError) as exc:
    print(f"Error: {exc}", file=sys.stderr)
    sys.exit(1)
PY
}

translate_cues() {
    python3 "$nemo_helper" translate-progress \
        --nemo-bin "$nemo_bin" \
        --model "$nmt_model" \
        --from "$1" --to "$2" \
        --input "$3" --output "$4"
}

ensure_english() {
    if (( english_ready == 0 )); then
        translate_cues "$source_language" en "$source_text" "$english_text"
        english_ready=1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help) show_help; exit 0 ;;
        -l | --from | --language)
            need_value "$1" "${2:-}"
            source_language_option="$2"
            shift 2
            ;;
        --from=*)
            source_language_option="${1#*=}"
            [[ -n "$source_language_option" ]] || { printf 'Error: --from requires a value.\n' >&2; exit 2; }
            shift
            ;;
        -t | --to)
            need_value "$1" "${2:-}"
            target_mode="$2"
            shift 2
            ;;
        --to=*)
            target_mode="${1#*=}"
            [[ -n "$target_mode" ]] || { printf 'Error: --to requires a value.\n' >&2; exit 2; }
            shift
            ;;
        -m | --nmt-model)
            need_value "$1" "${2:-}"
            nmt_model="$2"
            shift 2
            ;;
        --nmt-model=*)
            nmt_model="${1#*=}"
            [[ -n "$nmt_model" ]] || { printf 'Error: --nmt-model requires a value.\n' >&2; exit 2; }
            shift
            ;;
        -c | --cue)
            need_value "$1" "${2:-}"
            if ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" =~ ^0+$ ]]; then
                printf 'Error: --cue must be a positive integer.\n' >&2
                exit 2
            fi
            max_cue_chars="$2"
            shift 2
            ;;
        -f | --force) force_enabled=1; shift ;;
        --) shift; while [[ $# -gt 0 ]]; do input_files+=("$1"); shift; done; break ;;
        --*) printf 'Error: unknown option: %s\n' "$1" >&2; show_help >&2; exit 2 ;;
        *) input_files+=("$1"); shift ;;
    esac
done

if (( ${#input_files[@]} == 0 )); then
    printf 'Error: no input files were provided.\n\n' >&2
    show_help >&2
    exit 2
fi
if ! command -v python3 >/dev/null 2>&1; then
    printf 'Error: required command not found: python3\n' >&2
    exit 127
fi
if [[ ! -r "$nemo_helper" ]]; then
    printf 'Error: Python helper not found or unreadable: %s\n' "$nemo_helper" >&2
    exit 1
fi

target_mode="$(printf '%s' "$target_mode" | tr '[:upper:]' '[:lower:]')"
if ! python3 -c 'import tqdm' >/dev/null 2>&1; then
    printf 'Error: Python package tqdm is required; install it with: python3 -m pip install tqdm\n' >&2
    exit 1
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/nemo-translate.XXXXXXXX")"
progress_fifo=""
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
    rm -rf -- "$tmp_dir"
}
trap cleanup EXIT
start_progress() {
    local total="$1"
    progress_fifo="$tmp_dir/progress.fifo"
    if ! mkfifo "$progress_fifo"; then
        printf 'Error: could not create the progress pipe.\n' >&2
        return 1
    fi
    python3 "$nemo_helper" progress --total "$total" <"$progress_fifo" &
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
source_text="$tmp_dir/source.txt"
metadata_file="$tmp_dir/cues.json"
english_text="$tmp_dir/english.txt"
korean_text="$tmp_dir/korean.txt"
model_checked=0
start_progress "${#input_files[@]}"

for input_file in "${input_files[@]}"; do
    if [[ ! -f "$input_file" || ! -r "$input_file" ]]; then
        printf 'Error: input file not found or unreadable: %s\n' "$input_file" >&2
        exit 1
    fi
    input_name="$(basename "$input_file")"
    extension="${input_name##*.}"
    case "$extension" in
        srt | SRT | Srt | srT | SrT | sRt | sRT | SRt) subtitle_type=srt ;;
        vtt | VTT | Vtt | vtT | VtT | vTt | vTT | VTt) subtitle_type=vtt ;;
        *) printf 'Error: input must be an .srt or .vtt file: %s\n' "$input_file" >&2; exit 2 ;;
    esac
    subtitle_tool parse "$input_file" "$metadata_file" "$source_text"
    subtitle_info="$(subtitle_tool metadata "$metadata_file")"
    comment_language="${subtitle_info%%$'\t'*}"
    already_translated="${subtitle_info#*$'\t'}"
    if [[ "$already_translated" == "1" ]]; then
        report_status "Skipping: this subtitle is already marked as translated: $input_file"
        advance_progress
        continue
    fi

    input_dir="$(dirname "$input_file")"
    stem="${input_name%.*}"
    filename_language=""
    case "$stem" in
        *.[Ee][Nn]) filename_language=en ;;
        *.[Kk][Oo]) filename_language=ko ;;
    esac
    if [[ -n "$source_language_option" ]]; then
        source_language="$(normalize_language "$source_language_option")"
    elif [[ -n "$comment_language" && "$comment_language" != "und" && "$comment_language" != "auto" ]]; then
        source_language="$(normalize_language "$comment_language")"
    else
        source_language="$filename_language"
    fi
    if [[ -z "$source_language" ]]; then
        printf 'Error: source language is unknown for %s; provide --from CODE or use a .en/.ko filename suffix.\n' "$input_file" >&2
        exit 2
    fi
    case "$source_language" in
        auto | und | unknown)
            printf 'Error: source language is not identified for %s; provide --from CODE.\n' "$input_file" >&2
            exit 2
            ;;
    esac
    if ! [[ "$source_language" =~ ^[a-z][a-z0-9-]*$ ]]; then
        printf 'Error: invalid source language code: %s\n' "$source_language" >&2
        exit 2
    fi
    base_stem="$stem"
    if [[ -n "$filename_language" && "$filename_language" == "$source_language" ]]; then
        base_stem="${stem%.*}"
    fi

    same_language=0
    case "$target_mode" in
        auto | both)
            case "$source_language" in
                en) target_languages=(ko) ;;
                ko) target_languages=(en) ;;
                *) target_languages=(en ko) ;;
            esac
            ;;
        en)
            if [[ "$source_language" == "en" ]]; then same_language=1; else target_languages=(en); fi
            ;;
        ko)
            if [[ "$source_language" == "ko" ]]; then same_language=1; else target_languages=(ko); fi
            ;;
        *) printf 'Error: --to must be auto, en, ko, or both.\n' >&2; exit 2 ;;
    esac
    if (( same_language )); then
        report_status "Skipping: source is already in the requested language: $input_file"
        advance_progress
        continue
    fi

    target_outputs=()
    existing_output=""
    for target_language in "${target_languages[@]}"; do
        target_output="$input_dir/$base_stem.$target_language.$subtitle_type"
        target_outputs+=("$target_output")
        if [[ -z "$existing_output" && ( -e "$target_output" || -L "$target_output" ) ]]; then
            existing_output="$target_output"
        fi
    done
    if [[ -n "$existing_output" && "$force_enabled" -eq 0 ]]; then
        report_status "Skipping: translated output already exists (use --force to overwrite): $existing_output"
        advance_progress
        continue
    fi
    if [[ ! -x "$nemo_bin" ]]; then
        printf 'Error: nemo-speech executable not found or not executable: %s\n' "$nemo_bin" >&2
        exit 127
    fi
    if (( model_checked == 0 )); then
        python3 "$nemo_helper" check-model --kind nmt --nemo-bin "$nemo_bin" --path "$nmt_model"
        model_checked=1
    fi

    report_status "Translating: $input_file"
    english_ready=0
    english_subtitle="$tmp_dir/translated.en.$subtitle_type"
    korean_subtitle="$tmp_dir/translated.ko.$subtitle_type"
    declare -a temporary_outputs=()

    for target_language in "${target_languages[@]}"; do
        if [[ "$target_language" == "en" ]]; then
            ensure_english
            subtitle_tool build "$metadata_file" "$english_text" "$english_subtitle" "$max_cue_chars"
            python3 "$nemo_helper" annotate-subtitle \
                --subtitle "$english_subtitle" \
                --language en \
                --translated
            temporary_outputs+=("$english_subtitle")
        else
            if [[ "$source_language" == "en" ]]; then
                translate_cues en ko "$source_text" "$korean_text"
            else
                ensure_english
                translate_cues en ko "$english_text" "$korean_text"
            fi
            subtitle_tool build "$metadata_file" "$korean_text" "$korean_subtitle" "$max_cue_chars"
            python3 "$nemo_helper" annotate-subtitle \
                --subtitle "$korean_subtitle" \
                --language ko \
                --translated
            temporary_outputs+=("$korean_subtitle")
        fi
    done

    if (( force_enabled == 0 )); then
        existing_output=""
        for target_output in "${target_outputs[@]}"; do
            if [[ -e "$target_output" || -L "$target_output" ]]; then
                existing_output="$target_output"
                break
            fi
        done
        if [[ -n "$existing_output" ]]; then
            report_status "Skipping: translated output appeared during translation (use --force to overwrite): $existing_output"
            advance_progress
            continue
        fi
    fi

    for index in "${!target_languages[@]}"; do
        target_output="${target_outputs[$index]}"
        temporary_output="${temporary_outputs[$index]}"
        if [[ ! -s "$temporary_output" ]]; then
            printf 'Error: translated subtitle output is empty: %s\n' "$temporary_output" >&2
            exit 1
        fi
        if (( force_enabled )); then
            if ! mv -f -- "$temporary_output" "$target_output"; then
                printf 'Error: could not save translated subtitle file: %s\n' "$target_output" >&2
                exit 1
            fi
        else
            if ! mv -n -- "$temporary_output" "$target_output"; then
                printf 'Error: could not save translated subtitle file: %s\n' "$target_output" >&2
                exit 1
            fi
            if [[ -e "$temporary_output" ]]; then
                report_status "Skipping: translated output appeared before it could be saved (use --force to overwrite): $target_output"
                advance_progress
                continue 2
            fi
        fi
        report_status "Saved: $target_output"
    done
    advance_progress
done
