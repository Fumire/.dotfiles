#!/usr/bin/env python3
"""Helpers for nemo.sh: model checks and speaker-aware SRT generation."""

import argparse
import json
import math
import os
import re
import subprocess
import sys
from pathlib import Path

ASR_RESULT_KEYS = (
    "data",
    "result",
    "results",
    "transcript",
    "transcription",
    "transcriptions",
    "output",
    "hypothesis",
    "hypotheses",
    "utterance",
    "utterances",
    "audio",
    "payload",
)
ASR_TEXT_KEYS = ("text", "transcript", "transcription", "pred_text", "hypothesis", "result")


class NoTranscriptError(Exception):
    """Raised when an ASR result has no content from which to build subtitles."""


def read_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ValueError(f"Could not read valid JSON from {path}: {exc}") from exc


def result_objects(data):
    """Yield result dictionaries nested under common ASR wrapper fields."""
    stack = [data]
    while stack:
        value = stack.pop()
        if isinstance(value, dict):
            yield value
            for key in reversed(ASR_RESULT_KEYS):
                nested = value.get(key)
                if isinstance(nested, (dict, list)):
                    stack.append(nested)
        elif isinstance(value, list):
            stack.extend(reversed(value))


def check_model(args):
    path = Path(args.path)
    if not path.is_file() or not os.access(path, os.R_OK):
        raise ValueError(f"The {args.kind.upper()} model file is missing or unreadable: {path}")

    try:
        result = subprocess.run(
            [args.nemo_bin, "model", "info", str(path)],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError as exc:
        raise ValueError(f"Could not inspect the model with nemo-speech: {exc}") from exc

    output = (result.stdout or "").strip()
    diagnostics = "\n".join(part.strip() for part in (result.stderr, result.stdout) if part and part.strip())

    if result.returncode != 0:
        detail = diagnostics or f"model inspection exited with status {result.returncode}"
        raise ValueError(
            f"The {args.kind.upper()} model is not compatible with this nemo-speech runtime: {detail}"
        )

    try:
        info = json.loads(output)
    except json.JSONDecodeError as exc:
        raise ValueError(f"nemo-speech returned invalid model information for {path}: {exc}") from exc

    if info.get("runtime_compatible") is not True:
        errors = info.get("errors") or []
        detail = "; ".join(str(error) for error in errors) or "the runtime marked the model incompatible"
        raise ValueError(f"The {args.kind.upper()} model is not compatible with this nemo-speech runtime: {detail}")

    if args.kind == "nmt" and info.get("role") != "nmt":
        raise ValueError(
            f"The model at {path} is not an NMT model (reported role: {info.get('role')!r})."
        )


def base_language(value):
    if not isinstance(value, str):
        return None
    value = value.strip().replace("_", "-").split("-", 1)[0].lower()
    if re.fullmatch(r"[a-z]{2,3}", value):
        return value
    return None


def language_candidates(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for key in ("code", "language", "language_code", "locale"):
            candidate = value.get(key)
            if isinstance(candidate, str):
                yield candidate
    elif isinstance(value, list):
        for entry in value:
            yield from language_candidates(entry)


def get_source_language(data, words, requested_language):
    selected = base_language(requested_language)
    if selected and selected != "auto":
        return selected

    candidates = []
    for result in result_objects(data):
        for key in ("languages", "language", "language_code", "detected_language"):
            candidates.extend(language_candidates(result.get(key)))

    for item in words:
        if isinstance(item, dict):
            candidates.extend(language_candidates(item.get("language")))
            candidates.extend(language_candidates(item.get("language_code")))

    return next(
        (code for candidate in candidates if (code := base_language(candidate))),
        None,
    )


def record_text(item):
    for key in ("word", "text", "token", "transcript"):
        value = item.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def record_number(item, keys):
    for key in keys:
        try:
            number = float(item[key])
        except (KeyError, TypeError, ValueError):
            continue
        if math.isfinite(number):
            return number
    return None


def record_speaker(item):
    for key in ("speaker", "speaker_id", "speakerId", "spk_id"):
        value = item.get(key)
        if value not in (None, 0, ""):
            return value
    return None


def is_timed_text_record(item):
    return (
        isinstance(item, dict)
        and bool(record_text(item))
        and record_number(item, ("start", "start_time", "begin")) is not None
        and record_number(item, ("end", "end_time", "stop")) is not None
    )


def timestamped_records(data):
    result_dicts = list(result_objects(data))
    for result in result_dicts:
        for key in ("words", "word_timestamps", "word_segments"):
            records = result.get(key)
            if isinstance(records, list):
                usable = [record for record in records if is_timed_text_record(record)]
                if usable:
                    return usable, "words"

    for result in result_dicts:
        for key in ("segments", "utterances"):
            records = result.get(key)
            if isinstance(records, list):
                usable = [record for record in records if is_timed_text_record(record)]
                if usable:
                    return usable, "segments"
    return [], None


def transcript_text(data):
    for result in result_objects(data):
        for key in ASR_TEXT_KEYS:
            value = result.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()

    for result in result_objects(data):
        for key in ("segments", "utterances"):
            records = result.get(key)
            if isinstance(records, list):
                parts = [record_text(record) for record in records if isinstance(record, dict)]
                parts = [part for part in parts if part]
                if parts:
                    return " ".join(parts)
    return None


def result_duration(data):
    for result in result_objects(data):
        for key in ("duration", "audio_duration", "duration_seconds"):
            duration = record_number(result, (key,))
            if duration is not None and duration > 0:
                return duration
    return None


def timestamp(seconds):
    milliseconds = round(max(0, seconds) * 1000)
    hours, milliseconds = divmod(milliseconds, 3_600_000)
    minutes, milliseconds = divmod(milliseconds, 60_000)
    seconds, milliseconds = divmod(milliseconds, 1_000)
    return f"{hours:02}:{minutes:02}:{seconds:02},{milliseconds:03}"


def join_words(items):
    result = ""
    for item in items:
        word = item["word"].strip()
        if not word:
            continue
        if not result:
            result = word
        elif re.match(r"^[.,!?;:%)\]}。！？、]", word):
            result += word
        else:
            result += " " + word
    return result


def speaker_label(speaker):
    if isinstance(speaker, int) and speaker > 0:
        return f"Speaker {speaker}"
    if isinstance(speaker, str):
        match = re.search(r"(?:speaker|spk)[_\s-]*(\d+)", speaker, re.IGNORECASE)
        if match and int(match.group(1)) > 0:
            return f"Speaker {match.group(1)}"
    return "Speaker Unknown"


def build_source(args):
    data = read_json(args.json)
    if not isinstance(data, dict):
        raise ValueError("The transcription JSON root must be an object.")

    word_records, record_kind = timestamped_records(data)
    transcript_fallback = not word_records
    if transcript_fallback:
        recognized_text = transcript_text(data)
        if not isinstance(recognized_text, str) or not recognized_text.strip():
            fields = ", ".join(sorted(str(key) for key in data)) or "none"
            error = data.get("error")
            detail = f" NeMo-Speech reported: {error}." if isinstance(error, str) and error.strip() else ""
            raise NoTranscriptError(
                "The transcription JSON contains no recognized text or timestamped words/segments. "
                f"Top-level fields: {fields}.{detail}"
            )
        duration = result_duration(data)
        if duration is None:
            raise ValueError(
                "The transcription JSON has recognized text but no valid audio duration."
            )
        word_records = [{
            "word": recognized_text,
            "start": 0.0,
            "end": duration,
            "speaker": None,
        }]
        print(
            "Warning: no word timestamps were returned; created one full-duration cue "
            "labeled Speaker Unknown.",
            file=sys.stderr,
        )
    elif record_kind == "segments":
        print(
            "Warning: word-level timestamps were not returned; using timestamped segments.",
            file=sys.stderr,
        )

    if record_kind == "words" and not any(record_speaker(word) is not None for word in word_records):
        raise ValueError("The transcription JSON contains no speaker tags.")

    source_language = get_source_language(data, word_records, args.language)
    items = []
    for item in word_records:
        word = record_text(item)
        if not word:
            continue
        start = record_number(item, ("start", "start_time", "begin"))
        end = record_number(item, ("end", "end_time", "stop"))
        if start is None or end is None:
            raise ValueError("A transcription record has invalid timestamps.")
        if not (math.isfinite(start) and math.isfinite(end)):
            raise ValueError("A word has a non-finite timestamp.")
        items.append({
            "word": word,
            "start": max(0, start),
            "end": max(start, end),
            "speaker": record_speaker(item),
        })

    items.sort(key=lambda item: item["start"])
    cues = []
    current = []

    def flush():
        if not current:
            return
        text = join_words(current)
        if text:
            cues.append({
                "start": current[0]["start"],
                "end": current[-1]["end"],
                "speaker": current[0]["speaker"],
                "text": text,
            })
        current.clear()

    for word in items:
        if current:
            speaker_changed = word["speaker"] != current[-1]["speaker"]
            pause = word["start"] - current[-1]["end"]
            duration = word["end"] - current[0]["start"]
            length = len(join_words(current)) + len(word["word"])
            if speaker_changed or pause > 0.8 or duration > 6.0 or length > 80:
                flush()

        current.append(word)
        if len(current) >= 4 and re.search(r"[.!?。！？]$", word["word"]):
            flush()

    flush()
    if not cues:
        raise ValueError("No SRT subtitle cues could be generated.")

    srt_lines = []
    for index, cue in enumerate(cues, 1):
        srt_lines.extend([
            str(index),
            f"{timestamp(cue['start'])} --> {timestamp(max(cue['start'] + 0.001, cue['end']))}",
            f"[{speaker_label(cue['speaker'])}] {cue['text']}",
            "",
        ])

    try:
        Path(args.srt).write_text("\n".join(srt_lines), encoding="utf-8")
        Path(args.metadata).write_text(
            json.dumps({"source_language": source_language, "cues": cues}, ensure_ascii=False),
            encoding="utf-8",
        )
        Path(args.translation_input).write_text(
            "".join(cue["text"].replace("\n", " ").strip() + "\n" for cue in cues),
            encoding="utf-8",
        )
    except OSError as exc:
        raise ValueError(f"Could not write subtitle files: {exc}") from exc


def print_source_language(args):
    metadata = read_json(args.metadata)
    print(metadata.get("source_language") or "")


def build_translation(args):
    metadata = read_json(args.metadata)
    cues = metadata.get("cues", [])
    if not isinstance(cues, list) or not cues:
        raise ValueError("The subtitle metadata contains no cues.")

    try:
        translated_bytes = Path(args.translation).read_bytes()
    except OSError as exc:
        raise ValueError(f"Could not read translated cue text: {exc}") from exc

    try:
        translated_text = translated_bytes.decode("utf-8")
    except UnicodeDecodeError:
        translated_text = translated_bytes.decode("utf-8", errors="replace")
        print(
            "Warning: translated cue text contained invalid UTF-8 bytes; "
            "invalid sequences were replaced with U+FFFD.",
            file=sys.stderr,
        )
    translations = translated_text.splitlines()

    if len(translations) != len(cues):
        raise ValueError(
            "The number of translated cues does not match the source cues; "
            "the existing translated SRT was left unchanged."
        )

    lines = []
    for index, (cue, translated) in enumerate(zip(cues, translations), 1):
        translated = translated.strip()
        if not translated:
            raise ValueError(
                f"Translation for cue {index} is empty; the existing translated SRT was left unchanged."
            )
        lines.extend([
            str(index),
            f"{timestamp(cue['start'])} --> {timestamp(max(cue['start'] + 0.001, cue['end']))}",
            f"[{speaker_label(cue.get('speaker'))}] {translated}",
            "",
        ])

    try:
        Path(args.output).write_text("\n".join(lines), encoding="utf-8")
    except OSError as exc:
        raise ValueError(f"Could not write the translated SRT: {exc}") from exc


def build_parser():
    parser = argparse.ArgumentParser(description="Support utilities for nemo.sh.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    model_parser = subparsers.add_parser("check-model", help="Check model compatibility.")
    model_parser.add_argument("--kind", choices=("vad", "nmt"), required=True)
    model_parser.add_argument("--nemo-bin", required=True)
    model_parser.add_argument("--path", required=True)
    model_parser.set_defaults(func=check_model)

    source_parser = subparsers.add_parser("build-source", help="Build the source-language SRT.")
    source_parser.add_argument("--json", required=True)
    source_parser.add_argument("--srt", required=True)
    source_parser.add_argument("--metadata", required=True)
    source_parser.add_argument("--translation-input", required=True)
    source_parser.add_argument("--language", required=True)
    source_parser.set_defaults(func=build_source)

    language_parser = subparsers.add_parser("get-language", help="Print the source language code.")
    language_parser.add_argument("--metadata", required=True)
    language_parser.set_defaults(func=print_source_language)

    translation_parser = subparsers.add_parser("build-translation", help="Build the translated SRT.")
    translation_parser.add_argument("--metadata", required=True)
    translation_parser.add_argument("--translation", required=True)
    translation_parser.add_argument("--output", required=True)
    translation_parser.set_defaults(func=build_translation)

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()
    try:
        args.func(args)
    except NoTranscriptError as exc:
        print(f"Warning: {exc}", file=sys.stderr)
        return 3
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
