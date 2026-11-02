#!/usr/bin/env python3
"""Helpers for nemo.sh: model checks, speaker-aware SRTs, and timestamp-free playbooks."""

import argparse
import base64
import binascii
import ctypes
import json
import math
import os
import re
import select
import subprocess
import sys
import threading
import wave
from array import array
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
MAX_SUBTITLE_CUE_CHARS = 50
MIN_SUBTITLE_CUE_CHARS = len("[Speaker Unknown] ") + 1


def parse_cue_chars(value):
    try:
        cue_chars = int(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("must be an integer") from exc
    if cue_chars < MIN_SUBTITLE_CUE_CHARS:
        raise argparse.ArgumentTypeError(
            f"must be at least {MIN_SUBTITLE_CUE_CHARS} to fit a speaker label and one character"
        )
    return cue_chars


class NoTranscriptError(Exception):
    """Raised when an ASR result has no content from which to build subtitles."""


class _AsrBackendConfig(ctypes.Structure):
    _fields_ = [("size", ctypes.c_size_t), ("gpu", ctypes.c_int32)]


class _AsrModelConfig(ctypes.Structure):
    _fields_ = [
        ("size", ctypes.c_size_t),
        ("path", ctypes.c_char_p),
        ("name", ctypes.c_char_p),
    ]


class _AsrVadConfig(ctypes.Structure):
    _fields_ = [
        ("size", ctypes.c_size_t),
        ("model_path", ctypes.c_char_p),
        ("enable_masking", ctypes.c_bool),
        ("onset", ctypes.c_float),
        ("offset", ctypes.c_float),
    ]


class _AsrDiarConfig(ctypes.Structure):
    _fields_ = [
        ("size", ctypes.c_size_t),
        ("model_path", ctypes.c_char_p),
        ("chunk_frames", ctypes.c_int32),
        ("right_context_frames", ctypes.c_int32),
        ("left_context_frames", ctypes.c_int32),
        ("fifo_frames", ctypes.c_int32),
        ("spkcache_frames", ctypes.c_int32),
        ("update_period_frames", ctypes.c_int32),
    ]


class _AsrRecognizerConfig(ctypes.Structure):
    _fields_ = [
        ("size", ctypes.c_size_t),
        ("backend", ctypes.POINTER(_AsrBackendConfig)),
        ("model", ctypes.POINTER(_AsrModelConfig)),
        ("streaming", ctypes.c_void_p),
        ("decoder", ctypes.c_void_p),
        ("vad", ctypes.POINTER(_AsrVadConfig)),
        ("endpointing", ctypes.c_void_p),
        ("postproc", ctypes.c_void_p),
        ("diar", ctypes.POINTER(_AsrDiarConfig)),
        ("batching", ctypes.c_void_p),
    ]


class _AsrRecognitionOptions(ctypes.Structure):
    _fields_ = [
        ("size", ctypes.c_size_t),
        ("request_id", ctypes.c_char_p),
        ("language_code", ctypes.c_char_p),
        ("interim_results", ctypes.c_bool),
        ("enable_word_time_offsets", ctypes.c_bool),
        ("enable_automatic_punctuation", ctypes.c_bool),
        ("verbatim_transcripts", ctypes.c_bool),
        ("profanity_filter", ctypes.c_bool),
        ("stop_history_eou_ms", ctypes.c_int32),
        ("speech_contexts", ctypes.c_void_p),
        ("speech_context_count", ctypes.c_size_t),
        ("max_alternatives", ctypes.c_int32),
        ("enable_speaker_diarization", ctypes.c_bool),
        ("max_speaker_count", ctypes.c_int32),
    ]


class _NmtBackendConfig(ctypes.Structure):
    _fields_ = [("size", ctypes.c_size_t), ("gpu", ctypes.c_int32)]


class _NmtModelConfig(ctypes.Structure):
    _fields_ = [
        ("size", ctypes.c_size_t),
        ("path", ctypes.c_char_p),
        ("n_ctx", ctypes.c_int32),
    ]


class _NmtTranslatorConfig(ctypes.Structure):
    _fields_ = [
        ("size", ctypes.c_size_t),
        ("backend", ctypes.POINTER(_NmtBackendConfig)),
        ("model", ctypes.POINTER(_NmtModelConfig)),
        ("generation", ctypes.c_void_p),
        ("pool", ctypes.c_void_p),
    ]


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


def split_subtitle_text(text, max_chars):
    """Split text at sentence boundaries, then at nearby spaces when needed."""
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return []

    sentence_ends = set(".!?。！？")
    closing_chars = set("\"'”’」』）)]}")
    sentences = []
    start = 0
    index = 0
    while index < len(text):
        char = text[index]
        is_sentence_end = char in "!?。！？"
        if char == ".":
            previous_is_digit = index > 0 and text[index - 1].isdigit()
            next_is_digit = index + 1 < len(text) and text[index + 1].isdigit()
            next_is_boundary = (
                index + 1 == len(text)
                or text[index + 1].isspace()
                or text[index + 1] in closing_chars
            )
            is_sentence_end = not (previous_is_digit and next_is_digit) and next_is_boundary

        if not is_sentence_end:
            index += 1
            continue

        end = index + 1
        while end < len(text) and (text[end] in sentence_ends or text[end] in closing_chars):
            end += 1
        sentence = text[start:end].strip()
        if sentence:
            sentences.append(sentence)
        start = end
        while start < len(text) and text[start].isspace():
            start += 1
        index = start

    remainder = text[start:].strip()
    if remainder:
        sentences.append(remainder)

    chunks = []
    for sentence in sentences:
        remaining = sentence
        while len(remaining) > max_chars:
            split_at = remaining.rfind(" ", 0, max_chars + 1)
            if split_at <= 0:
                split_at = max_chars
            chunk = remaining[:split_at].strip()
            if not chunk:
                split_at = max_chars
                chunk = remaining[:split_at].strip()
            chunks.append(chunk)
            remaining = remaining[split_at:].strip()
        if remaining:
            chunks.append(remaining)
    return chunks


def speaker_label(speaker):
    if isinstance(speaker, int) and speaker > 0:
        return f"Speaker {speaker}"
    if isinstance(speaker, str):
        match = re.search(r"(?:speaker|spk)[_\s-]*(\d+)", speaker, re.IGNORECASE)
        if match and int(match.group(1)) > 0:
            return f"Speaker {match.group(1)}"
    return "Speaker Unknown"


def cue_text_limit(speaker, max_cue_chars=MAX_SUBTITLE_CUE_CHARS):
    """Keep the complete displayed cue, including its speaker label, within the limit."""
    label_length = len(f"[{speaker_label(speaker)}] ")
    return max(1, max_cue_chars - label_length)


def ends_sentence(text):
    closing_chars = "\"'”’」』）)]}"
    text = text.rstrip(closing_chars)
    return text.endswith((".", "!", "?", "。", "！", "？"))


def split_timed_text(text, start, end, speaker, max_cue_chars=MAX_SUBTITLE_CUE_CHARS):
    """Split a timed record and estimate sub-cue times by each text chunk's length."""
    chunks = split_subtitle_text(text, cue_text_limit(speaker, max_cue_chars))
    if not chunks:
        return []

    weights = [max(1, len(chunk)) for chunk in chunks]
    total_weight = sum(weights)
    duration = max(0.0, end - start)
    elapsed_weight = 0
    records = []
    for chunk, weight in zip(chunks, weights):
        chunk_start = start + duration * elapsed_weight / total_weight
        elapsed_weight += weight
        chunk_end = start + duration * elapsed_weight / total_weight
        records.append({
            "word": chunk,
            "start": chunk_start,
            "end": chunk_end,
            "speaker": speaker,
        })
    return records


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
        _write_diagnostic(
            "Warning: no word timestamps were returned; split the transcript into "
            "sentence- or phrase-sized cues with estimated timestamps and labeled Speaker Unknown."
        )
    elif record_kind == "segments":
        _write_diagnostic("Warning: word-level timestamps were not returned; using timestamped segments.")

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
        speaker = record_speaker(item)
        items.extend(split_timed_text(
            word,
            max(0, start),
            max(start, end),
            speaker,
            args.max_cue_chars,
        ))

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
            candidate_text = join_words([*current, word])
            text_limit = cue_text_limit(current[0]["speaker"], args.max_cue_chars)
            if (
                speaker_changed
                or pause > 0.8
                or duration > 6.0
                or len(candidate_text) > text_limit
            ):
                flush()

        current.append(word)
        if ends_sentence(word["word"]):
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
        _write_diagnostic(
            "Warning: translated cue text contained invalid UTF-8 bytes; "
            "invalid sequences were replaced with U+FFFD."
        )
    translations = translated_text.splitlines()

    if len(translations) != len(cues):
        raise ValueError(
            "The number of translated cues does not match the source cues; "
            "the existing translated SRT was left unchanged."
        )

    lines = []
    cue_index = 0
    for index, (cue, translated) in enumerate(zip(cues, translations), 1):
        translated = translated.strip()
        if not translated:
            translated = str(cue.get("text", "")).strip()
            if not translated:
                raise ValueError(
                    f"Translation and source text for cue {index} are empty; "
                    "the translated SRT could not be generated."
                )
            _write_diagnostic(
                f"Warning: translation for cue {index} was empty; "
                "the source cue text was preserved."
            )
        translated_chunks = split_timed_text(
            translated,
            cue["start"],
            cue["end"],
            cue.get("speaker"),
            args.max_cue_chars,
        )
        for translated_cue in translated_chunks:
            cue_index += 1
            lines.extend([
                str(cue_index),
                f"{timestamp(translated_cue['start'])} --> "
                f"{timestamp(max(translated_cue['start'] + 0.001, translated_cue['end']))}",
                f"[{speaker_label(translated_cue.get('speaker'))}] {translated_cue['word']}",
                "",
            ])

    try:
        Path(args.output).write_text("\n".join(lines), encoding="utf-8")
    except OSError as exc:
        raise ValueError(f"Could not write the translated SRT: {exc}") from exc


def build_playbook(args):
    try:
        srt_text = Path(args.srt).read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise ValueError(f"Could not read the SRT file as UTF-8: {exc}") from exc

    timestamp_line = re.compile(r"^\s*\d+:\d{2}:\d{2}[,.]\d{3}\s*-->")
    cue_texts = []
    for block in re.split(r"\r?\n(?:[ \t]*\r?\n)+", srt_text.strip()):
        lines = block.splitlines()
        timestamp_index = next(
            (index for index, line in enumerate(lines) if timestamp_line.match(line)),
            None,
        )
        if timestamp_index is None:
            continue

        text = " ".join(line.strip() for line in lines[timestamp_index + 1:] if line.strip())
        if not text:
            continue

        speaker_match = re.match(r"^\[([^\]]+)\]\s*(.*)$", text)
        if speaker_match:
            speaker, text = speaker_match.groups()
            text = text.strip()
        else:
            speaker = None
        if text:
            cue_texts.append((speaker, text))

    if not cue_texts:
        raise ValueError(f"No timestamped subtitle cues were found in: {args.srt}")

    turns = []
    for speaker, text in cue_texts:
        if turns and turns[-1][0] == speaker:
            turns[-1][1] += " " + text
        else:
            turns.append([speaker, text])

    playbook_lines = [
        f"{speaker}: {text}" if speaker else text
        for speaker, text in turns
    ]
    try:
        Path(args.output).write_text("\n\n".join(playbook_lines) + "\n", encoding="utf-8")
    except OSError as exc:
        raise ValueError(f"Could not write the playbook to {args.output}: {exc}") from exc


def _load_asr_sdk(nemo_bin):
    try:
        executable = Path(nemo_bin).expanduser().resolve(strict=True)
    except OSError as exc:
        raise ValueError(f"Could not resolve the nemo-speech executable: {exc}") from exc

    install_root = executable.parent.parent
    library_paths = (
        install_root / "lib" / "libnemo_speech_asr_c.dylib",
        install_root / "lib" / "libnemo_speech_asr_c.1.dylib",
        install_root / "lib" / "libnemo_speech_asr_c.so",
        install_root / "lib" / "libnemo_speech_asr_c.so.1",
    )
    library_path = next((path for path in library_paths if path.is_file()), None)
    if library_path is None:
        expected = ", ".join(str(path) for path in library_paths)
        raise ValueError(f"NeMo-Speech ASR SDK library was not found. Checked: {expected}")

    try:
        library = ctypes.CDLL(str(library_path))
    except OSError as exc:
        raise ValueError(f"Could not load the NeMo-Speech ASR SDK library at {library_path}: {exc}") from exc

    pointer = ctypes.c_void_p
    library.nemo_speech_asr_create.argtypes = [
        ctypes.POINTER(_AsrRecognizerConfig),
        ctypes.POINTER(pointer),
    ]
    library.nemo_speech_asr_create.restype = ctypes.c_int
    library.nemo_speech_asr_destroy.argtypes = [pointer]
    library.nemo_speech_asr_destroy.restype = None
    library.nemo_speech_asr_streaming_recognize.argtypes = [
        pointer,
        ctypes.POINTER(_AsrRecognitionOptions),
        ctypes.POINTER(pointer),
    ]
    library.nemo_speech_asr_streaming_recognize.restype = ctypes.c_int
    library.nemo_speech_asr_stream_push_f32.argtypes = [
        pointer,
        ctypes.POINTER(ctypes.c_float),
        ctypes.c_size_t,
        ctypes.c_int32,
    ]
    library.nemo_speech_asr_stream_push_f32.restype = ctypes.c_int
    library.nemo_speech_asr_stream_finish.argtypes = [pointer]
    library.nemo_speech_asr_stream_finish.restype = ctypes.c_int
    library.nemo_speech_asr_stream_next.argtypes = [pointer, ctypes.POINTER(pointer)]
    library.nemo_speech_asr_stream_next.restype = ctypes.c_int
    library.nemo_speech_asr_stream_close.argtypes = [pointer]
    library.nemo_speech_asr_stream_close.restype = None
    library.nemo_speech_asr_last_error.argtypes = []
    library.nemo_speech_asr_last_error.restype = ctypes.c_char_p

    library.nemo_speech_asr_result_is_final.argtypes = [pointer]
    library.nemo_speech_asr_result_is_final.restype = ctypes.c_bool
    library.nemo_speech_asr_result_audio_processed.argtypes = [pointer]
    library.nemo_speech_asr_result_audio_processed.restype = ctypes.c_float
    library.nemo_speech_asr_result_alternative_count.argtypes = [pointer]
    library.nemo_speech_asr_result_alternative_count.restype = ctypes.c_size_t
    library.nemo_speech_asr_result_transcript.argtypes = [pointer, ctypes.c_size_t]
    library.nemo_speech_asr_result_transcript.restype = ctypes.c_char_p
    library.nemo_speech_asr_result_word_count.argtypes = [pointer, ctypes.c_size_t]
    library.nemo_speech_asr_result_word_count.restype = ctypes.c_size_t
    library.nemo_speech_asr_result_word_text.argtypes = [
        pointer,
        ctypes.c_size_t,
        ctypes.c_size_t,
    ]
    library.nemo_speech_asr_result_word_text.restype = ctypes.c_char_p
    library.nemo_speech_asr_result_word_start_time.argtypes = [
        pointer,
        ctypes.c_size_t,
        ctypes.c_size_t,
    ]
    library.nemo_speech_asr_result_word_start_time.restype = ctypes.c_int32
    library.nemo_speech_asr_result_word_end_time.argtypes = [
        pointer,
        ctypes.c_size_t,
        ctypes.c_size_t,
    ]
    library.nemo_speech_asr_result_word_end_time.restype = ctypes.c_int32
    library.nemo_speech_asr_result_word_speaker_tag.argtypes = [
        pointer,
        ctypes.c_size_t,
        ctypes.c_size_t,
    ]
    library.nemo_speech_asr_result_word_speaker_tag.restype = ctypes.c_int32
    library.nemo_speech_asr_result_language_count.argtypes = [pointer, ctypes.c_size_t]
    library.nemo_speech_asr_result_language_count.restype = ctypes.c_size_t
    library.nemo_speech_asr_result_language_code.argtypes = [
        pointer,
        ctypes.c_size_t,
        ctypes.c_size_t,
    ]
    library.nemo_speech_asr_result_language_code.restype = ctypes.c_char_p
    library.nemo_speech_asr_result_destroy.argtypes = [pointer]
    library.nemo_speech_asr_result_destroy.restype = None
    return library


def _load_nmt_sdk(nemo_bin):
    try:
        executable = Path(nemo_bin).expanduser().resolve(strict=True)
    except OSError as exc:
        raise ValueError(f"Could not resolve the nemo-speech executable: {exc}") from exc

    install_root = executable.parent.parent
    library_paths = (
        install_root / "lib" / "libnemo_speech_nmt_c.dylib",
        install_root / "lib" / "libnemo_speech_nmt_c.1.dylib",
        install_root / "lib" / "libnemo_speech_nmt_c.so",
        install_root / "lib" / "libnemo_speech_nmt_c.so.1",
    )
    library_path = next((path for path in library_paths if path.is_file()), None)
    if library_path is None:
        expected = ", ".join(str(path) for path in library_paths)
        raise ValueError(f"NeMo-Speech NMT SDK library was not found. Checked: {expected}")

    try:
        library = ctypes.CDLL(str(library_path))
    except OSError as exc:
        raise ValueError(f"Could not load the NeMo-Speech NMT SDK library at {library_path}: {exc}") from exc

    pointer = ctypes.c_void_p
    library.nemo_speech_nmt_create.argtypes = [
        ctypes.POINTER(_NmtTranslatorConfig),
        ctypes.POINTER(pointer),
    ]
    library.nemo_speech_nmt_create.restype = ctypes.c_int
    library.nemo_speech_nmt_destroy.argtypes = [pointer]
    library.nemo_speech_nmt_destroy.restype = None
    library.nemo_speech_nmt_translate.argtypes = [
        pointer,
        ctypes.POINTER(ctypes.c_char_p),
        ctypes.c_size_t,
        ctypes.c_char_p,
        ctypes.c_char_p,
        ctypes.POINTER(pointer),
    ]
    library.nemo_speech_nmt_translate.restype = ctypes.c_int
    library.nemo_speech_nmt_result_count.argtypes = [pointer]
    library.nemo_speech_nmt_result_count.restype = ctypes.c_size_t
    library.nemo_speech_nmt_result_text.argtypes = [pointer, ctypes.c_size_t]
    library.nemo_speech_nmt_result_text.restype = ctypes.c_char_p
    library.nemo_speech_nmt_result_destroy.argtypes = [pointer]
    library.nemo_speech_nmt_result_destroy.restype = None
    library.nemo_speech_nmt_last_error.argtypes = []
    library.nemo_speech_nmt_last_error.restype = ctypes.c_char_p
    return library


def _emit_progress_message(message):
    try:
        os.write(3, f"{message}\n".encode("utf-8"))
        return True
    except OSError:
        return False


class _NativeLogForwarder:
    """Forward native SDK stderr a line at a time through the tqdm process."""

    def __init__(self):
        self.read_fd = None
        self.saved_stderr = None
        self.reader = None

    def start(self):
        read_fd = None
        write_fd = None
        saved_stderr = None
        try:
            read_fd, write_fd = os.pipe()
            saved_stderr = os.dup(2)
            os.dup2(write_fd, 2)
            os.close(write_fd)
        except OSError:
            if saved_stderr is not None:
                try:
                    os.dup2(saved_stderr, 2)
                except OSError:
                    pass
            for fd in (read_fd, write_fd, saved_stderr):
                if fd is not None:
                    try:
                        os.close(fd)
                    except OSError:
                        pass
            return

        self.read_fd = read_fd
        self.saved_stderr = saved_stderr
        self.reader = threading.Thread(target=self._read_lines, daemon=True)
        self.reader.start()

    def _forward_line(self, raw_line):
        raw_line = raw_line.rstrip(b"\r")
        if not raw_line:
            return
        line = raw_line.decode("utf-8", errors="replace")
        if not _emit_progress_message(f"native-log {line}"):
            try:
                os.write(self.saved_stderr, raw_line + b"\n")
            except OSError:
                pass

    def _read_lines(self):
        pending = bytearray()
        try:
            while True:
                chunk = os.read(self.read_fd, 4096)
                if not chunk:
                    break
                pending.extend(chunk)
                while True:
                    newline = pending.find(b"\n")
                    if newline < 0:
                        break
                    self._forward_line(bytes(pending[:newline]))
                    del pending[: newline + 1]
            if pending:
                self._forward_line(bytes(pending))
        finally:
            os.close(self.read_fd)

    def stop(self):
        if self.saved_stderr is None:
            return
        try:
            os.dup2(self.saved_stderr, 2)
        except OSError:
            pass
        if self.reader is not None:
            self.reader.join()
        try:
            os.close(self.saved_stderr)
        except OSError:
            pass
        self.saved_stderr = None


def _emit_progress_event(name, seconds=None):
    event = name if seconds is None else f"{name} {max(0.0, seconds):.6f}"
    _emit_progress_message(event)


def _write_diagnostic(message):
    encoded = base64.b64encode(message.encode("utf-8")).decode("ascii")
    if _emit_progress_message(f"diagnostic-base64 {encoded}"):
        return
    print(message, file=sys.stderr)


def _decode_sdk_text(value):
    return value.decode("utf-8", errors="replace") if value else ""


def translate_progress(args):
    try:
        input_text = Path(args.input).read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise ValueError(f"Could not read translation input {args.input}: {exc}") from exc
    source_texts = input_text.splitlines()
    if not source_texts:
        raise ValueError("The translation input contains no cues.")

    total = len(source_texts)
    _emit_progress_message(
        f"translate-start {total} {args.source_language} {args.target_language}"
    )
    library = None
    translator = ctypes.c_void_p()
    completed = 0
    success = False
    native_logs = _NativeLogForwarder()
    try:
        native_logs.start()
        library = _load_nmt_sdk(args.nemo_bin)
        backend = _NmtBackendConfig(ctypes.sizeof(_NmtBackendConfig), 0)
        model_path = os.fsencode(args.model)
        model = _NmtModelConfig(ctypes.sizeof(_NmtModelConfig), model_path, 0)
        config = _NmtTranslatorConfig()
        config.size = ctypes.sizeof(_NmtTranslatorConfig)
        config.backend = ctypes.pointer(backend)
        config.model = ctypes.pointer(model)

        status = library.nemo_speech_nmt_create(ctypes.byref(config), ctypes.byref(translator))
        if status != 0 or not translator.value:
            detail = _decode_sdk_text(library.nemo_speech_nmt_last_error()) or f"status {status}"
            raise ValueError(f"NeMo-Speech translation initialization failed: {detail}")

        source_language = args.source_language.encode("utf-8")
        target_language = args.target_language.encode("utf-8")
        translated_texts = []
        for index, source_text in enumerate(source_texts, 1):
            encoded_text = source_text.encode("utf-8")
            text_array = (ctypes.c_char_p * 1)(encoded_text)
            result = ctypes.c_void_p()
            status = library.nemo_speech_nmt_translate(
                translator,
                text_array,
                1,
                source_language,
                target_language,
                ctypes.byref(result),
            )
            if status != 0 or not result.value:
                detail = _decode_sdk_text(library.nemo_speech_nmt_last_error()) or f"status {status}"
                raise ValueError(
                    f"NeMo-Speech translation failed for cue {index}/{total}: {detail}"
                )
            try:
                result_count = library.nemo_speech_nmt_result_count(result)
                if result_count != 1:
                    raise ValueError(
                        f"NeMo-Speech returned {result_count} translations for cue {index}/{total}."
                    )
                translated = _decode_sdk_text(
                    library.nemo_speech_nmt_result_text(result, 0)
                ).replace("\r", " ").replace("\n", " ").strip()
            finally:
                library.nemo_speech_nmt_result_destroy(result)

            for attempt in range(1, 3):
                if translated:
                    break
                _write_diagnostic(
                    f"Warning: NeMo-Speech returned an empty translation for cue "
                    f"{index}/{total} ({args.source_language} to {args.target_language}); "
                    f"retrying ({attempt}/2)."
                )
                result = ctypes.c_void_p()
                status = library.nemo_speech_nmt_translate(
                    translator,
                    text_array,
                    1,
                    source_language,
                    target_language,
                    ctypes.byref(result),
                )
                if status != 0 or not result.value:
                    detail = _decode_sdk_text(library.nemo_speech_nmt_last_error()) or f"status {status}"
                    raise ValueError(
                        f"NeMo-Speech translation retry failed for cue {index}/{total}: {detail}"
                    )
                try:
                    result_count = library.nemo_speech_nmt_result_count(result)
                    if result_count != 1:
                        raise ValueError(
                            f"NeMo-Speech returned {result_count} translations for cue {index}/{total}."
                        )
                    translated = _decode_sdk_text(
                        library.nemo_speech_nmt_result_text(result, 0)
                    ).replace("\r", " ").replace("\n", " ").strip()
                finally:
                    library.nemo_speech_nmt_result_destroy(result)

            if not translated:
                _write_diagnostic(
                    f"Warning: translation for cue {index}/{total} remained empty after retries; "
                    "the source cue text was preserved."
                )
                translated = source_text.strip()
            translated_texts.append(translated)
            completed = index
            _emit_progress_message(f"translate-progress {completed}")

        try:
            Path(args.output).write_text("\n".join(translated_texts) + "\n", encoding="utf-8")
        except OSError as exc:
            raise ValueError(f"Could not write translated text to {args.output}: {exc}") from exc
        success = True
    finally:
        if library is not None and translator.value:
            library.nemo_speech_nmt_destroy(translator)
        native_logs.stop()
        if success:
            _emit_progress_message(f"translate-progress {total}")
        _emit_progress_message("translate-stop")


def transcribe_stream(args):
    try:
        audio = wave.open(args.wav, "rb")
    except (OSError, wave.Error) as exc:
        raise ValueError(f"Could not read the converted WAV file {args.wav}: {exc}") from exc

    with audio:
        channels = audio.getnchannels()
        sample_width = audio.getsampwidth()
        sample_rate = audio.getframerate()
        total_frames = audio.getnframes()
        if channels != 1 or sample_width != 2:
            raise ValueError("The converted WAV must contain mono 16-bit PCM audio.")
        if sample_rate <= 0 or total_frames <= 0:
            raise ValueError("The converted WAV contains no audio frames.")
        duration = total_frames / float(sample_rate)

        _emit_progress_event("asr-start", duration)
        library = None
        recognizer = ctypes.c_void_p()
        stream = ctypes.c_void_p()
        processed_seconds = 0.0
        completed = False
        native_logs = _NativeLogForwarder()
        try:
            native_logs.start()
            library = _load_asr_sdk(args.nemo_bin)

            backend = _AsrBackendConfig(ctypes.sizeof(_AsrBackendConfig), 0)
            model_path = os.fsencode(args.model)
            model = _AsrModelConfig(ctypes.sizeof(_AsrModelConfig), model_path, None)
            diar_path = os.fsencode(args.diar_model) if args.diar_model else None
            diar = _AsrDiarConfig(
                ctypes.sizeof(_AsrDiarConfig), diar_path, 0, 0, -1, 0, 0, 0
            )
            vad_path = os.fsencode(args.vad_model) if args.vad_model else None
            vad = _AsrVadConfig(
                ctypes.sizeof(_AsrVadConfig), vad_path, bool(vad_path), 0.5, 0.3
            )
            config = _AsrRecognizerConfig()
            config.size = ctypes.sizeof(_AsrRecognizerConfig)
            config.backend = ctypes.pointer(backend)
            config.model = ctypes.pointer(model)
            config.vad = ctypes.pointer(vad) if vad_path else None
            config.diar = ctypes.pointer(diar) if diar_path else None

            options = _AsrRecognitionOptions()
            options.size = ctypes.sizeof(_AsrRecognitionOptions)
            language = args.language.strip()
            options.language_code = (
                language.encode("utf-8") if language and language.lower() != "auto" else None
            )
            options.interim_results = True
            options.enable_word_time_offsets = True
            options.enable_automatic_punctuation = True
            options.enable_speaker_diarization = bool(diar_path)
            options.max_alternatives = 1

            status = library.nemo_speech_asr_create(ctypes.byref(config), ctypes.byref(recognizer))
            if status != 0 or not recognizer.value:
                detail = _decode_sdk_text(library.nemo_speech_asr_last_error()) or f"status {status}"
                raise ValueError(f"NeMo-Speech ASR initialization failed: {detail}")

            status = library.nemo_speech_asr_streaming_recognize(
                recognizer, ctypes.byref(options), ctypes.byref(stream)
            )
            if status != 0 or not stream.value:
                detail = _decode_sdk_text(library.nemo_speech_asr_last_error()) or f"status {status}"
                raise ValueError(f"NeMo-Speech streaming recognition could not start: {detail}")

            transcript_parts = []
            words = []
            languages = set()

            def accept_final_result(result_handle):
                alternatives = library.nemo_speech_asr_result_alternative_count(result_handle)
                if alternatives == 0:
                    return
                alternative = 0
                text = _decode_sdk_text(
                    library.nemo_speech_asr_result_transcript(result_handle, alternative)
                ).strip()
                if text:
                    transcript_parts.append(text)

                word_count = library.nemo_speech_asr_result_word_count(result_handle, alternative)
                for index in range(word_count):
                    word = _decode_sdk_text(
                        library.nemo_speech_asr_result_word_text(result_handle, alternative, index)
                    ).strip()
                    if not word:
                        continue
                    start_ms = library.nemo_speech_asr_result_word_start_time(
                        result_handle, alternative, index
                    )
                    end_ms = library.nemo_speech_asr_result_word_end_time(
                        result_handle, alternative, index
                    )
                    speaker = library.nemo_speech_asr_result_word_speaker_tag(
                        result_handle, alternative, index
                    )
                    words.append({
                        "word": word,
                        "start": start_ms / 1000.0,
                        "end": end_ms / 1000.0,
                        "speaker": speaker if speaker > 0 else None,
                    })

                language_count = library.nemo_speech_asr_result_language_count(
                    result_handle, alternative
                )
                for index in range(language_count):
                    language_code = _decode_sdk_text(
                        library.nemo_speech_asr_result_language_code(
                            result_handle, alternative, index
                        )
                    ).strip()
                    if language_code:
                        languages.add(language_code)

            def drain_results(finishing=False):
                nonlocal processed_seconds
                while True:
                    result = ctypes.c_void_p()
                    status = library.nemo_speech_asr_stream_next(stream, ctypes.byref(result))
                    if status != 0:
                        detail = _decode_sdk_text(library.nemo_speech_asr_last_error()) or f"status {status}"
                        raise ValueError(f"NeMo-Speech streaming transcription failed: {detail}")
                    if not result.value:
                        return
                    try:
                        result_seconds = library.nemo_speech_asr_result_audio_processed(result)
                        if math.isfinite(result_seconds):
                            processed_seconds = max(
                                processed_seconds, min(duration, max(0.0, result_seconds))
                            )
                            _emit_progress_event("asr-progress", processed_seconds)
                        is_final = library.nemo_speech_asr_result_is_final(result)
                        if is_final:
                            accept_final_result(result)
                        elif not finishing:
                            return
                    finally:
                        library.nemo_speech_asr_result_destroy(result)

            chunk_frames = max(1, sample_rate * 160 // 1000)
            while True:
                raw_samples = audio.readframes(chunk_frames)
                if not raw_samples:
                    break
                pcm_samples = array("h")
                pcm_samples.frombytes(raw_samples)
                if sys.byteorder != "little":
                    pcm_samples.byteswap()
                float_samples = array("f", (sample / 32768.0 for sample in pcm_samples))
                float_buffer = (ctypes.c_float * len(float_samples)).from_buffer(float_samples)
                status = library.nemo_speech_asr_stream_push_f32(
                    stream, float_buffer, len(float_samples), sample_rate
                )
                if status != 0:
                    detail = _decode_sdk_text(library.nemo_speech_asr_last_error()) or f"status {status}"
                    raise ValueError(f"NeMo-Speech could not process an audio chunk: {detail}")
                drain_results()

            status = library.nemo_speech_asr_stream_finish(stream)
            if status != 0:
                detail = _decode_sdk_text(library.nemo_speech_asr_last_error()) or f"status {status}"
                raise ValueError(f"NeMo-Speech could not finish streaming transcription: {detail}")
            drain_results(finishing=True)

            transcript = ""
            attaches_to_previous = set(",.!?;:%)]}»’”、。，！？；：…")
            for part in transcript_parts:
                if transcript and part and part[0] not in attaches_to_previous:
                    transcript += " "
                transcript += part

            payload = {
                "text": transcript,
                "duration": duration,
                "languages": sorted(languages),
                "words": words,
            }
            try:
                Path(args.json).write_text(
                    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )
            except OSError as exc:
                raise ValueError(f"Could not write transcription JSON to {args.json}: {exc}") from exc

            processed_seconds = duration
            _emit_progress_event("asr-progress", processed_seconds)
            completed = True
        finally:
            if library is not None:
                if stream.value:
                    library.nemo_speech_asr_stream_close(stream)
                if recognizer.value:
                    library.nemo_speech_asr_destroy(recognizer)
            native_logs.stop()
            _emit_progress_event("asr-stop", duration if completed else processed_seconds)


def _format_media_time(seconds):
    seconds = max(0, int(seconds))
    hours, remaining = divmod(seconds, 3600)
    minutes, seconds = divmod(remaining, 60)
    return f"{hours:02}:{minutes:02}:{seconds:02}"


def show_progress(args):
    try:
        from tqdm import tqdm
    except ImportError as exc:
        raise ValueError(
            "Python package tqdm is required. Install it with: python3 -m pip install tqdm"
        ) from exc

    files_bar = tqdm(
        total=args.total,
        desc="Files",
        unit="file",
        dynamic_ncols=True,
        file=sys.stderr,
    )
    task_bar = None
    translation_source = "source"
    translation_target = "target"
    pending = b""
    input_fd = sys.stdin.fileno()
    try:
        while True:
            readable, _, _ = select.select([input_fd], [], [], 0.12)
            if readable:
                chunk = os.read(input_fd, 4096)
                if not chunk:
                    break
                pending += chunk
                while b"\n" in pending:
                    raw_event, pending = pending.split(b"\n", 1)
                    event = raw_event.decode("utf-8", errors="replace").rstrip("\r")
                    if event == "1":
                        files_bar.update(1)
                    elif event.startswith("native-log "):
                        tqdm.write(event[len("native-log "):], file=sys.stderr)
                    elif event.startswith(("status-base64 ", "diagnostic-base64 ")):
                        encoded = event.partition(" ")[2]
                        try:
                            message = base64.b64decode(encoded, validate=True).decode(
                                "utf-8", errors="replace"
                            )
                        except (ValueError, binascii.Error):
                            continue
                        for message_line in message.split("\n"):
                            tqdm.write(message_line.rstrip("\r"), file=sys.stderr)
                    elif event.startswith("asr-start "):
                        try:
                            duration = max(0.0, float(event.split(maxsplit=1)[1]))
                        except (IndexError, ValueError):
                            duration = 0.0
                        if task_bar is not None:
                            task_bar.close()
                        task_bar = tqdm(
                            total=duration,
                            desc=f"Transcribing 00:00:00 / {_format_media_time(duration)}",
                            unit="s",
                            bar_format="{desc}: {bar} {percentage:3.0f}% [{elapsed} elapsed, ETA {remaining}]",
                            dynamic_ncols=True,
                            file=sys.stderr,
                            position=1,
                            leave=False,
                        )
                    elif event.startswith("asr-progress ") and task_bar is not None:
                        try:
                            processed = max(0.0, float(event.split(maxsplit=1)[1]))
                        except (IndexError, ValueError):
                            continue
                        if task_bar.total is not None:
                            processed = min(processed, task_bar.total)
                        if processed > task_bar.n:
                            task_bar.update(processed - task_bar.n)
                        total = task_bar.total or 0.0
                        task_bar.set_description_str(
                            f"Transcribing {_format_media_time(processed)} / {_format_media_time(total)}",
                            refresh=True,
                        )
                    elif event.startswith("translate-start "):
                        parts = event.split(maxsplit=3)
                        try:
                            total = max(0, int(parts[1]))
                        except (IndexError, ValueError):
                            total = 0
                        translation_source = parts[2] if len(parts) > 2 else "source"
                        translation_target = parts[3] if len(parts) > 3 else "target"
                        if task_bar is not None:
                            task_bar.close()
                        task_bar = tqdm(
                            total=total,
                            desc=f"Translating ({translation_source} to {translation_target}) 0/{total} cues",
                            unit="cue",
                            bar_format="{desc}: {bar} {percentage:3.0f}% [{elapsed} elapsed, ETA {remaining}]",
                            dynamic_ncols=True,
                            file=sys.stderr,
                            position=1,
                            leave=False,
                        )
                    elif event.startswith("translate-progress ") and task_bar is not None:
                        try:
                            completed = max(0, int(event.split(maxsplit=1)[1]))
                        except (IndexError, ValueError):
                            continue
                        if task_bar.total is not None:
                            completed = min(completed, int(task_bar.total))
                        if completed > task_bar.n:
                            task_bar.update(completed - task_bar.n)
                        total = int(task_bar.total or 0)
                        task_bar.set_description_str(
                            f"Translating ({translation_source} to {translation_target}) {completed}/{total} cues",
                            refresh=True,
                        )
                    elif event.startswith(("asr-stop", "translate-stop")) and task_bar is not None:
                        task_bar.close()
                        task_bar = None
    finally:
        if task_bar is not None:
            task_bar.close()
        files_bar.close()


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
    source_parser.add_argument(
        "--max-cue-chars", type=parse_cue_chars, default=MAX_SUBTITLE_CUE_CHARS
    )
    source_parser.set_defaults(func=build_source)

    language_parser = subparsers.add_parser("get-language", help="Print the source language code.")
    language_parser.add_argument("--metadata", required=True)
    language_parser.set_defaults(func=print_source_language)

    translation_parser = subparsers.add_parser("build-translation", help="Build the translated SRT.")
    translation_parser.add_argument("--metadata", required=True)
    translation_parser.add_argument("--translation", required=True)
    translation_parser.add_argument("--output", required=True)
    translation_parser.add_argument(
        "--max-cue-chars", type=parse_cue_chars, default=MAX_SUBTITLE_CUE_CHARS
    )
    translation_parser.set_defaults(func=build_translation)

    translate_progress_parser = subparsers.add_parser(
        "translate-progress", help="Translate subtitle cues with tqdm progress."
    )
    translate_progress_parser.add_argument("--nemo-bin", required=True)
    translate_progress_parser.add_argument("--model", required=True)
    translate_progress_parser.add_argument("--from", "--source-language", dest="source_language", required=True)
    translate_progress_parser.add_argument("--to", "--target-language", dest="target_language", required=True)
    translate_progress_parser.add_argument("--input", required=True)
    translate_progress_parser.add_argument("--output", required=True)
    translate_progress_parser.set_defaults(func=translate_progress)

    playbook_parser = subparsers.add_parser(
        "build-playbook", help="Build a timestamp-free speaker script from an SRT file."
    )
    playbook_parser.add_argument("--srt", required=True)
    playbook_parser.add_argument("--output", required=True)
    playbook_parser.set_defaults(func=build_playbook)

    progress_parser = subparsers.add_parser(
        "progress", help="Display file, transcription, and translation progress with tqdm."
    )
    progress_parser.add_argument("--total", type=int, required=True)
    progress_parser.set_defaults(func=show_progress)

    asr_parser = subparsers.add_parser(
        "transcribe-stream", help="Transcribe a WAV file with decoded-audio progress."
    )
    asr_parser.add_argument("--nemo-bin", required=True)
    asr_parser.add_argument("--wav", required=True)
    asr_parser.add_argument("--json", required=True)
    asr_parser.add_argument("--model", required=True)
    asr_parser.add_argument("--language", default="auto")
    asr_parser.add_argument("--diar-model", default="")
    asr_parser.add_argument("--vad-model", default="")
    asr_parser.set_defaults(func=transcribe_stream)

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()
    try:
        args.func(args)
    except NoTranscriptError as exc:
        _write_diagnostic(f"Warning: {exc}")
        return 3
    except Exception as exc:
        _write_diagnostic(f"Error: {exc}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
