#!/usr/bin/env python3
"""Run whisper-cli or FFmpeg with a media-time tqdm progress bar."""

import argparse
import os
import re
import subprocess
import sys


PROGRESS_PATTERN = re.compile(r"\bprogress\s*=\s*(\d{1,3})%")


def format_media_time(seconds):
    seconds = max(0, int(seconds))
    hours, remainder = divmod(seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}"


def parse_ffmpeg_time(line):
    if not line.startswith("out_time="):
        return None
    timestamp = line.partition("=")[2].strip()
    try:
        hours, minutes, seconds = timestamp.split(":", 2)
        return int(hours) * 3600 + int(minutes) * 60 + float(seconds)
    except (ValueError, TypeError):
        return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--progress-mode", choices=("transcribe", "ffmpeg"), default="transcribe")
    parser.add_argument("--duration", type=float, default=0.0)
    parser.add_argument("--description", default="Processing")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()

    command = args.command
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        print("Error: no command was provided.", file=sys.stderr)
        return 2

    try:
        from tqdm import tqdm
    except ImportError:
        print(
            "Error: Python package tqdm is required; install it with: python3 -m pip install tqdm",
            file=sys.stderr,
        )
        return 2

    duration = max(0.0, args.duration)
    is_ffmpeg = args.progress_mode == "ffmpeg"
    total = (duration if duration > 0 else None) if is_ffmpeg else (duration if duration > 0 else 100.0)
    if is_ffmpeg:
        description = (
            f"{args.description} {format_media_time(0)} / {format_media_time(duration)}"
            if duration > 0
            else args.description
        )
    else:
        description = (
            f"Transcribing {format_media_time(0)} / {format_media_time(duration)}"
            if duration > 0
            else "Transcribing"
        )
    bar_format = (
        "{desc}: {bar} {percentage:3.0f}% [{elapsed} elapsed, ETA {remaining}]"
        if total is not None
        else "{desc}: {bar} {n_fmt} s [{elapsed} elapsed, ETA {remaining}]"
    )
    progress = tqdm(
        total=total,
        desc=description,
        unit="s" if duration > 0 or is_ffmpeg else "%",
        bar_format=bar_format,
        dynamic_ncols=True,
        file=sys.stderr,
        position=0,
        leave=False,
    )
    diagnostics = []

    try:
        process = subprocess.Popen(
            command,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE if is_ffmpeg else subprocess.DEVNULL,
            stderr=subprocess.STDOUT if is_ffmpeg else subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
        )
    except OSError as error:
        progress.close()
        executable = os.path.basename(command[0])
        print(f"Error: could not start {executable}: {error}", file=sys.stderr)
        return 127

    completed = 0.0
    try:
        output_stream = process.stdout if is_ffmpeg else process.stderr
        assert output_stream is not None
        for line in output_stream:
            clean_line = line.rstrip("\r\n")
            if is_ffmpeg:
                key, separator, value = clean_line.partition("=")
                if separator and key == "out_time":
                    seconds = parse_ffmpeg_time(clean_line)
                    if seconds is not None:
                        target = min(seconds, duration) if duration > 0 else max(seconds, progress.n)
                        if target > progress.n:
                            progress.update(target - progress.n)
                        current_time = format_media_time(target)
                        label = (
                            f"{args.description} {current_time} / {format_media_time(duration)}"
                            if duration > 0
                            else f"{args.description} {current_time}"
                        )
                        progress.set_description_str(label, refresh=True)
                    continue
                if separator and key == "progress":
                    if value == "end" and duration > 0 and progress.n < duration:
                        progress.update(duration - progress.n)
                        progress.set_description_str(
                            f"{args.description} {format_media_time(duration)} / {format_media_time(duration)}",
                            refresh=True,
                        )
                    continue
                if separator and (key in {
                    "frame", "fps", "bitrate", "total_size", "out_time_us", "out_time_ms",
                    "dup_frames", "drop_frames", "speed",
                } or key.startswith("stream_")):
                    continue
                if clean_line:
                    diagnostics.append(clean_line)
                continue

            match = PROGRESS_PATTERN.search(clean_line)
            if not match:
                diagnostics.append(clean_line)
                continue

            percent = min(100, max(0, int(match.group(1))))
            target = total * percent / 100.0
            if target > completed:
                progress.update(target - completed)
                completed = target
            if duration > 0:
                progress.set_description_str(
                    f"Transcribing {format_media_time(target)} / {format_media_time(duration)}",
                    refresh=True,
                )

        return_code = process.wait()
        if return_code == 0 and total is not None and progress.n < total:
            progress.update(total - progress.n)
    except KeyboardInterrupt:
        process.terminate()
        process.wait()
        raise
    finally:
        progress.close()

    if return_code != 0:
        for line in diagnostics:
            if line:
                tqdm.write(line, file=sys.stderr)
        return return_code if return_code > 0 else 128 - return_code

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
